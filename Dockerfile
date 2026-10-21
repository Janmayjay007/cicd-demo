# Small official Python image, same version as your Mac
FROM python:3.12-slim

# Don't write .pyc files; show logs immediately
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Install dependencies first so Docker can cache this layer
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Then copy the code
COPY app/ ./app/

# Run as a non-root user (a security best practice)
RUN useradd --create-home appuser
USER appuser

EXPOSE 8000

# Docker checks this every 30s; slim images have no curl, so use Python
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')"

# Production server instead of Flask's dev server
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "app.main:app"]
