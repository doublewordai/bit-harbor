# Bit Harbor

Minimal containers with Hugging Face model weights for Kubernetes init containers.

## What is this?

This repository automatically builds tiny containers containing only LLM model weights from Hugging Face. These containers are designed to be used as Kubernetes init containers to speed up ML workloads by pre-downloading models.

## Quick Start

Use a pre-built model container as an init container:

```yaml
initContainers:
- name: model-loader
  image: ghcr.io/doublewordai/bit-harbor:gemma-3-2b
  volumeMounts:
  - name: models
    mountPath: /shared
  command: ['sh', '-c', 'cp -r /models/* /shared/']
```

Your main container can then access the models from the shared volume.

## Building Models

**Automatic builds:**

- Push to main → builds missing models
- Manual trigger → optionally force rebuild all

**Manual builds:**

```bash
# Build specific model locally
docker buildx build -t ghcr.io/doublewordai/bit-harbor:gemma-3-2b \
  --build-arg MODEL_REPO=https://huggingface.co/google/gemma-3-2b \
  --build-arg MODEL_NAME=gemma-3-2b .
```

## Available Models

All models are under 30B parameters. See `models.json` for the complete list:

- **Gemma 3**: 2B, 9B variants and 3n versions
- **Llama 3.1**: 8B base and instruct
- **Llama 3.2**: 1B, 3B base and instruct variants  
- **Qwen 3**: 1.8B, 7B, 14B instruct models
- **Qwen Embeddings**: Text embedding small and base
- **Qwen 2.5 VL**: 1.5B, 3B, 7B vision-language models

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

## How it Works

1. **Declarative models**: All models defined in `models.json`
2. **Smart building**: `build.sh` checks which images exist and only builds missing ones
3. **Git-based**: Uses git to clone Hugging Face model repos during Docker build
4. **Minimal containers**: Final images use scratch base with only model files at `/models`
5. **Auto-deployment**: GitHub Actions builds missing models on every push

## License

MIT
