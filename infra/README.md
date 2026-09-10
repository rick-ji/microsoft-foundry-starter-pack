# Infra: Microsoft Foundry with Private Network Integration

Bicep + compiled ARM that deploys a **Microsoft Foundry (Azure AI Foundry) account** (`Microsoft.CognitiveServices/accounts`, kind **`AIServices`**) with:

- **Public network access disabled** (`publicNetworkAccess: 'Disabled'`, `networkAcls.defaultAction: 'Deny'`)
- A **Private Endpoint** into your VNet
- **Private DNS zones** (`privatelink.cognitiveservices.azure.com`, `privatelink.openai.azure.com`, `privatelink.services.ai.azure.com`) + VNet links
- **System-assigned managed identity**
- **Foundry project management** enabled

**Region** and **network selection** are parameters (variables). The VNet/subnet and the private DNS zones can each be **created new** or **reused (existing)**.

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
| `subnetAddressPrefix` | `10.0.1.0/24` | Prefix for a **new** subnet |
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

Or use the parameters file:

```bash
az deployment group create -g rg-foundry -f infra/main.bicep -p @infra/main.parameters.json
```

## Rebuild the ARM template

`azuredeploy.json` is compiled from `main.bicep`. After editing the Bicep, regenerate it:

```bash
az bicep build --file infra/main.bicep --outfile infra/azuredeploy.json
```

## Notes & prerequisites

- Because public access is **disabled**, reach the account from **inside the VNet** (VPN/ExpressRoute/jumpbox/peered network). The portal playground needs network line-of-sight too.
- **Existing** VNet: ensure the subnet has `privateEndpointNetworkPolicies` set to `Disabled` (the template does this only for **new** subnets).
- **Existing** DNS zones: the template attaches them to the endpoint but does **not** create VNet links — ensure your zones are already linked to the VNet that will resolve them.
- Deploy models (Standard / PTU / Batch / Managed Compute) after the account exists — see [../docs/04-data-residency-and-deployment-types.md](../docs/04-data-residency-and-deployment-types.md).

## Reference

- `Microsoft.CognitiveServices/accounts` template reference — <https://learn.microsoft.com/en-us/azure/templates/microsoft.cognitiveservices/accounts>
- Configure private link for Foundry — <https://learn.microsoft.com/en-us/azure/ai-foundry/how-to/configure-private-link>
- Azure Verified Module (cognitive-services/account) — <https://github.com/Azure/bicep-registry-modules/tree/main/avm/res/cognitive-services/account>
