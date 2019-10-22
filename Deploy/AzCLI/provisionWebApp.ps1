# This IaC script provisions and configures a web app for tailwind traders
#
[CmdletBinding()]
param(
    [Parameter(Mandatory = $True)]
    [string]
    $servicePrincipal,

    [Parameter(Mandatory = $True)]
    [string]
    $servicePrincipalSecret,

    [Parameter(Mandatory = $True)]
    [string]
    $servicePrincipalTenantId,

    [Parameter(Mandatory = $True)]
    [string]
    $resourceGroupName,

    [Parameter(Mandatory = $True)]
    [string]
    $resourceGroupNameRegion,

    [Parameter(Mandatory = $True)]  
    [string]
    $webAppName,

    [Parameter(Mandatory = $True)]  
    [string]
    $appServiceRegion,

    [Parameter(Mandatory = $True)]  
    [string]
    $appServiceSKU,

    [Parameter(Mandatory = $True)]  
    [string]
    $apiUrl,

    [Parameter(Mandatory = $True)]  
    [string]
    $apiUrlShoppingCart
)


#region Login
# This logs in a service principal
#
Write-Output "Logging in to Azure with a service principal..."
az login `
    --service-principal `
    --username $servicePrincipal `
    --password $servicePrincipalSecret `
    --tenant $servicePrincipalTenantId
Write-Output "Done"
Write-Output ""
#endregion

#region Create Resource Group
# This creates the resource group used to house all of Mercury Health
#
Write-Output "Creating resource group $resourceGroupName in region $resourceGroupNameRegion..."
az group create `
    --name $resourceGroupName `
    --location $resourceGroupNameRegion
Write-Output "Done creating resource group"
Write-Output ""
#endregion

#region create app service
# create app service plan
#
Write-Output "creating app service plan..."
az appservice plan create `
    --name $("$webAppName" + "plan") `
    --resource-group $resourceGroupName `
    --location $appServiceRegion `
    --sku $appServiceSKU
Write-Output "done creating app service plan"
Write-Output ""

Write-Output "creating web app..."
az webapp create `
    --name $webAppName `
    --plan $("$webAppName" + "plan") `
    --resource-group $resourceGroupName
Write-Output "done creating web app"
Write-Output ""
#endregion

#region set endpoints
# Set api endpoint and api shopping cart endpoint
Write-Output "Setting api endpoint..."
az webapp config appsettings set `
    --name $webAppName `
    --resource-group $resourceGroupName `
    --settings ApiUrl=$apiUrl
Write-Output "Done setting api endpoint"
Write-Output ""


Write-Output "Setting api shopping cart endpoint..."
az webapp config appsettings set `
    --name $webAppName `
    --resource-group $resourceGroupName `
    --settings ApiUrlShoppingCart=$apiUrlShoppingCart
Write-Output "Done setting api shopping cart endpoint"
Write-Output ""
#endregion


#region create application insights for web app
# this creates an instance of appliction insight for node 1
#
Write-Output "creating application insight for web app..."
$appInsightCreateResponse=$(az resource create `
    --resource-group $resourceGroupName `
    --resource-type "Microsoft.Insights/components" `
    --name $($webAppName + "AppInsight") `
    --properties '{\"Application_Type\":\"web\"}') | ConvertFrom-Json
Write-Output "done creating app insight for node 1: $appInsightCreateResponse"
Write-Output ""

# # this gets the instrumentation key from the create response
# #
# Write-Output "getting instrumentation key from the create response..."
# $instrumentationKey = $appInsightCreateResponse.properties.InstrumentationKey
# Write-Output "done getting instrumentation key"
# Write-Output ""

# # this sets application insight to web app
# #
# Write-Output "setting and configuring application insight for webapp..."
# az webapp config appsettings set `
#     --resource-group $resourceGroupName `
#     --name $webAppName `
#     --slot-settings APPINSIGHTS_INSTRUMENTATIONKEY=$instrumentationKey `
#                     ApplicationInsightsAgent_EXTENSION_VERSION=~2 `
#                     XDT_MicrosoftApplicationInsights_Mode=recommended `
#                     APPINSIGHTS_PROFILERFEATURE_VERSION=1.0.0 `
#                     DiagnosticServices_EXTENSION_VERSION=~3 `
#                     APPINSIGHTS_SNAPSHOTFEATURE_VERSION=1.0.0 `
#                     SnapshotDebugger_EXTENSION_VERSION=~1 `
#                     InstrumentationEngine_EXTENSION_VERSION=~1 `
#                     XDT_MicrosoftApplicationInsights_BaseExtension=~1
# Write-Output "done setting and configuring application insight for web app"
# Write-Output ""
#endregion

#region Deploy Web App
# Deploy Web App
#
az webapp deployment source config-zip -g $resourceGroupName -n $webAppName --src .\Deploy\webapp.zip