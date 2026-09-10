# 1. What is Microsoft Foundry?

**Microsoft Foundry** (formerly **Azure AI Foundry**) is Microsoft's unified, enterprise-grade platform for building, deploying, governing, and operating **AI applications and agents** at production scale. It brings models, tools, knowledge, and governance together into a single control plane.

At Ignite 2025, Microsoft dropped "Azure" from the name to signal a shift from a *model-centric* service to an **agent-first platform** that reaches across Microsoft 365, Teams, and the broader business ecosystem — not just a single cloud service.

## The four pillars

| Pillar | What it covers |
|--------|----------------|
| **Agents** | First-class, autonomous AI agents you design, orchestrate, and run in production. |
| **Tools** | Function/tool calling and connectors into thousands of business systems (Microsoft Graph, SAP, Salesforce, MCP servers, etc.). |
| **Knowledge** | Grounding your agents/models on your own data (RAG, search, memory). |
| **Governance** | Identity, RBAC, observability, tracing, content safety, compliance, and auditing. |

## Why customers use it

- **Model choice (multi-model):** OpenAI, Anthropic, Meta (Llama), xAI (Grok), Mistral, Hugging Face, Microsoft (Phi), and more — behind one API and one billing relationship.
- **Full lifecycle management:** design → customize (fine-tune) → deploy → monitor → govern.
- **Enterprise controls built in:** Microsoft Entra ID, RBAC, private networking, content filtering, and data-residency options.
- **Production-ready, not just PoC:** observability, evaluations, and guardrails for real workloads.

## Core building blocks

- **Foundry account (resource):** An `Microsoft.CognitiveServices/accounts` resource of kind **`AIServices`**. This is what the Bicep template in [`/infra`](../infra/main.bicep) deploys.
- **Foundry project:** A workspace within the account where you organize models, agents, data, and evaluations.
- **Model deployments:** Instances of a model (Standard, Provisioned, Batch, or Managed Compute — see [doc 4](./04-data-residency-and-deployment-types.md)).

## Getting started (portal path)

1. Open the [Microsoft Foundry portal](https://ai.azure.com/?view=foundry).
2. Create a **Foundry account + project** (or deploy the [Bicep template](../infra/main.bicep) in this repo for a **private-network-secured** account).
3. Browse the **model catalog** and deploy a model (see [doc 2](./02-models-openai-vs-anthropic.md)).
4. Test in the **playground**, then wire it into your app or agent.

## Reference documentation

- Microsoft Foundry product page — <https://azure.microsoft.com/en-us/products/ai-foundry/>
- What is Microsoft Foundry — <https://learn.microsoft.com/en-us/azure/ai-foundry/what-is-azure-ai-foundry>
- Foundry Models overview — <https://learn.microsoft.com/en-us/azure/foundry/concepts/foundry-models-overview>
- Foundry portal — <https://ai.azure.com/?view=foundry>

> **Naming note:** You will see both "Azure AI Foundry" and "Microsoft Foundry" in documentation and the Azure portal during the transition. They refer to the same platform. The underlying Azure resource kind remains **`AIServices`**.
