// =============================================================================
// Microsoft Foundry - Standard Agent Setup (capability hosts + network injection)
// -----------------------------------------------------------------------------
// Layers the Foundry *Agent Service* on top of an EXISTING Foundry account
// (deploy infra/main.bicep first). It creates:
//   - A Foundry PROJECT (system-assigned identity)
//   - The three BYO dependencies the standard agent setup requires:
//       * Azure Cosmos DB   -> agent thread storage
//       * Azure Storage      -> agent file storage
//       * Azure AI Search    -> agent vector store
//   - Project CONNECTIONS (AAD auth) to each dependency
//   - Least-privilege ROLE ASSIGNMENTS for the project identity
//   - The ACCOUNT-level capability host (carries the agent-subnet network
//     injection via `customerSubnet`)
//   - The PROJECT-level capability host (wires the three connections)
//
// Schema mirrors the official sample:
//   microsoft-foundry/foundry-samples .../15-private-network-standard-agent-setup
//
// NOTE: capabilityHosts / networkInjections are PREVIEW; the Bicep type defs are
// stale, so `capabilityHostKind` + `customerSubnet` need BCP037 suppression.
// =============================================================================

targetScope = 'resourceGroup'

@description('Region for all resources. Defaults to the resource group location.')
param location string = resourceGroup().location

@description('Name of the EXISTING Foundry (AIServices) account created by main.bicep.')
param accountName string

@description('ARM resource ID of the delegated agent subnet (Microsoft.App/environments) — main.bicep output "agentSubnetIdOut".')
param agentSubnetId string

@description('Name of the Foundry project to create under the account.')
@maxLength(32)
param projectName string = 'agent-project'

@description('Project description.')
param projectDescription string = 'Foundry standard agent setup project.'

@description('Project display name.')
param projectDisplayName string = 'Agent Project'

@description('Name of the Cosmos DB account (agent thread storage).')
param cosmosDbName string = toLower('cos${uniqueString(resourceGroup().id, accountName)}')

@description('Name of the Storage account (agent file storage). 3-24 lowercase alphanumerics.')
@maxLength(24)
param storageAccountName string = toLower('st${uniqueString(resourceGroup().id, accountName)}')

@description('Name of the Azure AI Search service (agent vector store).')
param aiSearchName string = toLower('srch${uniqueString(resourceGroup().id, accountName)}')

@description('Public network access for the created dependencies. Use "Disabled" only if you also add private endpoints for each dependency (see README).')
@allowed([
  'Enabled'
  'Disabled'
])
param dependencyPublicNetworkAccess string = 'Enabled'

@description('Optional resource tags.')
param tags object = {}

// Platform-convention capability host names (match the implicit ones).
var accountCapHostName = '${accountName}@aml_aiagentservice'
var projectCapHostName = '${projectName}@aml_aiagentservice'

// Built-in role definition GUIDs.
var cosmosDbOperatorRoleId = '230815da-be43-4aae-9cb4-875f7bd000aa'
var storageBlobDataContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
var searchIndexDataContributorRoleId = '8ebe5a00-799e-43f5-93ac-243d3dce84a7'
var searchServiceContributorRoleId = '7ca78c08-252a-4471-8644-bb5ff32d4ba0'

// -----------------------------------------------------------------------------
// Existing Foundry account
// -----------------------------------------------------------------------------

resource account 'Microsoft.CognitiveServices/accounts@2025-04-01-preview' existing = {
  name: accountName
}

// -----------------------------------------------------------------------------
// Dependency: Cosmos DB (thread storage)
// -----------------------------------------------------------------------------

resource cosmosDb 'Microsoft.DocumentDB/databaseAccounts@2024-11-15' = {
  name: cosmosDbName
  location: location
  tags: tags
  kind: 'GlobalDocumentDB'
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    disableLocalAuth: true
    enableAutomaticFailover: false
    enableMultipleWriteLocations: false
    publicNetworkAccess: dependencyPublicNetworkAccess
    enableFreeTier: false
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    databaseAccountOfferType: 'Standard'
  }
}

// -----------------------------------------------------------------------------
// Dependency: Storage account (file storage)
// -----------------------------------------------------------------------------

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    publicNetworkAccess: dependencyPublicNetworkAccess
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: dependencyPublicNetworkAccess == 'Disabled' ? 'Deny' : 'Allow'
      virtualNetworkRules: []
    }
  }
}

// -----------------------------------------------------------------------------
// Dependency: Azure AI Search (vector store)
// -----------------------------------------------------------------------------

