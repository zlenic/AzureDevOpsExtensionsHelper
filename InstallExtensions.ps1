param(
    [Parameter(Mandatory=$true)]
    [String]$pat,
    
    [Parameter(Mandatory=$true)]
    [String]$orgName
    )

$orgUrl = "https://extmgmt.dev.azure.com/$orgName"
$queryString = "api-version=7.1-preview"

class Extension {
    [string] $extensionId
    [string] $publisherId
    [string] $version
}

$extensionSet = @(
    [Extension]@{extensionId='allure-test-reports';publisherId="ivang7";     version="1.1"}
    [Extension]@{extensionId='replacetokens';      publisherId="qetza";      version="4.4.0"}
    [Extension]@{extensionId='CreateWorkItem';     publisherId="mspremier";  version="1.17.0"}
)

# Create header using PAT
$token = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes(":$($pat)"))
$header = @{authorization = "Basic $token"}

foreach ($extensionMember in $extensionSet){
    try {
        $installedExtensionsUrl = "$orgUrl/_apis/extensionmanagement/installedextensions"+'?'+$queryString
        
        #Fetch installed extensions:
        $extensions = Invoke-RestMethod -Uri $installedExtensionsUrl -Method Get -ContentType "application/json" -Headers $header
        
        #Find out if current extension is already installed:
        $result = $extensions.value.Where({$_.extensionId -eq $extensionMember.extensionId});
        
        if ($result.Count -eq 0){
            # Install extension:
            $installExtensionUrl = "$orgUrl/_apis/extensionmanagement/installedextensionsbyname/"+$extensionMember.publisherId+"/" + $extensionMember.extensionId + "/" + $extensionMember.version +'?'+$queryString
            $extension = Invoke-RestMethod -Uri $installExtensionUrl -Method Post -Headers $header -ContentType "application/json"
            $extension
            Write-Host "INFO: Extension " $extensionMember.extensionId " installed."
        }else{
            Write-Host "INFO: Extension " $extensionMember.extensionId " was found to be already installed."
        }
        
      }catch{
        Write-Host "ERROR: Azure DevOps Extensions error durring installation of " + $extensionMember.extensionId
        Write-Host $_
      }
}
