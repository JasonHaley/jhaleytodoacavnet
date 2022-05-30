param name string
param location string
param principalId string = ''
param apiImageName string = ''

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2022-01-01-preview' = {
  name: '${name}acaenv'
  location: location
  properties: {
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
