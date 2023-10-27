targetScope = 'resourceGroup' 

@description('Tags to assign to the resource.')  
param tags object

@description('Name of the resource.')
param name string 

@description('Location of the resource.')
param location string   

@description('Number of days to retain logs.')
param retentionDays int 

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2020-10-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    retentionInDays: retentionDays
    sku: {
      name: 'Standalone'
    }
  }
}

resource logAnalyticsWorkspaceLock 'Microsoft.Authorization/locks@2017-04-01' = {
  name: '${name}-lock'
  scope: logAnalyticsWorkspace
  properties: {
    level: 'CanNotDelete'
    notes: 'Should not delete these logs.'
  }
}

output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
