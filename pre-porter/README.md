# Pre-Porter Helm Chart

Pre-Porter is a Helm chart that pre-pulls bit-harbor images on Kubernetes nodes using DaemonSets. Each DaemonSet runs the bit-harbor image with the built-in `/pause` binary, causing the container runtime to cache the image locally. This dramatically speeds up ML workload startup times by eliminating image pull time.

## Quick Start

```bash
# Add the OCI registry (coming with first release)
helm install pre-porter oci://ghcr.io/doublewordai/bit-harbor/pre-porter

# Or install from local chart
helm install pre-porter ./pre-porter
```

## Configuration

Create a `values.yaml` file:

```yaml
# Global image registry
imageRegistry: "ghcr.io/doublewordai/bit-harbor"

# Configure which model tags to pre-pull
# Each model name becomes the image tag: ghcr.io/doublewordai/bit-harbor:<model-name>
images:
  - name: "gemma-3-4b-it"  # Pulls ghcr.io/doublewordai/bit-harbor:gemma-3-4b-it
    enabled: true
    pullPolicy: "Always"
    
  - name: "llama-3.1-8b-instruct"  # Pulls ghcr.io/doublewordai/bit-harbor:llama-3.1-8b-instruct
    enabled: true
    pullPolicy: "Always"
    
  - name: "qwen-3-8b"  # Disabled - won't create DaemonSet
    enabled: false
    pullPolicy: "Always"
```

It creates a DaemonSet for each enabled image, pulling the specified model from the registry and keeping it cached on each node.

```bash
helm install pre-porter ./pre-porter -f values.yaml
```

### Advanced Configuration

Target different models to different node types:

```yaml
imageRegistry: "ghcr.io/doublewordai/bit-harbor"

# Global settings (applied to all images unless overridden)
globalNodeSelector:
  kubernetes.io/os: linux
  
globalTolerations:
  - key: "model-nodes"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"

globalResources:
  limits:
    cpu: "100m"
    memory: "128Mi"
  requests:
    cpu: "50m"
    memory: "64Mi"

images:
  # Large GPU models - only on GPU nodes
  - name: "llama-3.1-8b-instruct"
    enabled: true
    nodeSelector:
      accelerator: "nvidia-tesla-v100"
      gpu-memory: ">=16Gi"
    tolerations:
      - key: "gpu"
        operator: "Equal"
        value: "true"
        effect: "NoSchedule"
    resources:
      limits:
        cpu: "200m"
        memory: "256Mi"

  # Small CPU models - on CPU-optimized nodes  
  - name: "gemma-3-4b-it"
    enabled: true
    nodeSelector:
      node-type: "cpu-optimized"
      # gpu selector is NOT inherited from global
    resources:
      limits:
        cpu: "100m"
        memory: "128Mi"

  # Embedding models - on all nodes
  - name: "qwen-3-embedding-8b"
    enabled: true
    # Uses globalNodeSelector and globalTolerations
```

### Service Account Configuration

```yaml
serviceAccount:
  create: true
  name: ""  # Auto-generated if empty
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::123456789:role/pre-porter-role"

# Apply to all resources
commonLabels:
  team: "ml-ops"
  environment: "production"
  
commonAnnotations:
  "example.com/managed-by": "pre-porter"
```

## Usage Examples

### Enable Specific Images

```bash
# Enable multiple images at once
helm upgrade pre-porter ./pre-porter \
  --set-json 'images=[
    {"name":"gemma-3-4b-it","enabled":true},
    {"name":"llama-3.1-8b-instruct","enabled":true},
    {"name":"qwen-3-8b","enabled":false}
  ]'
```

### Refresh Images

```bash
# Restart all DaemonSets to re-pull images
kubectl rollout restart daemonset -l app.kubernetes.io/instance=pre-porter

# Restart specific image DaemonSet
kubectl rollout restart daemonset pre-porter-gemma-3-4b-it
```

### Monitor Pre-pulling

```bash
# Check DaemonSet status
kubectl get daemonsets -l app.kubernetes.io/instance=pre-porter

# View model cache container logs  
kubectl logs -l app.kubernetes.io/instance=pre-porter -c model-cache

# Check which nodes have images
kubectl get pods -l app.kubernetes.io/instance=pre-porter -o wide

# Monitor specific image
kubectl get pods -l pre-porter.io/image=gemma-3-4b-it
```

## Architecture

### Why One DaemonSet Per Image?

Pre-Porter creates a separate DaemonSet for each enabled image rather than one DaemonSet for all images.

**Benefits:**

- ✅ **Independent Control**: Different node selectors, tolerations per image
- ✅ **Independent Lifecycle**: Enable/disable/restart individual images  
- ✅ **Better Troubleshooting**: Isolated logs and status per image
- ✅ **Flexible Scheduling**: GPU models on GPU nodes, CPU models on CPU nodes
- ✅ **Failure Isolation**: One image failure doesn't affect others

**Example:** GPU models can target GPU nodes while CPU models target CPU-optimized nodes:

```yaml
images:
  - name: "large-gpu-model"
    nodeSelector: 
      accelerator: "nvidia-tesla-v100"
  - name: "small-cpu-model" 
    nodeSelector:
      node-type: "cpu-optimized"
```

## Development

### Testing

```bash
# Install helm unittest plugin
helm plugin install https://github.com/helm-unittest/helm-unittest

# Run unit tests  
helm unittest .

# Run specific test suite
helm unittest . -f 'tests/daemonset_test.yaml'
```

### Linting

```bash
# Lint the chart
helm lint .

# Template and validate
helm template test-release . --debug
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass: `helm unittest .`
5. Submit a pull request

## License

[MIT License](../LICENSE)
