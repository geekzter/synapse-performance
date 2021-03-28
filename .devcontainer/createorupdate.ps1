#!/usr/bin/env pwsh
# Runs post create commands to prep Codespace for project

# Update relevant packages
sudo apt-get update
#sudo apt-get install --only-upgrade -y azure-cli powershell
if (!(Get-Command func -ErrorAction SilentlyContinue)) {
    sudo apt-get install -y azure-functions-core-tools
}
if (!(Get-Command sqlcmd -ErrorAction SilentlyContinue)) {
    sudo ACCEPT_EULA=Y apt install msodbcsql17 -y
    sudo ACCEPT_EULA=Y apt install mssql-tools -y
}
if (!(Get-Command tmux -ErrorAction SilentlyContinue)) {
    sudo apt-get install -y tmux
}

# Determine directory locations (may vary based on what branch has been cloned initially)
$repoDirectory = (Split-Path (Split-Path (Get-ChildItem "100m.png" -Path ~ -Recurse).FullName -Parent) -Parent)
$terraformDirectory = Join-Path $repoDirectory "terraform"
# This will be the location where we save a PowerShell profile
$profileTemplate = (Join-Path (Split-Path -Parent -Path $MyInvocation.MyCommand.Path) profile.ps1)

# Get/update tfenv, for Terraform versioning
if (!(Get-Command tfenv -ErrorAction SilentlyContinue)) {
    Write-Host 'Installing tfenv...'
    git clone https://github.com/tfutils/tfenv.git ~/.tfenv
    sudo ln -s ~/.tfenv/bin/* /usr/local/bin
} else {
    Write-Host 'Upgrading tfenv...'
    git -C ~/.tfenv pull
}

Push-Location $terraformDirectory
# Get the desired version of Terraform
tfenv install latest
tfenv install min-required
tfenv use min-required
# We may as well initialize Terraform now
terraform init -upgrade
Pop-Location

# Use geekzter/bootstrap-os for PowerShell setup
if (!(Test-Path ~/bootstrap-os)) {
    git clone https://github.com/geekzter/bootstrap-os.git ~/bootstrap-os
} else {
    git -C ~/bootstrap-os pull
    # This has been run before, upgrade packages
    sudo apt-get upgrade -y
}
. ~/bootstrap-os/common/common_setup.ps1 -NoPackages
. ~/bootstrap-os/common/functions/functions.ps1
AddorUpdateModule Posh-Git

# Link PowerShell Profile
if (!(Test-Path $Profile)) {
    New-Item -ItemType symboliclink -Path $Profile -Target $profileTemplate -Force | Select-Object -ExpandProperty Name
}

# Create SSH keypair
if (!(Test-Path ~/.ssh/id_rsa)) {
    # pwsh doesn't let me create an empty passphrase
    bash -c "ssh-keygen -q -m PEM -N '' -f ~/.ssh/id_rsa"
}
