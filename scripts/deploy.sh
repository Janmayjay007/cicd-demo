#!/bin/bash
# Runs ON the server (sent over SSM). Expects TARGET, IMAGE, SHA, SIMULATE_FAILURE.
set -u
export HOME=${HOME:-/root}

if [ "$TARGET" = "production" ]; then NAME=cicd-demo; PORT=8000; else NAME=cicd-demo-staging; PORT=8001; fi

aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin "${IMAGE%%/*}" || exit 1
docker pull "$IMAGE" || exit 1

PREV=$(docker inspect --format '{{.Config.Image}}' "$NAME" 2>/dev/null || true)
echo "Previous image: ${PREV:-none}"

run_container() {  # $1=image  $2=version  $3=simulate-failure flag
  docker rm -f "$NAME" >/dev/null 2>&1 || true
  docker run -d --name "$NAME" --restart unless-stopped -p "$PORT:8000" \
    -e APP_VERSION="$2" -e SIMULATE_FAILURE="$3" "$1" >/dev/null
}

healthy() {
  for i in $(seq 1 15); do
    curl -fs "localhost:$PORT/health" >/dev/null && return 0
    sleep 2
  done
  return 1
}

run_container "$IMAGE" "$SHA" "$SIMULATE_FAILURE"
if healthy; then
  echo "HEALTHY: $NAME is running $SHA"
  exit 0
fi

echo "UNHEALTHY: the new version failed its health check"
docker logs "$NAME" 2>&1 | tail -n 10
if [ -n "$PREV" ]; then
  echo "Rolling back to $PREV"
  run_container "$PREV" "${PREV##*:}" 0
  if healthy; then echo "ROLLED BACK: $NAME is running ${PREV##*:}"; else echo "ROLLBACK ALSO FAILED"; fi
else
  echo "No previous image to roll back to"
  docker rm -f "$NAME" >/dev/null 2>&1 || true
fi
exit 1