resource aiSearch 'Microsoft.Search/searchServices@2024-06-01-preview' = {
  name: aiSearchName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'standard'
  }
  properties: {
    disableLocalAuth: false
    authOptions: {
      aadOrApiKey: {
        aadAuthFailureMode: 'http401WithBearerChallenge'
      }
    }
    hostingMode: 'default'
    partitionCount: 1
    replicaCount: 1
    semanticSearch: 'disabled'
    publicNetworkAccess: toLower(dependencyPublicNetworkAccess)
    networkRuleSet: {
      bypass: 'None'
      ipRules: []
    }
  }
}

// -----------------------------------------------------------------------------
// Foundry project + connections (AAD auth)
// -----------------------------------------------------------------------------

resource project 'Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview' = {
  parent: account
  name: projectName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    description: projectDescription
    displayName: projectDisplayName
  }

  resource cosmosConnection 'connections@2025-04-01-preview' = {
    name: cosmosDbName
    properties: {
      category: 'CosmosDB'
      target: cosmosDb.properties.documentEndpoint
      authType: 'AAD'
      metadata: {
        ApiType: 'Azure'
        ResourceId: cosmosDb.id
        location: cosmosDb.location
      }
    }
  }

  resource storageConnection 'connections@2025-04-01-preview' = {
    name: storageAccountName
    properties: {
      category: 'AzureStorageAccount'
      target: storage.properties.primaryEndpoints.blob
      authType: 'AAD'
      metadata: {
        ApiType: 'Azure'
        ResourceId: storage.id
        location: storage.location
      }
    }
  }

  resource searchConnection 'connections@2025-04-01-preview' = {
    name: aiSearchName
    properties: {
      category: 'CognitiveSearch'
      target: 'https://${aiSearchName}.search.windows.net'
      authType: 'AAD'
      metadata: {
        ApiType: 'Azure'
        ResourceId: aiSearch.id
        location: aiSearch.location
      }
    }
  }
}

// -----------------------------------------------------------------------------
// Role assignments for the project identity (account-level, pre-capabilityHost)
// -----------------------------------------------------------------------------

resource cosmosOperatorAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: cosmosDb
  name: guid(project.id, cosmosDbOperatorRoleId, cosmosDb.id)
  properties: {
    principalId: project.identity.principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', cosmosDbOperatorRoleId)
    principalType: 'ServicePrincipal'
  }
}

resource storageBlobAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: storage
  name: guid(project.id, storageBlobDataContributorRoleId, storage.id)
  properties: {
    principalId: project.identity.principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', storageBlobDataContributorRoleId)
    principalType: 'ServicePrincipal'
  }
}

resource searchIndexAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: aiSearch
  name: guid(project.id, searchIndexDataContributorRoleId, aiSearch.id)
  properties: {
    principalId: project.identity.principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', searchIndexDataContributorRoleId)
    principalType: 'ServicePrincipal'
  }
}

resource searchServiceAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: aiSearch
  name: guid(project.id, searchServiceContributorRoleId, aiSearch.id)
  properties: {
    principalId: project.identity.principalId
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', searchServiceContributorRoleId)
    principalType: 'ServicePrincipal'
  }
}

// -----------------------------------------------------------------------------
// Account-level capability host - carries the agent-subnet network injection
// -----------------------------------------------------------------------------

resource accountCapabilityHost 'Microsoft.CognitiveServices/accounts/capabilityHosts@2025-04-01-preview' = {
  parent: account
  name: accountCapHostName
  properties: {
    #disable-next-line BCP037
    capabilityHostKind: 'Agents'
    #disable-next-line BCP037
    customerSubnet: agentSubnetId
  }
  dependsOn: [
    cosmosOperatorAssignment
    storageBlobAssignment
    searchIndexAssignment
    searchServiceAssignment
  ]
}

// -----------------------------------------------------------------------------
// Project-level capability host - wires the three connections
// -----------------------------------------------------------------------------

resource projectCapabilityHost 'Microsoft.CognitiveServices/accounts/projects/capabilityHosts@2025-04-01-preview' = {
  parent: project
  name: projectCapHostName
  properties: {
    #disable-next-line BCP037
    capabilityHostKind: 'Agents'
    threadStorageConnections: [
      cosmosDbName
    ]
    storageConnections: [
      storageAccountName
    ]
    vectorStoreConnections: [
      aiSearchName
    ]
  }
  dependsOn: [
    accountCapabilityHost
  ]
}

// -----------------------------------------------------------------------------
// Outputs
// -----------------------------------------------------------------------------

output projectName string = project.name
output projectId string = project.id
output projectPrincipalId string = project.identity.principalId
output cosmosDbId string = cosmosDb.id
output storageAccountId string = storage.id
output aiSearchId string = aiSearch.id
output accountCapabilityHostName string = accountCapabilityHost.name
output projectCapabilityHostName string = projectCapabilityHost.name
