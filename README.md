# CitrixSharefile-DowngradeDisabledUsers
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
  
