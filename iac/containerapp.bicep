targetScope = 'subscription'

param location string = 'swedencentral'
param servicePrefix string = ''
param uniqueStringSalt string = ''
param acrLoginServer string = ''
param userAssignedIdentityClientId string = '' //needed for container apps managed identity login

resource rgskp 'Microsoft.Resources/resourceGroups@2022-09-01' existing = {
  name: 'rg-semantickernelplayground'
}

resource managedEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' existing = {
  name: 'skp-${uniqueString(uniqueStringSalt)}'
  scope: rgskp
}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: 'skp-${uniqueString(uniqueStringSalt)}'
  scope: rgskp
}

module containerApp 'br/public:avm/res/app/container-app:0.10.0' = {
  name: '${uniqueString(deployment().name, location)}-containerAppDeployment'
  scope: rgskp
  params: {
    // Required parameters
    workloadProfileName: 'Consumption'
    ingressTargetPort: 5000
    containers: [
      {
        image: '${acrLoginServer}/semantickernelplayground/api:latest'
        name: 'ai-agent-api'
        resources: {
          cpu: '0.25'
          memory: '0.5Gi'
        }
        env: [
          {
            name: 'AZURE_SERVICE_PREFIX'
            value: servicePrefix
          }
          {
            name: 'AZURE_USER_ASSIGNED_IDENTITY_CLIENT_ID'
            value: userAssignedIdentityClientId
          }
        ]
      }
    ]
    registries: [
      {
        server: acrLoginServer
        identity: userAssignedIdentity.id
      }
    ]
    environmentResourceId: managedEnvironment.id
    name: 'skp-${uniqueString(uniqueStringSalt)}'
    managedIdentities: {
      userAssignedResourceIds: [
        userAssignedIdentity.id
      ]
    }
  }
}
