#!/bin/bash
set -e

echo "======================================"
echo " Kind + Ollama + OpenWebUI + K8s MCP"
echo "======================================"

# ── Step 1: Fix kubeconfig ────────────────
echo ""
echo "[1/4] Fixing kubeconfig for Docker networking..."

KUBECONFIG_PATH="$HOME/.kube/config"

# Get kind container IP on the kind network
KIND_IP=$(docker inspect kind-control-plane \
  --format '{{(index .NetworkSettings.Networks "kind").IPAddress}}' 2>/dev/null || true)

if [ -z "$KIND_IP" ]; then
  echo "ERROR: kind-control-plane container not found or not on 'kind' network."
  echo "Make sure your kind cluster is running: kind create cluster"
  exit 1
fi

echo "  kind-control-plane IP: $KIND_IP"

# Update kubeconfig server address
CURRENT_CONTEXT=$(kubectl config current-context)
CLUSTER_NAME=$(kubectl config view --minify -o jsonpath='{.clusters[0].name}')

kubectl config set-cluster "$CLUSTER_NAME" \
  --server="https://${KIND_IP}:6443"

kubectl config set-cluster "$CLUSTER_NAME" \
  --insecure-skip-tls-verify=true

echo "  kubeconfig updated: server=https://${KIND_IP}:6443"

# Fix permissions so container can read it
cp "$KUBECONFIG_PATH" /tmp/kube-config-mcp
chmod 666 /tmp/kube-config-mcp
echo "  kubeconfig copied to /tmp/kube-config-mcp with 666 permissions"

# ── Step 2: Export for docker compose ────
echo ""
echo "[2/4] Setting environment variables..."
export KUBECONFIG=/tmp/kube-config-mcp

# ── Step 3: Stop old containers ──────────
echo ""
echo "[3/4] Stopping any old containers..."
docker compose down --remove-orphans 2>/dev/null || true

# ── Step 4: Start everything ─────────────
echo ""
echo "[4/4] Starting all services..."
KUBECONFIG=/tmp/kube-config-mcp docker compose up -d

echo ""
echo "======================================"
echo " Waiting for services to be healthy..."
echo "======================================"

# Wait for Open WebUI
echo -n "Waiting for Open WebUI"
for i in $(seq 1 30); do
  if curl -sf http://localhost:3000/health > /dev/null 2>&1; then
    echo " ✓"
    break
  fi
  echo -n "."
  sleep 5
done

# Wait for mcpo
echo -n "Waiting for mcpo"
for i in $(seq 1 20); do
  if curl -sf http://localhost:8082/openapi.json > /dev/null 2>&1; then
    echo " ✓"
    break
  fi
  echo -n "."
  sleep 3
done

echo ""
echo "======================================"
echo " All services started!"
echo "======================================"
echo ""
echo "  Open WebUI:  http://localhost:3000"
echo "  Ollama:      http://localhost:11434"
echo "  K8s MCP SSE: http://localhost:8081/sse"
echo "  mcpo API:    http://localhost:8082/openapi.json"
echo ""
echo "  Model being pulled: qwen2.5:7b (check with: docker logs ollama-init -f)"
echo ""
echo "  In Open WebUI:"
echo "  1. Select qwen2.5:7b model"
echo "  2. Click ⬡ icon in chat input"
echo "  3. Enable 'Kubernetes' tool"
echo "  4. Ask: 'List all pods in my cluster'"
echo ""
