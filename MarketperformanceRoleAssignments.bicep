targetScope = 'resourceGroup' 

@description('Users with their respective IDs from Azure Active Directory. More users can be added here, depending on requirements.')
param users array

@description('ID of the role definition to assign to users')
param customAideRoleDefinitionId string

@description('Name of the Form Recognizer resource to grant access to.')
param formRecognizerName string

@description('Name of the OpenAI resource to grant access to.')
param openAIName string


var assignmentDescription = 'AIDE DS users role assignment'

resource formRecognizer 'Microsoft.CognitiveServices/accounts@2022-12-01' existing = {
  name: formRecognizerName
  scope: resourceGroup()
}

resource openAI 'Microsoft.CognitiveServices/accounts@2022-03-01' existing = {
  name: openAIName
  scope: resourceGroup()
}

resource customFRAideRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principalId in users: {
  name: guid(subscription().id, principalId, customAideRoleDefinitionId, formRecognizerName)
  scope: formRecognizer
  properties: {
    roleDefinitionId: customAideRoleDefinitionId
    principalId: principalId
    principalType: 'User'
    description: assignmentDescription
  }
}]

resource customOpenAIAideRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [for principalId in users: {
  name: guid(subscription().id, principalId, customAideRoleDefinitionId, openAIName)
  scope: openAI
  properties: {
    roleDefinitionId: customAideRoleDefinitionId
    principalId: principalId
    principalType: 'User'
    description: assignmentDescription
  }
}]
