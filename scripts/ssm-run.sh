#!/bin/bash
# Runs in GitHub Actions: sends scripts/deploy.sh to the server over SSM.
set -u
TARGET="$1"

PARAMS=$(
  { echo "export TARGET=$TARGET IMAGE=$IMAGE SHA=$SHA SIMULATE_FAILURE=${SIMULATE_FAILURE:-0}"
    cat scripts/deploy.sh
  } | jq -Rs '{commands: split("\n")}'
)

CMD_ID=$(aws ssm send-command \
  --instance-ids "$INSTANCE_ID" \
  --document-name AWS-RunShellScript \
  --parameters "$PARAMS" \
  --query Command.CommandId --output text)
echo "SSM command: $CMD_ID"

STATUS=Pending
for i in $(seq 1 60); do
  sleep 5
  STATUS=$(aws ssm get-command-invocation --command-id "$CMD_ID" --instance-id "$INSTANCE_ID" \
    --query Status --output text 2>/dev/null || echo Pending)
  case "$STATUS" in Pending|InProgress|Delayed) ;; *) break ;; esac
done

aws ssm get-command-invocation --command-id "$CMD_ID" --instance-id "$INSTANCE_ID" --query StandardOutputContent --output text
aws ssm get-command-invocation --command-id "$CMD_ID" --instance-id "$INSTANCE_ID" --query StandardErrorContent --output text
echo "SSM status: $STATUS"
[ "$STATUS" = "Success" ]
