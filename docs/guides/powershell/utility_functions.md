# Fonctions Utilitaires PowerShell

Ce document contient des fonctions utilitaires PowerShell couramment utilisées dans le projet.

## Table des matières

- [Gestion des fichiers](#gestion-des-fichiers)
- [Manipulation de texte](#manipulation-de-texte)
- [Gestion des erreurs](#gestion-des-erreurs)
- [Interaction utilisateur](#interaction-utilisateur)
- [Logging](#logging)
- [Réseau](#réseau)
- [Système](#système)

## Gestion des fichiers

### Get-FileEncoding

Détecte l'encodage d'un fichier.

```powershell
function Get-FileEncoding {
    <#
    .SYNOPSIS
        Détecte l'encodage d'un fichier.
    .DESCRIPTION
        Cette fonction détecte l'encodage d'un fichier en analysant ses premiers octets.
    .PARAMETER Path
        Chemin du fichier à analyser.
    .EXAMPLE
        Get-FileEncoding -Path "C:\Temp\file.txt"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path
    )

    [byte[]]$byte = Get-Content -Path $Path -Encoding Byte -ReadCount 4 -TotalCount 4

    if ($byte[0] -eq 0xef -and $byte[1] -eq 0xbb -and $byte[2] -eq 0xbf) {
        return 'UTF8-BOM'
    }
    elseif ($byte[0] -eq 0xff -and $byte[1] -eq 0xfe -and $byte[2] -eq 0 -and $byte[3] -eq 0) {
        return 'UTF32-LE'
    }
    elseif ($byte[0] -eq 0 -and $byte[1] -eq 0 -and $byte[2] -eq 0xfe -and $byte[3] -eq 0xff) {
        return 'UTF32-BE'
    }
    elseif ($byte[0] -eq 0xff -and $byte[1] -eq 0xfe) {
        return 'UTF16-LE'
    }
    elseif ($byte[0] -eq 0xfe -and $byte[1] -eq 0xff) {
        return 'UTF16-BE'
    }
    else {
        return 'ASCII/UTF8'
    }
}
```

### Convert-FileEncoding

Convertit l'encodage d'un fichier.

```powershell
function Convert-FileEncoding {
    <#
    .SYNOPSIS
        Convertit l'encodage d'un fichier.
    .DESCRIPTION
        Cette fonction convertit l'encodage d'un fichier vers un autre encodage.
    .PARAMETER Path
        Chemin du fichier à convertir.
    .PARAMETER TargetEncoding
        Encodage cible (UTF8, UTF8-BOM, UTF16, UTF16-BE, UTF32, ASCII).
    .PARAMETER BackupPath
        Chemin du dossier de sauvegarde. Si non spécifié, aucune sauvegarde n'est créée.
    .EXAMPLE
        Convert-FileEncoding -Path "C:\Temp\file.txt" -TargetEncoding "UTF8-BOM" -BackupPath "C:\Temp\Backup"
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory=$true, Position=1)]
        [ValidateSet('UTF8', 'UTF8-BOM', 'UTF16', 'UTF16-BE', 'UTF32', 'ASCII')]
        [string]$TargetEncoding,

        [Parameter(Mandatory=$false)]
        [string]$BackupPath
    )

    if (-not (Test-Path -Path $Path)) {
        Write-Error "Le fichier '$Path' n'existe pas."
        return
    }

    # Créer une sauvegarde si demandé
    if ($BackupPath) {
        if (-not (Test-Path -Path $BackupPath)) {
            New-Item -Path $BackupPath -ItemType Directory -Force | Out-Null
        }
        
        $backupFile = Join-Path -Path $BackupPath -ChildPath (Split-Path -Path $Path -Leaf)
        Copy-Item -Path $Path -Destination $backupFile -Force
    }

    # Lire le contenu du fichier
    $content = Get-Content -Path $Path -Raw

    # Déterminer l'encodage cible
    $encoding = switch ($TargetEncoding) {
        'UTF8' { [System.Text.UTF8Encoding]::new($false) }
        'UTF8-BOM' { [System.Text.UTF8Encoding]::new($true) }
        'UTF16' { [System.Text.UnicodeEncoding]::new($false, $false) }
        'UTF16-BE' { [System.Text.UnicodeEncoding]::new($true, $false) }
        'UTF32' { [System.Text.UTF32Encoding]::new($false, $false) }
        'ASCII' { [System.Text.ASCIIEncoding]::new() }
    }

    # Écrire le contenu avec le nouvel encodage
    if ($PSCmdlet.ShouldProcess($Path, "Convertir l'encodage en $TargetEncoding")) {
        [System.IO.File]::WriteAllText($Path, $content, $encoding)
    }
}
```

## Manipulation de texte

### Remove-Diacritics

Supprime les accents et autres signes diacritiques d'une chaîne de caractères.

```powershell
function Remove-Diacritics {
    <#
    .SYNOPSIS
        Supprime les accents et autres signes diacritiques d'une chaîne de caractères.
    .DESCRIPTION
        Cette fonction supprime les accents et autres signes diacritiques d'une chaîne de caractères.
    .PARAMETER String
        Chaîne de caractères à traiter.
    .EXAMPLE
        Remove-Diacritics -String "Voilà un texte accentué"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [string]$String
    )

    $normalized = $String.Normalize([System.Text.NormalizationForm]::FormD)
    $sb = New-Object System.Text.StringBuilder

    for ($i = 0; $i -lt $normalized.Length; $i++) {
        $c = $normalized[$i]
        $category = [System.Globalization.CharUnicodeInfo]::GetUnicodeCategory($c)
        if ($category -ne [System.Globalization.UnicodeCategory]::NonSpacingMark) {
            [void]$sb.Append($c)
        }
    }

    return $sb.ToString().Normalize([System.Text.NormalizationForm]::FormC)
}
```

### Format-Json

Formate une chaîne JSON pour une meilleure lisibilité.

```powershell
function Format-Json {
    <#
    .SYNOPSIS
        Formate une chaîne JSON pour une meilleure lisibilité.
    .DESCRIPTION
        Cette fonction formate une chaîne JSON pour une meilleure lisibilité.
    .PARAMETER Json
        Chaîne JSON à formater.
    .PARAMETER Indentation
        Nombre d'espaces par niveau d'indentation.
    .EXAMPLE
        Format-Json -Json '{"name":"John","age":30}' -Indentation 4
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0, ValueFromPipeline=$true)]
        [string]$Json,

        [Parameter(Mandatory=$false)]
        [int]$Indentation = 4
    )

    $indent = 0
    $result = ""
    $inString = $false

    for ($i = 0; $i -lt $Json.Length; $i++) {
        $char = $Json[$i]
        
        # Gestion des chaînes de caractères
        if ($char -eq '"' -and ($i -eq 0 -or $Json[$i-1] -ne '\')) {
            $inString = -not $inString
            $result += $char
            continue
        }
        
        if ($inString) {
            $result += $char
            continue
        }
        
        # Gestion de l'indentation
        switch ($char) {
            '{' {
                $indent++
                $result += $char + "`n" + (' ' * ($indent * $Indentation))
            }
            '}' {
                $indent--
                $result += "`n" + (' ' * ($indent * $Indentation)) + $char
            }
            '[' {
                $indent++
                $result += $char + "`n" + (' ' * ($indent * $Indentation))
            }
            ']' {
                $indent--
                $result += "`n" + (' ' * ($indent * $Indentation)) + $char
            }
            ',' {
                $result += $char + "`n" + (' ' * ($indent * $Indentation))
            }
            ':' {
                $result += $char + ' '
            }
            default {
                if (-not [char]::IsWhiteSpace($char)) {
                    $result += $char
                }
            }
        }
    }

    return $result
}
```

## Gestion des erreurs

### Invoke-WithRetry

Exécute une commande avec plusieurs tentatives en cas d'échec.

```powershell
function Invoke-WithRetry {
    <#
    .SYNOPSIS
        Exécute une commande avec plusieurs tentatives en cas d'échec.
    .DESCRIPTION
        Cette fonction exécute une commande avec plusieurs tentatives en cas d'échec.
    .PARAMETER ScriptBlock
        Script à exécuter.
    .PARAMETER MaxRetries
        Nombre maximum de tentatives.
    .PARAMETER RetryDelay
        Délai entre les tentatives (en secondes).
    .PARAMETER RetryDelayType
        Type de délai entre les tentatives (Linear, Exponential).
    .EXAMPLE
        Invoke-WithRetry -ScriptBlock { Invoke-RestMethod -Uri "https://api.example.com" } -MaxRetries 3 -RetryDelay 2 -RetryDelayType Exponential
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory=$false)]
        [int]$MaxRetries = 3,

        [Parameter(Mandatory=$false)]
        [int]$RetryDelay = 1,

        [Parameter(Mandatory=$false)]
        [ValidateSet('Linear', 'Exponential')]
        [string]$RetryDelayType = 'Linear'
    )

    $retryCount = 0
    $completed = $false
    $result = $null

    while (-not $completed -and $retryCount -lt $MaxRetries) {
        try {
            $result = & $ScriptBlock
            $completed = $true
        }
        catch {
            $retryCount++
            $exception = $_
            
            if ($retryCount -ge $MaxRetries) {
                Write-Error "Échec après $MaxRetries tentatives. Dernière erreur : $exception"
                throw $exception
            }
            
            $delay = switch ($RetryDelayType) {
                'Linear' { $RetryDelay }
                'Exponential' { [math]::Pow(2, $retryCount - 1) * $RetryDelay }
            }
            
            Write-Warning "Tentative $retryCount/$MaxRetries a échoué. Nouvelle tentative dans $delay secondes. Erreur : $exception"
            Start-Sleep -Seconds $delay
        }
    }

    return $result
}
```

## Interaction utilisateur

### Get-YesNo

Demande une confirmation à l'utilisateur (Oui/Non).

```powershell
function Get-YesNo {
    <#
    .SYNOPSIS
        Demande une confirmation à l'utilisateur (Oui/Non).
    .DESCRIPTION
        Cette fonction demande une confirmation à l'utilisateur et retourne un booléen.
    .PARAMETER Prompt
        Message à afficher à l'utilisateur.
    .PARAMETER DefaultYes
        Indique si la réponse par défaut est Oui.
    .EXAMPLE
        if (Get-YesNo -Prompt "Voulez-vous continuer ?") { ... }
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Prompt,

        [Parameter(Mandatory=$false)]
        [switch]$DefaultYes
    )

    $choices = '&Oui', '&Non'
    $default = if ($DefaultYes) { 0 } else { 1 }
    
    $decision = $Host.UI.PromptForChoice('', $Prompt, $choices, $default)
    
    return $decision -eq 0
}
```

### Show-Menu

Affiche un menu interactif et retourne le choix de l'utilisateur.

```powershell
function Show-Menu {
    <#
    .SYNOPSIS
        Affiche un menu interactif et retourne le choix de l'utilisateur.
    .DESCRIPTION
        Cette fonction affiche un menu interactif et retourne le choix de l'utilisateur.
    .PARAMETER Title
        Titre du menu.
    .PARAMETER Options
        Tableau d'options à afficher.
    .EXAMPLE
        $choice = Show-Menu -Title "Menu principal" -Options @("Option 1", "Option 2", "Quitter")
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Title,

        [Parameter(Mandatory=$true, Position=1)]
        [string[]]$Options
    )

    Write-Host "`n$Title" -ForegroundColor Cyan
    Write-Host "================" -ForegroundColor Cyan

    for ($i = 0; $i -lt $Options.Count; $i++) {
        Write-Host "[$($i+1)] $($Options[$i])"
    }

    Write-Host "`nEntrez votre choix (1-$($Options.Count)) : " -NoNewline
    
    do {
        $choice = Read-Host
        $valid = $choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $Options.Count
        
        if (-not $valid) {
            Write-Host "Choix invalide. Entrez un nombre entre 1 et $($Options.Count) : " -NoNewline -ForegroundColor Red
        }
    } while (-not $valid)

    return [int]$choice
}
```

## Logging

### Write-Log

Écrit un message dans un fichier de log.

```powershell
function Write-Log {
    <#
    .SYNOPSIS
        Écrit un message dans un fichier de log.
    .DESCRIPTION
        Cette fonction écrit un message dans un fichier de log avec un horodatage.
    .PARAMETER Message
        Message à écrire dans le fichier de log.
    .PARAMETER Level
        Niveau de log (INFO, WARNING, ERROR).
    .PARAMETER LogFile
        Chemin du fichier de log.
    .EXAMPLE
        Write-Log -Message "Opération réussie" -Level INFO -LogFile "C:\Logs\script.log"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Message,

        [Parameter(Mandatory=$false)]
        [ValidateSet('INFO', 'WARNING', 'ERROR')]
        [string]$Level = 'INFO',

        [Parameter(Mandatory=$false)]
        [string]$LogFile = ".\script.log"
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"
    
    # Créer le dossier de log si nécessaire
    $logDir = Split-Path -Path $LogFile -Parent
    if ($logDir -and -not (Test-Path -Path $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }
    
    # Afficher le message dans la console
    switch ($Level) {
        'INFO' { Write-Verbose $logMessage }
        'WARNING' { Write-Warning $Message }
        'ERROR' { Write-Error $Message }
    }
    
    # Écrire dans le fichier de log
    Add-Content -Path $LogFile -Value $logMessage
}
```

## Réseau

### Test-Port

Teste si un port est ouvert sur un hôte distant.

```powershell
function Test-Port {
    <#
    .SYNOPSIS
        Teste si un port est ouvert sur un hôte distant.
    .DESCRIPTION
        Cette fonction teste si un port est ouvert sur un hôte distant.
    .PARAMETER ComputerName
        Nom ou adresse IP de l'hôte distant.
    .PARAMETER Port
        Numéro de port à tester.
    .PARAMETER Timeout
        Délai d'attente en millisecondes.
    .EXAMPLE
        Test-Port -ComputerName "server.example.com" -Port 80 -Timeout 1000
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$ComputerName,

        [Parameter(Mandatory=$true, Position=1)]
        [int]$Port,

        [Parameter(Mandatory=$false)]
        [int]$Timeout = 1000
    )

    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $connection = $tcpClient.BeginConnect($ComputerName, $Port, $null, $null)
        $wait = $connection.AsyncWaitHandle.WaitOne($Timeout, $false)
        
        if (-not $wait) {
            $tcpClient.Close()
            return $false
        }
        
        $tcpClient.EndConnect($connection)
        $tcpClient.Close()
        return $true
    }
    catch {
        return $false
    }
}
```

## Système

### Get-DiskSpace

Récupère l'espace disque disponible.

```powershell
function Get-DiskSpace {
    <#
    .SYNOPSIS
        Récupère l'espace disque disponible.
    .DESCRIPTION
        Cette fonction récupère l'espace disque disponible pour un ou plusieurs lecteurs.
    .PARAMETER Drive
        Lettre du lecteur (ex: C, D). Si non spécifié, tous les lecteurs sont analysés.
    .EXAMPLE
        Get-DiskSpace -Drive C
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false, Position=0)]
        [string[]]$Drive
    )

    $drives = if ($Drive) {
        $Drive | ForEach-Object { "$($_):" }
    }
    else {
        Get-PSDrive -PSProvider FileSystem | Select-Object -ExpandProperty Name | ForEach-Object { "$($_):" }
    }

    $result = @()
    
    foreach ($d in $drives) {
        try {
            $driveInfo = Get-PSDrive -Name $d.TrimEnd(':') -PSProvider FileSystem -ErrorAction Stop
            
            $result += [PSCustomObject]@{
                Drive = $d
                TotalSize = [math]::Round($driveInfo.Used / 1GB + $driveInfo.Free / 1GB, 2)
                UsedSpace = [math]::Round($driveInfo.Used / 1GB, 2)
                FreeSpace = [math]::Round($driveInfo.Free / 1GB, 2)
                PercentFree = [math]::Round(($driveInfo.Free / ($driveInfo.Used + $driveInfo.Free)) * 100, 2)
            }
        }
        catch {
            Write-Warning "Impossible de récupérer les informations pour le lecteur $d : $_"
        }
    }

    return $result
}
```

### Get-InstalledSoftware

Récupère la liste des logiciels installés.

```powershell
function Get-InstalledSoftware {
    <#
    .SYNOPSIS
        Récupère la liste des logiciels installés.
    .DESCRIPTION
        Cette fonction récupère la liste des logiciels installés à partir du registre Windows.
    .PARAMETER Name
        Nom du logiciel à rechercher (accepte les caractères génériques).
    .EXAMPLE
        Get-InstalledSoftware -Name "Microsoft*"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$false, Position=0)]
        [string]$Name = "*"
    )

    $uninstallKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
        "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
    )

    $result = @()

    foreach ($key in $uninstallKeys) {
        if (Test-Path -Path $key) {
            $subkeys = Get-ChildItem -Path $key

            foreach ($subkey in $subkeys) {
                $displayName = $subkey.GetValue("DisplayName")
                
                if ($displayName -and $displayName -like $Name) {
                    $result += [PSCustomObject]@{
                        Name = $displayName
                        Version = $subkey.GetValue("DisplayVersion")
                        Publisher = $subkey.GetValue("Publisher")
                        InstallDate = $subkey.GetValue("InstallDate")
                        UninstallString = $subkey.GetValue("UninstallString")
                        RegistryPath = $subkey.PSPath
                    }
                }
            }
        }
    }

    return $result | Sort-Object -Property Name
}
```
