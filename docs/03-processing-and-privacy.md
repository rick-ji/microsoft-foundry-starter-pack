# 3. How models are processed & privacy statements

This is the most important section for security, legal, and compliance reviewers. The key idea: **who processes your data and under whose terms depends on whether the model is *sold by Azure* or a *partner model*, and (for Anthropic) on the hosting path you choose.**

---

## 3.1 OpenAI / models sold by Azure — processing & privacy

**Data isolation guarantees (default):** Your prompts (inputs), completions (outputs), embeddings, and any fine-tuning/training data are:

- **Not** available to other customers.
- **Not** shared with OpenAI or other model providers.
- **Not** used to train or improve Microsoft's or any third party's foundation models — unless you explicitly opt in.
- Processed **entirely within Azure**; nothing is sent to OpenAI infrastructure.

**How a request is processed:**
1. Your prompt is sent to your model **deployment** inside your Azure resource.
2. Inference is **stateless** — the model does not retain content by default.
3. **Abuse monitoring** may analyze prompts/completions to detect Terms-of-Service violations. If automated classifiers flag content, a **sampled subset may be stored up to 30 days** and, if needed, escalated to a small number of authorized Microsoft reviewers under strict access controls.

**Opt-out — Modified Abuse Monitoring & no human review:** Eligible customers with sensitive/regulated workloads can apply for **Modified Abuse Monitoring**, which removes prompt/response **storage and human review**. Automated content filtering (guardrails) still applies. Approval is case-by-case via your Microsoft account team.

**References:**
- Data, privacy & security for Foundry Models sold by Azure — <https://learn.microsoft.com/en-us/azure/foundry/responsible-ai/openai/data-privacy>
- Abuse monitoring — <https://learn.microsoft.com/en-us/azure/foundry/openai/concepts/abuse-monitoring>
- Transparency note — <https://learn.microsoft.com/en-us/azure/foundry/responsible-ai/openai/transparency-note>

---

## 3.2 Anthropic Claude — processing & privacy

Anthropic is always the **independent data processor** for Claude inference. The specifics depend on the **hosting path**:

### Hosted on Azure (recommended for enterprise)
- Prompts/completions processed on **Azure infrastructure**; data at rest stays in your **selected Azure geography** (including US Data Zone support for sensitive workloads).
- Only **usage metadata** and content **flagged by Anthropic's safety systems** are sent to Anthropic for Trust & Safety review — reviewed on an **exceptions-only** basis.
- **Zero Data Retention (ZDR)** can be enabled — Anthropic keeps no prompts/outputs after the call completes.
- Azure-native controls apply: Entra ID, RBAC, private endpoints, data residency.

### Hosted on Anthropic
- Requests traverse the network to **Anthropic's own infrastructure**, potentially **outside** your Azure region.
- Governed **exclusively by Anthropic's Data Processing Addendum** for residency and privacy.
- Microsoft still supplies the Foundry experience and **billing**.

**Contractual split:** Anthropic's **Commercial Terms of Service + DPA** govern inference; Microsoft's **Product Terms + DPA** govern customer metadata (billing, contact, transaction records).

**References:**
- Compare Claude hosting options — <https://learn.microsoft.com/en-us/azure/foundry/foundry-models/concepts/claude-models-hosting-comparison>
- Anthropic: Claude in Microsoft Foundry — <https://platform.claude.com/docs/en/build-with-claude/claude-in-microsoft-foundry>

---

## 3.3 Side-by-side summary

| Topic | OpenAI (sold by Azure) | Claude – Hosted on Azure | Claude – Hosted on Anthropic |
|-------|------------------------|--------------------------|------------------------------|
| Inference runs on | Azure | Azure | Anthropic infra |
| Data processor | Microsoft | Anthropic | Anthropic |
| Governing inference terms | MS Product Terms + DPA | Anthropic ToS + DPA | Anthropic ToS + DPA |
| Trains provider models? | No (unless opt-in) | No | No |
| Human/safety review | Abuse monitoring (opt-out available) | Exceptions-only Trust & Safety | Exceptions-only Trust & Safety |
| Retention control | Modified Abuse Monitoring | Zero Data Retention option | Per Anthropic DPA |
| Data residency strength | Global / Data Zone / Regional | Selected Azure geography | Anthropic-governed |

---

## 3.4 Practical guidance

- For **regulated/sensitive** workloads: prefer **models sold by Azure** or **Claude Hosted on Azure**, plus a **Data Zone / Regional** deployment (see [doc 4](./04-data-residency-and-deployment-types.md)).
- **Minimize exposure:** redact/tokenize PII before inference where practical.
- **Network isolation:** disable public network access and use **private endpoints** (the [Bicep template](../infra/main.bicep) in this repo does exactly this).
- **Document controls** and validate applicable product terms/DPA with your legal team before production.

**General references:**
- Foundry data, privacy & security — <https://learn.microsoft.com/en-us/azure/ai-foundry/how-to/disable-local-auth>
- Microsoft Products & Services Data Protection Addendum (DPA) — <https://www.microsoft.com/licensing/docs/view/Microsoft-Products-and-Services-Data-Protection-Addendum-DPA>
- Microsoft Trust Center — <https://www.microsoft.com/trust-center>
