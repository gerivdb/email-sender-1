<#
.SYNOPSIS
    Script d'installation et de vérification du module ImportExcel.
.DESCRIPTION
    Ce script vérifie si le module ImportExcel est installé et l'installe si nécessaire.
    Il vérifie également la version du module et propose une mise à jour si une version
    plus récente est disponible.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date de création: 2025-04-23
#>

[CmdletBinding(SupportsShouldProcess=$true)]
param (
    [Parameter(Mandatory=$false)]
    [string]$RequiredVersion = "5.4.5",
    
    [Parameter(Mandatory=$false)]
    [switch]$Force,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet("CurrentUser", "AllUsers")]
    [string]$Scope = "CurrentUser"
)

# Fonction pour la journalisation
function Write-Log {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$Message,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$Level = "Info"
    )
    
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $ForegroundColor = switch ($Level) {
        "Info" { "White" }
        "Warning" { "Yellow" }
        "Error" { "Red" }
        "Success" { "Green" }
        default { "White" }
    }
    
    Write-Host "[$Timestamp] [$Level] $Message" -ForegroundColor $ForegroundColor
}

# Fonction pour vérifier si le module est installé
function Test-ModuleInstalled {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ModuleName
    )
    
    $Module = Get-Module -Name $ModuleName -ListAvailable
    return ($null -ne $Module)
}

# Fonction pour vérifier la version du module
function Get-ModuleVersion {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ModuleName
    )
    
    $Module = Get-Module -Name $ModuleName -ListAvailable
    if ($null -ne $Module) {
        return $Module.Version
    }
    return $null
}

# Fonction pour vérifier si une mise à jour est disponible
function Test-ModuleUpdateAvailable {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ModuleName,
        
        [Parameter(Mandatory=$false)]
        [version]$CurrentVersion
    )
    
    try {
        $OnlineModule = Find-Module -Name $ModuleName -ErrorAction Stop
        if ($null -eq $CurrentVersion) {
            return $true
        }
        
        $OnlineVersion = [version]$OnlineModule.Version
        return $OnlineVersion -gt $CurrentVersion
    }
    catch {
        Write-Log -Message "Impossible de vérifier les mises à jour pour le module $ModuleName : $_" -Level "Warning"
        return $false
    }
}

# Fonction pour installer le module
function Install-RequiredModule {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ModuleName,
        
        [Parameter(Mandatory=$false)]
        [string]$RequiredVersion,
        
        [Parameter(Mandatory=$false)]
        [switch]$Force,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("CurrentUser", "AllUsers")]
        [string]$Scope = "CurrentUser"
    )
    
    $InstallParams = @{
        Name = $ModuleName
        Scope = $Scope
        Force = $Force
    }
    
    if (-not [string]::IsNullOrEmpty($RequiredVersion)) {
        $InstallParams.RequiredVersion = $RequiredVersion
    }
    
    try {
        if ($PSCmdlet.ShouldProcess($ModuleName, "Install module")) {
            Install-Module @InstallParams
            Write-Log -Message "Module $ModuleName installé avec succès" -Level "Success"
            return $true
        }
        return $false
    }
    catch {
        Write-Log -Message "Erreur lors de l'installation du module $ModuleName : $_" -Level "Error"
        return $false
    }
}

# Fonction pour mettre à jour le module
function Update-ExistingModule {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ModuleName,
        
        [Parameter(Mandatory=$false)]
        [switch]$Force,
        
        [Parameter(Mandatory=$false)]
        [ValidateSet("CurrentUser", "AllUsers")]
        [string]$Scope = "CurrentUser"
    )
    
    $UpdateParams = @{
        Name = $ModuleName
        Scope = $Scope
        Force = $Force
    }
    
    try {
        if ($PSCmdlet.ShouldProcess($ModuleName, "Update module")) {
            Update-Module @UpdateParams
            Write-Log -Message "Module $ModuleName mis à jour avec succès" -Level "Success"
            return $true
        }
        return $false
    }
    catch {
        Write-Log -Message "Erreur lors de la mise à jour du module $ModuleName : $_" -Level "Error"
        return $false
    }
}

# Fonction pour tester le module
function Test-ExcelModule {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$ModuleName
    )
    
    try {
        # Importer le module
        Import-Module -Name $ModuleName -ErrorAction Stop
        
        # Créer un fichier Excel de test
        $TestData = @(
            [PSCustomObject]@{
                Name = "Test1"
                Value = 10
            },
            [PSCustomObject]@{
                Name = "Test2"
                Value = 20
            }
        )
        
        $TempFile = [System.IO.Path]::GetTempFileName() + ".xlsx"
        
        # Exporter les données vers Excel
        $TestData | Export-Excel -Path $TempFile -AutoSize -TableName "TestData"
        
        # Vérifier si le fichier a été créé
        $FileExists = Test-Path -Path $TempFile
        
        # Supprimer le fichier de test
        if ($FileExists) {
            Remove-Item -Path $TempFile -Force
        }
        
        if ($FileExists) {
            Write-Log -Message "Test du module $ModuleName réussi" -Level "Success"
            return $true
        }
        else {
            Write-Log -Message "Test du module $ModuleName échoué : le fichier n'a pas été créé" -Level "Error"
            return $false
        }
    }
    catch {
        Write-Log -Message "Erreur lors du test du module $ModuleName : $_" -Level "Error"
        return $false
    }
}

