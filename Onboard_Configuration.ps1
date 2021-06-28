#Version 2.0
#Update : 18 April 2021 
#Example 
#.\Onboard_Configuration_V2.0.ps1 -AZAutomationAccount "AzHCIAUTOACC" -AzWorkspaceName "hci-la" -AzResourceGroup "hci-rg"

[CmdletBinding(DefaultParameterSetName="NoParameters")]
param(

    [Parameter(Mandatory=$False,ParameterSetName="AZAutomationAccount")]
    [String] $AZAutomationAccount=$Null,

    [Parameter(Mandatory=$True,HelpMessage='Please Provide Resource Group Name')]
    [string]$AzResourceGroup,

    [Parameter(Mandatory=$True,HelpMessage='Please Provide Workspace Name')]
    [string]$AZWorkspaceName


)


Connect-AzAccount
$Sub = Get-AzSubscription | Out-GridView -Title "Please Select your AzSubscription" -PassThru
Select-AzSubscription -SubscriptionId $Sub.SubscriptionID


#Variable Section 

$ResourceGroup = Get-AzResourceGroup -Name "$AzResourceGroup"
$WorkspaceName = "$AZWorkspaceName"


$HybirWorkerGroup = "AZHCIGROUP"
$date = Get-Date(get-date).AddHours(1) -Format "MM/dd/yyyy HH:mm:ss"
$TimeZone = ([System.TimeZoneInfo]::Local).Id

#Automation Account Creation 
$User = "Contoso\Adminsitrator"
$Password = ConvertTo-SecureString "Password01" -AsPlainText -Force
$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $Password

#Login first with Connect-AzAccount 

$CSVINFO = @"
{
    "customLogName": "csvinfo_CL",
    "description": "Example custom log datasource",
    "inputs": [
        {
            "location": {
            "fileSystemLocations": {
                "windowsFileTypeLogPaths": [ "C:\\CSVToLAlogs\\CluserCSVinfo_*.log" ],
                }
            },
        "recordDelimiter": {
            "regexDelimiter": {
                "pattern": "\\n",
                "matchIndex": 0,
                "matchIndexSpecified": true,
                "numberedGroup": null
                }
            }
        }
    ],
    "extractions": [
        {
            "extractionName": "TimeGenerated",
            "extractionType": "DateTime",
            "extractionProperties": {
                "dateTimeExtraction": {
                    "regex": null,
                    "joinStringRegex": null
                    }
                }
            }
        ]
    }
"@
$CLUINFO = @"
{
    "customLogName": "cninfo_CL",
    "description": "Example custom log datasource",
    "inputs": [
        {
            "location": {
            "fileSystemLocations": {
                "windowsFileTypeLogPaths": [ "C:\\CSVToLAlogs\\Clusterinfo_*.log" ],
                }
            },
        "recordDelimiter": {
            "regexDelimiter": {
                "pattern": "\\n",
                "matchIndex": 0,
                "matchIndexSpecified": true,
                "numberedGroup": null
                }
            }
        }
    ],
    "extractions": [
        {
            "extractionName": "TimeGenerated",
            "extractionType": "DateTime",
            "extractionProperties": {
                "dateTimeExtraction": {
                    "regex": null,
                    "joinStringRegex": null
                    }
                }
            }
        ]
    }
"@


if (!($AZAutomationAccount -eq $null ) )
    {
        Write-host "Get AzAutomationAccount"
        $AutomationAccount = Get-AzAutomationAccount -ResourceGroupName $ResourceGroup.ResourceGroupName -Name $AZAutomationAccount
    }

Else 
    {
    #Create New Automation Account 
    $AutomationAccount = New-AzAutomationAccount -ResourceGroupName $ResourceGroup.ResourceGroupName -Name "AzHCIAUTOACC" -Location $ResourceGroup.Location
    }


#Enable workspace solutions "Updates - ChangeTracking- AzureAutomation"
 $IntelligencePack = Get-AzOperationalInsightsIntelligencePack -ResourceGroupName $ResourceGroup.ResourceGroupName -WorkspaceName  $WorkspaceName  | Where {$_.Name -eq "Updates" -or $_.Name -eq "ChangeTracking" -or $_.Name -eq "AzureAutomation"}
 if ($IntelligencePack[0].Enabled -eq $False) 
 { Write-host "Enable" $IntelligencePack[0].Name  "Soluaiton"
  Set-AzOperationalInsightsIntelligencePack -ResourceGroupName $ResourceGroup.ResourceGroupName -WorkspaceName  $WorkspaceName -IntelligencePackName "Updates" -Enabled $true}
 if ($IntelligencePack[1].Enabled -eq $False) 
 { Write-host "Enable" $IntelligencePack[1].Name  "Soluaiton"
 Set-AzOperationalInsightsIntelligencePack -ResourceGroupName $ResourceGroup.ResourceGroupName  -WorkspaceName  $WorkspaceName -IntelligencePackName "ChangeTracking" -Enabled $true}
  if ($IntelligencePack[2].Enabled -eq $False) 
 { Write-host "Enable" $IntelligencePack[2].Name  "Soluaiton"
 Set-AzOperationalInsightsIntelligencePack -ResourceGroupName $ResourceGroup.ResourceGroupName  -WorkspaceName  $WorkspaceName -IntelligencePackName "AzureAutomation" -Enabled $true}


