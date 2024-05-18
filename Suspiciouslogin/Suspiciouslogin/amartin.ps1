# Import the login data
Measure-Command {
#$Logins = switch -file $PSScriptRoot\LoginDatabase.csv { Default {$_} }
$logins = Import-Csv -Path $PSScriptRoot\LoginDatabase.csv

#return $Logins

# Initialize a hashtable to keep track of the login attempts
$loginAttempts = @{}

# Iterate over the login data
foreach ($login in $logins) {
    # If the user is not in the hashtable, add them
    if (-not $loginAttempts.ContainsKey($login.User)) {
        $loginAttempts[$login.User] = @{
            FailedAttempts = 0
            LastSuccessfulLogin = $null
        }
    }

    # Check if the login attempt is successful
    if ($login.PasswordResultHash -ge 100000) {
        # Reset the failed attempts and update the last successful login time
        $loginAttempts[$login.User].FailedAttempts = 0
        $loginAttempts[$login.User].LastSuccessfulLogin = $login.Time
    } else {
        # Increment the failed attempts
        $loginAttempts[$login.User].FailedAttempts++
    }

    # Check if the account is compromised
    if ($loginAttempts[$login.User].FailedAttempts -ge 3 -or
        ($loginAttempts[$login.User].LastSuccessfulLogin -eq $login.Time -and $login.PasswordResultHash -ge 100000)) {
        $loginAttempts[$login.User].IsCompromised = $true
    }
}

$loginAttempts.Count

# Count the total number of compromised and uncompromised accounts
$compromisedCount = $loginAttempts.Values.Where({ $_.IsCompromised }).Count
$compromisedCount
$uncompromisedCount = $loginAttempts.Count - $compromisedCount
$uncompromisedCount

# Load the user database
$users = Import-Csv -Path $PSScriptRoot\UserDatabase.csv

# Identify the users who are scheduled to work on Saturday
$saturdayUsers = $users.Where({ $_.WorkDays -match 'Sa|So' })

# Send a notification to the compromised accounts
$count = 0
foreach ($user in $saturdayUsers) {
    if ($loginAttempts[$user.UserID].IsCompromised) {
        # Send a notification
        #Send-MailMessage -To $user.Email -Subject "Account Compromised" -Body "Your account has been compromised. Please reset your password."
        $count++
    }
}

$count
}
