@description('リソースのロケーション')
param location string = resourceGroup().location

@description('Functionのデプロイ名')
param deployName string = 'fnapp${uniqueString(resourceGroup().id)}'
var hostingPlanName = deployName
var functionAppName = deployName

@description('ストレージアカウント名')
param storageAccountName string = '${uniqueString(resourceGroup().id)}azfunctions'

@description('ストレージアカウントのタイプ')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
])
param storageAccountType string = 'Standard_LRS'

@description('MongoDBの接続文字列')
param mongoConnectionString string

@description('MongoDBのデータベース名')
param mongoDatabaseName string

@description('MongoDBのコレクション名')
param mongoCollectionName string

@description('Functionsで使用するストレージアカウント')
resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {
    name: storageAccountType
  }
}

@description('FunctionsをデプロイするAppServiceプラン')
resource hostingPlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: 'Y1'
    tier: 'Dynamic'
    capacity: 0
  }
  properties: {
    reserved: true
  }
}

@description('MongoDBに格納を行うFunction')
resource azureFunction 'Microsoft.Web/sites@2022-09-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  properties: {
    reserved: true
    serverFarmId: hostingPlan.id
    siteConfig: {
      linuxFxVersion: 'Python|3.10'
      appSettings: [
        // キュー、トリガー、バインディングなどのFunctionのインフラに関するデータを保存するためのストレージ
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        // コードとコンテンツを保存するためのストレージ
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        // 関数アプリのコードと構成ファイルを保存するために使用するファイル共有の名前
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: toLower(functionAppName)
        }
        // Functionsのランタイムのバージョン
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'python'
        }
        {
          name: 'COSMOS_CONNECTION_STRING'
          value: mongoConnectionString
        }
        {
          name: 'MONGO_DB_NAME'
          value: mongoDatabaseName
        }
        {
          name: 'MONGO_COLLECTION_NAME'
          value: mongoCollectionName
        }
      ]
    }
  }
}

output functionName string = azureFunction.name
