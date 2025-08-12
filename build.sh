#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
REGISTRY="${REGISTRY:-ghcr.io}"
NAMESPACE="${NAMESPACE:-bit-harbor/bit-harbor}"
CHECK_EXISTING="${CHECK_EXISTING:-true}"
PUSH="${PUSH:-false}"
HF_TOKEN="${HF_TOKEN:-}"

echo "🚀 Starting dynamic model build process"
echo "Registry: $REGISTRY"
echo "Namespace: $NAMESPACE"
echo "Check existing: $CHECK_EXISTING"
echo "Push: $PUSH"
echo ""

# Parse models.json
if [ ! -f "models.json" ]; then
    echo -e "${RED}❌ models.json not found${NC}"
    exit 1
fi

# Extract model names and repos from JSON
MODELS=$(cat models.json | jq -r '.models[] | @base64')
TOTAL_MODELS=$(echo "$MODELS" | wc -l)

echo "📋 Found $TOTAL_MODELS models in models.json"
echo ""

MODELS_TO_BUILD=()
MODELS_SKIPPED=()

# Check which models need building
for model_data in $MODELS; do
    model=$(echo "$model_data" | base64 --decode | jq -r '.')
    model_name=$(echo "$model" | jq -r '.name')
    model_repo=$(echo "$model" | jq -r '.repo')
    
    image_tag="$REGISTRY/$NAMESPACE:$model_name"
    
    if [ "$CHECK_EXISTING" = "true" ]; then
        echo -n "🔍 Checking if $model_name exists... "
        
        # Check if image exists in registry
        if docker manifest inspect "$image_tag" >/dev/null 2>&1; then
            echo -e "${GREEN}✓ exists, skipping${NC}"
            MODELS_SKIPPED+=("$model_name")
        else
            echo -e "${YELLOW}✗ not found, will build${NC}"
            MODELS_TO_BUILD+=("$model_name|$model_repo")
        fi
    else
        echo -e "${YELLOW}🏗️  Will build $model_name${NC}"
        MODELS_TO_BUILD+=("$model_name|$model_repo")
    fi
done

echo ""

# Summary
if [ ${#MODELS_SKIPPED[@]} -gt 0 ]; then
    echo -e "${GREEN}✅ Skipped ${#MODELS_SKIPPED[@]} existing models${NC}"
fi

if [ ${#MODELS_TO_BUILD[@]} -eq 0 ]; then
    echo -e "${GREEN}🎉 All models already exist, nothing to build!${NC}"
    exit 0
fi

echo -e "${YELLOW}🏗️  Building ${#MODELS_TO_BUILD[@]} models...${NC}"
echo ""

# Build missing models
for model_info in "${MODELS_TO_BUILD[@]}"; do
    IFS='|' read -r model_name model_repo <<< "$model_info"
    
    echo -e "${YELLOW}🔨 Building $model_name...${NC}"
    
    # Build args
    BUILD_ARGS=(
        "build"
        "-f" "Dockerfile"
        "-t" "$REGISTRY/$NAMESPACE:$model_name"
        "--build-arg" "MODEL_REPO=$model_repo"
        "--build-arg" "MODEL_NAME=$model_name"
        "--platform" "linux/amd64,linux/arm64"
    )
    
    # Add HF token if provided
    if [ -n "$HF_TOKEN" ]; then
        BUILD_ARGS+=("--build-arg" "HF_TOKEN=$HF_TOKEN")
    fi
    
    # Add push if requested
    if [ "$PUSH" = "true" ]; then
        BUILD_ARGS+=("--push")
    fi
    
    BUILD_ARGS+=(".")
    
    echo "Running: docker buildx ${BUILD_ARGS[*]}"
    
    if docker buildx "${BUILD_ARGS[@]}"; then
        echo -e "${GREEN}✅ Successfully built $model_name${NC}"
    else
        echo -e "${RED}❌ Failed to build $model_name${NC}"
        exit 1
    fi
    
    echo ""
done

echo -e "${GREEN}🎉 Build process completed!${NC}"
echo -e "${GREEN}📦 Built ${#MODELS_TO_BUILD[@]} models${NC}"
if [ ${#MODELS_SKIPPED[@]} -gt 0 ]; then
    echo -e "${GREEN}⏭️  Skipped ${#MODELS_SKIPPED[@]} existing models${NC}"
fi