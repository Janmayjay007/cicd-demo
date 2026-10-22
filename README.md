# cicd-demo

![CI](https://github.com/Janmayjay007/cicd-demo/actions/workflows/ci.yml/badge.svg)

A small Flask API used to demonstrate a CI/CD pipeline with GitHub Actions, Docker and AWS.

## Endpoints

| Path | Returns |
|---|---|
| `/health` | `{"status":"ok"}`, used by health checks |
| `/version` | The running version (`APP_VERSION` env var, default `dev`) |
| `/items` | A sample list of items |

## Run locally

```bash
python3.12 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
python -m pytest -v
python -m app.main        # serves on http://localhost:8000
```

## Run with Docker

```bash
docker build -t cicd-demo:local .
docker run -d -p 8000:8000 -e APP_VERSION=local --name cicd-demo cicd-demo:local
curl localhost:8000/health
```

The image runs gunicorn as a non-root user and has a built-in `HEALTHCHECK`.

## CI pipeline

On every push to `main` and every pull request (`.github/workflows/ci.yml`):

1. **test**: install dependencies and run pytest.
2. **build**: only runs if tests pass. Builds the Docker image, tags it with the commit SHA, starts it, and fails the job unless `/health` responds.

A failing test blocks the build job, so a broken change can't produce an image.

## Roadmap

- [x] Flask API with tests
- [x] Dockerfile with health check
- [x] CI: test, build, smoke test
- [x] Push images to Amazon ECR
- [x] Deploy to AWS
- [ ] Staging, manual approval, production
- [ ] Automatic rollback on failed health check
- [ ] Architecture diagram