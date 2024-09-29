@description('API発行者名')
param publisherName string

@description('API発行者のメールアドレス')
param publisherEmail string

@description('Azure OpenAI ServiceのAPIエンドポイント')
param aoaiUrl string

@description('OpenAPIのURL')
param openApiUrl string

module mongodb 'modules/mongodb.bicep' = {
  name: 'mongodb'
  params: {
    databaseName: 'api'
    collectionName: 'prompt_log'
  }
}

module function 'modules/function.bicep' = {
  name: 'function'
  params: {
    mongoConnectionString: mongodb.outputs.connectionString
    mongoDatabaseName: mongodb.outputs.databaseName
    mongoCollectionName: mongodb.outputs.collectionName
  }
}

module apiManagement 'modules/apiManagement.bicep' = {
  name: 'apiManagement'
  params: {
    publisherName: publisherName
    publisherEmail: publisherEmail
    functionName: function.outputs.functionName
    serviceUrl: aoaiUrl
    openApiUrl: openApiUrl
  }
}
