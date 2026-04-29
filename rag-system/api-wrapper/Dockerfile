FROM node:20-alpine

WORKDIR /app

# Install dependencies first (layer caching)
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force

# Copy application
COPY . .

# Expose port
EXPOSE 3004

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3004/api/rag/health || exit 1

# Run as non-root user
USER node

CMD ["node", "index.js"]
