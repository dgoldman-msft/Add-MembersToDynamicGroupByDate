function Add-MembersToDynamicGroupByDate {
	<#
	.SYNOPSIS
		Stamp on-premises users and add them to an Azure dynamic group

	.DESCRIPTION
		This script will allow you to log in to your local Active Directory and stamp a custom attribute then login via Graph to Azure and create a Dynamic Group based on those properties

	.PARAMETER ConnectToAD
		Switch used to indicate we want to connect to local Active Directory

	.PARAMETER CreateDynamicGroup
		Switch used to indicate we want to connect to AzureAD

	.PARAMETER DynamicGroupName
		Name for Dynamic Group

	.PARAMETER Description
		Group description

	.PARAMETER EndDate
		Query end date

	.PARAMETER ExtensionAttribute
		ExtensionAttribute 1 - 15 to stamp

	.PARAMETER ExtensionAttributeValue
		Value for ExtensionAttribute being stamped

	.PARAMETER OutputDirectory
		Logging output directory

	.PARAMETER OutputFile
		Logging output file name

	.PARAMETER StartDate
		Query start date

	.PARAMETER SaveResults
		Switch to indicate you want results saved to the Output directory

	.EXAMPLE
		PS C:\> Add-MembersToDynamicGroupByDate -ConnectToAD -StartDate '8/1/2022' -EndDate '8/31/2022' -ExtensionAttribute ExtensionAttribute1 -ExtensionAttributeValue "YourValue"

		This will connect to Active directory and query for all users based on start and end date and stamp them with the ExtensionAttribute selected and ExtensionAttributeValue defined

	.EXAMPLE
		PS C:\> Add-MembersToDynamicGroupByDate -CreateDynamicGroup -DynamicGroupName "MyDynamicGroup" -Description 'My Dynamic Group" -ExtensionAttribute ExtensionAttribute1

		This will connect to the Azure AD via Graph and create a Dynamic Group with a define membership that will search users based on ExtensionAttribute and ExtensionAttributeValue defined

	.NOTES
	    None
	#>

	[CmdletBinding(DefaultParameterSetName = 'Default')]
	[OutputType('System.String')]
	[OutputType('System.IO.File')]
	param(
		[Parameter(ParameterSetName = 'LocalAD')]
		[switch]
		$ConnectToAD,

		[Parameter(ParameterSetName = 'AzureAD')]
		[switch]
		$CreateDynamicGroup,

		[Parameter(ParameterSetName = 'AzureAD')]
		[string]
		$DynamicGroupName = "Test Dynamic Group",

		[Parameter(ParameterSetName = 'AzureAD')]
		[string]
		$Description = "Dynamic group created for users created between certain dates",

		[Parameter(ParameterSetName = 'LocalAD')]
		[string]
		$EndDate = '1/31/2022',

		[Parameter(ParameterSetName = 'LocalAD')]
		[Parameter(ParameterSetName = 'AzureAD')]
		[ValidateSet('extensionAttribute1', 'extensionAttribute2', 'extensionAttribute3', 'extensionAttribute4', 'extensionAttribute5', 'extensionAttribute6', `
				'extensionAttribute7', 'extensionAttribute8', 'extensionAttribute9', 'extensionAttribute10', 'extensionAttribute11', 'extensionAttribute12', `
				'extensionAttribute13', 'extensionAttribute14', 'extensionAttribute15')]
		[string]
		$ExtensionAttribute = 'extensionAttribute1',

		[Parameter(ParameterSetName = 'AzureAD')]
		[string]
		$ExtensionAttributeValue = 'whenCreatedOn',

		[string]
		$OutputDirectory = "c:\ScriptOutput",

		[string]
		$OutputFile = "AzureADPreviewGroupMembership.csv",

		[Parameter(ParameterSetName = 'LocalAD')]
		[string]
		$StartDate = '1/1/2022',

		[switch]
		$SaveResults
	)

	begin {
		$parameters = $PSBoundParameters

		try {
			Write-Verbose "Checking for the Microsoft.Graph.Groups module"
			if (-NOT (Get-Module -Name Microsoft.Graph.Groups -ListAvailable)) {
				Write-Verbose "Installing the Microsoft.Graph.Groups module from the PowerShellGallery"
				if (Install-Module -Name Microsoft.Graph.Groups -Repository PSGallery -Scope CurrentUser -Force) {
					Import-Module -Name Microsoft.Graph.Groups -Force
					Write-Verbose "Microsoft.Graph.Groups import complete"
				}
			}
			else {
				Import-Module -Name Microsoft.Graph.Groups -Force
				Write-Verbose "Microsoft.Graph.Groups import complete"
			}
		}
		catch {
			Write-Output "POWERSHELL MODULE ERROR: $_"
			return
		}

		try {
			Write-Verbose "Checking for existence of: $($OutputDirectory)"
			if (-NOT(Test-Path -Path $OutputDirectory)) {
				$null = New-Item -Path $OutputDirectory -ItemType Directory
				Write-Verbose "Created new directory: $($OutputDirectory)"
			}
		}
		catch {
			Write-Output "TEMP DIRECTORY ERROR: $_"
			return
		}
	}

	process {
		if ($parameters.ContainsKey('ConnectToAD')) {
			try {
				Write-Output "Connecting to Active Directory"
				$adUsers = Get-AdUser -Filter * -Properties * | Select-Object SamAccountName, whenCreated
				$adUsers | ForEach-Object {
					if ($_.whenCreated) {
						$dateCreated = (($_.whenCreated) -split ' ')[0]
						if ([DateTime]$dateCreated -ge $StartDate -and [DateTime]$dateCreated -le $EndDate) {
							Write-Output "SamAccountName: $($_.SamAccountName) - whenCreated: $($_.whenCreated)"
							Write-Verbose "Setting extension attribute: $($ExtensionAttribute) on $($_.UserPrincipalName)"
							Set-ADUser -Identity $_.SamAccountName -Replace @{"$($ExtensionAttribute)" = "$($ExtensionAttributeValue)" }
						}
					}
				}
			}
			catch {
				Write-Output "ACTIVE DIRECTORY ERROR: $_"
				return
			}
		}

		if ($parameters.ContainsKey('CreateDynamicGroup')) {
			try {
				Write-Output "Connecting to Azure AD via Graph"
				Connect-MgGraph -Scopes Group.ReadWrite.All, Directory.ReadWrite.All -ErrorAction Stop
				Write-Output "Creating new Azure AD Dynamic Group: $($DynamicGroupName)"
				$params = @{
					DisplayName                   = $DynamicGroupName
					Description                   = $Description
					GroupTypes                    = 'DynamicMembership'
					MailEnabled                   = $False
					MailNickname                  = ($DynamicGroupName -replace ' ')
					MembershipRule                = "(user.$ExtensionAttribute -eq ""$ExtensionAttributeValue"")"
					MembershipRuleProcessingState = 'On'
					SecurityEnabled               = $True
					Visibility                    = 'Public'
				}
				if ($group = New-MgGroup @params) {
					Write-Verbose "$($group)"
					Write-Output "New Dynamic Group $($DynamicGroupName) created!"
				}
				else { Write-Output "Dynamic Group failed to create" }
			}
			catch {
				Write-Output "GROUP CREATION ERROR: $_"
				return
			}
		}

		if ($parameters.ContainsKey('SaveResults')) {
			try {
				[PSCustomObject]$adUsers | Sort-Object whenCreated -Descending | Export-Csv -Path (Join-Path -Path $OutputDirectory -ChildPath $Outputfile) -Encoding utf8 -NoTypeInformation -Append -ErrorAction Stop
			}
			catch {
				Write-Output "SAVING RESULTS ERROR: $_"
			}
		}
	}

	end {
		Write-Output "Completed!"
	}
}
