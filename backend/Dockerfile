# syntax=docker/dockerfile:1

FROM python:3.11-slim

# Fail fast + avoid .pyc + flush logs in real time
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    # Ensure 'python' and 'pip' are always available on PATH
    PATH="/usr/local/bin:$PATH"

WORKDIR /app

# System deps:
# - build-essential: compile any wheels that need it
# - postgresql-client + libpq-dev: Postgres client libs (psycopg2)
# - curl: useful for debugging/healthchecks
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
      build-essential \
      postgresql-client \
      libpq-dev \
      curl \
  && rm -rf /var/lib/apt/lists/*

COPY requirements.txt requirements.txt

# Use python -m pip so we never rely on a 'pip' binary being present
RUN python -m pip install --upgrade pip \
  && python -m pip install --no-cache-dir -r requirements.txt

# Copy the rest of the app
COPY . .

# Collect static at build time (safe; does not require DB)
RUN python manage.py collectstatic --noinput

# Railway provides $PORT at runtime
EXPOSE 8000

# Start Gunicorn on the dynamic PORT env var
CMD ["sh", "-c", "gunicorn config.wsgi:application --bind 0.0.0.0:${PORT:-8000} --workers 3 --timeout 120"]
