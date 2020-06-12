# Define Azure DevOps and KeyVault variables 
$org = "https://dev.azure.com/JFAzDoOrg"
$project = "JFProject001"
$vaultName = "JFCoreKV"
$secretName = "AzDoPAT"

# Get and define authentication method
$azDoPAT = (Get-AzKeyVaultSecret -VaultName $vaultName -Name $secretName).SecretValueText
$BasicAuth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f '', $azDoPAT)))

$authHeader = @{
    Authorization = "Basic $BasicAuth"
}

# Create the variables used for the payload files.
$envPayload = get-content -Path ./payload-samples/env.json -Raw 
$svcConPayLoad = get-content -Path ./payload-samples/aks-svc-con.json -Raw 
$envSvcConLink = get-content -Path ./payload-samples/env-svc-con-link.json -Raw 

# Create the environment and save the output to the $env variable. 
$env = Invoke-RestMethod -Method POST `
    -Uri $org/$project/_apis/distributedtask/environments?api-version=5.0-preview.1 `
    -ContentType "application/json" `
    -Headers $authHeader `
    -body $envPayload

# Create the Service Connection and save the output to the $svcCon variable
$svcCon = Invoke-RestMethod -Method POST `
    -Uri $org/$project/_apis/serviceendpoint/endpoints?api-version=5.1-preview.2  `
    -ContentType "application/json" `
    -Headers $authHeader `
    -body $svcConPayLoad

# Define parameters for environmentId and svcConId
$envId = $env.id
$svcConId = $svcCon.id

# Update the $envSvcConLink to include the $svcConId
$envSvcConLinkPayload = $envSvcConLink.replace("svcConPlaceHolder", $svcConId)

# Create the link between the service connection and the environment.  Note the $envId variable in the URI
Invoke-RestMethod -Method POST `
    -Uri $org/$project/_apis/distributedtask/environments/$envId/providers/kubernetes?api-version=5.0-preview.1  `
    -ContentType "application/json" `
    -Headers $authHeader `
    -body $envSvcConLinkPayload