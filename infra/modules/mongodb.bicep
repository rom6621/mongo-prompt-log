@description('リソースのロケーション')
param location string = resourceGroup().location

@description('データベースアカウント名')
param databaseAccountName string = 'mongodb${uniqueString(resourceGroup().id)}'

@description('データベース名')
param databaseName string

@description('コレクション名')
param collectionName string

@description('MongoDBのバージョン')
param mongoServerVersion string = '4.2'

@description('MongoDBのデータベースアカウント')
resource databaseAccount 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' = {
  name: databaseAccountName
  location: location
  kind: 'MongoDB'
  properties: {
    enableFreeTier: true
    databaseAccountOfferType: 'Standard'
    consistencyPolicy: {
      defaultConsistencyLevel: 'Session'
    }
    locations: [
      {
        locationName: location
      }
    ]
    apiProperties: {
      serverVersion: mongoServerVersion
    }
  }
}

@description('MongoDBのデータベース')
resource database 'Microsoft.DocumentDB/databaseAccounts/mongodbDatabases@2024-05-15' = {
  parent: databaseAccount
  name: databaseName
  properties: {
    resource: {
      id: databaseName
    }
  }
}

@description('プロンプト履歴を格納するコレクション')
resource collection 'Microsoft.DocumentDB/databaseAccounts/mongodbDatabases/collections@2024-05-15' = {
  parent: database
  name: collectionName
  properties: {
    resource: {
      id: collectionName
    }
  }
}

output connectionString string = databaseAccount.listConnectionStrings().connectionStrings[0].connectionString
output databaseName string = database.name
output collectionName string = collection.name
