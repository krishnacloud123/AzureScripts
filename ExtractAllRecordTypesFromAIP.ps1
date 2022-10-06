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
Script      : ExtractAllRecordTypesFromAIP.PS1
Author      : Krishna V
Version     : 1.0.0
Description : The script exports data from  Search-UnifiedAuditLog to csv file for all the events and also publishes total time for the query to extract the data.
#>

$sessionID = [Guid]::NewGuid().ToString() + "_" +  "ExtractLogs" + (Get-Date).ToString("yyyyMMddHHmmssfff")
[DateTime]$start = [DateTime]::UtcNow.Adddays(-21)
[DateTime]$end = [DateTime]::UtcNow
$resultSize = 5000
 
$VerbosePreference = "SilentlyContinue"

#import exchange online management module
Import-Module ExchangeOnlineManagement

#connect to exchangeonline
Connect-ExchangeOnline
 
# The same script can be extened to include other records 
$record = "ExchangeAdmin","ExchangeItem","ExchangeItemGroup","SharePoint","SyntheticProbe","SharePointFileOperation","OneDrive","AzureActiveDirectory","AzureActiveDirectoryAccountLogon","DataCenterSecurityCmdlet","ComplianceDLPSharePoint","Sway","ComplianceDLPExchange","SharePointSharingOperation","AzureActiveDirectoryStsLogon","SkypeForBusinessPSTNUsage","SkypeForBusinessUsersBlocked","SecurityComplianceCenterEOPCmdlet","ExchangeAggregatedOperation","PowerBIAudit","CRM","Yammer","SkypeForBusinessCmdlets","Discovery","MicrosoftTeams","ThreatIntelligence","MailSubmission","MicrosoftFlow","AeD","MicrosoftStream","ComplianceDLPSharePointClassification","ThreatFinder","Project","SharePointListOperation","SharePointCommentOperation","DataGovernance","Kaizala","SecurityComplianceAlerts","ThreatIntelligenceUrl","SecurityComplianceInsights","MIPLabel","WorkplaceAnalytics","PowerAppsApp","PowerAppsPlan","ThreatIntelligenceAtpContent","LabelContentExplorer","TeamsHealthcare","ExchangeItemAggregated","HygieneEvent","DataInsightsRestApiAudit","InformationBarrierPolicyApplication","SharePointListItemOperation","SharePointContentTypeOperation","SharePointFieldOperation","MicrosoftTeamsAdmin","HRSignal
","MicrosoftTeamsDevice","MicrosoftTeamsAnalytics","InformationWorkerProtection","Campaign","DLPEndpoint","AirInvestigation","Quarantine","MicrosoftForms","ApplicationAudit","ComplianceSupervisionExchange","CustomerKeyServiceEncryption","OfficeNative","MipAutoLabelSharePointItem","MipAutoLabelSharePointPolicyLocation","MicrosoftTeamsShifts","MipAutoLabelExchangeItem","CortanaBriefing","Search","WDATPAlerts","MDATPAudit"
	


ForEach ($record in $record)
{
    Write-Host "Processing " $record
    $auditLogSearchResults = Search-UnifiedAuditLog -StartDate $start -EndDate $end -RecordType $record -SessionId $sessionID -SessionCommand ReturnLargeSet -ResultSize $resultSize | ConvertTo-Json | out-file C:\Work\Quest\ScriptforAutomation\WorkingCode\output\output.json
 }
 # if you want to understand how long the query was running - you can run the following script.

 Measure-Command { [array]$Records = Search-UnifiedAuditlog -Operations ComplianceSettingChanged -StartDate $start -EndDate $end -Formatted -ResultSize 5000 }



 
