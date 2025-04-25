<#
.SYNOPSIS
    Effectue des substitutions automatiques pour les caractères problématiques dans les fichiers.

.DESCRIPTION
    Ce script analyse les fichiers et remplace automatiquement les caractères qui peuvent causer des problèmes
    dans certains environnements ou avec certains outils. Il peut remplacer les caractères spéciaux, les espaces
    dans les noms de fichiers, et d'autres caractères problématiques.

.PARAMETER Path
    Chemin du fichier ou du dossier à traiter. Si un dossier est spécifié, tous les fichiers correspondant
    au filtre seront traités.

.PARAMETER Filter
    Filtre pour les fichiers à traiter. Par défaut, tous les fichiers sont traités.

.PARAMETER Recurse
    Si spécifié, les sous-dossiers seront également traités.

.PARAMETER RenameFiles
    Si spécifié, les noms de fichiers contenant des caractères problématiques seront également renommés.

.PARAMETER SubstituteInContent
    Si spécifié, les caractères problématiques dans le contenu des fichiers seront remplacés.

.PARAMETER CreateBackup
    Si spécifié, une copie de sauvegarde des fichiers originaux sera créée avant la substitution.

.PARAMETER BackupExtension
    Extension à ajouter aux fichiers de sauvegarde. Par défaut, ".bak".

.PARAMETER CustomReplacements
    Table de hachage contenant des paires clé-valeur pour des remplacements personnalisés.
    Par exemple: @{"é"="e"; "à"="a"; "ç"="c"}

.EXAMPLE
    .\CharacterSubstitution.ps1 -Path "C:\Scripts" -Filter "*.ps1" -Recurse -SubstituteInContent

.NOTES
    Auteur: Système d'analyse d'erreurs
    Date de création: 07/04/2025
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

# Table de remplacement par défaut pour les caractères problématiques
$defaultReplacements = @{
    # Caractères accentués
    'à' = 'a'; 'á' = 'a'; 'â' = 'a'; 'ã' = 'a'; 'ä' = 'a'; 'å' = 'a'; 'æ' = 'ae'
    'ç' = 'c'; 'č' = 'c'
    'è' = 'e'; 'é' = 'e'; 'ê' = 'e'; 'ë' = 'e'; 'ē' = 'e'; 'ė' = 'e'; 'ę' = 'e'
    'ì' = 'i'; 'í' = 'i'; 'î' = 'i'; 'ï' = 'i'; 'ī' = 'i'; 'į' = 'i'
    'ñ' = 'n'; 'ń' = 'n'
    'ò' = 'o'; 'ó' = 'o'; 'ô' = 'o'; 'õ' = 'o'; 'ö' = 'o'; 'ø' = 'o'; 'ō' = 'o'; 'œ' = 'oe'
    'ù' = 'u'; 'ú' = 'u'; 'û' = 'u'; 'ü' = 'u'; 'ū' = 'u'
    'ý' = 'y'; 'ÿ' = 'y'
    'ß' = 'ss'
    'Þ' = 'th'
    'À' = 'A'; 'Á' = 'A'; 'Â' = 'A'; 'Ã' = 'A'; 'Ä' = 'A'; 'Å' = 'A'; 'Æ' = 'AE'
    'Ç' = 'C'; 'Č' = 'C'
    'È' = 'E'; 'É' = 'E'; 'Ê' = 'E'; 'Ë' = 'E'; 'Ē' = 'E'; 'Ė' = 'E'; 'Ę' = 'E'
    'Ì' = 'I'; 'Í' = 'I'; 'Î' = 'I'; 'Ï' = 'I'; 'Ī' = 'I'; 'Į' = 'I'
    'Ñ' = 'N'; 'Ń' = 'N'
    'Ò' = 'O'; 'Ó' = 'O'; 'Ô' = 'O'; 'Õ' = 'O'; 'Ö' = 'O'; 'Ø' = 'O'; 'Ō' = 'O'; 'Œ' = 'OE'
    'Ù' = 'U'; 'Ú' = 'U'; 'Û' = 'U'; 'Ü' = 'U'; 'Ū' = 'U'
    'Ý' = 'Y'; 'Ÿ' = 'Y'
    
    # Caractères spéciaux
    '«' = '"'; '»' = '"'; '„' = '"'; '"' = '"'; '"' = '"'
    ''' = "'"; ''' = "'"
    '€' = 'EUR'; '£' = 'GBP'; '¥' = 'JPY'
    '©' = '(c)'; '®' = '(r)'; '™' = '(tm)'
    '°' = 'deg'
    '±' = '+/-'
    '×' = 'x'
    '÷' = '/'
    '…' = '...'
    '•' = '*'
    '·' = '-'
    '¿' = '?'
    '¡' = '!'
    '¼' = '1/4'; '½' = '1/2'; '¾' = '3/4'
    
    # Caractères problématiques dans les noms de fichiers
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
    
    # Autres caractères problématiques
    '`' = ''
    '$' = 'S'
    '^' = ''
    '&' = 'and'
    '#' = 'num'
    '@' = 'at'
    '!' = ''
    '~' = '-'
}

