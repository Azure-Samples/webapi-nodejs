param location string
param logAnalyticsName string
param appInsightsName string

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  location: location
  name: logAnalyticsName
}

resource appInsights 'Microsoft.Insights/components@2020-02-02-preview' = {
  location: location
  name: appInsightsName
  kind: 'web'
  properties: {
    Application_Type: 'web'
    WorkspaceResourceId: logAnalytics.id
  }
}

output instrumentationKey string = appInsights.properties.InstrumentationKey
output workspaceId string = appInsights.properties.WorkspaceResourceId
