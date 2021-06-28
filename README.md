# Azure_HCI_Dashboard
1.	Create a Log Analytics workspace

    Go to https://portal.azure.com and click Sign In
    
    Create Azure Log Analytics Workspace 
    
    Download and Copy the files "Counters.json" & "CSVInfo.Ps1" & "Onboard_Configuration.ps1" to Example C:\HCI_Dashboard\ 
		
		Edit the following Line (37) With Hybrid Worker Account 
		#Automation Account Creation 
		$User = "Contoso\Adminsitrator"
		$Password = ConvertTo-SecureString "Password01" -AsPlainText -Force
		$Credential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $User, $Password
		
		
			.\Onboard_Configuration.ps1 -AZAutomationAccount "AzHCIAUTOACC" -AzWorkspaceName "hci-la" -AzResourceGroup "hci-rg"
		 
		 Script Will Create Automation Account if not Exists 
		 Script will Enable the following Azure log Analytics Solution 
		 			Update Mangamenet Solution 
					Change Tracking  Solution 
					Azure Automation Solution
		Script will Create Custom Log "CSVINFOlog" used in Single Cluster node to collect CSV information 
		Script will Create RunAsAccount for the automation account 

    
