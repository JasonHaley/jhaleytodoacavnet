param name string
param location string
param imageName string
param principalId string

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-01-01-preview' existing = {
  name: '${name}acaenv'
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-12-01-preview' existing = {
  name: '${replace(name, '-', '')}reg'
}

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: '${name}insights'
}

resource api 'Microsoft.App/containerApps@2022-01-01-preview' = {
  name: '${name}api'
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    configuration: {
      activeRevisionsMode: 'single'
      ingress: {
        external: true
        targetPort: 80
        transport: 'auto'
      }
      secrets: [
        {
          name: 'registry-password'
          value: containerRegistry.listCredentials().passwords[0].value
        }
      ]
      registries: [
        {
          server: '${containerRegistry.name}.azurecr.io'
          username: containerRegistry.name
          passwordSecretRef: 'registry-password'
        }
      ]
    }
    template: {
      containers: [
        {
          image: imageName
          name: 'main'
          env: [
            {
              name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
              value: appInsights.properties.InstrumentationKey
            }
            {
              name: 'AZURE_COSMOS_ENDPOINT'
              value: cosmos.properties.documentEndpoint
            }
            {
              name: 'AZURE_COSMOS_DATABASE_NAME'
              value: cosmos::database.name
            }
          ]
        }
      ]
    }
  }
}

resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2021-04-15' = {
  name: '${name}cosmos'
  location: location
  properties: {
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    databaseAccountOfferType: 'Standard'
  }

  resource database 'sqlDatabases' = {
    name: 'Todo'
    properties: {
      resource: {
        id: 'Todo'
      }
    }

    resource list 'containers' = {
      name: 'TodoList'
      properties: {
        resource: {
          id: 'TodoList'
          partitionKey: {
            paths: [
              '/id'
            ]
          }
        }
        options: {}
      }
    }

    resource item 'containers' = {
      name: 'TodoItem'
      properties: {
        resource: {
          id: 'TodoItem'
          partitionKey: {
            paths: [
              '/id'
            ]
          }
        }
        options: {}
      }
    }
  }

  resource roleDefinition 'sqlroleDefinitions' = {
    name: guid(cosmos.id, name, 'sql-role')
    properties: {
      assignableScopes: [
        cosmos.id
      ]
      permissions: [
        {
          dataActions: [
            'Microsoft.DocumentDB/databaseAccounts/readMetadata'
            'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/items/*'
            'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers/*'
          ]
          notDataActions: []
        }
      ]
      roleName: 'Reader Writer'
      type: 'CustomRole'
    }
  }

  resource userRole 'sqlRoleAssignments' = if (!empty(principalId)) {
    name: guid(roleDefinition.id, principalId, cosmos.id)
    properties: {
      principalId: principalId
      roleDefinitionId: roleDefinition.id
      scope: cosmos.id
    }
  }

  resource appRole 'sqlRoleAssignments' = {
    name: guid(roleDefinition.id, api.id, cosmos.id)
    properties: {
      principalId: api.identity.principalId
      roleDefinitionId: roleDefinition.id
      scope: cosmos.id
    }

    dependsOn: [
      userRole
    ]
  }
}

output API_URL string = 'https://${api.properties.configuration.ingress.fqdn}'
output APP_APPINSIGHTS_INSTRUMENTATIONKEY string = appInsights.properties.InstrumentationKey
