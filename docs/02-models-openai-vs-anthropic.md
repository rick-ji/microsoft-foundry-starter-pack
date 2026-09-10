# 2. Models breakdown: OpenAI vs. Anthropic

Microsoft Foundry is **multi-model**. Two of the most requested model families are **OpenAI** and **Anthropic (Claude)**. They are commercially and technically integrated in *different* ways, which matters for architecture, privacy, and contracts.

> ⚠️ Model version names below change frequently. Always confirm the exact models and versions in the live **[Foundry model catalog](https://ai.azure.com/explore/models)**.

## 2.1 OpenAI models ("Azure OpenAI" / Models sold by Azure)

- **Examples:** GPT‑4o / GPT‑4o mini, GPT‑4.1 family, o‑series reasoning models, embeddings (`text-embedding-3-*`), DALL·E / image, audio, and realtime models.
- **Commercial model:** **Sold by Azure** ("Models sold directly by Azure"). Microsoft is your contracting party.
- **Hosting:** Runs **entirely inside Microsoft Azure**. Prompts and completions are **not** sent to OpenAI's infrastructure.
- **Deployment types:** Standard (Global / Data Zone / Regional), Provisioned Throughput (PTU), Batch, Developer. See [doc 4](./04-data-residency-and-deployment-types.md).

## 2.2 Anthropic Claude models

- **Examples:** Claude Opus, Claude Sonnet, Claude Haiku families.
- **Commercial model:** **Models from Partners & Community.** Anthropic is an **independent data processor** for inference; Microsoft provides the Foundry experience, infrastructure, and billing.
- **Hosting — two paths (this is the key difference):**
  - **Hosted on Azure:** Prompts/completions are processed on Azure infrastructure; data at rest stays in your selected Azure geography. **Recommended for enterprise/regulated workloads.**
  - **Hosted on Anthropic:** Requests are sent to Anthropic's own infrastructure (may be outside your Azure region), governed by Anthropic's terms — sometimes gives earliest access to new Claude features.
- **Terms:** Governed by **Anthropic's Commercial Terms of Service and Data Processing Addendum** for inference; Microsoft's DPA covers billing/support metadata.

## 2.3 How they differ (at a glance)

| Dimension | OpenAI (sold by Azure) | Anthropic Claude (partner) |
|-----------|------------------------|----------------------------|
| Contracting party for inference | Microsoft | Anthropic (independent data processor) |
| Where inference runs | Azure only | Azure **or** Anthropic (you choose) |
| Governing terms | Microsoft Product Terms + DPA | Anthropic Commercial ToS + DPA |
| Abuse monitoring | Microsoft abuse monitoring (opt-out via Modified Abuse Monitoring) | Anthropic Trust & Safety (exceptions-only review); optional zero data retention |
| Deployment types | Standard / Provisioned / Batch / Developer | Serverless (Standard); hosting-path dependent |
| Data residency guarantees | Global / Data Zone / Regional | Strongest when **Hosted on Azure** |

See [doc 3 – processing & privacy](./03-processing-and-privacy.md) for the detail behind these rows.

## 2.4 Other model families available

Meta **Llama**, xAI **Grok**, **Mistral**, **Hugging Face** open models, Microsoft **Phi**, and more — offered as either **Models sold by Azure**, **Partner models (serverless)**, or **open models on Managed Compute** (see [doc 5](./05-managed-compute.md)).

## Reference documentation

- Foundry Models overview — <https://learn.microsoft.com/en-us/azure/foundry/concepts/foundry-models-overview>
- Explore the model catalog — <https://ai.azure.com/explore/models>
- Models sold directly by Azure — <https://learn.microsoft.com/en-us/azure/foundry/concepts/models-sold-directly-by-azure>
- Claude in Microsoft Foundry — <https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/claude-models-hosting-comparison>
- Anthropic docs: Claude in Microsoft Foundry — <https://platform.claude.com/docs/en/build-with-claude/claude-in-microsoft-foundry>
