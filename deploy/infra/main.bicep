param location string
@secure()
param postgresAdminPassword string
param webapiNodeEnv string
param webApiHostingPlanName string
param webApiName string
param logAnalyticsName string
param appInsightsName string
param dbServerName string
param dbName string

module monitoring './webapi/monitoring.bicep' = {
  name: 'monitoringDeploy'
  params: {
    location: location
    logAnalyticsName: logAnalyticsName
    appInsightsName: appInsightsName
  }
}

module db './webapi/db.bicep' = {
  name: 'dbDeploy'
  params: {
    location: location
    workspaceId: monitoring.outputs.workspaceId
    administratorLoginPassword: postgresAdminPassword
    dbServerName: dbServerName
    dbName: dbName
  }
}

module webApi './webapi/webapp.bicep' = {
  name: 'webAppDeploy'
  params: {
    location: location
    workspaceId: monitoring.outputs.workspaceId
    appSettingsPgHost: db.outputs.pgHost
    appSettingsPgUser: db.outputs.pgUser
    appSettingsPgDb: db.outputs.pgDb
    appSettingsNodeEnv: webapiNodeEnv
    appSettingsPgPassword: postgresAdminPassword
    appSettingsInsightsKey: monitoring.outputs.instrumentationKey
    webApiHostingPlanName: webApiHostingPlanName
    webApiName: webApiName
  }
}

output webapiId string = webApi.outputs.webApiId
output postgresHost string = db.outputs.pgHost
output postgresUser string = db.outputs.pgUser
output postgresDb string = db.outputs.pgDb
