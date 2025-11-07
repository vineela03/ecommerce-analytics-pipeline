FROM python:3.11-slim

WORKDIR /app

# Install system dependencies (git required by dbt)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        postgresql-client && \
    rm -rf /var/lib/apt/lists/*

# Install dbt
RUN pip install --no-cache-dir \
    dbt-core==1.9.0 \
    dbt-postgres==1.9.0

# Copy dbt project
COPY . /app/dbt

WORKDIR /app/dbt

# Set environment variables
ENV DBT_PROFILES_DIR=/app/dbt
ENV DBT_SEND_ANONYMOUS_USAGE_STATS=False

CMD ["dbt", "run"]