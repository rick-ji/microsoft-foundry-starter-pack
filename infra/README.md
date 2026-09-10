# Infra: Microsoft Foundry with Private Network Integration

Bicep + compiled ARM that deploys a **Microsoft Foundry (Azure AI Foundry) account** (`Microsoft.CognitiveServices/accounts`, kind **`AIServices`**) with:

- **Public network access disabled** (`publicNetworkAccess: 'Disabled'`, `networkAcls.defaultAction: 'Deny'`)
- A **Private Endpoint** into your VNet
- A **delegated agent outbound subnet** (`Microsoft.App/environments`) for Foundry **Agent Service** network injection
- **Private DNS zones** (`privatelink.cognitiveservices.azure.com`, `privatelink.openai.azure.com`, `privatelink.services.ai.azure.com`) + VNet links
- **System-assigned managed identity**
- **Foundry project management** enabled

**Region** and **network selection** are parameters (variables). The VNet/subnet and the private DNS zones can each be **created new** or **reused (existing)**.

## Prerequisites: minimum RBAC roles

The template creates an AI Services account, (optionally) a VNet/subnet, a private endpoint, and (optionally) private DNS zones + links. It does **not** create role assignments. To deploy, the identity running it needs the following **built-in** roles.

**Simplest (single resource group, new network + new DNS):**

| Role | Scope | Why |
|------|-------|-----|
| **Contributor** | Target resource group | Covers account, network, private endpoint, and DNS creation. Cannot assign roles (not needed here). |

**Least-privilege alternative (instead of Contributor):**

