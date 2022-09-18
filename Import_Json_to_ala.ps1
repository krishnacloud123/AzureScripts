<#   
      The MIT License (MIT)
      
      Copyright (c) 2015 Microsoft Corporation
      
      Permission is hereby granted, free of charge, to any person obtaining a copy
      of this software and associated documentation files (the "Software"), to deal
      in the Software without restriction, including without limitation the rights
      to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
      copies of the Software, and to permit persons to whom the Software is
      furnished to do so, subject to the following conditions:
      
      The above copyright notice and this permission notice shall be included in all
      copies or substantial portions of the Software.
      
      THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
      IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
      FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
      AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
      LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
      OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
      SOFTWARE.
#>



<#
      Script      : Import_Json_to_ala.ps1
      Author      : Krishna V
      Version     : 1.0.0
      Description : The script will import Json file into Azure Log analytics into a customer-specified Log Analytics table.
                  : Please note this is a sample code and it will only work for a single file.
#>

{
       param (
     # Log Analytics table where the data is written to
       [string]$LogAnalyticsTableName ,
       [String]$subscriptionId

       )

}


#--------------------------------------------------------------   
#Step 0 : Intital setup 
#--------------------------------------------------------------- 
#subscription - Replace with your own.
$subscriptionId = "38e210c9-f725-420d-a307-5a739f45f830"
# Log Analytics table where the data is written to
$LogAnalyticsTableName = "AzureResourceTableV4"
# your Log Analytics workspace ID
$LogAnalyticsWorkspaceId = "d7936737-b7f9-4e35-939e-cbcd2a00fccf"

# Use either the primary or the secondary Connected Sources client authentication key   
$LogAnalyticsPrimaryKey = "rXjBssgozWg/QGvpijDkMCLYGxxO5WZhMeiGJ118NMRuxHK7XovP7CoqicQ47rzcEiS6Ulsl8v7dTT1evlp1NQ==" 


# Replace  resourceGroup , storageAccountName , containerName with values from your enviornment.
$resourceGroup = "demo-foradxala-r286"
$storageAccountName = "newstorag222e"
 
# following are sample locations
$downloadPath="\Work\Quest\ScriptforAutomation\WorkingCode\output\"
$downloadLocation="\Work\Quest\ScriptforAutomation\WorkingCode\output\"
#jsonpath - for testing purpose the value is harded coded. 
$jsonpath = "C:\Work\Quest\ScriptforAutomation\WorkingCode\output\files\inputs\2022-09-18_12-29-15_AM.json"




if($LogAnalyticsWorkspaceId -eq "") { throw "Log Analytics workspace Id is missing! Update the script and run again" }
if($LogAnalyticsPrimaryKey -eq "")  { throw "Log Analytics primary key is missing! Update the script and run again" }



Function Extract_blob()
{
 
    # ---------------------------------------------------------------   
    #    Name           : Extract_blob
    #    Value          : This extract files from theContainers in the Blob Storage into exact directly structure.
    #                     Do note the purpose of this script is to download the files to a folder location. Once the file is download - copy the actual location of the file to $jsonpath variabel.
    # ---------------------------------------------------------------

    $storageAccount = Get-AzStorageAccount   -ResourceGroupName $resourceGroup    -Name $storageAccountName 
    $ctx = $storageAccount.Context 

    $storageAcc=Get-AzStorageAccount -ResourceGroupName  $resourceGroup  -Name $storageAccountName 
    
    ## Get the storage account context

    $ctx=$storageAcc.Context

    ## Get all the containers

    $containers=Get-AzStorageContainer  -Context $ctx 
    
        
    foreach($container in $containers)

    {        

        ## check if folder exists

        $folderPath=$downloadPath+"\"+$container.Name

        $destination=$downloadLocation+"\"+$container.Name

        $folderExists=Test-Path -Path $folderPath

        if($folderExists)

        {

            Write-Host -ForegroundColor Magenta $container.Name "- folder exists"

            ## Get the blob contents from the container

            $blobContents=Get-AzStorageBlob -Container $container.Name  -Context $ctx

            foreach($blobContent in $blobContents)

            {

                ## Download the blob contentFor

                Get-AzStorageBlobContent -Container $container.Name  -Context $ctx -Blob $blobContent.Name -Destination $destination -Force

            }

        }

        else

        {        

            Write-Host -ForegroundColor Magenta $container.Name "- folder does not exist"

            ## Create the new folder

            New-Item -ItemType Directory -Path $folderPath

            ## Get the blob contents from the container

            $blobContents=Get-AzStorageBlob -Container $container.Name  -Context $ctx

            foreach($blobContent in $blobContents)

            {

                ## Download the blob content

                Get-AzStorageBlobContent -Container $container.Name  -Context $ctx -Blob $blobContent.Name -Destination $destination -Force

            }

        }

    }   
  
}


