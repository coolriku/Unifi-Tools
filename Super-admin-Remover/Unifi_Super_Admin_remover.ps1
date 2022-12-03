Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.Application]::EnableVisualStyles()
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Form                            = New-Object system.Windows.Forms.Form
$Form.ClientSize                 = '724,402'
$Form.text                       = "Unifi Super Admin Remover"
$Form.TopMost                    = $false

$Button_getcred                  = New-Object system.Windows.Forms.Button
$Button_getcred.text             = "Get Credentials"
$Button_getcred.width            = 147
$Button_getcred.height           = 20
$Button_getcred.location         = New-Object System.Drawing.Point(368,9)
$Button_getcred.Font             = 'Microsoft Sans Serif,10'

$TextBox_url                     = New-Object system.Windows.Forms.TextBox
$TextBox_url.multiline           = $false
$TextBox_url.width               = 184
$TextBox_url.height              = 20
$TextBox_url.location            = New-Object System.Drawing.Point(177,9)
$TextBox_url.Font                = 'Microsoft Sans Serif,10'
$TextBox_url.text                = 'https://example.com:8443'

$Label1                          = New-Object system.Windows.Forms.Label
$Label1.text                     = "Unifi Controller URL:port"
$Label1.AutoSize                 = $true
$Label1.width                    = 25
$Label1.height                   = 10
$Label1.location                 = New-Object System.Drawing.Point(16,11)
$Label1.Font                     = 'Microsoft Sans Serif,10'

$Button_login                    = New-Object system.Windows.Forms.Button
$Button_login.text               = "Login"
$Button_login.width              = 60
$Button_login.height             = 20
$Button_login.enabled            = $false
$Button_login.location           = New-Object System.Drawing.Point(647,9)
$Button_login.Font               = 'Microsoft Sans Serif,10'

$DataGridView1                   = New-Object system.Windows.Forms.DataGridView
$DataGridView1.width             = 689
$DataGridView1.height            = 273
$DataGridView1.location          = New-Object System.Drawing.Point(17,102)
$DataGridView1.ReadOnly          = $true
$DataGridView1.ColumnCount       = 3
$DataGridView1.Columns[0].Name   = "Admin"
$DataGridView1.Columns[1].Name   = "Site"
$DataGridView1.Columns[2].Name   = "Status"

$Label3                          = New-Object system.Windows.Forms.Label
$Label3.text                     = "Log"
$Label3.AutoSize                 = $true
$Label3.width                    = 25
$Label3.height                   = 10
$Label3.location                 = New-Object System.Drawing.Point(19,73)
$Label3.Font                     = 'Microsoft Sans Serif,10'

$Label2                          = New-Object system.Windows.Forms.Label
$Label2.text                     = "Select Super admin to remove"
$Label2.AutoSize                 = $true
$Label2.width                    = 25
$Label2.height                   = 10
$Label2.location                 = New-Object System.Drawing.Point(19,42)
$Label2.Font                     = 'Microsoft Sans Serif,10'

$ComboBox_super_admins           = New-Object system.Windows.Forms.ComboBox
$ComboBox_super_admins.text      = "comboBox"
$ComboBox_super_admins.width     = 119
$ComboBox_super_admins.height    = 20
$ComboBox_super_admins.location  = New-Object System.Drawing.Point(212,37)
$ComboBox_super_admins.Font      = 'Microsoft Sans Serif,10'
$ComboBox_super_admins.Text      = $null

$Button_remove_superadmin        = New-Object system.Windows.Forms.Button
$Button_remove_superadmin.text   = "Remove superadmin"
$Button_remove_superadmin.width  = 140
$Button_remove_superadmin.height  = 20
$Button_remove_superadmin.enabled  = $false
$Button_remove_superadmin.location  = New-Object System.Drawing.Point(341,38)
$Button_remove_superadmin.Font   = 'Microsoft Sans Serif,10'

$CheckBox_ignoressl              = New-Object system.Windows.Forms.CheckBox
$CheckBox_ignoressl.text         = "Ignore SSL Cert"
$CheckBox_ignoressl.AutoSize     = $true
$CheckBox_ignoressl.width        = 110
$CheckBox_ignoressl.height       = 20
$CheckBox_ignoressl.location     = New-Object System.Drawing.Point(526,11)
$CheckBox_ignoressl.Font         = 'Microsoft Sans Serif,10'

$ErrorProvider1 = New-Object System.Windows.Forms.ErrorProvider

$Form.controls.AddRange(@($Button_getcred,$TextBox_url,$Label1,$Button_login,$DataGridView1,$Label3,$Label2,$ComboBox_super_admins,$Button_remove_superadmin,$CheckBox_ignoressl))

