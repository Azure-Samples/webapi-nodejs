param location string
param workspaceId string
param appSettingsPgHost string
param appSettingsPgUser string
@secure()
param appSettingsPgPassword string
param appSettingsPgDb string
param appSettingsNodeEnv string
param appSettingsInsightsKey string
param webApiHostingPlanName string
param webApiName string


resource webApiHostingPlan 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: webApiHostingPlanName
  location: location
  kind: 'linux'
  sku: {
    name: 'B1'
  }
  properties: {
    reserved: true
  }
}

resource webApi 'Microsoft.Web/sites@2020-06-01' = {
  name: webApiName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    siteConfig: {
      linuxFxVersion: 'NODE|14-lts'
      ftpsState: 'FtpsOnly'
      appSettings: [
        {
          name: 'PGHOST'
          value: '${appSettingsPgHost}'
        }
        {
          name: 'PGUSER'
          value: '${appSettingsPgUser}@${appSettingsPgHost}'
        }
        {
          name: 'PGPASSWORD'
          value: '${appSettingsPgPassword}'
        }
        {
          name: 'PGDB'
          value: '${appSettingsPgDb}'
        }
        {
          name: 'NODE_ENV'
          value: '${appSettingsNodeEnv}'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: '${appSettingsInsightsKey}'
        }
        {
          name: 'PGSSLMODE'
          value: 'require'
        }
        {
          name: 'ENABLE_ORYX_BUILD'
          value: 'true'
        }
        {
          name: 'SCM_DO_BUILD_DURING_DEPLOYMENT'
          value: 'true'
        }
        {
          name: 'CUSTOM_BUILD_COMMAND'
          value: 'npm ci --production'
        }
      ]
    }
    serverFarmId: webApiHostingPlan.id
  }
}

resource webDiagnostics 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  scope: webApi
  name: 'logAnalytics-${webApiName}'
  properties: {
    workspaceId: workspaceId
    logs: [
      {
        enabled: true
        category: 'AppServicePlatformLogs'
      }
      {
        enabled: true
        category: 'AppServiceIPSecAuditLogs'
      }
      {
        enabled: true
        category: 'AppServiceAuditLogs'
      }
      {
        enabled: true
        category: 'AppServiceFileAuditLogs'
      }
      {
        enabled: true
        category: 'AppServiceAppLogs'
      }
      {
        enabled: true
        category: 'AppServiceConsoleLogs'
      }
      {
        enabled: true
        category: 'AppServiceHTTPLogs'
      }
      {
        enabled: true
        category: 'AppServiceAntivirusScanAuditLogs'
      }
    ]
    metrics: [
      {
        enabled: true
        category: 'AllMetrics'
      }
    ]
  }
}

output webApiId string = webApi.id