| Role | Scope | Covers |
|------|-------|--------|
| **Cognitive Services Contributor** (`a97b65f3-24c7-4388-baec-2e87135dc908`) | Target RG | The Foundry `AIServices` account |
| **Network Contributor** (`4d97b98b-1d4f-4787-a291-c67834d212e7`) | Target RG (+ the VNet's RG if existing) | VNet, subnet, private endpoint |
| **Private DNS Zone Contributor** (`b12aa53e-6015-4669-85d0-8515ebb3ae7f`) | RG holding the DNS zones | Private DNS zones + VNet links + DNS zone group |

**Additional scopes when using existing resources (cross-RG):**

| If you set... | You also need... |
|---------------|------------------|
| `vnetNewOrExisting=existing` in another RG | **Network Contributor** on that VNet's resource group (to create the private endpoint / read the subnet) |
| `privateDnsZoneNewOrExisting=existing` in another RG | **Private DNS Zone Contributor** on that DNS resource group (to create the DNS zone group binding) |

**To create the resource group itself** (if it doesn't exist yet): **Contributor** at the **subscription** scope, or have an admin pre-create the RG.

> Assigning roles requires **Owner** or **User Access Administrator** — needed only by whoever grants the above to the deployer, not by the deployment itself.

### Assign the least-privilege set (Azure CLI)

```bash
RG=rg-foundry
ASSIGNEE="<user-or-service-principal-object-id>"

az role assignment create --assignee "$ASSIGNEE" --role "Cognitive Services Contributor" --resource-group "$RG"
az role assignment create --assignee "$ASSIGNEE" --role "Network Contributor"             --resource-group "$RG"
az role assignment create --assignee "$ASSIGNEE" --role "Private DNS Zone Contributor"     --resource-group "$RG"
```

## Deploy to Azure (one click)

[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#create/Microsoft.Template/uri/https%3A%2F%2Fraw.githubusercontent.com%2Frick-ji%2Fmicrosoft-foundry-starter-pack%2Fmain%2Finfra%2Fazuredeploy.json)

> The button opens the Azure portal custom-deployment blade pre-loaded with `azuredeploy.json`. Pick a subscription/resource group, set region + network, and deploy.

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `location` | resource group location | **Region** for all resources |
| `foundryAccountName` | `foundry-<unique>` | Foundry (AI Services) account name |
| `customSubDomainName` | account name | Globally-unique subdomain (required for private endpoint) |
| `skuName` | `S0` | Account SKU |
| `vnetNewOrExisting` | `new` | **`new`** creates a VNet+subnet; **`existing`** reuses one |
| `vnetName` | `foundry-vnet` | VNet name (new or existing) |
| `vnetResourceGroup` | current RG | RG of the **existing** VNet |
| `vnetAddressPrefix` | `10.0.0.0/16` | Address space for a **new** VNet |
| `subnetName` | `foundry-pe-subnet` | Subnet hosting the private endpoint |
| `subnetAddressPrefix` | `10.0.1.0/24` | Prefix for a **new** private-endpoint subnet |
| `agentSubnetName` | `foundry-agent-subnet` | Subnet **delegated to `Microsoft.App/environments`** for Foundry Agent Service outbound traffic |
| `agentSubnetAddressPrefix` | `10.0.2.0/24` | Prefix for a **new** agent subnet (must be **≥ /24**) |
| `privateEndpointName` | `<account>-pe` | Private endpoint name |
| `privateDnsZoneNewOrExisting` | `new` | **`new`** creates DNS zones; **`existing`** reuses them |
| `privateDnsZoneResourceGroup` | current RG | RG of **existing** private DNS zones |
| `tags` | `{}` | Resource tags |

## Deploy with Azure CLI

```bash
az group create -n rg-foundry -l eastus2

# New network + new DNS zones (simplest)
az deployment group create \
  -g rg-foundry \
  -f infra/main.bicep \
  -p location=eastus2 foundryAccountName=my-foundry-account

# Bring your own (existing) VNet/subnet + existing DNS zones
az deployment group create \
  -g rg-foundry \
  -f infra/main.bicep \
  -p location=eastus2 \
     vnetNewOrExisting=existing vnetName=my-vnet vnetResourceGroup=rg-network \
     subnetName=pe-subnet \
     privateDnsZoneNewOrExisting=existing privateDnsZoneResourceGroup=rg-dns
```

Or use a parameters file:

```bash
# New VNet + new DNS zones
az deployment group create -g rg-foundry -f infra/main.bicep -p @infra/main.parameters.json

# Existing (bring-your-own) VNet/subnet + existing DNS zones
az deployment group create -g rg-foundry -f infra/main.bicep -p @infra/main.parameters.existing.json
```

Two example parameter files are provided:

| File | Scenario |
|------|----------|
| [`main.parameters.json`](./main.parameters.json) | Create a **new** VNet/subnet and **new** private DNS zones |
| [`main.parameters.existing.json`](./main.parameters.existing.json) | Reuse an **existing** VNet/subnet (`rg-network`) and **existing** DNS zones (`rg-dns`) |

## Rebuild the ARM template

`azuredeploy.json` is compiled from `main.bicep`. After editing the Bicep, regenerate it:

```bash
az bicep build --file infra/main.bicep --outfile infra/azuredeploy.json
```

## Foundry Agent Service: the delegated outbound subnet

Microsoft Foundry's **Agent Service** can run agents **injected into your virtual network** (a "standard"/BYO-VNet setup) so that all **outbound agent traffic** — data proxy, tool calls, and private-endpoint access to Storage, Cosmos DB, AI Search, Key Vault, etc. — originates from *your* network instead of a Microsoft-managed one.

To enable this, the Agent Service (built on Azure Container Apps technology) needs a **dedicated subnet delegated to `Microsoft.App/environments`**, so it can inject its runtime/data-proxy compute into that subnet. This template creates that subnet for you:

- **Separate from the private-endpoint subnet.** The `agentSubnetName` subnet carries agent *outbound* traffic; the `subnetName` subnet holds the *inbound* private endpoint. They must not be the same subnet.
- **Delegation:** `Microsoft.App/environments` (set automatically in `main.bicep`).
- **Size:** at least **/24** — Microsoft recommends this for agent injection, and the subnet **cannot be resized in place** later, so don't undersize it.
- **Existing VNet:** when `vnetNewOrExisting=existing`, you must pre-create the delegated subnet yourself and pass its name via `agentSubnetName`; the template references it (output `agentSubnetIdOut`) but won't add the delegation for you.
- **Resource providers:** register **`Microsoft.App`** and **`Microsoft.ContainerService`** in the subscription before deploying, or agent injection fails.
- **Immutable:** subnet delegation/injection can't be moved to a different subnet without redeploying the environment.

> Deploying this subnet makes the network **ready** for network-injected agents. You still associate it when you create the Agent Service **capability host / project** (portal or a follow-up template). The output `agentSubnetIdOut` gives you the exact subnet resource ID to plug in.

## Notes & prerequisites

- **RBAC:** See [Prerequisites: minimum RBAC roles](#prerequisites-minimum-rbac-roles) above.
- Because public access is **disabled**, reach the account from **inside the VNet** (VPN/ExpressRoute/jumpbox/peered network). The portal playground needs network line-of-sight too.
- **Existing** VNet: ensure the subnet has `privateEndpointNetworkPolicies` set to `Disabled` (the template does this only for **new** subnets).
- **Existing** DNS zones: the template attaches them to the endpoint but does **not** create VNet links — ensure your zones are already linked to the VNet that will resolve them.
- Deploy models (Standard / PTU / Batch / Managed Compute) after the account exists — see [../docs/04-data-residency-and-deployment-types.md](../docs/04-data-residency-and-deployment-types.md).

## Reference

- `Microsoft.CognitiveServices/accounts` template reference — <https://learn.microsoft.com/en-us/azure/templates/microsoft.cognitiveservices/accounts>
- Configure private link for Foundry — <https://learn.microsoft.com/en-us/azure/ai-foundry/how-to/configure-private-link>
- Foundry Agent Service networking (deep dive) — <https://learn.microsoft.com/en-us/azure/foundry/agents/concepts/agents-networking-deep-dive>
- Set up private networking for Agent Service — <https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/virtual-networks>
- Subnet delegation overview — <https://learn.microsoft.com/en-us/azure/virtual-network/subnet-delegation-overview>
- Azure Verified Module (cognitive-services/account) — <https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/cognitive-services/account>
