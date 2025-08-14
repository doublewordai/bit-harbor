# Pre-Porter Helm Chart

Pre-Porter is a Helm chart that pre-pulls bit-harbor images across Kubernetes nodes using OpenKruise AdvancedCronJobs and BroadcastJobs.

Using OpenKruise AdvancedCronJobs, Pre-Porter automatically creates BroadcastJobs that run on all matching nodes simultaneously. Each BroadcastJob runs the bit-harbor image with the built-in `/pause` binary, which exits after the image is pulled. This dramatically speeds up ML workload startup times by eliminating image pull time when using bit harbor as an init container.

## Prerequisites

**OpenKruise Required**: This chart uses OpenKruise AdvancedCronJob and BroadcastJob resources. You must install OpenKruise in your cluster before using Pre-Porter.

```bash
# Install OpenKruise 
helm repo add openkruise https://openkruise.github.io/charts/
helm install kruise openkruise/kruise --version v1.7.2

# Or let Pre-Porter install it for you (recommended)
helm install pre-porter ./pre-porter --set kruise.enabled=true
```

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
    
  - name: "qwen-3-8b"  # Disabled - won't create Jobs
    enabled: false
    pullPolicy: "Always"

# Enable AdvancedCronJob to create BroadcastJobs
advancedCronJob:
  enabled: true
  schedule: "0 2 * * *"  # Daily at 2 AM UTC
```

The AdvancedCronJob will create BroadcastJobs for each enabled image, automatically running on all matching nodes to pull and cache the specified model.

```bash
helm install pre-porter ./pre-porter -f values.yaml
```

### Advanced Configuration

Target different models to different GPU node types:

```yaml
imageRegistry: "ghcr.io/doublewordai/bit-harbor"

# Global settings (applied to all BroadcastJobs unless overridden)  
globalNodeSelector:
  nvidia.com/gpu: "true"  # target only GPU nodes

# Global tolerations for GPU nodes
globalTolerations:
  - key: "nvidia.com/gpu"
    operator: "Exists"
    effect: "NoSchedule"

globalResources:
  limits:
    cpu: "100m"
    memory: "128Mi"
  requests:
    cpu: "50m"
    memory: "64Mi"

# Enable AdvancedCronJob to create BroadcastJobs
advancedCronJob:
  enabled: true
  schedule: "0 */12 * * *"  # Twice daily

images:
  # Large GPU models - targets V100 nodes
  - name: "llama-3.1-8b-instruct"
    enabled: true
    nodeSelector:
      accelerator: "nvidia-tesla-v100"
    resources:
      limits:
        cpu: "200m"
        memory: "512Mi"

  # Small GPU models - targets any GPU node  
  - name: "gemma-3-4b-it"
    enabled: true
    # Uses globalNodeSelector (any GPU node)

  # Embedding models - targets T4 nodes
  - name: "qwen-3-embedding-8b"
    enabled: true
    nodeSelector:
      accelerator: "nvidia-tesla-t4"
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

### Automatic Cache Refresh

Pre-Porter can automatically refresh the image cache on all nodes using AdvancedCronJob:

```yaml
# AdvancedCronJob configuration (transparent Kubernetes resource)
advancedCronJob:
  enabled: true
  schedule: "0 2 * * *"  # Standard cron expression - daily at 2 AM UTC
  timeZone: "UTC"
  
  # BroadcastJob template configuration
  broadcastJobTemplate:
    # Completion policy for BroadcastJob
    completionPolicy:
      type: Always
      activeDeadlineSeconds: 3600  # 1 hour timeout
    
    # TTL for automatic cleanup
    ttlSecondsAfterFinished: 86400  # 1 day
  
  # Optional: Pause the AdvancedCronJob
  suspend: false
```

The AdvancedCronJob will create BroadcastJobs according to the cron schedule, running on all matching nodes to keep the cache hot.

### Monitor Pre-pulling

```bash
# Check BroadcastJob status  
kubectl get broadcastjobs -l app.kubernetes.io/instance=pre-porter

# Check refresh status (AdvancedCronJobs)
kubectl get advancedcronjobs -l app.kubernetes.io/instance=pre-porter

# View completed and running pods from BroadcastJobs
kubectl get pods -l app.kubernetes.io/instance=pre-porter -o wide

# View logs from BroadcastJob pods
kubectl logs -l app.kubernetes.io/instance=pre-porter -c model-cache

# Monitor specific image BroadcastJobs
kubectl get broadcastjobs -l pre-porter.io/image=gemma-3-4b-it

# Check BroadcastJob completion status
kubectl get broadcastjobs -l app.kubernetes.io/instance=pre-porter -o custom-columns='NAME:.metadata.name,DESIRED:.spec.template.spec.completionPolicy.type,SUCCEEDED:.status.succeeded,FAILED:.status.failed'

# View refresh execution history  
kubectl describe advancedcronjobs -l app.kubernetes.io/instance=pre-porter
```

## Development

### Testing

```bash
# Install helm unittest plugin
helm plugin install https://github.com/helm-unittest/helm-unittest

# Run unit tests  
helm unittest .

# Run specific test suite
helm unittest . -f 'tests/job_management_test.yaml'
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
