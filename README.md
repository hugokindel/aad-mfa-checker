# Azure Active Directory MFA Checker

Small tool used to verify and edit the MFA status of every user in any Azure Active Directory.  
Disclaimer: The methods used here have been deprecated and only work if you use the legacy MFA methods of Azure AD. Now, you should favor Conditional Access which is not covered by this program. Also, this only work on Windows hosts due to Azure's deprecated MFA API.

## How to use

Follow these steps on a PowerShell terminal in this directory:

- Install MSOnline: `Install-Module MSOnline`
- Import module: `Import-Module MSOnline` (might not be necessary)
- Connect to your Microsoft 365 account: `Connect-MSOnline`
- Run the following command: `.\mfa_checker.ps1`

#### Execute MFA status changes

By default, the script will only show user informations.  
To actually change a user MFA status, you need to run it with the following parameter: `.\mfa_checker.ps1 -Y`

#### Add exclusions

Edit the `$ExclusionList` variable in case you want to exclude users from the audit.

## Dependencies

- [MSOnline](https://learn.microsoft.com/en-us/powershell/module/msonline/?view=azureadps-1.0)
