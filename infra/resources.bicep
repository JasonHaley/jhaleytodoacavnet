param name string
param location string
param principalId string = ''
param apiImageName string = ''

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
      {
        name: 'webapp'
        properties: {
          addressPrefix: '10.0.16.0/21'
          delegations: [
            {
              name: 'delegation'
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

resource webappSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  parent: virtualNetwork
  name: 'webapp'
  properties: {
    addressPrefix: '10.0.16.0/21'
    delegations: [
      {
        name: 'delegation'
        properties: {
          serviceName: 'Microsoft.Web/serverfarms'
        }
      }
    ]
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
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
      internal: true
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

module privateDnsResources './privatedns.bicep' = {
  name: '${name}privateDns'
  params: {
    privateDnsZoneName: containerAppsEnvironment.properties.defaultDomain
    containerEnvStaticIp: containerAppsEnvironment.properties.staticIp
    vnetName: virtualNetwork.name
    vnetId: virtualNetwork.id
  }
}

module api './api.bicep' = {
  name: '${name}api'
  params: {
    imageName: apiImageName != '' ? apiImageName : 'nginx:latest'
    name: name
    location: location
    principalId: principalId
  }
  dependsOn: [
    containerAppsEnvironment
    containerRegistry
    appInsightsResources
  ]
}

resource appServicePlan 'Microsoft.Web/serverFarms@2020-06-01' = {
  name: '${name}plan'
  location: location
  sku: {
    name: 'B1'
  }
}

resource webappVNetConnection 'Microsoft.Web/sites/virtualNetworkConnections@2021-03-01' = {
  parent: web
  name: '${name}webappvnetconnection'
  location: location
  properties: {
    vnetResourceId: webappSubnet.id
    isSwift: true
  }
}

resource webConfig 'Microsoft.Web/sites/config@2021-03-01' = {
  parent: web
  name: 'web'
  location: location
  properties: {
    vnetName: webappVNetConnection.name
    vnetRouteAllEnabled: true
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
    virtualNetworkSubnetId: webappSubnet.id
  }

  resource appSettings 'config' = {
    name: 'appsettings'
    properties: {
      'SCM_DO_BUILD_DURING_DEPLOYMENT': 'true'
      'APPINSIGHTS_INSTRUMENTATIONKEY': appInsightsResources.outputs.APPINSIGHTS_INSTRUMENTATIONKEY
      'API_BASE_URL': api.outputs.API_URL
      'REACT_APP_API_BASE_URL': ''
      'REACT_APP_APPINSIGHTS_INSTRUMENTATIONKEY': appInsightsResources.outputs.APPINSIGHTS_INSTRUMENTATIONKEY
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

output APPINSIGHTS_INSTRUMENTATIONKEY string = appInsightsResources.outputs.APPINSIGHTS_INSTRUMENTATIONKEY
output API_URI string = api.outputs.API_URL
output WEB_URI string = 'https://${web.properties.defaultHostName}'
output AZURE_CONTAINER_REGISTRY_NAME string = containerRegistry.name
output AZURE_CONTAINER_REGISTRY_ENDPOINT string = containerRegistry.properties.loginServer
output AZURE_CONTAINER_REGISTRY_SECRET_REFERENCE string = 'registry-password'
