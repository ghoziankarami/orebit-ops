FROM python:3.11-slim AS dashboard

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

COPY scripts/ /app/scripts/
COPY config/ /app/config/
COPY .env.example /app/.env.example

RUN pip install --no-cache-dir \
    streamlit \
    chromadb \
    requests \
    numpy \
    pandas \
    pyyaml \
    folium \
    plotly \
    matplotlib \
    seaborn

EXPOSE 8503

CMD ["streamlit", "run", "/app/scripts/rag_dashboard_full.py", "--server.port", "8503", "--server.address", "0.0.0.0"]

FROM node:18-slim AS api-wrapper

ENV NODE_ENV=production
ENV RAG_API_HOST=0.0.0.0

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-venv \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

ENV PATH="/opt/venv/bin:${PATH}"

RUN python3 -m venv /opt/venv

COPY api-wrapper/package*.json ./
RUN npm ci --omit=dev

RUN pip install --no-cache-dir chromadb requests

COPY api-wrapper/ ./

EXPOSE 3004

CMD ["node", "index.js"]
