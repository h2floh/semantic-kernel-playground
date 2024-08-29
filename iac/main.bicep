targetScope = 'subscription'

param location string = 'swedencentral'
param uniqueStringSalt string = 'semantickernelplayground'
param storageAccountName string = 'fwagner2258644035'
param storageAccountResourceGroup string = 'rg-AzureAI'
param searchLocation string = 'canadacentral' // semantic search not yet available in swedencentral as of 2024-08-26
param restore bool = false

resource rgskp 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-semantickernelplayground'
  location: location
}

resource rgstorage 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name: storageAccountResourceGroup
}

module userAssignedIdentity 'br/public:avm/res/managed-identity/user-assigned-identity:0.3.0' = {
  name: '${uniqueString(deployment().name, location)}-managed-identity'
  scope: rgskp
  params: {
    // Required parameters
    name: 'skp-${uniqueString(uniqueStringSalt)}'
    // Non-required parameters
    federatedIdentityCredentials: [
      {
        audiences: [
          'api://AzureADTokenExchange'
        ]
        issuer: 'https://token.actions.githubusercontent.com'
        name: 'GitHubActions'
        subject: 'repo:h2floh/semantic-kernel-playground:ref:refs/heads/main'
      }
    ]
    location: location
  }
}

module azureai 'br/public:avm/res/cognitive-services/account:0.7.0' = {
  name: '${uniqueString(deployment().name, location)}-azureai-account'
  scope: rgskp
  params: {
    //restore: restore
    // Required parameters
    kind: 'AIServices'
    customSubDomainName: 'skp-${uniqueString(uniqueStringSalt)}'
    publicNetworkAccess: 'Enabled'
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
    roleAssignments: [
      {
        principalId: userAssignedIdentity.outputs.principalId
        roleDefinitionIdOrName: 'Cognitive Services OpenAI User'
      }
      {
        principalId: 'e7359a6e-64fc-4f74-8be2-6c3778a53e1a'
        roleDefinitionIdOrName: 'Cognitive Services OpenAI User'
      }
    ]
  }
}

module searchService 'br/public:avm/res/search/search-service:0.6.0' = {
  name: '${uniqueString(deployment().name, location)}-azureai-search'
  scope: rgskp
  params: {
    // Required parameters
    name: 'skp-${uniqueString(uniqueStringSalt)}'
    // Non-required parameters
    location: searchLocation
    partitionCount: 1
    replicaCount: 1
    semanticSearch: 'free'
    sku: 'basic'
    managedIdentities: {
      systemAssigned: true
    }
    roleAssignments: [
      {
        principalId: userAssignedIdentity.outputs.principalId
        roleDefinitionIdOrName: 'Search Index Data Reader'
      }
      {
        principalId: 'e7359a6e-64fc-4f74-8be2-6c3778a53e1a'
        roleDefinitionIdOrName: 'Search Index Data Reader'
      }
    ]
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

output azureAiAccountName string = azureai.outputs.name
output searchServiceName string = searchService.outputs.name
