# Add-MembersToDynamicGroupByDate
This script will allow you to log in to your local Active Directory and stamp a custom attribute then login via Graph to Azure and create a Dynamic Group based on those properties.

<b><span style="color:yellow">NOTE:</span> This version requires that you have hybrid exchange and Azure Active Directory connect setup. The properties are stamped on the On-Premises objects in an extension attribute and flow over via AADC to the cloud. The script will automate the group creation and dynamic membership based on your settings. This was done to avoid using cloud extended extensions or schema updates.


- <span style="color:orange">EXAMPLE 1:</span> Add-MembersToDynamicGroupByDate -ConnectToAD -StartDate '8/1/2022' -EndDate '8/31/2022' -ExtensionAttribute ExtensionAttribute1 -ExtensionAttributeValue "YourValue"

	<span style="color:gray">This will connect to Active directory and query for all users based on start and end date and stamp them with the ExtensionAttribute selected and ExtensionAttributeValue defined</span>

- <span style="color:orange">EXAMPLE 2:</span> Add-MembersToDynamicGroupByDate -CreateDynamicGroup -DynamicGroupName "MyDynamicGroup" -Description 'My Dynamic Group" -ExtensionAttribute ExtensionAttribute1

    <span style="color:gray">This will connect to the Azure AD via Graph and create a Dynamic Group with a define membership that will search users based on ExtensionAttribute and ExtensionAttributeValue defined</span>
