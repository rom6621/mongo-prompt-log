@description('リソースのロケーション')
param location string = resourceGroup().location

@description('API Managementサービス名')
param serviceName string = 'apimservice${uniqueString(resourceGroup().id)}'

@description('API名')
param apiName string = 'api${uniqueString(resourceGroup().id)}'

@description('発行者名')
param publisherName string

@description('発行者のメールアドレス')
param publisherEmail string

@description('バックエンドサービスのURL')
param serviceUrl string

@description('OpenAPIのURL')
param openApiUrl string

@description('プロンプトの格納を行うFunction名')
param functionName string

@description('API Managementサービス')
resource apiManagementService 'Microsoft.ApiManagement/service@2023-09-01-preview' = {
  name: serviceName
  location: location
  sku:{
    capacity: 0
    name: 'Consumption'
  }
  properties:{
    publisherName: publisherName
    publisherEmail: publisherEmail
  }
}

resource apiManagementApi 'Microsoft.ApiManagement/service/apis@2023-09-01-preview' = {
  name: apiName
  parent: apiManagementService
  properties: {
    displayName: apiName
    path: toLower(apiName)
    subscriptionRequired: true
    subscriptionKeyParameterNames: {
      header: 'api-key'
      query: 'api-key'
    }
    protocols: ['https']
    serviceUrl: serviceUrl
    format: 'openapi-link'
    value: openApiUrl
  }
}

var policyXml = replace(
  loadTextContent('policies.xml'),
  '{{functionUrl}}',
  'https://${functionName}.azurewebsites.net/api/prompt-log'
)

resource apiManagementApiPolicy 'Microsoft.ApiManagement/service/apis/policies@2023-09-01-preview' = {
  name: 'policy'
  parent: apiManagementApi
  properties: {
    format: 'rawxml'
    value: policyXml
  }
}

