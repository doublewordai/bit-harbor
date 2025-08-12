import os
import subprocess
from huggingface_hub import snapshot_download

model_repo = os.environ.get("MODEL_REPO", "").replace("https://huggingface.co/", "")
hf_token = os.environ.get("HF_TOKEN") or None

print(f"Downloading {model_repo} to /models")

snapshot_download(
    repo_id=model_repo,
    local_dir="/models",
    token=hf_token,
    allow_patterns=[
        "*.safetensors",
        "*.bin",
        "*.json",
        "*.txt",
        "tokenizer.model",
        "*.tiktoken",
        "tokenizer/*"
    ],
    ignore_patterns=[
        "*.onnx*",
        "*.pb",
        "*.h5",
        "*.msgpack",
        "*.ckpt",
        "*pytorch_model*",
        "training_args.json",
        "*.md"
    ]
)

print("Download complete!")
subprocess.run(["du", "-sh", "/models"])
subprocess.run(["find", "/models", "-type", "f"])