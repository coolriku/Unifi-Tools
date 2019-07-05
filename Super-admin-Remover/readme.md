# Unifi Super Admin Remover
This tools helps removing an Super Administrator from all sites.
Currently in the Unifi controller, it is not possible to delete a super admin from all sites with ease.
It requires lots of manual work, demote the super admin to admin, remove that admin from all sites one at a time.

![Example main screen](https://github.com/coolriku/Unifi-Tools/Super-admin-remover/images/sar1.png)

## Requirements

 - Unifi controller access via https
 - Super Administrator Credentials
 - Windows machine with Powershell

## how to run?

 1. Save the Powershell script (.ps1) to a folder
 2. Right click on the downloaded script and choose "Run with PowerShell"
 3. Enter your Unifi Controller URL with https:// and :[port] as seen on the screen
 4. Click on the "Get Credentials" Button and fill in your Super Administrator account(not the one you want to remove)
 5. Check "Ignore SSL Cert" if your controller uses a self-signed Certificate
 6. Click on the button "Login"
 7. Choose the Super Administrator you want to remove from the list
 8. Click on "Remove Super Administrator" and see the magic happen in the field below.
 9. Check the logs for errors,
 10. Finished! 
