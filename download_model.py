import os
import subprocess
import time
import sys
from huggingface_hub import snapshot_download

model_repo = os.environ.get("MODEL_REPO", "").replace("https://huggingface.co/", "")
hf_token = os.environ.get("HF_TOKEN") or None

print(f"Downloading {model_repo} to /models")

# Add retry logic for large models
max_retries = 3
for attempt in range(max_retries):
    try:
        print(f"Download attempt {attempt + 1}/{max_retries}")
        
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
            ],
            resume_download=True,
            max_workers=1  # Reduce concurrent downloads to avoid timeouts
        )
        
        print("Download complete!")
        break
        
    except Exception as e:
        print(f"Download failed on attempt {attempt + 1}: {e}")
        if attempt == max_retries - 1:
            print("All download attempts failed")
            sys.exit(1)
        print(f"Retrying in 5 seconds...")
        time.sleep(5)

subprocess.run(["du", "-sh", "/models"])
subprocess.run(["find", "/models", "-type", "f"])