#Register Automation Account 
$RegistrationInfo = Get-AzAutomationRegistrationInfo -ResourceGroupName  $ResourceGroup.ResourceGroupName -AutomationAccountName $AutomationAccount.AutomationAccountName
$Runbook = New-AzAutomationRunbook -Name "RetrieveCSVInfo" -Type PowerShell -ResourceGroupName  $ResourceGroup.ResourceGroupName -AutomationAccountName $AutomationAccount.AutomationAccountName
$Schedule = New-AzAutomationSchedule -AutomationAccountName $AutomationAccount.AutomationAccountName -Name "GetCSVInfoSch" -StartTime $date -HourInterval 1 -ResourceGroupName $ResourceGroup.ResourceGroupName -TimeZone $TimeZone
Import-AzAutomationRunbook -Name $Runbook -Path ".\CSVinfo.Ps1" -Type PowerShell -ResourceGroupName $ResourceGroup.ResourceGroupName -AutomationAccountName $AutomationAccount.AutomationAccountName -Force
Publish-AzAutomationRunbook -AutomationAccountName $AutomationAccount.AutomationAccountName -ResourceGroupName $ResourceGroup.ResourceGroupName -Name $Runbook.Name
New-AzAutomationCredential -AutomationAccountName $AutomationAccount.AutomationAccountName -Name "OnPremHCI" -Value $Credential -ResourceGroupName $ResourceGroup.ResourceGroupName 

#Adding the HybridRunbookWorker on the source Machine Selected Node 
#Current Set Version 7.3.1095.0
Write-host "Please Connect to One of the Cluster Nodes and Run the following Command" -ForegroundColor Green
Write-Host "cd 'C:\Program Files\Microsoft Monitoring Agent\Agent\AzureAutomation\7.3.1095.0\HybridRegistration' " -ForegroundColor Yellow
Write-Host "Import-Module .\HybridRegistration.psd1" -ForegroundColor Yellow
Write-Host "Add-HybridRunbookWorker –GroupName $HybirWorkerGroup -Url "$RegistrationInfo.Endpoint" -Key "$RegistrationInfo.PrimaryKey"" -ForegroundColor Yellow
Write-host "if The Machine already Registered in another HybridRunbookWorker Please Delete the following Key HKLM:\SOFTWARE\Microsoft\HybridRunbookWorker" -ForegroundColor Red
Pause 



Register-AzAutomationScheduledRunbook -RunbookName $Runbook.Name -ResourceGroupName  $ResourceGroup.ResourceGroupName -AutomationAccountName $AutomationAccount.AutomationAccountName -ScheduleName $Schedule.Name -RunOn $HybirWorkerGroup 



$Counters = Get-Content -raw .\Counters.json |ConvertFrom-Json
Foreach ($Counter in $Counters )
{
    Write-Host "Adding" $Counter -ForegroundColor Green
    New-AzOperationalInsightsWindowsPerformanceCounterDataSource -ResourceGroupName $ResourceGroup.ResourceGroupName -WorkspaceName $WorkspaceName -ObjectName $Counter.ObjectName -InstanceName $Counter.InstanceName -CounterName $Counter.CounterName -IntervalSeconds $Counter.intervalSeconds -Name $Counter.Name
}


#Adding Event Logs Collection 
New-AzOperationalInsightsWindowsEventDataSource -ResourceGroupName $ResourceGroup.ResourceGroupName  -WorkspaceName $WorkspaceName  -EventLogName "Application" -CollectErrors  -CollectWarnings  -Name "Application Event Log"
New-AzOperationalInsightsWindowsEventDataSource -ResourceGroupName $ResourceGroup.ResourceGroupName  -WorkspaceName $WorkspaceName  -EventLogName "System" -CollectErrors  -CollectWarnings  -Name "System Event Log"
New-AzOperationalInsightsWindowsEventDataSource -ResourceGroupName $ResourceGroup.ResourceGroupName  -WorkspaceName $WorkspaceName  -EventLogName "Microsoft-Windows-Health/Operational" -CollectErrors  -CollectWarnings  -Name "HCI Health Service"

#Adding Custom Logs 
New-AzOperationalInsightsCustomLogDataSource -ResourceGroupName $ResourceGroup.ResourceGroupName -WorkspaceName $WorkspaceName -CustomLogRawJson "$CSVINFO" -Name "CSVINFOlog"

