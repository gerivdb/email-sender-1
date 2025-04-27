<#
.SYNOPSIS
    Effectue des substitutions automatiques pour les caractÃ¨res problÃ©matiques dans les fichiers.

.DESCRIPTION
    Ce script analyse les fichiers et remplace automatiquement les caractÃ¨res qui peuvent causer des problÃ¨mes
    dans certains environnements ou avec certains outils. Il peut remplacer les caractÃ¨res spÃ©ciaux, les espaces
    dans les noms de fichiers, et d'autres caractÃ¨res problÃ©matiques.

.PARAMETER Path
    Chemin du fichier ou du dossier Ã  traiter. Si un dossier est spÃ©cifiÃ©, tous les fichiers correspondant
    au filtre seront traitÃ©s.

.PARAMETER Filter
    Filtre pour les fichiers Ã  traiter. Par dÃ©faut, tous les fichiers sont traitÃ©s.

.PARAMETER Recurse
    Si spÃ©cifiÃ©, les sous-dossiers seront Ã©galement traitÃ©s.

.PARAMETER RenameFiles
    Si spÃ©cifiÃ©, les noms de fichiers contenant des caractÃ¨res problÃ©matiques seront Ã©galement renommÃ©s.

.PARAMETER SubstituteInContent
    Si spÃ©cifiÃ©, les caractÃ¨res problÃ©matiques dans le contenu des fichiers seront remplacÃ©s.

.PARAMETER CreateBackup
    Si spÃ©cifiÃ©, une copie de sauvegarde des fichiers originaux sera crÃ©Ã©e avant la substitution.

.PARAMETER BackupExtension
    Extension Ã  ajouter aux fichiers de sauvegarde. Par dÃ©faut, ".bak".

.PARAMETER CustomReplacements
    Table de hachage contenant des paires clÃ©-valeur pour des remplacements personnalisÃ©s.
    Par exemple: @{"Ã©"="e"; "Ã "="a"; "Ã§"="c"}

.EXAMPLE
    .\CharacterSubstitution.ps1 -Path "C:\Scripts" -Filter "*.ps1" -Recurse -SubstituteInContent

.NOTES
    Auteur: SystÃ¨me d'analyse d'erreurs
    Date de crÃ©ation: 07/04/2025
    Version: 1.0
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$Path,
    
    [Parameter(Mandatory = $false)]
    [string]$Filter = "*.*",
    
    [Parameter(Mandatory = $false)]
    [switch]$Recurse,
    
    [Parameter(Mandatory = $false)]
    [switch]$RenameFiles,
    
    [Parameter(Mandatory = $false)]
    [switch]$SubstituteInContent,
    
    [Parameter(Mandatory = $false)]
    [switch]$CreateBackup,
    
    [Parameter(Mandatory = $false)]
    [string]$BackupExtension = ".bak",
    
    [Parameter(Mandatory = $false)]
    [hashtable]$CustomReplacements = @{}
)

