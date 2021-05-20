param location string
param workspaceId string
param administratorLogin string = 'postgres_admin'
@secure()
param administratorLoginPassword string
param dbServerName string
param dbName string

resource postgreSQLServer 'Microsoft.DBforPostgreSQL/servers@2017-12-01' = {
  name: dbServerName
  location: location
  properties: {
    createMode: 'Default'
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    sslEnforcement: 'Enabled'
  }

  resource db 'databases@2017-12-01' = {
    name: dbName
  }

  resource firewallRules 'firewallRules@2017-12-01' = {
    name: 'AllowAny'
    properties: {
      startIpAddress: '0.0.0.0'
      endIpAddress: '255.255.255.255'
    }
  }
}

resource dbDiagnostics 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  scope: postgreSQLServer
  name: 'logAnalytics-${dbName}'
  properties: {
    workspaceId: workspaceId
    logs: [
      {
        enabled: true
        category: 'PostgreSQLLogs'
      }
      {
        enabled: true
        category: 'QueryStoreRuntimeStatistics'
      }
      {
        enabled: true
        category: 'QueryStoreWaitStatistics'
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

output pgHost string = postgreSQLServer.properties.fullyQualifiedDomainName
output pgUser string = administratorLogin
output pgPassword string = administratorLoginPassword
output pgDb string = last(split(postgreSQLServer::db.name, '/'))
