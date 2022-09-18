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
Script      : UploadDataToBlob.ps1
Author      : Krishna V
Version     : 1.0.0
Description : The script exports Data from AzResource resoruce into a Json document and that gets upload to Blob Storage.
#>


param (

    [String]$subscriptionId,
    [String]$storageAccountRG ,
    [String]$storageAccountName ,
    [String]$storageContainerName 
)

    #Replace these values accordingly 
    $subscriptionId = ""
    $storageAccountRG = ""
    $storageAccountName = ""
    $storageContainerName = "files"
    $region = ""

    Function date_time()
    {
         return (Get-Date -UFormat "%Y-%m-%d_%I-%M-%S_%p").tostring()
    }

    Function Connect-Azure($subscriptionId)
    {
 
        # Select right Azure Subscription
        #Select-AzSubscription -Subscription $subscriptionId
  
        # Connect to your Azure subscription
         Connect-AzAccount
    }

    Function Create-RG($storageAccountRG)
    {
        New-AzResourceGroup -Name $storageAccountRG -Location $region
    }

    Function Build-Storage ($storageContainerName , $storageAccountRG, $storageAccountName , $region)
    {
 
        # Capture reference to a Storage Account at creation
        $storageContext = New-AzStorageAccount -ResourceGroupName  $storageAccountRG -Name $storageAccountName -Location $region -SkuName Standard_GRS 

        # Retrieve the Context from the Storage Account
        $storageContext = $storageContext.Context

        New-AzStorageContainer -Name $storageContainerName   -Context $storageContext  -Permission Off

        Upload-toStorage -storageContainerName $storageContainerName -storageContext $storageContext
 
       
     }

    Function Upload-toStorage ( $storageContainerName,$storageContext )
    {
        $logfilename = "inputs/" + (date_time) + ".json"

        #This is sample - please change the location accordingly.
        # Ruunning the cmdlet and storing the output in json format. The idea is to show case  a source data.
        Get-AzResource | ConvertTo-Json | out-file C:\output.json
        #Uploading the output file into Blob Storage with propername.
        Set-AzStorageBlobContent -File "C:\output.json" `
          -Container $storageContainerName `
          -Blob $logfilename `
          -Context $storageContext `
          -StandardBlobTier Hot

    }
 

    if($subscriptionId -eq "") { throw "storageAccountRG is missing! Update the script and run again" }
    if($storageAccountRG -eq "")  { throw "storageAccountRG is missing! Update the script and run again" }
    if($storageAccountName -eq "")  { throw "storageAccountName is missing! Update the script and run again" }
    if($storageContainerName -eq "")  { throw "storageContainerName is missing! Update the script and run again" }
    if($region -eq "")  { throw "region is missing! Update the script and run again" }
    

    Connect-Azure -subscriptionId $subscriptionId
    Create-RG -storageAccountRG $storageAccountRG
    Build-Storage  -storageContainerName $storageContainerName -storageAccountRG $storageAccountRG -storageAccountName $storageAccountName -region $region 