# Fusionner les remplacements par défaut avec les remplacements personnalisés
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
    
    # Méthode de secours si EncodingDetector.ps1 n'est pas disponible
    try {
        $bytes = [System.IO.File]::ReadAllBytes($FilePath)
        
        # Vérifier les différents BOM
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
            # Si aucun BOM n'est détecté, supposer UTF-8 sans BOM
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
        Write-Error "Erreur lors de la détection de l'encodage pour le fichier '$FilePath': $_"
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
        # Créer une sauvegarde si demandé
        if ($CreateBackup) {
            $backupPath = "$FilePath$BackupExtension"
            Copy-Item -Path $FilePath -Destination $backupPath -Force
            Write-Verbose "Sauvegarde créée: $backupPath"
        }
        
        # Obtenir l'encodage du fichier
        $encodingInfo = Get-FileEncodingInfo -FilePath $FilePath
        
        if ($null -eq $encodingInfo) {
            Write-Error "Impossible de déterminer l'encodage du fichier '$FilePath'."
            return $false
        }
        
        # Lire le contenu du fichier
        $content = [System.IO.File]::ReadAllText($FilePath, $encodingInfo.EncodingObj)
        
        # Compter les caractères problématiques avant substitution
        $problematicCharsCount = 0
        foreach ($char in $Replacements.Keys) {
            $problematicCharsCount += ($content.ToCharArray() | Where-Object { $_ -eq $char }).Count
        }
        
        if ($problematicCharsCount -eq 0) {
            Write-Verbose "Aucun caractère problématique trouvé dans le fichier '$FilePath'."
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
        
        # Écrire le contenu modifié dans le fichier
        [System.IO.File]::WriteAllText($FilePath, $newContent, $encodingInfo.EncodingObj)
        
        Write-Verbose "Caractères problématiques remplacés dans le fichier '$FilePath'. ($problematicCharsCount caractères remplacés)"
        
        return [PSCustomObject]@{
            FilePath = $FilePath
            Success = $true
            CharactersReplaced = $problematicCharsCount
            NeedsReplacement = $true
        }
    }
    catch {
        Write-Error "Erreur lors de la substitution des caractères dans le fichier '$FilePath': $_"
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
        
        # Vérifier si le nom de fichier contient des caractères problématiques
        $needsRenaming = $false
        foreach ($char in $Replacements.Keys) {
            if ($fileName.Contains($char)) {
                $needsRenaming = $true
                break
            }
        }
        
        if (-not $needsRenaming) {
            Write-Verbose "Le nom de fichier '$fileName' ne contient pas de caractères problématiques."
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
        
        # Vérifier si le nouveau chemin existe déjà
        if (Test-Path -Path $newFilePath -PathType Leaf) {
            Write-Warning "Le fichier '$newFilePath' existe déjà. Génération d'un nom unique."
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
        
        Write-Verbose "Fichier renommé: '$fileName' -> '$newFileName'"
        
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
    
    # Vérifier si le chemin existe
    if (-not (Test-Path -Path $Path)) {
        Write-Error "Le chemin '$Path' n'existe pas."
        return
    }
    
    # Déterminer si le chemin est un fichier ou un dossier
    $isFile = Test-Path -Path $Path -PathType Leaf
    
    # Obtenir la liste des fichiers à traiter
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
    
    Write-Host "Traitement de $totalFiles fichiers pour la substitution de caractères..."
    
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
        
        # Renommer le fichier si nécessaire
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
                
                # Mettre à jour le chemin du fichier pour les opérations suivantes
                $file = Get-Item -Path $renameResult.NewPath
            }
        }
        
        # Substituer les caractères dans le contenu si nécessaire
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
    
    # Afficher le résumé
    Write-Host "`nRésumé de la substitution de caractères:"
    Write-Host "  Total des fichiers traités: $totalFiles"
    Write-Host "  Fichiers renommés: $renamedFiles"
    Write-Host "  Fichiers avec contenu modifié: $contentModifiedFiles"
    Write-Host "  Fichiers ignorés (aucune modification nécessaire): $skippedFiles"
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

# Exécution principale
$result = Process-Files -Path $Path -Filter $Filter -Recurse $Recurse.IsPresent -RenameFiles $RenameFiles.IsPresent -SubstituteInContent $SubstituteInContent.IsPresent -CreateBackup $CreateBackup.IsPresent -BackupExtension $BackupExtension -Replacements $replacements

# Retourner le résultat
return $result
