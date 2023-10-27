targetScope = 'subscription' 

@description('Role definition object.')
param customUserRole object

resource customRoleDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' = {
  name: guid(subscription().id, string(customUserRole.actions), string(customUserRole.notActions), customUserRole.roleName)
  properties: {
    roleName: 'ail-${customUserRole.roleName}'
    description: customUserRole.roleDescription
    type: 'customRole'
    permissions: [
      {
        actions: customUserRole.actions
        notActions: customUserRole.notActions
        dataActions: customUserRole.dataActions
        notDataActions: customUserRole.notDataActions
      }
    ]
    assignableScopes: [
      subscription().id
    ]
  }
}

output customRoleDefinitionId string = customRoleDefinition.id
