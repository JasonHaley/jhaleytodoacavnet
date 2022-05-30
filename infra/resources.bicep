param name string
param location string
param principalId string = ''

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2020-11-01' = {
  name: '${name}vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    dhcpOptions: {
      dnsServers: []
    }
    subnets: [
      {
        name: 'controlplane'
        properties: {
          addressPrefix: '10.0.0.0/21'
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'applications'
        properties: {
          addressPrefix: '10.0.8.0/21'
          delegations: []
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

resource applicationSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  parent: virtualNetwork
  name: 'applications'
  properties: {
    addressPrefix: '10.0.8.0/21'
    delegations: []
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

resource controlPlaneSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  parent: virtualNetwork
  name: 'controlplane'
  properties: {
    addressPrefix: '10.0.0.0/21'
    delegations: []
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-01-01-preview' = {
  name: '${name}acaenv'
  location: location
  properties: {
    vnetConfiguration: {
      internal: false
      infrastructureSubnetId: controlPlaneSubnet.id
      runtimeSubnetId: applicationSubnet.id
      dockerBridgeCidr: '10.2.0.1/16'
      platformReservedCidr: '10.1.0.0/16'
      platformReservedDnsIP: '10.1.0.2'
    }
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
  }
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-12-01-preview' = {
  name: '${replace(name, '-', '')}reg'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    adminUserEnabled: true
    anonymousPullEnabled: false
    dataEndpointEnabled: false
    encryption: {
      status: 'disabled'
    }
    networkRuleBypassOptions: 'AzureServices'
    publicNetworkAccess: 'Enabled'
    zoneRedundancy: 'Disabled'
  }
}

resource appServicePlan 'Microsoft.Web/serverFarms@2020-06-01' = {
  name: '${name}plan'
  location: location
  sku: {
    name: 'B1'
  }
}

resource web 'Microsoft.Web/sites@2021-01-15' = {
  name: '${name}web'
  location: location
  kind: 'app,linux'
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      alwaysOn: true
      ftpsState: 'FtpsOnly'
    }
    httpsOnly: true
  }

  resource appSettings 'config' = {
    name: 'appsettings'
    properties: {
      'SCM_DO_BUILD_DURING_DEPLOYMENT': 'false'
      'APPINSIGHTS_INSTRUMENTATIONKEY': appInsightsResources.outputs.APPINSIGHTS_INSTRUMENTATIONKEY
    }
  }

  resource logs 'config' = {
    name: 'logs'
    properties: {
      applicationLogs: {
        fileSystem: {
          level: 'Verbose'
        }
      }
      detailedErrorMessages: {
        enabled: true
      }
      failedRequestsTracing: {
        enabled: true
      }
      httpLogs: {
        fileSystem: {
          enabled: true
          retentionInDays: 1
          retentionInMb: 35
        }
      }
    }
  }
}

module privateDnsResources './privatedns.bicep' = {
  name: '${name}privateDns'
  params: {
    privateDnsZoneName: containerAppsEnvironment.properties.defaultDomain
    containerEnvStaticIp: containerAppsEnvironment.properties.staticIp
    vnetName: virtualNetwork.name
    vnetId: virtualNetwork.id
  }
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
          image: 'nginx:latest'
          name: 'main'
          env: [
            {
              name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
              value: appInsightsResources.outputs.APPINSIGHTS_INSTRUMENTATIONKEY
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

module appInsightsResources './appinsights.bicep' = {
  name: '${name}insightsres'
  params: {
    name: toLower(name)
    location: location
  }
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  name: '${name}loganalytics'
  location: location
  properties: any({
    retentionInDays: 30
    features: {
      searchVersion: 1
    }
    sku: {
      name: 'PerGB2018'
    }
  })
}

resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2021-04-15' = {
  name: '${name}cosmos'
  kind: 'MongoDB'
  location: location
  properties: {
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    databaseAccountOfferType: 'Standard'
    enableAutomaticFailover: false
    enableMultipleWriteLocations: false
    apiProperties: {
      serverVersion: '4.0'
    }
    capabilities: [
      {
        name: 'EnableServerless'
      }
    ]
  }

  resource database 'mongodbDatabases' = {
    name: 'Todo'
    properties: {
      resource: {
        id: 'Todo'
      }
    }

    resource list 'collections' = {
      name: 'TodoList'
      properties: {
        resource: {
          id: 'TodoList'
          shardKey: {
            _id: 'Hash'
          }
          indexes: [
            {
              key: {
                keys: [
                  '_id'
                ]
              }
            }
          ]
        }
      }
    }

    resource item 'collections' = {
      name: 'TodoItem'
      properties: {
        resource: {
          id: 'TodoItem'
          shardKey: {
            _id: 'Hash'
          }
          indexes: [
            {
              key: {
                keys: [
                  '_id'
                ]
              }
            }
          ]
        }
      }
    }
  }
}

output AZURE_COSMOS_DATABASE_NAME string = cosmos::database.name
output APPINSIGHTS_INSTRUMENTATIONKEY string = appInsightsResources.outputs.APPINSIGHTS_INSTRUMENTATIONKEY
output API_URI string = 'https://${api.properties.configuration.ingress.fqdn}'
output WEB_URI string = 'https://${web.properties.defaultHostName}'
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.name
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.properties.loginServer
output AZURE_CONTAINER_REGISTRY_SECRET_REFERENCE string = 'registry-password'
