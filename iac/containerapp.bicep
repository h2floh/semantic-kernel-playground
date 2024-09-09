targetScope = 'subscription'

param location string = 'swedencentral'
param servicePrefix string = ''
param uniqueStringSalt string = ''
param acrLoginServer string = ''
param managedEnvironmentResourceId string = ''
param userAssignedIdentityResourceId string = '' //needed for association to container app
param userAssignedIdentityClientId string = '' //needed for container apps managed identity login

resource rgskp 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-semantickernelplayground'
  location: location
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
        identity: userAssignedIdentityResourceId
      }
    ]
    environmentResourceId: managedEnvironmentResourceId
    name: 'skp-${uniqueString(uniqueStringSalt)}'
    managedIdentities: {
      userAssignedResourceIds: [
        userAssignedIdentityResourceId
      ]
    }
  }
}
