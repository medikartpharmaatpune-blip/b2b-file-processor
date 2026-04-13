# ── Stage 1: dependency installer ──────────────────────────────────────────
# Separate stage means pip install runs in isolation.
# Final image won't contain gcc, build tools, or pip cache.
FROM python:3.11-slim AS builder

WORKDIR /build

# Copy requirements FIRST — before any source code.
# This layer only rebuilds when requirements.txt changes,
# not on every code change. Critical for fast CI/CD builds.
COPY requirements.txt .

RUN pip install --no-cache-dir --prefix=/install -r requirements.txt


# ── Stage 2: final runtime image ───────────────────────────────────────────
FROM python:3.11-slim AS runtime

# Non-root user — security baseline, expected in regulated environments
RUN groupadd -r appuser && useradd -r -g appuser appuser

# Critical for container logging — without this Python buffers stdout
# and docker logs / Cloud Logging sees nothing until buffer flushes
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONPATH=/app

WORKDIR /app

# Copy only the installed packages from the builder stage.
# No build tools, no compiler, no pip cache in the final image.
COPY --from=builder /install /usr/local

# Copy application source — this layer changes on every code change.
# Kept last so all layers above it stay cached between deployments.
COPY --chown=appuser:appuser app/ ./app/

# Document the health check port
EXPOSE 8080

# Switch to non-root before the process starts
USER appuser

# Exec form — SIGTERM reaches Python directly, not a shell wrapper.
# Gunicorn serves the health endpoint; main subscriber runs alongside.
CMD ["python", "-m", "app.main"]
