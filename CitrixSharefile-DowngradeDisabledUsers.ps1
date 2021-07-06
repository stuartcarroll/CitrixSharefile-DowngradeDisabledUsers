<#
Stu Carroll - Coffee Cup Solutions (stu.carroll@coffeecupsolutions.com) 2021

.SYNOPSIS
Downgrade Citrix Sharefile Employee users that have been disabled, possibly my Citrix Sharefile UMT when a users AD account has been disabled, and downgrade them to a client users account to free up licenses

To avoid hard coding or passing sensitive customer data inline this script requires the following environment variables to be set: 

  $ENV:SFClientID - Sharefile API Client ID 
  $ENV:SFClientSecret - Sharefile API Client Secret
  $ENV:SFUser - Sharefile Account Username
  $ENV:SFAppPass - Sharefile Account App Password

.DESCRIPTION
  .PARAMETER Region
Select the Sharefile region for your instance 
 	eu - europe
	us - united states 

  .PARAMETER Subdomain
Enter Sharefile subdomain 

  .PARAMETER NewOwner
The email address of the account that should take ownership of the disabled account's item sand groups

  .PARAMETER Mode
Set the script mode:
    info - Make no changes, just output disabled users
    commit - Downgrade all disabled user accounts to client accounts 

    .EXAMPLE
& '.\CitrixSharefile-DowngradeDisabledUsers.ps1' -subdomain <subdomain> -region <eu/us> -NewOwner <email> -mode commit

Downgrade disabled employee accounts. This is a destructuve change.

.\CitrixSharefile-DowngradeDisabledUsers.ps1' -subdomain coffeecup -region eu -NewOwner me@coffeecup.com -mode commit

    .EXAMPLE
& '.\CitrixSharefile-DowngradeDisabledUsers.ps1' -subdomain <subdomain> -region <eu/us> -NewOwner <email> -mode info

Show disabled employee accounts. This is a NON destructuve change.

.\CitrixSharefile-DowngradeDisabledUsers.ps1' -subdomain coffeecup -region eu -NewOwner me@coffeecup.com -mode info

#>

param(  
    #Sharefile Region
    [Parameter(Position = 0, Mandatory = $true)]
    [ValidateSet("eu","us")]
    [String]$Region = "eu",
    #Sharefile Subdomain
    [Parameter(Position = 1, Mandatory = $true)]
    [String]$Subdomain = "",
    #User to reassign Items and Groups to
    [Parameter(Position = 2, Mandatory = $true)]
    [String]$NewOwner = "",
    #Mode
    # info - Make no changes, just output disabled users
    # commit - Downgrade all disabled user accounts to client accounts 
    [Parameter(Position = 3, Mandatory = $true)]
    [ValidateSet("info","commit")]
    [String]$mode = "info"
)

switch ( $Region )
{
    eu { $tld = 'eu'    }
    us { $tld = 'com'    }
}

#Set Domain Token URL 
$TokenURL = "https://"+$Subdomain+".sharefile.com/oauth/token"


#Get Authetnication Environemnt Variables 
$SFClientID = $ENV:SFClientID
$SFClientSecret = $ENV:SFClientSecret
$SFUser = $ENV:SFUser
$SFAppPass = $ENV:SFAppPass

#Check Auth Environment Variables are set, if not Exit.
if(!$SFClientID){
  Write-Error "No Sharefile Client ID set in environment variables. Script will exit."
  Exit
}
if(!$SFClientSecret){
  Write-Error "No Sharefile Client Secret set in environment variables. Script will exit."
  Exit
}
if(!$SFUser){
  Write-Error "No Sharefile user set in environment variables. Script will exit."
  Exit
}
if(!$SFAppPass){
  Write-Error "No Sharefile app password set in environment variables. Script will exit."
  Exit
}

#Request data 
$Body = @{
    grant_type = "password"
    client_id = $SFClientID
    client_secret = $SFClientSecret
    username = $SFUser
    password = $SFAppPass
    }
  
$contentType = 'application/x-www-form-urlencoded' 

#Authenticate to Sharefile Rest API and set Access Token
$response = Invoke-WebRequest $TokenURL -Method POST -Body $Body -ContentType $contentType
$accessToken = ($response.Content | convertfrom-json).access_token

if(!$accessToken){
  Write-Error "Problem obtaining access token. Script will exit."
  Exit 
}

$SharefileAPI = "https://"+$Subdomain+".sf-api."+$tld

#Get Employee accounts 
$EmployeeURI = $SharefileAPI+"/sf/v3/Accounts/Employees"
$reportData = Invoke-RestMethod -Uri $EmployeeURI -Method GET -Headers @{"Authorization"="Bearer $accessToken"} -ContentType "application/json"

#Find ID of new owner
if(!$NewOwner){
  Write-Error "No new owner set for disabled account's items or groups. Script will exit."
  Exit
}
else{
  $NewOwnerID = ($reportData.value | Where-Object {$_.Email -eq $NewOwner}).Id 
}
#Ensure owner ID can be extracted from NewOwner email 
if(!$NewOwnerID){
  Write-Error "ID coul dnot be extracted from -NewOwner parameter. Script will exit."
  Exit
}
else{
  Write-Host "New Owner Email is: "$NewOwner -ForegroundColor Cyan
  Write-Host "New Owner ID is: "$NewOwnerID -ForegroundColor Cyan
}

#Filter for disabled user accounts  
$DisabledAccounts = $reportData.value | where-object {$_.IsDisabled -eq $true}

#For each disabled account (if any exist)
if($DisabledAccounts){
  foreach($Account in $DisabledAccounts){
    if($mode -eq "commit"){
      write-host "Downgrading the following user account: "$Account.email -ForegroundColor Yellow
      #Downgrade Employee to Client
      $DowngradeURI = $SharefileAPI+"/sf/v3/Users/Employees/Downgrade"
      
      #Request data 
      $DowngradeBody = @{
        UserIds = $Account.Id
        ReassignItemsToId = $NewOwnerID
        ReassignGroupsToId = $NewOwnerID
        }
    
      $DownGradeUser = Invoke-RestMethod -Uri $DowngradeURI -Method POST -Body $DowngradeBody -Headers @{"Authorization"="Bearer $accessToken"}
      
      #Check user has been downgraded
      $UserURI = "https://"+$Subdomain+".sf-api."+$tld+"/sf/v3/Users("+$Account.Id+")"
      $userData = Invoke-RestMethod -Uri $userURI -Method GET -Headers @{"Authorization"="Bearer $accessToken"} -ContentType "application/json"
      
      #Check if account if Client or Employee
      if($userData.Roles[0] -eq "Client"){
        Write-Output "Successfully Downgraded user"
        $userData
      }
      elseif($userData.Roles[0] -eq "Exmployee") {
        Write-Error "Failed to downgrade user" 
      }
      else {
        Write-Error "No user data returned."
      }
    }
    elseif($mode -eq "info"){
      
      $Account

    }

    
  }
}
else{
  Write-Output "No disabled user accounts returned from API."
}

