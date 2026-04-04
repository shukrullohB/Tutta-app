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

# Repo root'dan build bo'layotgan bo'lsa, backend dagi fayllarni /app ga copy qilamiz
COPY backend/ /app/

RUN python -m pip install --upgrade pip \
  && python -m pip install --no-cache-dir -r requirements.txt

RUN python manage.py collectstatic --noinput

EXPOSE 8000

CMD ["sh", "-c", "gunicorn config.wsgi:application --bind 0.0.0.0:${PORT:-8000} --workers 3 --timeout 120"]