Function Build-Signature ($customerId, $sharedKey, $date, $contentLength, $method, $contentType, $resource) {
    # ---------------------------------------------------------------   
    #    Name           : Build-Signature
    #    Value          : Creates the authorization signature used in the REST API call to Log Analytics
    # ---------------------------------------------------------------

    $xHeaders = "x-ms-date:" + $date
    $stringToHash = $method + "`n" + $contentLength + "`n" + $contentType + "`n" + $xHeaders + "`n" + $resource

    $bytesToHash = [Text.Encoding]::UTF8.GetBytes($stringToHash)
    $keyBytes = [Convert]::FromBase64String($sharedKey)

    $sha256 = New-Object System.Security.Cryptography.HMACSHA256
    $sha256.Key = $keyBytes
    $calculatedHash = $sha256.ComputeHash($bytesToHash)
    $encodedHash = [Convert]::ToBase64String($calculatedHash)
    $authorization = 'SharedKey {0}:{1}' -f $customerId,$encodedHash
    return $authorization
}

Function Post-LogAnalyticsData($body, $LogAnalyticsTableName) {
    # ---------------------------------------------------------------   
    #    Name           : Post-LogAnalyticsData
    #    Value          : Writes the data to Log Analytics using a REST API
    #    Input          : 1) PSObject with the data
    #                     2) Table name in Log Analytics
    #    Return         : None
    # ---------------------------------------------------------------
    
    #Step 0: sanity checks
    if($body -isnot [array]) {return}
    if($body.Count -eq 0) {return}

    #Step 1: convert the PSObject to JSON
    $bodyJson = $body | ConvertTo-Json
    $bodyJson

    #Step 2: get the UTF8 bytestream for the JSON
    $bodyJsonUTF8 = ([System.Text.Encoding]::UTF8.GetBytes($bodyJson))

    #Step 3: build the signature        
    $method = "POST"
    $contentType = "application/json"
    $resource = "/api/logs"
    $rfc1123date = [DateTime]::UtcNow.ToString("r")
    $contentLength = $bodyJsonUTF8.Length    
    $signature = Build-Signature -customerId $LogAnalyticsWorkspaceId -sharedKey $LogAnalyticsPrimaryKey -date $rfc1123date -contentLength $contentLength -method $method -contentType $contentType -resource $resource
    
    #Step 4: create the header
    $headers = @{
        "Authorization" = $signature;
        "Log-Type" = $LogAnalyticsTableName;
        "x-ms-date" = $rfc1123date;
        #"time-generated-field" = $TimeStampField;
    };

    #Step 5: REST API call
    $uri = 'https://' + $LogAnalyticsWorkspaceId + ".ods.opinsights.azure.com" + $resource + "?api-version=2016-04-01"
    $response = Invoke-WebRequest -Uri $uri -Method Post -Headers $headers -ContentType $contentType -Body $bodyJsonUTF8 -UseBasicParsing
    #$bodyJsonUTF8
    $response

    if ($Response.StatusCode -eq 200) {   
        $rows = $body.Count
        Write-Information -MessageData "   $rows rows written to Log Analytics workspace $uri" -InformationAction Continue
    }

}


Function Import-DatatoALA() {
    # ---------------------------------------------------------------   
    #    Name           : Import-DatatoALA
    #    Desc           : Extracts data from file thats holds the Json Data into Array and then lodads it into Log analytics workspace tables for reporting purposes.
    #    Return         : None
    # ---------------------------------------------------------------
    
    
        #Stored Json document will be extracted and processed.
        #do note $jsonpath need to be constrcuted . Currently its hardcoded.
        $importedJsonData = get-content -path $jsonpath | convertfrom-json
          
        # Status update
        $recordsCount = $importedJsonData.Count
        Write-Information -MessageData "   $recordsCount rows returned by Importing Json" -InformationAction Continue

        # If there is no data, skip
        if ($recordsCount.Count -eq 0) { continue; }

        # Else format for Log Analytics
        $log_analytics_array = @()            
        foreach($i in $importedJsonData) {
            $newitem = [PSCustomObject]@{    
                Location              = $i.Location
                ResourceGroupName     = $i.ResourceGroupName
                SubscriptionId        = $i.SubscriptionId
            }
            $log_analytics_array += $newitem

        }

        # Push data to Log Analytics
        Post-LogAnalyticsData -LogAnalyticsTableName $LogAnalyticsTableName -body $log_analytics_array
    }

    Function Connect-Azure($subscriptionId)
    {
 
        # Select right Azure Subscription
        #Select-AzSubscription -Subscription $subscriptionId
  
        # Connect to your Azure subscription
         Connect-AzAccount
    }

#Main flow beings
  Connect-Azure -subscriptionId $subscriptionId
  Extract_blob
  Import-DatatoALA
  Build-Signature 

    