# Table de remplacement par dÃ©faut pour les caractÃ¨res problÃ©matiques
$defaultReplacements = @{
    # CaractÃ¨res accentuÃ©s
    'Ã ' = 'a'; 'Ã¡' = 'a'; 'Ã¢' = 'a'; 'Ã£' = 'a'; 'Ã¤' = 'a'; 'Ã¥' = 'a'; 'Ã¦' = 'ae'
    'Ã§' = 'c'; 'Ä' = 'c'
    'Ã¨' = 'e'; 'Ã©' = 'e'; 'Ãª' = 'e'; 'Ã«' = 'e'; 'Ä“' = 'e'; 'Ä—' = 'e'; 'Ä™' = 'e'
    'Ã¬' = 'i'; 'Ã­' = 'i'; 'Ã®' = 'i'; 'Ã¯' = 'i'; 'Ä«' = 'i'; 'Ä¯' = 'i'
    'Ã±' = 'n'; 'Å„' = 'n'
    'Ã²' = 'o'; 'Ã³' = 'o'; 'Ã´' = 'o'; 'Ãµ' = 'o'; 'Ã¶' = 'o'; 'Ã¸' = 'o'; 'Å' = 'o'; 'Å“' = 'oe'
    'Ã¹' = 'u'; 'Ãº' = 'u'; 'Ã»' = 'u'; 'Ã¼' = 'u'; 'Å«' = 'u'
    'Ã½' = 'y'; 'Ã¿' = 'y'
    'ÃŸ' = 'ss'
    'Ãž' = 'th'
    'Ã€' = 'A'; 'Ã' = 'A'; 'Ã‚' = 'A'; 'Ãƒ' = 'A'; 'Ã„' = 'A'; 'Ã…' = 'A'; 'Ã†' = 'AE'
    'Ã‡' = 'C'; 'ÄŒ' = 'C'
    'Ãˆ' = 'E'; 'Ã‰' = 'E'; 'ÃŠ' = 'E'; 'Ã‹' = 'E'; 'Ä’' = 'E'; 'Ä–' = 'E'; 'Ä˜' = 'E'
    'ÃŒ' = 'I'; 'Ã' = 'I'; 'ÃŽ' = 'I'; 'Ã' = 'I'; 'Äª' = 'I'; 'Ä®' = 'I'
    'Ã‘' = 'N'; 'Åƒ' = 'N'
    'Ã’' = 'O'; 'Ã“' = 'O'; 'Ã”' = 'O'; 'Ã•' = 'O'; 'Ã–' = 'O'; 'Ã˜' = 'O'; 'ÅŒ' = 'O'; 'Å’' = 'OE'
    'Ã™' = 'U'; 'Ãš' = 'U'; 'Ã›' = 'U'; 'Ãœ' = 'U'; 'Åª' = 'U'
    'Ã' = 'Y'; 'Å¸' = 'Y'
    
    # CaractÃ¨res spÃ©ciaux
    'Â«' = '"'; 'Â»' = '"'; 'â€ž' = '"'; '"' = '"'; '"' = '"'
    ''' = "'"; ''' = "'"
    'â‚¬' = 'EUR'; 'Â£' = 'GBP'; 'Â¥' = 'JPY'
    'Â©' = '(c)'; 'Â®' = '(r)'; 'â„¢' = '(tm)'
    'Â°' = 'deg'
    'Â±' = '+/-'
    'Ã—' = 'x'
    'Ã·' = '/'
    'â€¦' = '...'
    'â€¢' = '*'
    'Â·' = '-'
    'Â¿' = '?'
    'Â¡' = '!'
    'Â¼' = '1/4'; 'Â½' = '1/2'; 'Â¾' = '3/4'
    
    # CaractÃ¨res problÃ©matiques dans les noms de fichiers
    ' ' = '_'
    '/' = '_'
    '\' = '_'
    ':' = '_'
    '*' = '_'
    '?' = '_'
    '"' = '_'
    '<' = '_'
    '>' = '_'
    '|' = '_'
    
    # Autres caractÃ¨res problÃ©matiques
    '`' = ''
    '$' = 'S'
    '^' = ''
    '&' = 'and'
    '#' = 'num'
    '@' = 'at'
    '!' = ''
    '~' = '-'
}

# Fusionner les remplacements par dÃ©faut avec les remplacements personnalisÃ©s
$replacements = $defaultReplacements.Clone()
foreach ($key in $CustomReplacements.Keys) {
    $replacements[$key] = $CustomReplacements[$key]
}

function Get-FileEncodingInfo {
    param (
        [string]$FilePath
    )
    
    # Utiliser le script EncodingDetector.ps1 s'il est disponible
    $encodingDetectorPath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "EncodingDetector.ps1"
    
    if (Test-Path -Path $encodingDetectorPath -PathType Leaf) {
        return & $encodingDetectorPath -FilePath $FilePath
    }
    
    # MÃ©thode de secours si EncodingDetector.ps1 n'est pas disponible
    try {
        $bytes = [System.IO.File]::ReadAllBytes($FilePath)
        
        # VÃ©rifier les diffÃ©rents BOM
        if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
            $encoding = "UTF-8 with BOM"
            $encodingObj = [System.Text.Encoding]::UTF8
        }
        elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFE -and $bytes[1] -eq 0xFF) {
            $encoding = "UTF-16 BE"
            $encodingObj = [System.Text.Encoding]::BigEndianUnicode
        }
        elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 0xFF -and $bytes[1] -eq 0xFE) {
            if ($bytes.Length -ge 4 -and $bytes[2] -eq 0x00 -and $bytes[3] -eq 0x00) {
                $encoding = "UTF-32 LE"
                $encodingObj = [System.Text.Encoding]::UTF32
            }
            else {
                $encoding = "UTF-16 LE"
                $encodingObj = [System.Text.Encoding]::Unicode
            }
        }
        elseif ($bytes.Length -ge 4 -and $bytes[0] -eq 0x00 -and $bytes[1] -eq 0x00 -and $bytes[2] -eq 0xFE -and $bytes[3] -eq 0xFF) {
            $encoding = "UTF-32 BE"
            $encodingObj = [System.Text.Encoding]::GetEncoding("utf-32BE")
        }
        else {
            # Si aucun BOM n'est dÃ©tectÃ©, supposer UTF-8 sans BOM
            $encoding = "UTF-8 (no BOM)"
            $encodingObj = New-Object System.Text.UTF8Encoding $false
        }
        
        return [PSCustomObject]@{
            FilePath = $FilePath
            Encoding = $encoding
            EncodingObj = $encodingObj
        }
    }
    catch {
        Write-Error "Erreur lors de la dÃ©tection de l'encodage pour le fichier '$FilePath': $_"
        return $null
    }
}

