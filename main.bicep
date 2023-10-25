targetScope = 'subscription'  

@description('Environment name suffix for resources.')
@allowed([
  'prod'
  'staging'
  'qa'
  'dev'
])
param environment string = 'dev'

@description('GUID used to generate unique deployment name suffixes')
param deploymentNamesGuid string = newGuid()

// 3-character suffix to add some uniqueness to deployment names
var suffix = toLower(take(uniqueString(deploymentNamesGuid), 3))

//It will be updated once we have the right repo name
var tags  = {
  owner: 'AIL ML Engineering'
  purpose: 'Azure cognitive services used across projects: voc-classifier-v2'
  environment: environment
  CreatedBy: 'AIL.Provisioning.CognitiveServices/templates/main.bicep'
}

var defaultLocations = {
  dev: 'northeurope'
  qa: 'northeurope'
  staging: 'centralus'
  prod: 'centralus'
}

var shortRegionNames = {
  centralus: 'cus'
  northeurope: 'ne'
}

var location = defaultLocations[environment]


module variables 'variables.bicep' = {
  name: 'variables'
  scope: subscription()
  params: {
    shortLocation: shortRegionNames[location]
    environment: environment
  }
}

resource servicesResourceGroup 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: 'rg-ail-mp-voc-${environment}-${shortRegionNames[location]}'
  location: location
  tags: tags
}


module logAnalytics 'loganalytics.bicep' = {
  scope: servicesResourceGroup
  name: 'logAnalytics'
  params: {
    location: location
    name: variables.outputs.logs.workspaceName
    retentionDays: variables.outputs.logs.retentionDays
    tags: tags
  }
}

module openAI 'openAI.bicep' = {
  dependsOn: [
    logAnalytics
  ]
  name: 'openai_voc_classifier_v2'
  scope: servicesResourceGroup
  params: {
    location: variables.outputs.openai.location
    name: variables.outputs.openai.serviceName
    sku: variables.outputs.openai.sku
    subnets: variables.outputs.openai.allowedSubnets
    tags: tags
    logAnalyticsID: logAnalytics.outputs.logAnalyticsWorkspaceId
    allowPublicAccess: variables.outputs.openai.allowPublicAccess
    deployments: variables.outputs.openai.deployments
  }
}

module mpDsRoleDefinition 'roleDefinition.bicep' = {
  name: 'mpDsRoleDefinition'
  params: {
    customUserRole: variables.outputs.roles.mpds.role
  }
}

module mpRoleAssignments 'mpRoleAssignments.bicep' = {
  dependsOn: [
    openAI
    mpDsRoleDefinition  
  ]
  scope: servicesResourceGroup
  name: 'mpRoleAssignments'
  params: {
    customMpRoleDefinitionId: mpDsRoleDefinition.outputs.customRoleDefinitionId
    users: variables.outputs.roles.mpds.users
    openAIName: variables.outputs.openai.serviceName
  }
}

module monitoring 'monitoring.bicep' = {
  scope: servicesResourceGroup
  name: 'monitoring-${suffix}'
  params: {
    location: location
    name: variables.outputs.logs.workspaceName
    retentionDays: variables.outputs.logs.retentionDays
    tags: tags
    backendApplicationInsightsName: variables.outputs.logs.backendApplicationInsightsName
  }
}


output rg string = servicesResourceGroup.name
output openAI string = openAI.outputs.openAIName
