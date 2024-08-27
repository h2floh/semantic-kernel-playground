targetScope = 'subscription'

param location string = 'swedencentral'
param uniqueStringSalt string = 'semantickernelplayground'
param storageAccountName string = 'fwagner2258644035'
param storageAccountResourceGroup string = 'rg-AzureAI'
param keyVaultName string = 'kv-florianw956471178930'
param keyVaultResourceGroup string = 'rg-AzureAI'
param restore bool = false

resource rgskp 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-semantickernelplayground'
  location: location
}

resource rgstorage 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name: storageAccountResourceGroup
}

resource rgkv 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name: keyVaultResourceGroup
}

module azureai 'br/public:avm/res/cognitive-services/account:0.7.0' = {
  name: '${uniqueString(deployment().name, location)}-azureai-account'
  scope: rgskp
  params: {
    restore: restore
    // Required parameters
    kind: 'AIServices'
    name: 'skp-${uniqueString(uniqueStringSalt)}'
    deployments: [
      {
        model: {
          format: 'OpenAI'
          name: 'gpt-35-turbo-16k'
          version: '0613'
        }
        name: 'gpt-35-turbo-16k'
        sku: {
          capacity: 1
          name: 'Standard'
        }
      }
    ]
    location: location
  }
}

module searchService 'br/public:avm/res/search/search-service:0.6.0' = {
  name: '${uniqueString(deployment().name, location)}-azureai-search'
  scope: rgskp
  params: {
    // Required parameters
    name: 'skp-${uniqueString(uniqueStringSalt)}'
    // Non-required parameters
    location: 'canadacentral' // not yes available in swedencentral as of 2024-08-26
    partitionCount: 1
    replicaCount: 1
    semanticSearch: 'free'
    sku: 'basic'
    managedIdentities: {
      systemAssigned: true
    }
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' existing = {
  name: storageAccountName
  scope: rgstorage
}

module resourceRoleAssignment 'br/public:avm/ptn/authorization/resource-role-assignment:0.1.1' = {
  name: '${uniqueString(deployment().name, location)}-RoleAssignment'
  scope: rgstorage
  params: {
    // Required parameters
    principalId: searchService.outputs.systemAssignedMIPrincipalId
    resourceId: storageAccount.id
    roleDefinitionId: '2a2b9908-6ea1-4ae2-8e65-a410df84e7d1'
    // Non-required parameters
    description: 'Assign Storage Blob Data Reader role to the managed identity on the storage account.'
    principalType: 'ServicePrincipal'
    roleName: 'Storage Blob Data Reader'
  }
}

resource aoai 'Microsoft.CognitiveServices/accounts@2024-04-01-preview' existing = {
  name: 'skp-${uniqueString(uniqueStringSalt)}'
  scope: rgskp
}

// Switch later to a dedicated keyvault and give a user assigned managed identity access to it
module aoaiKey 'br/public:avm/res/key-vault/vault:0.7.1' = {
  name: '${uniqueString(deployment().name, location)}-azureai-key'
  scope: rgkv
  params: {
    name: keyVaultName
    location: 'swedencentral'
    secrets: [
      {
        name: 'openaikey'
        value: aoai.listKeys().key1
      }
    ]
  }
}

output azureAiAccountName string = azureai.name
output searchServiceName string = searchService.name
