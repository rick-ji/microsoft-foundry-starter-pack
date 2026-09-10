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

> Deploying this subnet makes the network **ready** for network-injected agents. You still associate it when you create the Agent Service **capability host / project** — use the [`agent-standard-setup.bicep`](#agent-service-capability-host-standard-agent-setup) module below (or the portal). The output `agentSubnetIdOut` gives you the exact subnet resource ID to plug in.

## Agent Service capability host (standard agent setup)

[`agent-standard-setup.bicep`](./agent-standard-setup.bicep) is a **second-stage** module that layers the Foundry **Agent Service** onto the account from `main.bicep`. Run it **after** the base deployment.

**What it creates:**

| Resource | Role in the agent setup |
|----------|-------------------------|
| Foundry **project** (system-assigned identity) | Container for agents |
| **Azure Cosmos DB** | Agent **thread storage** (`threadStorageConnections`) |
| **Azure Storage** | Agent **file storage** (`storageConnections`) |
| **Azure AI Search** | Agent **vector store** (`vectorStoreConnections`) |
| Project **connections** (AAD auth) | Named links from the project to each dependency |
| **Role assignments** | Cosmos DB Operator, Storage Blob Data Contributor, Search Index Data Contributor, Search Service Contributor — granted to the project identity |
| **Account** capability host | Carries the **network injection** via `customerSubnet` = your agent subnet |
| **Project** capability host | Wires the three connections into the agent runtime |

**How the network injection works here:** the account-level capability host's `customerSubnet` is set to the delegated `agentSubnetId`, so all agent runtime/data-proxy compute is injected into your `foundry-agent-subnet` and outbound traffic originates from your VNet.

**Deploy:**

```bash
# 1) Get the agent subnet ID from the base deployment output
AGENT_SUBNET_ID=$(az deployment group show -g rg-foundry -n main --query properties.outputs.agentSubnetIdOut.value -o tsv)

# 2) Deploy the standard agent setup
az deployment group create \
  -g rg-foundry \
  -f infra/agent-standard-setup.bicep \
  -p accountName=my-foundry-account agentSubnetId="$AGENT_SUBNET_ID" projectName=agent-project
```

Or with the example parameters file (edit `agentSubnetId` first):

```bash
az deployment group create -g rg-foundry -f infra/agent-standard-setup.bicep -p @infra/agent-standard-setup.parameters.json
```

**Key parameters:** `accountName` (existing), `agentSubnetId` (required), `projectName`, `cosmosDbName` / `storageAccountName` / `aiSearchName` (auto-named), `dependencyPublicNetworkAccess` (`Enabled` default; see below).

**Important notes:**
- **Preview APIs:** capability hosts + `networkInjections` use `2025-04-01-preview`. The Bicep type defs are stale, so `capabilityHostKind` / `customerSubnet` are set with `#disable-next-line BCP037` — this is expected and matches the official sample.
- **One capability host per account:** if the account already has one (e.g., it was created with `networkInjections.scenario='agent'`, which auto-creates it), this module's account-level host will conflict — remove/skip it in that case.
- **Additional RBAC to deploy this module:** the deployer also needs to **create role assignments**, i.e. **Owner** or **User Access Administrator** on the dependency scopes (on top of the roles in the base table).
- **Full private isolation:** `dependencyPublicNetworkAccess='Enabled'` is the turnkey default so the deployment succeeds without extra plumbing. For production **network isolation**, set it to `Disabled` **and add private endpoints + private DNS** for Cosmos (`privatelink.documents.azure.com`), Blob (`privatelink.blob.core.windows.net`), and Search (`privatelink.search.windows.net`) — see the official sample linked below.
- **Data-plane container roles:** the fully-secured official sample applies a *second pass* of container-scoped Cosmos/Blob data-plane role assignments **after** the capability host provisions its containers. This starter module applies the account-scoped roles needed to create the host; add the container-scoped pass if your agents fail on thread/file access.

**Regenerate the compiled ARM** after editing:

```bash
az bicep build --file infra/agent-standard-setup.bicep --outfile infra/agent-standard-setup.json
```

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
- Official standard-agent (network-secured) sample — <https://github.com/microsoft-foundry/foundry-samples/tree/main/infrastructure/infrastructure-setup-bicep/15-private-network-standard-agent-setup>
- capabilityHosts template reference — <https://learn.microsoft.com/en-us/azure/templates/microsoft.cognitiveservices/accounts/capabilityhosts>
- Azure Verified Module (cognitive-services/account) — <https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/cognitive-services/account>
