param location string
param customLocationId string
param dataControllerId string
param subscriptionId string
param resourceGroupName string
param namespace string
param dbName string
param administratorLogin string = 'postgres'
@secure()
param administratorLoginPassword string
param engineVersion int = 12
param workers int = 0
param memoryRequest string = '0.25Gi'
param serviceType string = 'LoadBalancer'
param dataStorageClass string = ''
param logStorageClass string = ''
param backupStorageClass string = ''

resource postgreSQLServer 'Microsoft.AzureArcData/postgresInstances@2021-03-02-preview' = {
  name: dbName
  location: location
  extendedLocation: {
    name: customLocationId
    type: 'CustomLocation'
  }
  properties: {
    admin: administratorLogin
    basicLoginInformation: {
      username: administratorLogin
      password: administratorLoginPassword
    }
    k8sRaw: {
      kind: 'postgresql'
      spec: {
        engine: {
          version: engineVersion
        }
        scale: {
          workers: workers
        }
        scheduling: {
          default: {
            resources: {
              requests: {
                memory: memoryRequest
              }
            }
          }
        }
        services: {
          primary: {
            type: serviceType
          }
        }
        storage: {
          data: {
            volumes: [
              {
                className: dataStorageClass
                size: '10Gi'
              }
            ]
          }
          logs: {
            volumes: [
              {
                className: logStorageClass
                size: '10Gi'
              }
            ]
          }
          backups: {
            volumes: [
              {
                className: backupStorageClass
                size: '10Gi'
              }
            ]
          }
        }
        settings: {
          azure: {
            subscriptionId: subscriptionId
            resourceGroupName: resourceGroupName
            location: location
          }
        }
      }
      metadata: {
        namespace: namespace
      }
    }
    dataControllerId: dataControllerId
  }
}

output pgHost string = '${dbName}-external-svc'
output pgHostExternal string = first(split(postgreSQLServer.properties.k8sRaw.status.primaryEndpoint,':'))
output pgUser string = administratorLogin
output pgPassword string = administratorLoginPassword
output pgDb string = 'postgres'
