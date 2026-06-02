![image_alt](https://github.com/faizank789/kind_with_MCP/blob/backend/images/Architure.png?raw=true)

**Architecture Summary**

This Docker Compose stack provides an AI-powered Kubernetes assistant using Open WebUI, Ollama, and the Kubernetes MCP Server.

**Components**
1. Open WebUI (webui-service)
 - User-facing web interface.
 - Accessible at: http://localhost:3000
 - Sends AI requests to Ollama.
 - Connects to the Kubernetes MCP Server to perform Kubernetes operations.
2. Ollama (ollama-service)
 - Hosts the local LLM (e.g., Qwen, Llama, Mistral).
 - Accessible internally at: http://ollama:11434
 - Processes prompts and generates responses.
3. Kubernetes MCP Server (kubernetes-mcp)
 - Acts as a bridge between the AI model and Kubernetes.
 - Uses the mounted kubeconfig file for cluster authentication.
- Exposes an MCP endpoint:
**http://kubernetes-mcp:8080/mcp**
Communicates with the Kubernetes API.


4. Kubernetes Cluster (kind)
The target Kubernetes environment.
MCP Server executes cluster queries and operations using the Kubernetes API.


**Request Flow**
**Normal AI Chat**
User
  ↓
Open WebUI
  ↓
Ollama
  ↓
AI Response
  ↓
User



Example:

**"Explain Kubernetes Deployments"**

Open WebUI sends the prompt to Ollama and displays the generated response.

Kubernetes-Aware AI Chat
User
  ↓
Open WebUI
  ↓
Kubernetes MCP Server
  ↓
Kubernetes API
  ↓
Cluster Data
  ↓
Open WebUI
  ↓
Ollama (for reasoning)
  ↓
User


Example:

"How many pods are running in namespace prod?"

1. Open WebUI sends the request to MCP.
2. MCP queries Kubernetes.
3. Kubernetes returns pod information.
4. Ollama interprets the data.
5. Open WebUI displays a human-readable answer.


  ** Network Layout**


                 Docker Network (mcp-network)
 ┌───────────────────────────────────────────────┐
 │                                               │
 │  Open WebUI  ───────►  Ollama                │
 │       │                                       │
 │       ▼                                       │
 │  Kubernetes MCP Server                        │
 └───────┬───────────────────────────────────────┘
         │
         ▼
   kind Network
         │
         ▼
 Kubernetes Cluster
 
**Volumes**
Volume	        | Purpose
ollama_data     |	Stores downloaded AI models
open-webui_data |	Stores WebUI settings, chats, users
./kubeconfig    |	Provides Kubernetes cluster access

**Key Benefits**
- Local AI inference using Ollama.
- Natural language Kubernetes operations through MCP.
- No cloud dependency for LLM processing.
- Secure cluster access using kubeconfig.
- Web-based interface for easy interaction.

**Example Queries**
- "Show all namespaces."
- "List failed pods."
- "How many nodes are Ready?"
- "Explain why pod nginx-123 is restarting."
- "Generate a deployment YAML for Redis."

This setup essentially turns Open WebUI into a Kubernetes-aware AI assistant that can both answer questions and interact with your cluster through the MCP server.
