@description('Name of the exemption.')
param exemptionName string

@description('Policy assignment to exempt from.')
param exemptionAssignment string

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2022-06-01' existing = {
  name: exemptionAssignment
  scope: subscription()
}

resource exemption 'Microsoft.Authorization/policyExemptions@2022-07-01-preview' = {
  name: exemptionName
  dependsOn: [
    policyAssignment
  ]
  properties: {
    assignmentScopeValidation: 'Default'
    exemptionCategory: 'Waiver'
    policyAssignmentId: policyAssignment.id
  }
}
