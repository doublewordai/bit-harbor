# Minimal container for storing Hugging Face model weights
# Uses huggingface-hub to download only essential files
FROM python:3.11-alpine as downloader

# Install huggingface-hub
RUN pip install --no-cache-dir huggingface-hub

# Arguments for model download
ARG MODEL_REPO
ARG MODEL_NAME
ARG HF_TOKEN=""

# Set working directory and create models directory
WORKDIR /workspace
RUN mkdir -p /models

# Copy download script
COPY download_model.py /workspace/download_model.py

# Download the model
RUN MODEL_REPO="${MODEL_REPO}" HF_TOKEN="${HF_TOKEN}" python download_model.py

# Test stage for debugging
FROM downloader as test
RUN ls -la /models && \
    du -sh /models/* | head -10

# Build a minimal static binary that just exits
FROM golang:alpine as binary-builder
RUN echo 'package main; func main() {}' > /tmp/pause.go && \
    cd /tmp && \
    CGO_ENABLED=0 go build -ldflags="-s -w" -o /pause pause.go

# Final minimal image with just the model files
FROM scratch

# Copy model files from downloader stage  
COPY --from=downloader /models /models

# Copy the pause binary for container to run
COPY --from=binary-builder /pause /pause

# Add labels for documentation
ARG MODEL_NAME
LABEL org.opencontainers.image.source="https://github.com/bit-harbor/bit-harbor"
LABEL org.opencontainers.image.description="Minimal container with ${MODEL_NAME} model weights"
LABEL org.opencontainers.image.title="${MODEL_NAME}"

# Set the pause binary as entrypoint and command
ENTRYPOINT ["/pause"]
CMD ["/pause"]

# This container is meant to be used as an init container
# The files are available at /models for copying to shared volumes