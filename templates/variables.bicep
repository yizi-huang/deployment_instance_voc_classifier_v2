targetScope = 'subscription' 

@description('Azure Region in which to deploy the resources.')
param shortLocation string

@description('Environment name suffix for resources.')
@allowed([
  'prod'
  'staging'
  'qa'
  'dev'
])
param environment string

resource k8sSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = {
  name: '${environment}-aksvnet-${shortLocation}/aks-subnet'
  scope: resourceGroup('${environment}-ds-api-ail-ul-com-${shortLocation}')
}

// resource qaSubnet 'Microsoft.Network/virtualNetworks/subnets@2022-11-01' existing = {
//   name: 'QAAgentPool-vnet/default'
//   scope: resourceGroup('53e77d8e-c18b-4040-846b-282ed557ee9a', 'QAAgentsPool-rg')
// }

var subSuffix = environment == 'dev' || environment == 'qa' ? 'dev' : 'prod'


// Yizi, Peter, Pedro
var mpDSUsers = [
  '6d85748d-7595-4337-bbb9-05b96ec8f63c'
  'bcf2ca40-ba34-46f2-aa4b-32b8e5936ef4'
  'fd8d1c97-fcc0-401f-a03d-025313275941'
]

var modelName = 'turbo'
var modelType = 'gpt-35-turbo-16k'

// AILabs Devs and QA may need to read keys and ping the services
var customMpDSUserRole = {
  roleName: 'custom-mp-voc-user-${subSuffix}'
  roleDescription: 'Custom role with access needed for AILabs devs to access cognitive services associated with MP'
  actions: [
    'Microsoft.CognitiveServices/*/read'
    'Microsoft.CognitiveServices/accounts/listkeys/action'
  ]
  notActions: []
  dataActions: []
  notDataActions: []
}

output roles object = {
  mpds: {
    users: environment == 'dev' ? mpDSUsers : []
    role: customMpDSUserRole
  }
}


output openai object = {
  serviceName: environment == 'dev' ? 'openai-ail-${environment}-weu' : 'openai-ail-${environment}-eus'
  sku: 'S0'
  allowedSubnets: [
    k8sSubnet.id
  ]
  location: environment == 'dev' ? 'westeurope' : 'eastus'
  allowPublicAccess: environment == 'dev' ? true : false
  modelConfig: {
    modelType:  modelType
    modelName: modelName
    temperature: 0
    topP: 1
    maxTokens: 1000
    stopSequence: ''
    systemMessage: 'You are an AI assistant that helps people find information.'
    apiVersion: '2023-06-01-preview'
    stream: true
  }
  deployments: [
    {
      name: modelType
      model: {
        format: 'OpenAI'
        name: modelName
        version: '0613'
      }
      capacity: 30
    }
  ]
}

output logs object = {
  workspaceName: 'logs-voc-ail-${environment}-${shortLocation}'
  retentionDays: 30
  backendApplicationInsightsName: 'appi-voc-ail-${environment}-${shortLocation}'
}
