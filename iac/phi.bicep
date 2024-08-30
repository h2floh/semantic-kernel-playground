param uniqueStringSalt string
param endpointName string = 'skp-${uniqueString(uniqueStringSalt)}'
param location string = resourceGroup().location
param modelId string = 'azureml://registries/azureml/models/Phi-3-small-128k-instruct'

module vault 'br/public:avm/res/key-vault/vault:0.7.1' = {
  name: '${uniqueString(deployment().name, location)}-vaultDeployment'
  params: {
    // Required parameters
    name: 'skp-${uniqueString(uniqueStringSalt)}'
    sku: 'standard'
    // Non-required parameters
    enablePurgeProtection: false
    location: location
  }
}

module storageAccount 'br/public:avm/res/storage/storage-account:0.13.0' = {
  name: '${uniqueString(deployment().name, location)}-storageAccountDeployment'
  params: {
    // Required parameters
    name: 'skp${uniqueString(uniqueStringSalt)}'
    // Non-required parameters
    kind: 'BlobStorage'
    location: location
    skuName: 'Standard_LRS'
  }
}

module aiHub 'br/public:avm/res/machine-learning-services/workspace:0.7.0' = {
  name: '${uniqueString(deployment().name, location)}-hubDeployment'
  params: {
    // Required parameters
    name: 'skp-${uniqueString(uniqueStringSalt)}'
    sku: 'Basic'
    publicNetworkAccess: 'Enabled'
    kind: 'Hub'
    // Non-required parameters
    associatedKeyVaultResourceId: vault.outputs.resourceId
    associatedStorageAccountResourceId: storageAccount.outputs.resourceId
    location: location
  }
}

module aiProject 'br/public:avm/res/machine-learning-services/workspace:0.7.0' = {
  name: '${uniqueString(deployment().name, location)}-projectDeployment'
  params: {
    // Required parameters
    name: 'skp-pr-${uniqueString(uniqueStringSalt)}'
    sku: 'Basic'
    kind: 'Project'
    hubResourceId: aiHub.outputs.resourceId
    location: location
  }
}

resource projectName_endpoint 'Microsoft.MachineLearningServices/workspaces/serverlessEndpoints@2024-04-01-preview' = {
  name: 'skp-pr-${uniqueString(uniqueStringSalt)}/${endpointName}'
  location: location
  sku: {
    name: 'Consumption'
  }
  properties: {
    modelSettings: {
      modelId: modelId
    }
  }
  dependsOn: [
    aiProject
  ]
}
