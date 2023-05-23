# Do not forget to run `Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass` and `Connect-MsolService `before execution.

if (-not (Get-MsolDomain -ErrorAction SilentlyContinue)) {
    Write-Error "Please use 'Connect-MsolService' before running this script!" -ErrorAction Stop
}

$ExclusionList = @()

Function Get-UsersStatus {
    $Users = Get-MsolUser -All -ErrorAction Stop | Where-Object { $_.UserType -ne 'Guest' }

    foreach ($User in $Users) {
        if ($ExclusionList -contains $User.UserPrincipalName -or $User.BlockCredential) {
            continue
        }

        $MethodType = $User.StrongAuthenticationMethods | Where-Object {$_.IsDefault -eq $true} | select -ExpandProperty MethodType

        foreach ($Method in $User.StrongAuthenticationMethods) {
            if ($Method.MethodType -eq "PhoneAppNotification" -or $User.MethodType -eq "PhoneAppOTP") {
                $MethodType = $Method.MethodType
                break
            }
        }

        [PSCustomObject] @{
            UserPrincipalName = $User.UserPrincipalName
            PerUserMFAState = if ($User.StrongAuthenticationRequirements) { $User.StrongAuthenticationRequirements.State} else { $PerUserMFAState = 'Disabled' }
            MethodType = $MethodType
        }
    }
}

$Users = Get-UsersStatus

Write-Output ""
Write-Output "---------------- Users With SMS Authentication ----------------"
$i = 0
foreach ($User in $Users) {
    if ($User.MethodType -eq "OneWaySMS") {
        Write-Output $User.UserPrincipalName

        $i++
    }
}
Write-Output "Total: $($i)"

Write-Output ""
Write-Output "---------------- Users Ready for MFA Enforcement ----------------"
$i = 0
foreach ($User in $Users) {
    if (($User.PerUserMFAState -eq $null -or $User.PerUserMFAState -eq "Enabled") -and ($User.MethodType -eq "PhoneAppNotification" -or $User.MethodType -eq "PhoneAppOTP")) {
        if ($args.count -ne 0 -and $args[0] -eq "-Y") {
            $mfa = New-Object -TypeName Microsoft.Online.Administration.StrongAuthenticationRequirement
            $mfa.RelyingParty = "*"
            $mfa.State = "Enforced"
            $mfa.RememberDevicesNotIssuedBefore = (Get-Date)

            Set-MsolUser -UserPrincipalName $User.UserPrincipalName -StrongAuthenticationRequirements @($mfa)
        }

        $old_status = if ($User.PerUserMFAState -eq $null) { "Disabled" } else { "Enabled" }
        Write-Output "$($User.UserPrincipalName): $($old_status) -> Enforced"

        $i++
    }
}
Write-Output "Total: $($i)"

if ($i -gt 0 -and ($args.count -eq 0 -or $args[0] -ne "-Y")) {
    Write-Output ""
    Write-Output "Add parameter '-Y' at next run to apply enforcement for these users."
}


Write-Output ""
Write-Output "---------------- Number of Unprotected Users (MFA is not Enforced) ----------------"
$i = 0
foreach ($User in $Users) {
    if ($User.PerUserMFAState -ne "Enforced") {
        Write-Output $User.UserPrincipalName
        $i++
    }
}
Write-Output "Total: $($i)"

Write-Output ""
Write-Output "---------------- Number of Protected Users (MFA is Enforced) ----------------"
$i = 0
foreach ($User in $Users) {
    if ($User.PerUserMFAState -eq "Enforced") {
        Write-Output $User.UserPrincipalName
        $i++
    }
}
Write-Output "Total: $($i)"
