# 5. Managed Compute

**Managed Compute** is a Foundry deployment option where your model runs on **dedicated, Azure-managed GPU virtual machines** inside your resource — instead of on a shared, pay-per-token serverless endpoint.

## When to use Managed Compute

Use it when a model **can't** be (or you don't want it) served through the serverless/pay-as-you-go API:

- **Open-source & Hugging Face models** not offered as serverless (e.g., many Llama, Mistral, and community models).
- **Custom or fine-tuned** models you bring yourself.
- Workloads needing **dedicated capacity, predictable latency, network isolation**, or a specific **GPU family**.
- Scenarios requiring **full control** over scale (instance count, autoscale) and the compute environment.

## How it works

1. From the **model catalog**, pick a model that supports **Managed Compute** and choose **Deploy → Managed Compute**.
2. Select a **GPU VM SKU** (e.g., NC/ND-series with **A100 / H100** class GPUs) and an **instance count**.
3. Foundry provisions a **real-time online endpoint** (built on Azure Machine Learning managed online endpoints) with autoscale, health probes, and logging.
4. You call the endpoint over REST/SDK; it can be secured with **private endpoints / no public access**.

## Billing model (important)

- Billed **per compute hour** for the underlying VMs **as long as the endpoint is running** — **not per token**.
- You pay whether or not the endpoint is actively serving requests, so **scale to zero / delete** idle endpoints to control cost.
- **Quota:** Requires available **GPU VM quota** (vCPU family quota) in the region; request increases as needed.

## Managed Compute vs. Serverless — quick compare

| | Managed Compute | Serverless API (Standard) |
|--|-----------------|---------------------------|
| Infrastructure | Dedicated GPU VMs (you size) | Fully abstracted, shared |
| Billing | Per **compute hour** | Per **token** (or PTU) |
| Model coverage | Open-source, custom, HF, partner | Models sold by Azure + partner catalog |
| Scaling | You configure (autoscale, instances) | Automatic |
| Isolation | Strong (dedicated + private networking) | Shared multi-tenant |
| Idle cost | Yes (pay while running) | No (pay per use) |
| Best for | Custom/OSS models, dedicated capacity | Fast start, variable/low volume |

## Cost-control tips

- **Delete or scale down** endpoints when idle.
- Right-size the **GPU SKU** and **instance count** to real throughput.
- Use **autoscale** with sensible min/max instances.
- Consider **Batch/Serverless** first if the model is available that way and volume is variable.

## Reference documentation

- Deployment overview (serverless vs managed compute) — <https://learn.microsoft.com/en-us/azure/foundry/concepts/deployments-overview>
- Deploy models via Managed Compute — <https://learn.microsoft.com/en-us/azure/ai-foundry/how-to/deploy-models-managed>
- Managed online endpoints (Azure ML) — <https://learn.microsoft.com/en-us/azure/machine-learning/concept-endpoints-online>
- GPU-optimized VM sizes — <https://learn.microsoft.com/en-us/azure/virtual-machines/sizes-gpu>
- Model catalog — <https://ai.azure.com/explore/models>
