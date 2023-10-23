targetScope = 'resourceGroup'

@description('Tags to assign to the resource.')
param tags object 

@description('Name of the resource.')
param name string

@description('Location of the resource.')
param location string 

@description('Custom subdomain to be used for service endpoint, defaults to resource name.')
param customSubdomain string = name

@description('Pricing tier of the service.')
param sku string 

@description('Subnets to allow traffic from.')
param subnets array

@description('LogAnalytics workspace ID to save logs to.')
param logAnalyticsID string

@description('Whether to allow public network access')
param allowPublicAccess bool

param deployments array = []

var vnetRules = [for net in subnets: {id: net}]

resource OpenAI_voc_classifier_v2 'Microsoft.CognitiveServices/accounts@2022-03-01' = {
  name: name
  location: location
  kind: 'OpenAI_voc_classifier_v2'
  sku: {
    name: sku
  }
  tags: tags
  properties: {
    customSubDomainName: customSubdomain
    publicNetworkAccess: 'Enabled'
    networkAcls: allowPublicAccess == true ? { defaultAction: 'Allow' } : {
      defaultAction: 'Deny'
      virtualNetworkRules: vnetRules
      raiPolicy: {  
        customContentFilter: {  
          enabled: true  
          policyName: 'CustomContentFilter238' //will recreate similar content filter with new name for production purpose  
            }  
          }  
        }  
      }
}

resource diagnosticLogs 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
  name: '${name}-diagnostics'
  scope: OpenAI_voc_classifier_v2
  properties: {
    workspaceId: logAnalyticsID
    logs: [
      {
        categoryGroup: 'allLogs'
        enabled: true
      }
    ]
  }
}


@batchSize(1)
resource deployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = [for deployment in deployments: {
  parent: OpenAI_voc_classifier_v2
  name: deployment.name
  properties: {
    model: deployment.model
    raiPolicyName: contains(deployment, 'raiPolicyName') ? deployment.raiPolicyName : null
  }
  sku: {
    name: 'Standard'
    capacity: deployment.capacity
  }
}]

output openAIName string = OpenAI_voc_classifier_v2.name
output openAIKey1 string = OpenAI_voc_classifier_v2.listKeys().key1
output openAIKey2 string = OpenAI_voc_classifier_v2.listKeys().key2
