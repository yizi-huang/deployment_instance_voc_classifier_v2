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

// QA pool IP
var whitelistIPs = ['20.82.193.222']

// Amy Forando(Digital Software Engineering), Eric Terlep, 
// Michael Nyhan(Senior LSM Operations Engineer), Nick Fenlason
var apimUsers = [
  'b041ef89-bbdd-44f3-aaec-2fa3323e30aa'
  '51fea898-a437-40d5-823a-2a08bd7d090f'
  '066ca5f9-1c8a-42e3-a412-28af94956981'
  'e1c4e936-e0c3-4073-a80d-9cc008abccfd'
]

// APIM devs need to be able to configure inbound network traffic on Form Recognizer, and read its keys from the resource itself (now) or key vault (future)
var customApimUserRole = {
    roleName: 'custom-apim-cognitive-user-${subSuffix}'
    roleDescription: 'Custom role with access needed for APIM developers to configure AILabs resources'
    actions: [
      'Microsoft.CognitiveServices/*'
    ]
    notActions: []
    dataActions: [
      'Microsoft.KeyVault/vaults/secrets/getSecret/action'
      'Microsoft.KeyVault/vaults/secrets/readMetadata/action'
    ]
    notDataActions: []
}

// Yizi, Peter, Pedro, Liji, Anabela
var aideDSUsers = [
  '6d85748d-7595-4337-bbb9-05b96ec8f63c'
  'bcf2ca40-ba34-46f2-aa4b-32b8e5936ef4'
  'fd8d1c97-fcc0-401f-a03d-025313275941'
  '6e683842-d65a-4679-9825-9b36a1d0b315'
  'b8a8a5d5-ba8d-4396-86b9-2b3ea7f93323'
]

// AILabs Devs and QA may need to read keys and ping the services
var customAideDSUserRole = {
  roleName: 'custom-aide-cognitive-user-${subSuffix}'
  roleDescription: 'Custom role with access needed for AILabs devs to access cognitive services associated with AIDE'
  actions: [
    'Microsoft.CognitiveServices/*/read'
    'Microsoft.CognitiveServices/accounts/listkeys/action'
  ]
  notActions: []
  dataActions: []
  notDataActions: []
}

output roles object = {
  apim: {
    users: environment == 'dev' ? [] : apimUsers
    role: customApimUserRole
  }
  aideds: {
    users: environment == 'dev' ? aideDSUsers : []
    role: customAideDSUserRole
  }
}

output formrec object = {
  serviceName: 'formrec-ail-${environment}-${shortLocation}'
  sku: 'S0'
  allowedSubnets: [
  ]
  ips: whitelistIPs
  allowPublicAccess: environment == 'dev' ? true : false
}

output compvis object = {
  serviceName: 'compvis-ail-${environment}-${shortLocation}'
  sku: environment == 'dev' ? 'F0' : 'S1'
  allowedSubnets: [
    k8sSubnet.id
  ]
}

output openai object = {
  serviceName: environment == 'dev' ? 'openai-ail-${environment}-weu' : 'openai-ail-${environment}-eus'
  sku: 'S0'
  allowedSubnets: [
    k8sSubnet.id
  ]
  location: environment == 'dev' ? 'westeurope' : 'eastus'  // openAI currenly unavailable in our default locations
  exemptionName: 'openai-location-exemption'
  allowPublicAccess: environment == 'dev' ? true : false
}

output logs object = {
  workspaceName: 'logs-cogn-ail-${environment}-${shortLocation}'
  retentionDays: 30
}

output keyvault object = {
  vaultName: 'kv-cogn-ail-${environment}-${shortLocation}'
  enableSoftDelete: environment == 'prod' ? true : false
}