$Button_getcred.Add_Click({ get_credentials })
$Button_login.Add_Click({ login })
$Button_remove_superadmin.Add_Click({ remove_sadmin })


function get_credentials {
    $get_credentials = Get-Credential -Message "Unifi controller login"
    if ($get_credentials) {
        $script:credential = @{'username' = $get_credentials.UserName;'password' = $get_credentials.GetNetworkCredential().Password }
        $Button_login.enabled            = $true
    }
 }

function login {
    $script:baseurl = $TextBox_url.Text
    if ($CheckBox_ignoressl.Checked){
        add-type @"
            using System.Net;
            using System.Security.Cryptography.X509Certificates;
            public class TrustAllCertsPolicy : ICertificatePolicy {
                public bool CheckValidationResult(
                    ServicePoint srvPoint, X509Certificate certificate,
                    WebRequest request, int certificateProblem) {
                    return true;
                }
            }
"@
        [System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
        $CheckBox_ignoressl.Enabled = $false
    }
    try {
        $request = Invoke-webrequest -Uri "$script:baseurl/api/login" -UseBasicParsing -method post -body ($script:credential|ConvertTo-Json) -ContentType "application/json; charset=utf-8" -SessionVariable script:myWebSession
        if($request.StatusCode -eq 200) {
                $self_request = Invoke-restmethod -Uri "$baseurl/api/self" -WebSession $myWebSession -ContentType "application/json; charset=utf-8"
                $self = $self_request.data | where {$_.is_super -eq 'True'}
                if ($self) {
                    $errorprovider1.Clear()
                    load_admins
                } else {
                    $errorprovider1.SetError($this, "Loggedin User is not Super Admin, please use an other login")
                }
        } else {
            $errorprovider1.SetError($this, "Login Failed, Username or Password incorrect")
        }
    }
    catch {
        $errorprovider1.SetError($this, $_.Exception.Message)
    }
 }

function load_admins {
    $alladmins_request = Invoke-restmethod -Uri "$baseurl/api/stat/admin" -WebSession $myWebSession -ContentType "application/json; charset=utf-8"
    $script:alladmins = $alladmins_request.data  | where {$_.is_super -eq 'True'}
    $ComboBox_super_admins.Items.Clear()
    foreach ($admin in $alladmins){
        if ($admin.email){
            $ComboBox_super_admins.Items.Add($admin.email)
        }
        else {
            $ComboBox_super_admins.Items.Add($admin.name)
        }
    }
    #$ComboBox_super_admins.Items.AddRange($alladmins.name)
    $ComboBox_super_admins.SelectedIndex = 0
    $Button_remove_superadmin.enabled  = $true
 }

function remove_sadmin {
    $selectedadmin = $ComboBox_super_admins.SelectedItem
    $selectedadmin = $script:alladmins | Where-Object {($_.name -eq $selectedadmin) -or ($_.email -eq $selectedadmin)}
    $selectedadminid = $selectedadmin._id
    $allsites_request = Invoke-restmethod -Uri "$baseurl/api/self/sites" -WebSession $myWebSession -ContentType "application/json; charset=utf-8"
    $allsites = $allsites_request.data
    $i = 0
    $jsondatademote = @{'cmd' = 'revoke-super-admin';'admin' = $selectedadminid}
    $jsondatarevoke = @{'cmd' = 'revoke-admin';'admin' = $selectedadminid}
    foreach ($site in $allsites){
        $sitename = $site.name
        $desc = $site.desc
        if ($i -eq 0) {
            try {
                $demoteadmin_request = Invoke-restmethod -Uri "$baseurl/api/s/$sitename/cmd/sitemgr" -Method Post -Body ($jsondatademote|ConvertTo-Json) -WebSession $myWebSession -ContentType "application/json; charset=utf-8"
                $DataGridView1.Rows.Add($selectedadmin.name,'Demote Super Admin','Success')
            }
            catch {
                $DataGridView1.Rows.Add($selectedadmin.name,'Super Admin',$_.Exception.Message)
            }
        }
        try {
            $revokeadmin_request = Invoke-restmethod -Uri "$baseurl/api/s/$sitename/cmd/sitemgr" -Method Post -Body ($jsondatarevoke|ConvertTo-Json) -WebSession $myWebSession -ContentType "application/json; charset=utf-8"
            $DataGridView1.Rows.Add($selectedadmin.name,$desc,'Success')
        }
        catch {
            $DataGridView1.Rows.Add($selectedadmin.name,$desc,$_.Exception.Message)
        }
        $i ++
    }
 }

[void]$Form.ShowDialog()