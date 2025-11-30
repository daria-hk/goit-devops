# Dockerfile für Django-Applikation
FROM python:3.11-slim

# Setze Arbeitsverzeichnis
WORKDIR /app

# Umgebungsvariablen
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1

# System dependencies installieren
RUN apt-get update && apt-get install -y \
    gcc \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# Python dependencies installieren
COPY requirements.txt .
RUN pip install --upgrade pip && \
    pip install -r requirements.txt

# Applikation kopieren
COPY app/ .

# Non-root user erstellen
RUN useradd -m -u 1000 django && \
    chown -R django:django /app

USER django

# Port exponieren
EXPOSE 8000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:8000/health', timeout=2)"

# Start command
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "4", "config.wsgi:application"]

