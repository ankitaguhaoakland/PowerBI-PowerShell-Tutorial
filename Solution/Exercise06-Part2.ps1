Write-Host

Connect-PowerBIServiceAccount | Out-Null

$workspaceName = "Dev Camp Labs"

$workspace = Get-PowerBIWorkspace -Name $newWorkspaceName

$pbixFilePath = "$PSScriptRoot\SalesByState.pbix"

$importName = "Sales Report for California"

$import = New-PowerBIReport -Path $pbixFilePath -WorkspaceId $workspace.Id `
                            -Name $importName -ConflictAction CreateOrOverwrite

# get object for new dataset
$dataset = Get-PowerBIDataset -WorkspaceId $workspace.Id | Where-Object Name -eq $import.Name

$workspaceId = $workspace.Id
$datasetId = $dataset.Id

$datasources = Get-PowerBIDatasource -WorkspaceId $workspaceId -DatasetId $datasetId

foreach($datasource in $datasources) {
  
  $gatewayId = $datasource.gatewayId
  $datasourceId = $datasource.datasourceId
  $datasourePatchUrl = "gateways/$gatewayId/datasources/$datasourceId"

  Write-Host "Patching credentials for $datasourceId"

  # add credentials for SQL datasource
  $sqlUserName = "CptStudent"
  $sqlUserPassword = "pass@word1"
  
  # create HTTP request body to patch datasource credentials
  $userNameJson = "{""name"":""username"",""value"":""$sqlUserName""}"
  $passwordJson = "{""name"":""password"",""value"":""$sqlUserPassword""}"

  $patchBody = @{
    "credentialDetails" = @{
      "credentials" = "{""credentialData"":[ $userNameJson, $passwordJson ]}"
      "credentialType" = "Basic"
      "encryptedConnection" =  "NotEncrypted"
      "encryptionAlgorithm" = "None"
      "privacyLevel" = "Organizational"
    }
  }

  # convert body contents to JSON
  $patchBodyJson = ConvertTo-Json -InputObject $patchBody -Depth 6 -Compress

  # execute PATCH operation to set datasource credentials
  Invoke-PowerBIRestMethod -Method Patch -Url $datasourePatchUrl -Body $patchBodyJson
}
