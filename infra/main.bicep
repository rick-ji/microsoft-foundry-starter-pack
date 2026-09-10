// =============================================================================
// Microsoft Foundry Starter Pack - Private Network Integration
// -----------------------------------------------------------------------------
// Deploys a Microsoft Foundry (Azure AI Foundry) account of kind "AIServices"
// with public network access DISABLED and a Private Endpoint for private,
// VNet-only connectivity.
//
// Region and network selection are exposed as parameters (variables). The
// virtual network / subnet used by the Private Endpoint can be either an
// EXISTING network or a NEW one created by this template. Private DNS zones can
// likewise be created new or reused (bring-your-own).
// =============================================================================

targetScope = 'resourceGroup'

// -----------------------------------------------------------------------------
// General
// -----------------------------------------------------------------------------

@description('Azure region for all resources. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Name of the Microsoft Foundry (AI Services) account.')
@minLength(3)
@maxLength(64)
param foundryAccountName string = 'foundry-${uniqueString(resourceGroup().id)}'

@description('Globally unique custom subdomain, required for private endpoint / token auth. Defaults to the account name.')
param customSubDomainName string = toLower(foundryAccountName)

@description('SKU for the Foundry account.')
@allowed([
  'S0'
])
param skuName string = 'S0'

// -----------------------------------------------------------------------------
// Network selection (NEW or EXISTING)
// -----------------------------------------------------------------------------

@description('Whether to create a NEW virtual network + subnet for the private endpoint, or use an EXISTING one.')
@allowed([
  'new'
  'existing'
])
param vnetNewOrExisting string = 'new'

@description('Name of the virtual network (new or existing).')
param vnetName string = 'foundry-vnet'

@description('Resource group of the EXISTING virtual network. Ignored when creating a new VNet. Defaults to the current resource group.')
param vnetResourceGroup string = resourceGroup().name

@description('Address space for the NEW virtual network. Ignored for existing VNets.')
param vnetAddressPrefix string = '10.0.0.0/16'

@description('Name of the subnet (new or existing) that hosts the private endpoint.')
param subnetName string = 'foundry-pe-subnet'

@description('Address prefix for the NEW subnet. Ignored for existing subnets.')
param subnetAddressPrefix string = '10.0.1.0/24'

// -----------------------------------------------------------------------------
// Private endpoint + DNS
// -----------------------------------------------------------------------------

@description('Name of the private endpoint.')
param privateEndpointName string = '${foundryAccountName}-pe'

@description('Whether to create NEW private DNS zones or reuse EXISTING ones.')
@allowed([
  'new'
  'existing'
])
param privateDnsZoneNewOrExisting string = 'new'

@description('Resource group of EXISTING private DNS zones. Ignored when creating new zones. Defaults to the current resource group.')
param privateDnsZoneResourceGroup string = resourceGroup().name

@description('Optional resource tags applied to created resources.')
param tags object = {}

// -----------------------------------------------------------------------------
// Variables
// -----------------------------------------------------------------------------

// Private DNS zones required to resolve a Foundry (AIServices) account privately.
var privateDnsZoneNames = [
  'privatelink.cognitiveservices.azure.com'
  'privatelink.openai.azure.com'
  'privatelink.services.ai.azure.com'
]

var vnetId = vnetNewOrExisting == 'new'
  ? newVnet.id
  : resourceId(vnetResourceGroup, 'Microsoft.Network/virtualNetworks', vnetName)

var subnetId = vnetNewOrExisting == 'new'
  ? '${newVnet.id}/subnets/${subnetName}'
  : resourceId(vnetResourceGroup, 'Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)

var privateDnsZoneIds = [
  for zone in privateDnsZoneNames: privateDnsZoneNewOrExisting == 'new'
    ? resourceId('Microsoft.Network/privateDnsZones', zone)
    : resourceId(privateDnsZoneResourceGroup, 'Microsoft.Network/privateDnsZones', zone)
]

// -----------------------------------------------------------------------------
// Virtual network (created only when vnetNewOrExisting == 'new')
// -----------------------------------------------------------------------------

resource newVnet 'Microsoft.Network/virtualNetworks@2023-11-01' = if (vnetNewOrExisting == 'new') {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressPrefix
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
    ]
  }
}

// -----------------------------------------------------------------------------
// Microsoft Foundry (AI Services) account - private only
// -----------------------------------------------------------------------------

resource foundry 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: foundryAccountName
  location: location
  tags: tags
  kind: 'AIServices'
  sku: {
    name: skuName
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    // Enables Foundry projects on the account.
    allowProjectManagement: true
    customSubDomainName: toLower(customSubDomainName)
    // Lock down public access - reachable only through the private endpoint.
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      defaultAction: 'Deny'
    }
  }
}

// -----------------------------------------------------------------------------
// Private endpoint
// -----------------------------------------------------------------------------

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: privateEndpointName
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${privateEndpointName}-conn'
        properties: {
          privateLinkServiceId: foundry.id
          groupIds: [
            'account'
          ]
        }
      }
    ]
  }
}

// -----------------------------------------------------------------------------
// Private DNS zones (created only when privateDnsZoneNewOrExisting == 'new')
// -----------------------------------------------------------------------------

resource newDnsZones 'Microsoft.Network/privateDnsZones@2020-06-01' = [
  for zone in privateDnsZoneNames: if (privateDnsZoneNewOrExisting == 'new') {
    name: zone
    location: 'global'
    tags: tags
  }
]

resource newDnsZoneLinks 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = [
  for (zone, i) in privateDnsZoneNames: if (privateDnsZoneNewOrExisting == 'new') {
    parent: newDnsZones[i]
    name: 'link-to-${vnetName}'
    location: 'global'
    tags: tags
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: vnetId
      }
    }
  }
]

// -----------------------------------------------------------------------------
// Private DNS zone group - binds the private endpoint NIC to the DNS zones
// -----------------------------------------------------------------------------

resource dnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-11-01' = {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      for (zone, i) in privateDnsZoneNames: {
        name: replace(zone, '.', '-')
        properties: {
          privateDnsZoneId: privateDnsZoneIds[i]
        }
      }
    ]
  }
  dependsOn: [
    newDnsZones
  ]
}

// -----------------------------------------------------------------------------
// Outputs
// -----------------------------------------------------------------------------

output foundryAccountId string = foundry.id
output foundryAccountName string = foundry.name
output foundryEndpoint string = foundry.properties.endpoint
output privateEndpointId string = privateEndpoint.id
output vnetIdOut string = vnetId
output subnetIdOut string = subnetId
