# Télécharger et installer Go
$goVersion = "1.21.5" # Dernière version stable
$downloadUrl = "https://golang.org/dl/go$goVersion.windows-amd64.msi"
$installerPath = "$env:TEMP\go$goVersion.msi"

# Télécharger l'installateur
Invoke-WebRequest -Uri $downloadUrl -OutFile $installerPath

# Installer Go
Start-Process msiexec.exe -ArgumentList "/i `"$installerPath`" /quiet" -Wait

# Configurer les variables d'environnement
$env:GOROOT = "C:\Program Files\Go"
$env:GOPATH = "$env:USERPROFILE\go"
$env:Path += ";$env:GOROOT\bin;$env:GOPATH\bin"

# Rafraîchir les variables d'environnement
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

# Vérifier l'installation
go version