function Substitute-CharactersInContent {
    param (
        [string]$FilePath,
        [hashtable]$Replacements,
        [bool]$CreateBackup,
        [string]$BackupExtension
    )
    
    try {
        # CrÃ©er une sauvegarde si demandÃ©
        if ($CreateBackup) {
            $backupPath = "$FilePath$BackupExtension"
            Copy-Item -Path $FilePath -Destination $backupPath -Force
            Write-Verbose "Sauvegarde crÃ©Ã©e: $backupPath"
        }
        
        # Obtenir l'encodage du fichier
        $encodingInfo = Get-FileEncodingInfo -FilePath $FilePath
        
        if ($null -eq $encodingInfo) {
            Write-Error "Impossible de dÃ©terminer l'encodage du fichier '$FilePath'."
            return $false
        }
        
        # Lire le contenu du fichier
        $content = [System.IO.File]::ReadAllText($FilePath, $encodingInfo.EncodingObj)
        
        # Compter les caractÃ¨res problÃ©matiques avant substitution
        $problematicCharsCount = 0
        foreach ($char in $Replacements.Keys) {
            $problematicCharsCount += ($content.ToCharArray() | Where-Object { $_ -eq $char }).Count
        }
        
        if ($problematicCharsCount -eq 0) {
            Write-Verbose "Aucun caractÃ¨re problÃ©matique trouvÃ© dans le fichier '$FilePath'."
            return [PSCustomObject]@{
                FilePath = $FilePath
                Success = $true
                CharactersReplaced = 0
                NeedsReplacement = $false
            }
        }
        
        # Effectuer les remplacements
        $newContent = $content
        foreach ($char in $Replacements.Keys) {
            $newContent = $newContent.Replace($char, $Replacements[$char])
        }
        
        # Ã‰crire le contenu modifiÃ© dans le fichier
        [System.IO.File]::WriteAllText($FilePath, $newContent, $encodingInfo.EncodingObj)
        
        Write-Verbose "CaractÃ¨res problÃ©matiques remplacÃ©s dans le fichier '$FilePath'. ($problematicCharsCount caractÃ¨res remplacÃ©s)"
        
        return [PSCustomObject]@{
            FilePath = $FilePath
            Success = $true
            CharactersReplaced = $problematicCharsCount
            NeedsReplacement = $true
        }
    }
    catch {
        Write-Error "Erreur lors de la substitution des caractÃ¨res dans le fichier '$FilePath': $_"
        return [PSCustomObject]@{
            FilePath = $FilePath
            Success = $false
            CharactersReplaced = 0
            NeedsReplacement = $true
            Error = $_.Exception.Message
        }
    }
}

function Rename-FileWithSubstitution {
    param (
        [string]$FilePath,
        [hashtable]$Replacements
    )
    
    try {
        $directory = [System.IO.Path]::GetDirectoryName($FilePath)
        $fileName = [System.IO.Path]::GetFileName($FilePath)
        
        # VÃ©rifier si le nom de fichier contient des caractÃ¨res problÃ©matiques
        $needsRenaming = $false
        foreach ($char in $Replacements.Keys) {
            if ($fileName.Contains($char)) {
                $needsRenaming = $true
                break
            }
        }
        
        if (-not $needsRenaming) {
            Write-Verbose "Le nom de fichier '$fileName' ne contient pas de caractÃ¨res problÃ©matiques."
            return [PSCustomObject]@{
                OriginalPath = $FilePath
                NewPath = $FilePath
                Success = $true
                NeedsRenaming = $false
            }
        }
        
        # Effectuer les remplacements dans le nom de fichier
        $newFileName = $fileName
        foreach ($char in $Replacements.Keys) {
            $newFileName = $newFileName.Replace($char, $Replacements[$char])
        }
        
        # Construire le nouveau chemin complet
        $newFilePath = Join-Path -Path $directory -ChildPath $newFileName
        
        # VÃ©rifier si le nouveau chemin existe dÃ©jÃ 
        if (Test-Path -Path $newFilePath -PathType Leaf) {
            Write-Warning "Le fichier '$newFilePath' existe dÃ©jÃ . GÃ©nÃ©ration d'un nom unique."
            $fileNameWithoutExt = [System.IO.Path]::GetFileNameWithoutExtension($newFileName)
            $fileExt = [System.IO.Path]::GetExtension($newFileName)
            $counter = 1
            
            do {
                $newFileName = "$fileNameWithoutExt($counter)$fileExt"
                $newFilePath = Join-Path -Path $directory -ChildPath $newFileName
                $counter++
            } while (Test-Path -Path $newFilePath -PathType Leaf)
        }
        
        # Renommer le fichier
        Rename-Item -Path $FilePath -NewName $newFileName
        
        Write-Verbose "Fichier renommÃ©: '$fileName' -> '$newFileName'"
        
        return [PSCustomObject]@{
            OriginalPath = $FilePath
            NewPath = $newFilePath
            Success = $true
            NeedsRenaming = $true
        }
    }
    catch {
        Write-Error "Erreur lors du renommage du fichier '$FilePath': $_"
        return [PSCustomObject]@{
            OriginalPath = $FilePath
            NewPath = $FilePath
            Success = $false
            NeedsRenaming = $true
            Error = $_.Exception.Message
        }
    }
}

