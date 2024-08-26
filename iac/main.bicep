targetScope = 'subscription'

param location string = 'swedencentral'
param uniqueStringSalt string = 'semantickernelplayground'

resource rgskp 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-semantickernelplayground'
  location: location
}

module azureai 'br/public:avm/res/cognitive-services/account:0.7.0' = {
  name: '${uniqueString(deployment().name, location)}-azureai-account'
  scope: rgskp
  params: {
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
  }
}

output azureAiAccountName string = azureai.name
output searchServiceName string = searchService.name
