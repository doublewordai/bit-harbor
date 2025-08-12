# Minimal container for storing Hugging Face model weights
# Uses git-lfs to clone models directly from Hugging Face
FROM alpine:latest as downloader

# Install git and git-lfs
RUN apk add --no-cache git git-lfs

# Arguments for model download
ARG MODEL_REPO
ARG MODEL_NAME
ARG HF_TOKEN=""

# Set working directory
WORKDIR /workspace

# Configure git for Hugging Face
RUN git config --global user.email "container@example.com" && \
    git config --global user.name "Container Builder"

# Download the model using git
RUN if [ -n "${HF_TOKEN}" ]; then \
        # Use token for authentication on gated models
        echo "Using authentication for gated model"; \
        git clone https://user:${HF_TOKEN}@$(echo ${MODEL_REPO} | sed 's|https://||') /models; \
    else \
        # Public model, no auth needed
        echo "Cloning public model: ${MODEL_REPO}"; \
        git clone ${MODEL_REPO} /models; \
    fi

# Remove git metadata to save space
RUN rm -rf /models/.git

# List downloaded files for verification
RUN echo "Downloaded files:" && \
    find /models -type f -name "*.bin" -o -name "*.safetensors" -o -name "*.json" -o -name "*.txt" | head -20

# Test stage for debugging
FROM downloader as test
RUN ls -la /models && \
    du -sh /models/* | head -10

# Final minimal image with just the model files
FROM scratch

# Copy model files from downloader stage
COPY --from=downloader /models /models

# Add labels for documentation
ARG MODEL_NAME
LABEL org.opencontainers.image.source="https://github.com/bit-harbor/bit-harbor"
LABEL org.opencontainers.image.description="Minimal container with ${MODEL_NAME} model weights"
LABEL org.opencontainers.image.title="${MODEL_NAME}"

# This container is meant to be used as an init container
# The files are available at /models for copying to shared volumes