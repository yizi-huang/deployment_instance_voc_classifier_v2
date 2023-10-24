targetScope = 'resourceGroup' 

@description('Tags to assign to the resource.')
param tags object

@description('Name of the resource.')
param name string

@description('Location of the resource.')
param location string

@description('Number of days to retain logs.')
param retentionDays int

@description('Name of the Application Insights resource for the backend Web App')
param backendApplicationInsightsName string

@description('Email address of the distribution list used for sending alerts')
param emailDistributionListForAlerts string

// TODO evaluate what tier to use
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
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

resource backendAppInsights 'microsoft.insights/components@2020-02-02' = {
  name: backendApplicationInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    SamplingPercentage: 100
    RetentionInDays: 60
    DisableIpMasking: false
    WorkspaceResourceId: logAnalyticsWorkspace.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource notifyByEmailActionGroup 'microsoft.insights/actionGroups@2022-06-01' = {
  name: 'Notify by Email'
  location: 'Global'
  properties: {
    groupShortName: 'notifyemail'
    enabled: true
    emailReceivers: [
      {
        name: 'Email distribution list for UL Chatbot alerts'
        emailAddress: emailDistributionListForAlerts
      }
    ]
  }
}

output logAnalyticsWorkspaceId string = logAnalyticsWorkspace.id
output backendApplicationInsightsName string = backendAppInsights.name
output actionGroupId string = notifyByEmailActionGroup.id
