
#Set up Envinroment Variables for Sharefile authorisation 

$ClientID = ""
$ClientSecret = ""
$User = ""
$Pass = ""

[System.Environment]::SetEnvironmentVariable('SFClientID',$ClientID,[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('SFClientSecret',$ClientSecret,[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('SFUser',$User,[System.EnvironmentVariableTarget]::Machine)
[System.Environment]::SetEnvironmentVariable('SFAppPass',$Pass,[System.EnvironmentVariableTarget]::Machine)

