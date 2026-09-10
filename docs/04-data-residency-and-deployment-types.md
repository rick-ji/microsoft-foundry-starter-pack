# 4. Data residency & deployment types

**Where your data is processed** is a function of the **deployment type** you choose for each model. Foundry offers several, trading off price, throughput guarantees, and data-residency scope.

---

## 4.1 Deployment types

### Serverless API (pay-as-you-go, no infra to manage)

| Type | Data processing location | Pricing model | Best for |
|------|--------------------------|---------------|----------|
| **Global Standard** | Any Azure region worldwide | Lowest per-token | Most workloads; broadest availability & capacity |
| **Data Zone Standard** | Within a Microsoft **data zone** (US, EU, APAC) | Slightly higher than Global | Compliance/residency within a zone |
| **Regional / Standard** | Within a single Azure **geography** | Regional pricing | Strict single-geography residency |
| **Provisioned Throughput (PTU)** | Global or Data Zone (configurable) | **Reserved capacity** (hourly / monthly / yearly) | Predictable, high-volume, latency-sensitive, mission-critical |
| **Batch** | Various | **~50% discount** vs Standard | Large asynchronous, non-real-time jobs |
| **Developer** | Varies | Low, **temporary** (e.g. 24h) | Fine-tuned model evaluation — **not production** |

### Managed Compute (dedicated GPU infrastructure)
For open-source, partner, or custom models needing dedicated hardware. **You** control the VM SKU/scale; billed per **compute hour**. See [doc 5](./05-managed-compute.md).

> Not every model supports every deployment type — check the model card in the catalog.

---

## 4.2 Data residency: Global vs Data Zone vs Regional

| Aspect | Global Standard | Data Zone | Regional / Standard |
|--------|-----------------|-----------|---------------------|
| **Data at rest** | Stored in your selected Azure geography | Stored within the data zone | Stored within the geography |
| **Inference processing** | May run in **any** Azure region | Stays within the **data zone** (US / EU / APAC) | Stays within the **geography** (may move between regions inside it) |
| **Residency guarantee** | ❌ No processing-residency guarantee | ✅ Contractual: never leaves the zone | ✅ Stays within geography |
| **Typical use** | Lowest cost, max capacity | GDPR / sovereignty, EU or US only | Strict single-country/geo needs |

**EU Data Zone** examples: **Sweden Central**, **Germany West Central**. **US Data Zone** keeps processing within US regions.

> **Rule of thumb:** For a hard "data must never leave the EU/US" requirement, choose a **Data Zone** deployment type. **Global** does **not** guarantee processing residency.

---

## 4.3 Choosing a deployment type — decision guide

1. **Do you have a residency requirement?**
   - Hard EU/US boundary → **Data Zone** (or Regional).
   - No hard requirement, want lowest cost/most capacity → **Global Standard**.
2. **Is throughput predictable and high?** → **Provisioned Throughput (PTU)**.
3. **Is the work asynchronous / bulk?** → **Batch** (big discount).
4. **Custom or open-source model needing dedicated GPUs?** → **Managed Compute** ([doc 5](./05-managed-compute.md)).
5. **Just evaluating a fine-tune?** → **Developer**.

---

## Reference documentation

- Deployment types for Foundry Models — <https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/deployment-types>
- Deployments overview — <https://learn.microsoft.com/en-us/azure/foundry/concepts/deployments-overview>
- Region availability — <https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/models-sold-directly-by-azure-region-availability>
- Data zones & residency (Azure OpenAI data privacy) — <https://learn.microsoft.com/en-us/azure/foundry/responsible-ai/openai/data-privacy>
- Provisioned throughput (PTU) concepts — <https://learn.microsoft.com/en-us/azure/ai-foundry/openai/concepts/provisioned-throughput>
- Global data residency in Azure — <https://azure.microsoft.com/en-us/explore/global-infrastructure/data-residency/>
