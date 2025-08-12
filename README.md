# Bit Harbor

Minimal containers with Hugging Face model weights for Kubernetes init containers.

## What is this?

This repository automatically builds tiny containers containing only LLM model weights from Hugging Face. These containers are designed to be used as Kubernetes init containers to speed up ML workloads by pre-downloading models.

## Quick Start

Use a pre-built model container as an init container. Since these are scratch-based containers without shell, you need a helper container to copy files:

```yaml
initContainers:
# First container provides the models (exits immediately)
- name: model-provider
  image: ghcr.io/doublewordai/bit-harbor:gemma-3-4b-it
  volumeMounts:
  - name: model-volume
    mountPath: /data
  # No command needed - container has built-in /pause binary

# Second container copies the models to shared volume
- name: model-copier
  image: busybox:stable
  volumeMounts:
  - name: model-volume
    mountPath: /data
  - name: shared-models
    mountPath: /shared
  command: ['sh', '-c', 'cp -r /data/models/* /shared/']

volumes:
- name: model-volume
  emptyDir: {}
- name: shared-models
  emptyDir: {}
```

Your main container can then access the models from the shared-models volume.

## Building Models

**Automatic builds:**

- Push to main → builds missing models
- Manual trigger → optionally force rebuild all

**Manual builds:**

```bash
# Build specific model locally
docker buildx build -t ghcr.io/doublewordai/bit-harbor:gemma-3-4b-it \
  --build-arg MODEL_REPO=https://huggingface.co/google/gemma-3-4b-it \
  --build-arg MODEL_NAME=gemma-3-4b-it \
  --build-arg HF_TOKEN=your_token_here .
```

## Available Models

All models are under 30B parameters. See `models.json` for the complete list:

- **Gemma 3**: 4B, 12B instruction-tuned and 3n variants
- **Llama 3.1**: 8B instruction-tuned
- **Llama 3.2**: 1B, 3B instruction-tuned variants  
- **Qwen 3**: 1.7B, 8B, 14B models
- **Qwen Embeddings**: 0.6B and 8B embedding models
- **Qwen 2.5 VL**: 3B, 7B vision-language instruction-tuned models

## Adding Models

Edit `models.json`:

```json
{
  "models": [
    {
      "name": "my-model",
      "repo": "https://huggingface.co/org/model-name"
    }
  ]
}
```

## [License](LICENSE)

MIT
