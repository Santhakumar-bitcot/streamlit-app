param appName string = 'streamlit-on-azure'
param location string = resourceGroup().location
param skuName string = 'B1'
param acrName string = '${replace(appName, '-', '')}acr'
param acrResourceGroup string = resourceGroup().name
param containerImageName string = 'myapp'
param containerImageTag string = 'latest'

resource appServicePlan 'Microsoft.Web/serverfarms@2022-03-01' = {
  name: '${appName}-plan'
  location: location
  sku: {
    name: skuName
    tier: 'Basic'
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
    name: acrName
    location: location
    sku: {
      name: 'Basic'
    }
    properties: {
      adminUserEnabled: false
    }
  }
  

resource webApp 'Microsoft.Web/sites@2022-03-01' = {
  name: appName
  location: location
  kind: 'app,linux,container'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    siteConfig: {
      linuxFxVersion: 'DOCKER|${acr.properties.loginServer}/${containerImageName}:${containerImageTag}'
      acrUseManagedIdentityCreds: true
    }
    httpsOnly: true
  }
}


// If ACR is in the same resource group, we can assign the role directly
resource sameRGAcrPullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (acrResourceGroup == resourceGroup().name) {
  name: guid(resourceGroup().id, webApp.id, 'acrpull')
  scope: acr
  properties: {
    principalId: webApp.identity.principalId
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d') // AcrPull role ID
    principalType: 'ServicePrincipal'
  }
}

