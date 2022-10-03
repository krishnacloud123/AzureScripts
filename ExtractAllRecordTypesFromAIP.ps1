$sessionID = [Guid]::NewGuid().ToString() + "_" +  "ExtractLogs" + (Get-Date).ToString("yyyyMMddHHmmssfff")
[DateTime]$start = [DateTime]::UtcNow.Adddays(-21)
[DateTime]$end = [DateTime]::UtcNow
$record =  "AipHeartBeat" 
$resultSize = 5000
 
$VerbosePreference = "SilentlyContinue"


#import exchange online management module
Import-Module ExchangeOnlineManagement

#connect to exchangeonline
Connect-ExchangeOnline

	

#93	AipDiscover	Azure Information Protection (AIP) scanner events.
#94	AipSensitivityLabelAction	AIP sensitivity label events.
#95	AipProtectionAction	AIP protection events.
#96	AipFileDeleted	AIP file deletion events.
#97	AipHeartBeat	AIP heartbeat events.


#$record = @('AipSensitivityLabelAction', 'AipProtectionAction', 'AipFileDeleted', 'AipHeartBeat','AipDiscover')
#$record = 'AipDiscover'

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



 
