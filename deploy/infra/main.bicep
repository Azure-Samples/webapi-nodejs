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
param kubeEnvironmentId string = ''
param customLocationId string = ''
param dataControllerId string = ''

module monitoring './webapi/monitoring.bicep' = {
  name: 'monitoringDeploy'
  params: {
    location: location
    logAnalyticsName: logAnalyticsName
    appInsightsName: appInsightsName
  }
}

module dbAzure './webapi/dbAzure.bicep' = if (customLocationId == '') {
  name: 'dbAzureDeploy'
  params: {
    location: location
    workspaceId: monitoring.outputs.workspaceId
    administratorLoginPassword: postgresAdminPassword
    dbServerName: dbServerName
    dbName: dbName
  }
}

module dbArc './webapi/dbArc.bicep' = if (customLocationId != '') {
  name: 'dbArcDeploy'
  params: {
    location: location
    customLocationId: customLocationId
    dataControllerId: dataControllerId
    subscriptionId: subscription().id
    resourceGroupName: resourceGroup().name
    namespace: 'appservice-ns' //Should be derived from customLocation
    dbName: substring(uniqueString(dbName),0,5) //Name length restrictions
    administratorLoginPassword: postgresAdminPassword
  }
}

module webApiAzure './webapi/webappAzure.bicep' = if (customLocationId == '') {
  name: 'webAppAzureDeploy'
  params: {
    location: location
    workspaceId: monitoring.outputs.workspaceId
    appSettingsPgHost: customLocationId == '' ? dbAzure.outputs.pgHost : dbArc.outputs.pgHost //The ternary operator is needed to ensure deployment dependencies are correct
    appSettingsPgUser: customLocationId == '' ? dbAzure.outputs.pgUser : dbArc.outputs.pgUser //The ternary operator is needed to ensure deployment dependencies are correct
    appSettingsPgDb: customLocationId == '' ? dbAzure.outputs.pgDb : dbArc.outputs.pgDb //The ternary operator is needed to ensure deployment dependencies are correct
    appSettingsNodeEnv: webapiNodeEnv
    appSettingsPgPassword: postgresAdminPassword
    appSettingsInsightsKey: monitoring.outputs.instrumentationKey
    webApiHostingPlanName: webApiHostingPlanName
    webApiName: webApiName
  }
}

module webApiArc './webapi/webappArc.bicep' = if (customLocationId != '') {
  name: 'webAppArcDeploy'
  params: {
    location: location
    kubeEnvironmentId: kubeEnvironmentId
    customLocationId: customLocationId
    workspaceId: monitoring.outputs.workspaceId
    appSettingsPgHost: customLocationId == '' ? dbAzure.outputs.pgHost : dbArc.outputs.pgHost //The ternary operator is needed to ensure deployment dependencies are correct
    appSettingsPgUser: customLocationId == '' ? dbAzure.outputs.pgUser : dbArc.outputs.pgUser //The ternary operator is needed to ensure deployment dependencies are correct
    appSettingsPgDb: customLocationId == '' ? dbAzure.outputs.pgDb : dbArc.outputs.pgDb //The ternary operator is needed to ensure deployment dependencies are correct
    appSettingsNodeEnv: webapiNodeEnv
    appSettingsPgPassword: postgresAdminPassword
    appSettingsInsightsKey: monitoring.outputs.instrumentationKey
    webApiHostingPlanName: webApiHostingPlanName
    webApiName: webApiName
  }
}

output webapiId string = customLocationId == '' ? webApiAzure.outputs.webApiId : webApiArc.outputs.webApiId
output postgresHost string = customLocationId == '' ? dbAzure.outputs.pgHost : dbArc.outputs.pgHost
output postgresHostExternal string = customLocationId == '' ? dbAzure.outputs.pgHost : dbArc.outputs.pgHostExternal
output postgresUser string = customLocationId == '' ? '${dbAzure.outputs.pgUser}@${dbAzure.outputs.pgHost}' : dbArc.outputs.pgUser
output postgresDb string = customLocationId == '' ? dbAzure.outputs.pgDb : dbArc.outputs.pgDb
