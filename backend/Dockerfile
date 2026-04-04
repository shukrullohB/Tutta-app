# syntax=docker/dockerfile:1

FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/usr/local/bin:$PATH"

WORKDIR /app

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
      build-essential \
      postgresql-client \
      libpq-dev \
      curl \
  && rm -rf /var/lib/apt/lists/*

# Build context should be the backend directory (Railway root dir = backend)
COPY . /app/

RUN python -m pip install --upgrade pip \
  && python -m pip install --no-cache-dir -r requirements.txt

RUN chmod +x /app/entrypoint.sh

EXPOSE 8000

CMD ["sh", "/app/entrypoint.sh"]
