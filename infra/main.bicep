targetScope = 'subscription'

@minLength(1)
@maxLength(17)
@description('Prefix for all resources, i.e. {name}storage')
param name string

@minLength(1)
@description('Primary location for all resources')
param location string

@description('Id of the user or app to assign application roles')
param principalId string = ''

resource resourceGroup 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: '${name}rg'
  location: location
}

module resources './resources.bicep' = {
  name: '${resourceGroup.name}res'
  scope: resourceGroup
  params: {
    name: toLower(name)
    location: location
    principalId: principalId
  }
}

output APPINSIGHTS_INSTRUMENTATIONKEY string = resources.outputs.APPINSIGHTS_INSTRUMENTATIONKEY
output API_BASE_URL string = resources.outputs.API_URI
output REACT_APP_API_BASE_URL string = resources.outputs.WEB_URI
output REACT_APP_APPINSIGHTS_INSTRUMENTATIONKEY string = resources.outputs.APPINSIGHTS_INSTRUMENTATIONKEY
output AZURE_LOCATION string = location
output AZURE_CONTAINER_REGISTRY_NAME string = resources.outputs.AZURE_CONTAINER_REGISTRY_NAME
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = resources.outputs.AZURE_CONTAINER_REGISTRY_ENDPOINT
output AZURE_CONTAINER_REGISTRY_SECRET_REFERENCE string = resources.outputs.AZURE_CONTAINER_REGISTRY_SECRET_REFERENCE