function Process-Files {
    param (
        [string]$Path,
        [string]$Filter,
        [bool]$Recurse,
        [bool]$RenameFiles,
        [bool]$SubstituteInContent,
        [bool]$CreateBackup,
        [string]$BackupExtension,
        [hashtable]$Replacements
    )
    
    # VÃ©rifier si le chemin existe
    if (-not (Test-Path -Path $Path)) {
        Write-Error "Le chemin '$Path' n'existe pas."
        return
    }
    
    # DÃ©terminer si le chemin est un fichier ou un dossier
    $isFile = Test-Path -Path $Path -PathType Leaf
    
    # Obtenir la liste des fichiers Ã  traiter
    $files = if ($isFile) {
        Get-Item -Path $Path
    }
    else {
        Get-ChildItem -Path $Path -Filter $Filter -File -Recurse:$Recurse
    }
    
    $totalFiles = $files.Count
    $renamedFiles = 0
    $contentModifiedFiles = 0
    $errorFiles = 0
    $skippedFiles = 0
    
    Write-Host "Traitement de $totalFiles fichiers pour la substitution de caractÃ¨res..."
    
    $results = @()
    
    foreach ($file in $files) {
        Write-Verbose "Traitement du fichier: $($file.FullName)"
        $fileResult = [PSCustomObject]@{
            OriginalPath = $file.FullName
            NewPath = $file.FullName
            ContentModified = $false
            Renamed = $false
            Success = $true
            Error = $null
        }
        
        # Renommer le fichier si nÃ©cessaire
        if ($RenameFiles) {
            $renameResult = Rename-FileWithSubstitution -FilePath $file.FullName -Replacements $Replacements
            
            if (-not $renameResult.Success) {
                $fileResult.Success = $false
                $fileResult.Error = $renameResult.Error
                $errorFiles++
                $results += $fileResult
                continue
            }
            
            if ($renameResult.NeedsRenaming) {
                $fileResult.NewPath = $renameResult.NewPath
                $fileResult.Renamed = $true
                $renamedFiles++
                
                # Mettre Ã  jour le chemin du fichier pour les opÃ©rations suivantes
                $file = Get-Item -Path $renameResult.NewPath
            }
        }
        
        # Substituer les caractÃ¨res dans le contenu si nÃ©cessaire
        if ($SubstituteInContent) {
            $substituteResult = Substitute-CharactersInContent -FilePath $file.FullName -Replacements $Replacements -CreateBackup $CreateBackup -BackupExtension $BackupExtension
            
            if (-not $substituteResult.Success) {
                $fileResult.Success = $false
                $fileResult.Error = $substituteResult.Error
                $errorFiles++
                $results += $fileResult
                continue
            }
            
            if ($substituteResult.NeedsReplacement) {
                $fileResult.ContentModified = $true
                $contentModifiedFiles++
            }
        }
        
        if (-not $fileResult.Renamed -and -not $fileResult.ContentModified) {
            $skippedFiles++
        }
        
        $results += $fileResult
    }
    
    # Afficher le rÃ©sumÃ©
    Write-Host "`nRÃ©sumÃ© de la substitution de caractÃ¨res:"
    Write-Host "  Total des fichiers traitÃ©s: $totalFiles"
    Write-Host "  Fichiers renommÃ©s: $renamedFiles"
    Write-Host "  Fichiers avec contenu modifiÃ©: $contentModifiedFiles"
    Write-Host "  Fichiers ignorÃ©s (aucune modification nÃ©cessaire): $skippedFiles"
    Write-Host "  Fichiers en erreur: $errorFiles"
    
    return [PSCustomObject]@{
        TotalFiles = $totalFiles
        RenamedFiles = $renamedFiles
        ContentModifiedFiles = $contentModifiedFiles
        SkippedFiles = $skippedFiles
        ErrorFiles = $errorFiles
        DetailedResults = $results
    }
}

# ExÃ©cution principale
$result = Process-Files -Path $Path -Filter $Filter -Recurse $Recurse.IsPresent -RenameFiles $RenameFiles.IsPresent -SubstituteInContent $SubstituteInContent.IsPresent -CreateBackup $CreateBackup.IsPresent -BackupExtension $BackupExtension -Replacements $replacements

# Retourner le rÃ©sultat
return $result