# Vérifier si le module PSGallery est disponible
try {
    $PSGallery = Get-PSRepository -Name "PSGallery" -ErrorAction Stop
    if ($PSGallery.InstallationPolicy -ne "Trusted") {
        if ($PSCmdlet.ShouldProcess("PSGallery", "Set as trusted repository")) {
            Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
            Write-Log -Message "PSGallery défini comme dépôt de confiance" -Level "Info"
        }
    }
}
catch {
    Write-Log -Message "Impossible d'accéder au dépôt PSGallery : $_" -Level "Error"
    exit 1
}

# Vérifier si le module ImportExcel est installé
$ModuleName = "ImportExcel"
$IsInstalled = Test-ModuleInstalled -ModuleName $ModuleName

if ($IsInstalled) {
    $CurrentVersion = Get-ModuleVersion -ModuleName $ModuleName
    Write-Log -Message "Module $ModuleName version $CurrentVersion est déjà installé" -Level "Info"
    
    # Vérifier si une version spécifique est requise
    if (-not [string]::IsNullOrEmpty($RequiredVersion)) {
        $RequiredVersionObj = [version]$RequiredVersion
        
        if ($CurrentVersion -lt $RequiredVersionObj) {
            Write-Log -Message "La version actuelle ($CurrentVersion) est inférieure à la version requise ($RequiredVersion)" -Level "Warning"
            
            $InstallSpecificVersion = Install-RequiredModule -ModuleName $ModuleName -RequiredVersion $RequiredVersion -Force:$Force -Scope $Scope
            if (-not $InstallSpecificVersion) {
                Write-Log -Message "Impossible d'installer la version requise du module $ModuleName" -Level "Error"
                exit 1
            }
        }
        elseif ($CurrentVersion -gt $RequiredVersionObj -and $Force) {
            Write-Log -Message "La version actuelle ($CurrentVersion) est supérieure à la version requise ($RequiredVersion), mais l'installation forcée est demandée" -Level "Warning"
            
            $InstallSpecificVersion = Install-RequiredModule -ModuleName $ModuleName -RequiredVersion $RequiredVersion -Force:$Force -Scope $Scope
            if (-not $InstallSpecificVersion) {
                Write-Log -Message "Impossible d'installer la version requise du module $ModuleName" -Level "Error"
                exit 1
            }
        }
    }
    else {
        # Vérifier si une mise à jour est disponible
        $UpdateAvailable = Test-ModuleUpdateAvailable -ModuleName $ModuleName -CurrentVersion $CurrentVersion
        
        if ($UpdateAvailable) {
            Write-Log -Message "Une mise à jour est disponible pour le module $ModuleName" -Level "Info"
            
            if ($Force -or $PSCmdlet.ShouldContinue("Voulez-vous mettre à jour le module $ModuleName ?", "Mise à jour du module")) {
                $Updated = Update-ExistingModule -ModuleName $ModuleName -Force:$Force -Scope $Scope
                if (-not $Updated) {
                    Write-Log -Message "Impossible de mettre à jour le module $ModuleName" -Level "Warning"
                }
            }
        }
        else {
            Write-Log -Message "Le module $ModuleName est à jour" -Level "Success"
        }
    }
}
else {
    Write-Log -Message "Module $ModuleName n'est pas installé" -Level "Warning"
    
    # Installer le module
    $InstallParams = @{
        ModuleName = $ModuleName
        Force = $Force
        Scope = $Scope
    }
    
    if (-not [string]::IsNullOrEmpty($RequiredVersion)) {
        $InstallParams.RequiredVersion = $RequiredVersion
    }
    
    $Installed = Install-RequiredModule @InstallParams
    
    if (-not $Installed) {
        Write-Log -Message "Impossible d'installer le module $ModuleName" -Level "Error"
        exit 1
    }
}

# Tester le module
$TestResult = Test-ExcelModule -ModuleName $ModuleName

if ($TestResult) {
    Write-Log -Message "Module $ModuleName est correctement installé et fonctionnel" -Level "Success"
    exit 0
}
else {
    Write-Log -Message "Module $ModuleName est installé mais ne fonctionne pas correctement" -Level "Error"
    exit 1
}
