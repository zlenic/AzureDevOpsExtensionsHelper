param(
    [Parameter(Mandatory=$true)]
    [String]$pat,
    [Parameter(Mandatory=$true)]
    [String]$orgName,
    [Parameter(Mandatory=$true)]
    [String[]]$extensionNames=@("Create Work Item","Replace Tokens")
    )

$orgUrl = "https://extmgmt.dev.azure.com/$orgName"
$queryString = "api-version=7.1-preview"

# Create header using PAT
$token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($pat)"))
$header = @{authorization = "Basic $token"}

try{
    $installedExtensionsUrl = "$orgUrl/_apis/extensionmanagement/installedextensions"+'?'+$queryString
    #Fetch installed extensions:
    $extensions = Invoke-RestMethod -Uri $installedExtensionsUrl -Method Get -ContentType "application/json" -Headers $header
    #Discover target extensions:
    $results = $extensions.value | Where-Object {$_.extensionName -in $extensionNames}
}catch{
    Write-Host "ERROR: Azure DevOps Extensions error durring REST API invocation"
    Write-Host $_
}

#Display results:
if ($results.Count -eq 0){
    Write-Host "INFO: None of the extensions were found within installed extensions on $orgUrl"
    Exit 0
}elseif ($results.Count -eq $extensionNames.Count) {
    Write-Host "INFO: All extensions were discovered : "
} else {
    Write-Host "INFO: Some of extensions were discovered : "
}

$results | Format-Table -GroupBy BasePriority -Wrap -Property extensionId, publisherId, version
