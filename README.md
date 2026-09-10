# Microsoft Foundry Starter Pack

A customer-ready starter pack to get going with **Microsoft Foundry** (formerly **Azure AI Foundry**). It explains the platform, compares **OpenAI** and **Anthropic** models, details **how data is processed** and the **privacy** posture, covers **data residency**, **deployment types**, and **Managed Compute**, provides a **pricing** guide with authoritative Microsoft links, and ships a **one-click Bicep deployment** for a Foundry account secured with **private network integration**.

> **Naming:** "Azure AI Foundry" and "Microsoft Foundry" refer to the same platform during the 2025 rebrand. The Azure resource kind is **`AIServices`**.

---

## 🚀 One-click deploy: Foundry account + Private Endpoint

Deploys a Foundry (`AIServices`) account with **public access disabled**, a **private endpoint**, **private DNS**, and a **delegated agent outbound subnet** for Foundry **Agent Service** network injection. **Region** and **network selection** are variables; the VNet and DNS zones can be **new or existing**.

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Frick-ji%2Fmicrosoft-foundry-starter-pack%2Fmain%2Finfra%2Fazuredeploy.json)

Details, parameters, and CLI instructions: [`infra/README.md`](./infra/README.md).

**Two-stage deploy:** `main.bicep` provisions the account + private network (incl. the delegated agent subnet); the optional [`agent-standard-setup.bicep`](./infra/README.md#agent-service-capability-host-standard-agent-setup) then adds the **Agent Service** — a project, Cosmos/Storage/Search dependencies, connections, role assignments, and the capability hosts that bind the agent runtime to your subnet.

---

## 📚 Documentation

| # | Doc | What's inside |
|---|-----|---------------|
| 1 | [What is Microsoft Foundry?](./docs/01-what-is-foundry.md) | Concept, four pillars, building blocks, getting started |
| 2 | [Models: OpenAI vs Anthropic](./docs/02-models-openai-vs-anthropic.md) | Families, commercial models, key differences |
| 3 | [Processing & Privacy](./docs/03-processing-and-privacy.md) | How data is processed, abuse monitoring, privacy statements |
| 4 | [Data Residency & Deployment Types](./docs/04-data-residency-and-deployment-types.md) | Global / Data Zone / Regional, PTU, Batch, Developer |
| 5 | [Managed Compute](./docs/05-managed-compute.md) | Dedicated GPU deployments, billing, when to use |
| 6 | [Pricing](./docs/06-pricing.md) | Cost model + authoritative Microsoft pricing links |

---

## 🧭 Recommended reading order

1. **Understand the platform** → [doc 1](./docs/01-what-is-foundry.md)
2. **Pick a model family** → [doc 2](./docs/02-models-openai-vs-anthropic.md)
3. **Check privacy & compliance** → [doc 3](./docs/03-processing-and-privacy.md)
4. **Choose residency & deployment type** → [doc 4](./docs/04-data-residency-and-deployment-types.md) / [doc 5](./docs/05-managed-compute.md)
5. **Estimate cost** → [doc 6](./docs/06-pricing.md)
6. **Deploy privately** → [`infra/`](./infra/README.md)

---

## 🔑 Key takeaways

- **Multi-model:** OpenAI, Anthropic, Meta, xAI, Mistral, Hugging Face, Microsoft — one API, one bill.
- **Two integration models:** *sold by Azure* (OpenAI — runs entirely in Azure) vs *partner* (Anthropic — Azure-hosted **or** Anthropic-hosted).
- **Residency is a deployment-type choice:** use **Data Zone / Regional** for hard EU/US boundaries; **Global** is cheapest but no processing-residency guarantee.
- **Managed Compute** = dedicated GPUs, billed per compute-hour, for OSS/custom models.
- **Secure by default:** the included template disables public access and uses private endpoints.
- **Agent-ready networking:** a dedicated subnet delegated to `Microsoft.App/environments` supports network-injected Foundry Agent Service.

---

## 📎 Top reference links

- Microsoft Foundry — <https://azure.microsoft.com/en-us/products/ai-foundry/>
- Foundry portal — <https://ai.azure.com/?view=foundry>
- Foundry Models overview — <https://learn.microsoft.com/en-us/azure/foundry/concepts/foundry-models-overview>
- Deployment types — <https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/deployment-types>
- Data, privacy & security — <https://learn.microsoft.com/en-us/azure/foundry/responsible-ai/openai/data-privacy>
- Pricing — <https://azure.microsoft.com/en-us/pricing/details/ai-foundry-models/>

---

## ⚠️ Disclaimer

This starter pack is **community/educational material**, not official Microsoft documentation. Product names, model versions, features, and prices change frequently — always validate against the **linked Microsoft Learn and Azure pricing pages**, which are the source of truth. Review applicable **Product Terms** and **Data Protection Addendum (DPA)** with your legal/compliance team before production use.

## License

[MIT](./LICENSE)
