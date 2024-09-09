targetScope = 'subscription'

param location string = 'swedencentral'
param uniqueStringSalt string = 'semantickernelplayground'
param storageAccountName string = 'fwagner2258644035'
param storageAccountResourceGroup string = 'rg-AzureAI'
param searchLocation string = 'canadacentral' // semantic search not yet available in swedencentral as of 2024-08-26
param restore bool = false
param developerPrincipalId string = 'e7359a6e-64fc-4f74-8be2-6c3778a53e1a'
param federatedIdentityPrincipalId string = '7f4d5d70-395a-4075-bf4d-3245553bac10'

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
    restore: restore
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
        principalId: developerPrincipalId
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
        principalId: developerPrincipalId
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

module phiEndpoint 'phi.bicep' = {
  name: '${uniqueString(deployment().name, location)}-phiEndpoint'
  scope: rgskp
  params: {
    location: location
    uniqueStringSalt: uniqueStringSalt
    managedIdentityPrincipalId: userAssignedIdentity.outputs.principalId
    developerPrincipalId: developerPrincipalId
  }
}

module workspace 'br/public:avm/res/operational-insights/workspace:0.6.0' = {
  name: '${uniqueString(deployment().name, location)}-workspaceDeployment'
  scope: rgskp
  params: {
    // Required parameters
    name: 'skp-${uniqueString(uniqueStringSalt)}'
  }
}

// Possible values for workloadProfileType in ARM managedEnvironments are:
// - Consumption
// - Bursting
// - Reserved
// - Spot
module managedEnvironment 'br/public:avm/res/app/managed-environment:0.7.0' = {
  name: '${uniqueString(deployment().name, location)}-managedEnvironmentDeployment'
  scope: rgskp
  params: {
    // Required parameters
    logAnalyticsWorkspaceResourceId: workspace.outputs.resourceId
    name: 'skp-${uniqueString(uniqueStringSalt)}'
    // Non-required parameters
    internal: false
    zoneRedundant: false
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
  }
}

module registry 'br/public:avm/res/container-registry/registry:0.4.0' = {
  name: '${uniqueString(deployment().name, location)}-registryDeployment'
  scope: rgskp
  params: {
    // Required parameters
    name: 'skp${uniqueString(uniqueStringSalt)}'
    // Non-required parameters
    acrSku: 'Basic'
    roleAssignments: [
      {
        principalId: userAssignedIdentity.outputs.principalId
        roleDefinitionIdOrName: 'AcrPull'
      }
      {
        principalId: developerPrincipalId
        roleDefinitionIdOrName: 'AcrPush'
      }
      {
        principalId: federatedIdentityPrincipalId
        roleDefinitionIdOrName: 'AcrPush'
      }
    ]
  }
}

module containerApp 'br/public:avm/res/app/container-app:0.10.0' = {
  name: '${uniqueString(deployment().name, location)}-containerAppDeployment'
  scope: rgskp
  params: {
    // Required parameters
    workloadProfileName: 'Consumption'

    containers: [
      {
        image: '${registry.outputs.loginServer}/semantickernelplayground/api:latest'
        name: 'ai-agent-api'
        resources: {
          cpu: '0.25'
          memory: '0.5Gi'
        }
      }
    ]
    registries: [
      {
        server: registry.outputs.loginServer
        identity: userAssignedIdentity.outputs.resourceId
      }
    ]
    environmentResourceId: managedEnvironment.outputs.resourceId
    name: 'skp-${uniqueString(uniqueStringSalt)}'
    managedIdentities: {
      userAssignedResourceIds: [
        userAssignedIdentity.outputs.resourceId
      ]
    }
  }
}


output azureAiAccountName string = azureai.outputs.name
output searchServiceName string = searchService.outputs.name
