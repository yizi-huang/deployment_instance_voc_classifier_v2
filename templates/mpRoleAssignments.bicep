targetScope = 'resourceGroup' 

@description('Users with their respective IDs from Azure Active Directory. More users can be added here, depending on requirements.')
param users array

@description('ID of the role definition to assign to users')
param customMpRoleDefinitionId string

@description('Name of the OpenAI resource to grant access to.')
param openAIName string

var assignmentDescription = 'MP DS users role assignment'

resource openAI 'Microsoft.CognitiveServices/accounts@2022-03-01' existing = {
  name: openAIName
  scope: resourceGroup()
}

resource customOpenAIMpRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principalId in users: {
  name: guid(subscription().id, principalId, customMpRoleDefinitionId, openAIName)
  scope: openAI
  properties: {
    roleDefinitionId: customMpRoleDefinitionId
    principalId: principalId
    principalType: 'User'
    description: assignmentDescription
  }
}]
