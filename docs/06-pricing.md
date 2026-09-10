# 6. Pricing

Foundry pricing is **consumption-based** and varies by **model**, **deployment type**, **region/data zone**, and **modality** (text, image, audio, embeddings). This page explains the *shape* of the pricing and links to the **authoritative Microsoft pricing pages** — always price a specific workload against the live calculator, since rates change.

> 💡 There is **no charge for the Foundry account resource itself**. You pay for the **models/tokens** and any **dedicated compute** (Managed Compute, PTU) you provision.

---

## 6.1 What you pay for

| Cost component | How it's billed | Notes |
|----------------|-----------------|-------|
| **Standard (serverless) inference** | Per **1K/1M tokens**, split **input** vs **output** | Output tokens usually cost more than input |
| **Global vs Data Zone vs Regional** | Per-token rate **varies by scope** | Global lowest; Data Zone/Regional slightly higher |
| **Provisioned Throughput (PTU)** | **Reserved capacity** — hourly, or discounted **monthly/annual** reservations | Predictable cost for steady high volume |
| **Batch** | Per token at **~50% discount** | Asynchronous, non-real-time |
| **Managed Compute** | Per **GPU VM compute-hour** | Pay while the endpoint runs (see [doc 5](./05-managed-compute.md)) |
| **Fine-tuning** | **Training** (per token/compute) + **hosting** of the fine-tuned deployment | Hosting billed separately |
| **Images / audio / embeddings** | Per image, per minute/character, or per token | Modality-specific rates |
| **Partner models (e.g. Anthropic)** | Per token at the **partner's rates** via Azure billing | Billed through your Azure invoice |
| **Add-ons** | Content Safety, AI Search, storage, networking, monitoring | Billed as their own Azure services |

---

## 6.2 How to estimate a workload

1. Identify the **model** and **modality**.
2. Choose a **deployment type** (Standard / PTU / Batch / Managed Compute) and **region / data zone**.
3. Estimate **input + output tokens per request × requests/month**.
4. Plug into the **Azure Pricing Calculator**.
5. For steady, high volume, compare **PTU reservations** vs pay-as-you-go.

---

## 6.3 Authoritative Microsoft pricing links

- **Foundry Models pricing (overview)** — <https://azure.microsoft.com/en-us/pricing/details/ai-foundry-models/>
- **Foundry Models pricing – Microsoft/Azure models** — <https://azure.microsoft.com/en-us/pricing/details/ai-foundry-models/microsoft/>
- **Azure OpenAI / Foundry OpenAI pricing** — <https://azure.microsoft.com/en-us/pricing/details/cognitive-services/openai-service/>
- **Azure AI Foundry (platform) pricing** — <https://azure.microsoft.com/en-us/pricing/details/ai-foundry/>
- **Provisioned Throughput (PTU) pricing & reservations** — <https://learn.microsoft.com/en-us/azure/ai-foundry/openai/concepts/provisioned-throughput>
- **Azure Pricing Calculator** — <https://azure.microsoft.com/en-us/pricing/calculator/>
- **Azure Machine Learning (Managed Compute) pricing** — <https://azure.microsoft.com/en-us/pricing/details/machine-learning/>
- **GPU VM pricing (Linux)** — <https://azure.microsoft.com/en-us/pricing/details/virtual-machines/linux/>
- **Azure AI Content Safety pricing** — <https://azure.microsoft.com/en-us/pricing/details/cognitive-services/content-safety/>
- **Azure AI Search pricing** — <https://azure.microsoft.com/en-us/pricing/details/search/>

---

## 6.4 Cost-optimization checklist

- ✅ Prefer **Global Standard** unless residency requires Data Zone/Regional.
- ✅ Use **Batch** for non-real-time bulk jobs (~50% off).
- ✅ Move steady high-volume traffic to **PTU reservations**.
- ✅ **Delete/scale-down** idle Managed Compute endpoints.
- ✅ Right-size prompts; cache; trim max output tokens.
- ✅ Set **Azure Cost Management budgets & alerts** — <https://learn.microsoft.com/en-us/azure/cost-management-billing/costs/tutorial-acm-create-budgets>

> ⚠️ **Disclaimer:** All rates are set by Microsoft and change over time. Figures in any third-party summary can be stale — the **linked Microsoft pages and the pricing calculator are the single source of truth**.
