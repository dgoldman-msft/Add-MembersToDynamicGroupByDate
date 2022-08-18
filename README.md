# Add-MembersToDynamicGroupByDate
This script will allow you to log in to your local Active Directory and stamp a custom attribute then login via Graph to Azure and create a Dynamic Group based on those properties


- EXAMPLE 1: Add-MembersToDynamicGroupByDate -ConnectToAD -StartDate '8/1/2022' -EndDate '8/31/2022' -ExtensionAttribute ExtensionAttribute1 -ExtensionAttributeValue "YourValue"

	This will connect to Active directory and query for all users based on start and end date and stamp them with the ExtensionAttribute selected and ExtensionAttributeValue defined

- EXAMPLE 2: Add-MembersToDynamicGroupByDate -CreateDynamicGroup -DynamicGroupName "MyDynamicGroup" -Description 'My Dynamic Group" -ExtensionAttribute ExtensionAttribute1

    This will connect to the Azure AD via Graph and create a Dynamic Group with a define membership that will search users based on ExtensionAttribute and ExtensionAttributeValue defined
