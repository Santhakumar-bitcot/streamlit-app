param appName string = 'streamlit-on-azure'
param location string = resourceGroup().location
param skuName string = 'B1'
param acrName string = '${replace(appName, '-', '')}acr'
param acrResourceGroup string = resourceGroup().name
@secure()
param gitHubPAT string // GitHub Personal Access Token (for private repo access)

param dockerFilePath string = 'Dockerfile'
// param contextPath string = '.'


param imageName string = 'streamlit-azure-app'
param imageTag string = 'latestnew'
param repoUrl string = 'https://github.com/Santhakumar-bitcot/streamlit-app'
param repoBranch string = 'main'

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
      linuxFxVersion: 'DOCKER|${acr.properties.loginServer}/${imageName}:${imageTag}'
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

resource acrTask 'Microsoft.ContainerRegistry/registries/tasks@2025-03-01-preview' = {
    name: 'build-${imageName}-task'
    parent: acr
    location: location
    properties: {
      status: 'Enabled'
      platform: {
        os: 'Linux'
        architecture: 'amd64'
      }
      agentConfiguration: {
        cpu: 2
      }
      step: {
        type: 'Docker'
        contextPath: repoUrl
        dockerFilePath: dockerFilePath
        imageNames: [
          '${imageName}:${imageTag}'
        ]
      }
      credentials: {
        sourceRegistry: null
        customRegistries: null
        sourceRepository: {
          loginMode: 'Token'
          token: gitHubPAT
        }
      }
      trigger: {
        baseImageTrigger: {
          name: 'baseImageUpdateTrigger'
          baseImageTriggerType: 'Runtime'
          status: 'Enabled'
        }
        sourceTriggers: [
          {
            name: 'GitHubPushTrigger'
            status: 'Enabled'
            sourceTriggerEvents: [
              'commit'
            ]
            sourceRepository: {
              branch: repoBranch
              repositoryUrl: repoUrl
              sourceControlType: 'Github'
              sourceControlAuthProperties: {
                tokenType: 'PAT'
                token: gitHubPAT
              }
            }
          }
        ]
      }
      isSystemTask: true
    }
  }
