# organize-root-files-secure.ps1
# Plan Dev v41 - Phase 1.1.1.2 - Script Sécurisé avec Protection Multi-Couches
# Version: 2.0 SECURE
# Date: 2025-06-03
# 
# Ce script implémente un système de protection multi-couches pour l'organisation
# sécurisée des fichiers racine du projet EMAIL_SENDER_1

[CmdletBinding()]
param(
    [Parameter(HelpMessage = "Mode simulation uniquement (aucune modification réelle)")]
    [switch]$SimulateOnly,
    
    [Parameter(HelpMessage = "Désactiver la confirmation interactive")]
    [switch]$NoConfirmation,
    
    [Parameter(HelpMessage = "Chemin vers le fichier de configuration de protection")]
    [string]$ConfigPath = ".\projet\security\protection-config.json",
    
    [Parameter(HelpMessage = "Dossier de destination pour les fichiers non essentiels")]
    [string]$TargetFolder = "misc"
)

# Configuration globale du script sécurisé
$ErrorActionPreference = "Stop"
$InformationPreference = "Continue"

# ===== COUCHE 1: INITIALISATION ET VALIDATION =====

function Initialize-SecureEnvironment {
    [CmdletBinding()]
    param()
    
    Write-Information "🔒 INITIALISATION SÉCURISÉE - organize-root-files-secure v2.0"
    Write-Information "Plan Dev v41 - Système de protection multi-couches activé"
    
    # Validation de l'environnement d'exécution
    $scriptPath = $MyInvocation.ScriptName
    if (-not $scriptPath) {
        $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Definition
    }
    
    $projectRoot = Split-Path -Parent $scriptPath
    if (-not (Test-Path $projectRoot)) {
        throw "ERREUR CRITIQUE: Impossible de déterminer la racine du projet"
    }
    
    Write-Information "✅ Racine du projet validée: $projectRoot"
    
    return @{
        ProjectRoot = $projectRoot
        ScriptPath  = $scriptPath
        Timestamp   = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        SessionId   = [System.Guid]::NewGuid().ToString().Substring(0, 8)
    }
}

function Get-ProtectionConfiguration {
    [CmdletBinding()]
    param(
        [string]$ConfigPath,
        [string]$ProjectRoot
    )
    
    Write-Information "📋 Chargement de la configuration de protection..."
    
    # Configuration par défaut basée sur l'audit de sécurité
    $defaultConfig = @{
        # Fichiers critiques - JAMAIS déplacer (Audit: 22 fichiers manquants)
        CriticalFiles        = @{
            System   = @('.gitmodules', '.gitignore', '.git', '.github', '.vscode', '.env', '.env.*')
            Config   = @('package.json', 'go.mod', 'go.sum', 'Makefile', 'docker-compose.yml', 'Dockerfile')
            Security = @('*.key', '*.pem', '*.cert', '*.p12', 'secrets.*', 'credentials.*')
            Build    = @('*.sln', '*.csproj', '*.vcxproj', 'CMakeLists.txt', 'build.gradle', 'pom.xml')
            Scripts  = @('organize-*.ps1', '*.sh', '*.bat', '*.cmd')
            Docs     = @('README.*', 'LICENSE*', 'CHANGELOG.*', 'SECURITY.*')
        }
        
        # Extensions à surveiller
        WatchedExtensions    = @('.ps1', '.sh', '.bat', '.json', '.yml', '.yaml', '.xml', '.md')
        
        # Dossiers interdits d'accès
        ForbiddenDirectories = @('.git', 'node_modules', '.vscode', '.github', 'tools', 'projet')
        
        # Seuils de sécurité
        SecurityThresholds   = @{
            MaxFilesToMove           = 50
            MaxTotalSizeMB           = 100
            RequireConfirmationAbove = 10
        }
    }
    
    # Tentative de chargement du fichier de configuration personnalisé
    $fullConfigPath = Join-Path $ProjectRoot $ConfigPath
    if (Test-Path $fullConfigPath) {
        try {
            $customConfig = Get-Content $fullConfigPath | ConvertFrom-Json -AsHashtable
            Write-Information "✅ Configuration personnalisée chargée: $fullConfigPath"
            
            # Fusion des configurations (priorité à la configuration personnalisée)
            foreach ($key in $customConfig.Keys) {
                $defaultConfig[$key] = $customConfig[$key]
            }
        }
        catch {
            Write-Warning "⚠️  Erreur lors du chargement de la configuration: $_"
            Write-Information "📋 Utilisation de la configuration par défaut"
        }
    }
    else {
        Write-Information "📋 Configuration par défaut utilisée (pas de config personnalisée)"
    }
    
    return $defaultConfig
}

# ===== COUCHE 2: ANALYSE ET CLASSIFICATION DES FICHIERS =====

function Get-FileClassification {
    [CmdletBinding()]
    param(
        [System.IO.FileInfo]$File,
        [hashtable]$ProtectionConfig
    )
    
    $classification = @{
        File        = $File
        IsCritical  = $false
        IsProtected = $false
        Category    = "Unknown"
        Risk        = "Low"
        CanMove     = $true
        Reason      = ""
    }
    
    # Vérification dans chaque catégorie de fichiers critiques
    foreach ($category in $ProtectionConfig.CriticalFiles.Keys) {
        foreach ($pattern in $ProtectionConfig.CriticalFiles[$category]) {
            if ($File.Name -like $pattern -or $File.FullName -like "*$pattern*") {
                $classification.IsCritical = $true
                $classification.IsProtected = $true
                $classification.Category = $category
                $classification.Risk = "Critical"
                $classification.CanMove = $false
                $classification.Reason = "Fichier critique ($category): correspond au motif '$pattern'"
                break
            }
        }
        if ($classification.IsCritical) { break }
    }
    
    # Vérification des extensions surveillées
    if (-not $classification.IsCritical) {
        $extension = $File.Extension
        if ($ProtectionConfig.WatchedExtensions -contains $extension) {
            $classification.IsProtected = $true
            $classification.Category = "WatchedExtension"
            $classification.Risk = "Medium"
            $classification.Reason = "Extension surveillée: $extension"
        }
    }
    
    # Classification par défaut pour les fichiers non protégés
    if (-not $classification.IsProtected) {
        $classification.Category = "Movable"
        $classification.Risk = "Low"
        $classification.Reason = "Fichier non critique, peut être déplacé"
    }
    
    return $classification
}

function Invoke-FileAnalysis {
    [CmdletBinding()]
    param(
        [string]$ProjectRoot,
        [hashtable]$ProtectionConfig
    )
    
    Write-Information "🔍 ANALYSE DES FICHIERS - Couche de protection active"
    
    $analysis = @{
        TotalFiles      = 0
        ProtectedFiles  = @()
        MovableFiles    = @()
        CriticalFiles   = @()
        SuspiciousFiles = @()
        TotalSizeMB     = 0
        Warnings        = @()
    }
    
    try {
        # Récupération sécurisée des fichiers (uniquement racine, pas récursif)
        $allFiles = Get-ChildItem -Path $ProjectRoot -File -ErrorAction Stop
        $analysis.TotalFiles = $allFiles.Count
        
        Write-Information "📊 Analyse de $($analysis.TotalFiles) fichiers dans la racine du projet"
        
        foreach ($file in $allFiles) {
            $classification = Get-FileClassification -File $file -ProtectionConfig $ProtectionConfig
            $fileSizeMB = [math]::Round($file.Length / 1MB, 2)
            $analysis.TotalSizeMB += $fileSizeMB
            
            # Classification et stockage
            switch ($classification.Category) {
                { $_ -in @("System", "Config", "Security", "Build", "Scripts", "Docs") } {
                    $analysis.CriticalFiles += $classification
                    Write-Verbose "🛡️  PROTÉGÉ: $($file.Name) - $($classification.Reason)"
                }
                "WatchedExtension" {
                    $analysis.ProtectedFiles += $classification
                    Write-Verbose "⚠️  SURVEILLÉ: $($file.Name) - $($classification.Reason)"
                }
                "Movable" {
                    $analysis.MovableFiles += $classification
                    Write-Verbose "📦 DÉPLAÇABLE: $($file.Name) - Taille: ${fileSizeMB}MB"
                }
                default {
                    $analysis.SuspiciousFiles += $classification
                    $analysis.Warnings += "Fichier non classifié: $($file.Name)"
                }
            }
            
            # Détection de fichiers suspects (taille importante)
            if ($fileSizeMB -gt 10) {
                $analysis.Warnings += "Fichier volumineux détecté: $($file.Name) (${fileSizeMB}MB)"
            }
        }
        
        Write-Information "✅ Analyse terminée:"
        Write-Information "   🛡️  Fichiers critiques protégés: $($analysis.CriticalFiles.Count)"
        Write-Information "   ⚠️  Fichiers surveillés: $($analysis.ProtectedFiles.Count)"  
        Write-Information "   📦 Fichiers déplaçables: $($analysis.MovableFiles.Count)"
        Write-Information "   ❓ Fichiers suspects: $($analysis.SuspiciousFiles.Count)"
        Write-Information "   📊 Taille totale: $([math]::Round($analysis.TotalSizeMB, 2))MB"
        
    }
    catch {
        throw "ERREUR lors de l'analyse des fichiers: $_"
    }
    
    return $analysis
}

# ===== COUCHE 3: VALIDATION ET SIMULATION =====

function Test-MoveOperationSafety {
    [CmdletBinding()]
    param(
        [array]$FilesToMove,
        [string]$TargetPath,
        [hashtable]$SecurityThresholds
    )
    
    Write-Information "🔒 VALIDATION DE SÉCURITÉ - Contrôle des opérations de déplacement"
    
    $validation = @{
        IsValid  = $true
        Errors   = @()
        Warnings = @()
        Summary  = @{
            FileCount            = $FilesToMove.Count
            TotalSizeMB          = 0
            RequiresConfirmation = $false
        }
    }
    
    # Calcul de la taille totale
    foreach ($fileClass in $FilesToMove) {
        $validation.Summary.TotalSizeMB += [math]::Round($fileClass.File.Length / 1MB, 2)
    }
    
    # Vérification des seuils de sécurité
    if ($validation.Summary.FileCount -gt $SecurityThresholds.MaxFilesToMove) {
        $validation.Errors += "Nombre de fichiers excède le seuil autorisé ($($SecurityThresholds.MaxFilesToMove))"
        $validation.IsValid = $false
    }
    
    if ($validation.Summary.TotalSizeMB -gt $SecurityThresholds.MaxTotalSizeMB) {
        $validation.Errors += "Taille totale excède le seuil autorisé ($($SecurityThresholds.MaxTotalSizeMB)MB)"
        $validation.IsValid = $false
    }
    
    if ($validation.Summary.FileCount -gt $SecurityThresholds.RequireConfirmationAbove) {
        $validation.Summary.RequiresConfirmation = $true
        $validation.Warnings += "Confirmation requise: nombre de fichiers > $($SecurityThresholds.RequireConfirmationAbove)"
    }
    
    # Vérification de l'existence du dossier de destination
    if (-not (Test-Path $TargetPath)) {
        $validation.Warnings += "Le dossier de destination sera créé: $TargetPath"
    }
    
    # Détection de conflits potentiels
    if (Test-Path $TargetPath) {
        $existingFiles = Get-ChildItem -Path $TargetPath -File
        foreach ($fileClass in $FilesToMove) {
            if ($existingFiles.Name -contains $fileClass.File.Name) {
                $validation.Warnings += "Conflit potentiel: $($fileClass.File.Name) existe déjà dans la destination"
            }
        }
    }
    
    Write-Information "📊 Résumé de validation:"
    Write-Information "   📁 Fichiers à déplacer: $($validation.Summary.FileCount)"
    Write-Information "   📏 Taille totale: $([math]::Round($validation.Summary.TotalSizeMB, 2))MB"
    Write-Information "   ✅ Validation: $(if ($validation.IsValid) { 'SUCCÈS' } else { 'ÉCHEC' })"
    Write-Information "   🔔 Confirmation requise: $(if ($validation.Summary.RequiresConfirmation) { 'OUI' } else { 'NON' })"
    
    if ($validation.Errors.Count -gt 0) {
        Write-Warning "❌ Erreurs détectées:"
        $validation.Errors | ForEach-Object { Write-Warning "   $_" }
    }
    
    if ($validation.Warnings.Count -gt 0) {
        Write-Warning "⚠️  Avertissements:"
        $validation.Warnings | ForEach-Object { Write-Warning "   $_" }
    }
    
    return $validation
}

function Invoke-SimulationEngine {
    [CmdletBinding()]
    param(
        [array]$FilesToMove,
        [string]$TargetPath,
        [string]$ProjectRoot
    )
    
    Write-Information "🎮 MOTEUR DE SIMULATION - Test des opérations sans modifications"
    
    $simulation = @{
        Success    = $true
        Operations = @()
        Conflicts  = @()
        Errors     = @()
        Summary    = @{
            TotalOperations   = $FilesToMove.Count
            EstimatedDuration = 0
            RiskLevel         = "Low"
        }
    }
    
    # Vérification de l'intégrité du chemin de destination
    $fullTargetPath = Join-Path $ProjectRoot $TargetPath
    
    foreach ($fileClass in $FilesToMove) {
        $operation = @{
            SourceFile    = $fileClass.File.FullName
            TargetFile    = Join-Path $fullTargetPath $fileClass.File.Name
            Status        = "Pending"
            Risk          = $fileClass.Risk
            EstimatedTime = [math]::Max(1, [math]::Round($fileClass.File.Length / 1MB))
        }
        
        # Simulation des vérifications
        try {
            # Test d'accès en lecture au fichier source
            if (-not (Test-Path $operation.SourceFile -PathType Leaf)) {
                $operation.Status = "Error"
                $simulation.Errors += "Fichier source introuvable: $($fileClass.File.Name)"
                $simulation.Success = $false
                continue
            }
            
            # Test de permissions de lecture
            $acl = Get-Acl $operation.SourceFile -ErrorAction Stop
            if (-not $acl) {
                $operation.Status = "Warning"
                $simulation.Conflicts += "Permissions incertaines: $($fileClass.File.Name)"
            }
            
            # Vérification de conflit de destination
            if (Test-Path $operation.TargetFile) {
                $operation.Status = "Conflict"
                $simulation.Conflicts += "Fichier existe déjà: $($fileClass.File.Name)"
                $simulation.Summary.RiskLevel = "Medium"
            }
            else {
                $operation.Status = "Ready"
            }
            
        }
        catch {
            $operation.Status = "Error"
            $simulation.Errors += "Erreur de simulation pour $($fileClass.File.Name): $_"
            $simulation.Success = $false
        }
        
        $simulation.Operations += $operation
        $simulation.Summary.EstimatedDuration += $operation.EstimatedTime
    }
    
    # Calcul du niveau de risque global
    if ($simulation.Errors.Count -gt 0) {
        $simulation.Summary.RiskLevel = "High"
    }
    elseif ($simulation.Conflicts.Count -gt 2) {
        $simulation.Summary.RiskLevel = "Medium"
    }
    
    Write-Information "🎯 Résultats de simulation:"
    Write-Information "   ✅ Succès: $(if ($simulation.Success) { 'OUI' } else { 'NON' })"
    Write-Information "   ⏱️  Durée estimée: $($simulation.Summary.EstimatedDuration) secondes"
    Write-Information "   🎚️  Niveau de risque: $($simulation.Summary.RiskLevel)"
    Write-Information "   ⚠️  Conflits: $($simulation.Conflicts.Count)"
    Write-Information "   ❌ Erreurs: $($simulation.Errors.Count)"
    
    return $simulation
}# ===== COUCHE 4: INTERFACE UTILISATEUR ET CONFIRMATION =====

function Show-OperationSummary {
    [CmdletBinding()]
    param(
        [hashtable]$Analysis,
        [hashtable]$Validation,
        [hashtable]$Simulation
    )
    
    Write-Host "`n" -NoNewline
    Write-Host "╔════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║                    RÉSUMÉ DE L'OPÉRATION SÉCURISÉE                            ║" -ForegroundColor Green  
    Write-Host "╠════════════════════════════════════════════════════════════════════════════════╣" -ForegroundColor Green
    Write-Host "║ Plan Dev v41 - organize-root-files-secure v2.0                                ║" -ForegroundColor Green
    Write-Host "╚════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
    
    Write-Host "`n🔍 ANALYSE DES FICHIERS:" -ForegroundColor Cyan
    Write-Host "   📁 Total de fichiers analysés: $($Analysis.TotalFiles)" -ForegroundColor White
    Write-Host "   🛡️  Fichiers critiques protégés: $($Analysis.CriticalFiles.Count)" -ForegroundColor Green
    Write-Host "   ⚠️  Fichiers surveillés: $($Analysis.ProtectedFiles.Count)" -ForegroundColor Yellow
    Write-Host "   📦 Fichiers à déplacer: $($Analysis.MovableFiles.Count)" -ForegroundColor Blue
    Write-Host "   📊 Taille totale: $([math]::Round($Analysis.TotalSizeMB, 2))MB" -ForegroundColor White
    
    Write-Host "`n🔒 VALIDATION DE SÉCURITÉ:" -ForegroundColor Cyan
    $validationColor = if ($Validation.IsValid) { "Green" } else { "Red" }
    Write-Host "   ✅ Statut: $(if ($Validation.IsValid) { 'VALIDÉ' } else { 'ÉCHEC' })" -ForegroundColor $validationColor
    Write-Host "   📊 Fichiers à déplacer: $($Validation.Summary.FileCount)" -ForegroundColor White
    Write-Host "   📏 Taille totale: $([math]::Round($Validation.Summary.TotalSizeMB, 2))MB" -ForegroundColor White
    Write-Host "   🔔 Confirmation requise: $(if ($Validation.Summary.RequiresConfirmation) { 'OUI' } else { 'NON' })" -ForegroundColor White
    
    Write-Host "`n🎮 SIMULATION:" -ForegroundColor Cyan
    $simColor = if ($Simulation.Success) { "Green" } else { "Red" }
    Write-Host "   🎯 Succès: $(if ($Simulation.Success) { 'OUI' } else { 'NON' })" -ForegroundColor $simColor
    Write-Host "   ⏱️  Durée estimée: $($Simulation.Summary.EstimatedDuration) secondes" -ForegroundColor White
    Write-Host "   🎚️  Niveau de risque: $($Simulation.Summary.RiskLevel)" -ForegroundColor White
    Write-Host "   ⚠️  Conflits détectés: $($Simulation.Conflicts.Count)" -ForegroundColor $(if ($Simulation.Conflicts.Count -gt 0) { "Yellow" } else { "Green" })
    Write-Host "   ❌ Erreurs détectées: $($Simulation.Errors.Count)" -ForegroundColor $(if ($Simulation.Errors.Count -gt 0) { "Red" } else { "Green" })
    
    if ($Analysis.Warnings.Count -gt 0) {
        Write-Host "`n⚠️  AVERTISSEMENTS:" -ForegroundColor Yellow
        $Analysis.Warnings | ForEach-Object { Write-Host "   • $_" -ForegroundColor Yellow }
    }
    
    if ($Validation.Errors.Count -gt 0) {
        Write-Host "`n❌ ERREURS CRITIQUES:" -ForegroundColor Red
        $Validation.Errors | ForEach-Object { Write-Host "   • $_" -ForegroundColor Red }
    }
}

function Request-UserConfirmation {
    [CmdletBinding()]
    param(
        [hashtable]$Analysis,
        [hashtable]$Validation,
        [hashtable]$Simulation,
        [string]$TargetFolder
    )
    
    Show-OperationSummary -Analysis $Analysis -Validation $Validation -Simulation $Simulation
    
    if (-not $Validation.IsValid) {
        Write-Host "`n❌ OPÉRATION BLOQUÉE - Erreurs de validation détectées" -ForegroundColor Red
        Write-Host "   Veuillez corriger les erreurs avant de continuer." -ForegroundColor Red
        return $false
    }
    
    if ($Analysis.MovableFiles.Count -eq 0) {
        Write-Host "`n✅ AUCUNE ACTION NÉCESSAIRE - Tous les fichiers sont déjà protégés ou organisés" -ForegroundColor Green
        return $false
    }
    
    Write-Host "`n📋 DÉTAIL DES FICHIERS À DÉPLACER:" -ForegroundColor Cyan
    $Analysis.MovableFiles | Select-Object -First 10 | ForEach-Object {
        $sizeMB = [math]::Round($_.File.Length / 1MB, 2)
        Write-Host "   📄 $($_.File.Name) (${sizeMB}MB)" -ForegroundColor White
    }
    
    if ($Analysis.MovableFiles.Count -gt 10) {
        Write-Host "   ... et $($Analysis.MovableFiles.Count - 10) autres fichiers" -ForegroundColor Gray
    }
    
    Write-Host "`n🎯 DESTINATION: $TargetFolder/" -ForegroundColor Cyan
    
    Write-Host "`n" -NoNewline
    Write-Host "╔════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Magenta
    Write-Host "║                               CONFIRMATION REQUISE                            ║" -ForegroundColor Magenta
    Write-Host "╚════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Magenta
    
    do {
        Write-Host "`nVoulez-vous procéder au déplacement des fichiers? " -ForegroundColor Yellow -NoNewline
        Write-Host "[O]ui / [N]on / [D]étails / [S]imuler : " -ForegroundColor White -NoNewline
        $response = Read-Host
        
        switch ($response.ToUpper()) {
            "O" { 
                Write-Host "✅ Confirmation reçue - Procédure de déplacement autorisée" -ForegroundColor Green
                return $true 
            }
            "N" { 
                Write-Host "❌ Opération annulée par l'utilisateur" -ForegroundColor Red
                return $false 
            }
            "D" {
                Write-Host "`n📋 LISTE COMPLÈTE DES FICHIERS:" -ForegroundColor Cyan
                $Analysis.MovableFiles | ForEach-Object {
                    $sizeMB = [math]::Round($_.File.Length / 1MB, 2)
                    Write-Host "   📄 $($_.File.Name) - ${sizeMB}MB - $($_.Reason)" -ForegroundColor White
                }
            }
            "S" {
                Write-Host "`n🎮 DÉTAILS DE SIMULATION:" -ForegroundColor Cyan
                $Simulation.Operations | ForEach-Object {
                    $statusColor = switch ($_.Status) {
                        "Ready" { "Green" }
                        "Conflict" { "Yellow" }
                        "Error" { "Red" }
                        default { "White" }
                    }
                    Write-Host "   $($_.Status): $(Split-Path $_.SourceFile -Leaf)" -ForegroundColor $statusColor
                }
            }
            default {
                Write-Host "⚠️  Réponse invalide. Veuillez saisir O, N, D ou S." -ForegroundColor Yellow
            }
        }
    } while ($response.ToUpper() -notin @("O", "N"))
    
    return $false
}

# ===== COUCHE 5: EXÉCUTION SÉCURISÉE =====

function Invoke-SecureFileMove {
    [CmdletBinding()]
    param(
        [array]$FilesToMove,
        [string]$TargetPath,
        [string]$SessionId
    )
    
    Write-Information "🚀 EXÉCUTION SÉCURISÉE - Déplacement des fichiers avec protection"
    
    $execution = @{
        Success    = $true
        MovedFiles = @()
        Errors     = @()
        StartTime  = Get-Date
        SessionId  = $SessionId
    }
    
    # Création du dossier de destination avec vérification
    if (-not (Test-Path $TargetPath)) {
        try {
            New-Item -ItemType Directory -Path $TargetPath -Force | Out-Null
            Write-Information "📁 Dossier de destination créé: $TargetPath"
        }
        catch {
            $execution.Errors += "Impossible de créer le dossier de destination: $_"
            $execution.Success = $false
            return $execution
        }
    }
    
    $totalFiles = $FilesToMove.Count
    $currentFile = 0
    
    foreach ($fileClass in $FilesToMove) {
        $currentFile++
        $percentComplete = [math]::Round(($currentFile / $totalFiles) * 100)
        
        Write-Progress -Activity "Déplacement sécurisé des fichiers" -Status "Traitement: $($fileClass.File.Name)" -PercentComplete $percentComplete
        
        $operation = @{
            SourceFile = $fileClass.File.FullName
            TargetFile = Join-Path $TargetPath $fileClass.File.Name
            Status     = "Pending"
            Timestamp  = Get-Date
            Error      = $null
        }
        
        try {
            # Vérification finale de sécurité
            if (-not (Test-Path $operation.SourceFile)) {
                throw "Fichier source introuvable"
            }
            
            # Vérification de conflit
            if (Test-Path $operation.TargetFile) {
                $backupName = "$($fileClass.File.BaseName)_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')$($fileClass.File.Extension)"
                $backupPath = Join-Path $TargetPath $backupName
                Move-Item $operation.TargetFile $backupPath -Force
                Write-Warning "⚠️  Conflit résolu: fichier existant sauvegardé en $backupName"
            }
            
            # Opération de déplacement sécurisée
            Move-Item $operation.SourceFile $operation.TargetFile -ErrorAction Stop
            $operation.Status = "Success"
            
            Write-Information "✅ Déplacé: $($fileClass.File.Name) -> $TargetPath"
            
        }
        catch {
            $operation.Status = "Error"
            $operation.Error = $_.Exception.Message
            $execution.Errors += "Erreur lors du déplacement de $($fileClass.File.Name): $_"
            $execution.Success = $false
            
            Write-Error "❌ Échec: $($fileClass.File.Name) - $_"
        }
        
        $execution.MovedFiles += $operation
    }
    
    Write-Progress -Activity "Déplacement sécurisé des fichiers" -Completed
    
    $execution.EndTime = Get-Date
    $execution.Duration = $execution.EndTime - $execution.StartTime
    
    Write-Information "🏁 Exécution terminée:"
    Write-Information "   ✅ Fichiers déplacés avec succès: $(($execution.MovedFiles | Where-Object { $_.Status -eq 'Success' }).Count)"
    Write-Information "   ❌ Erreurs rencontrées: $($execution.Errors.Count)"
    Write-Information "   ⏱️  Durée totale: $([math]::Round($execution.Duration.TotalSeconds, 2)) secondes"
    
    return $execution
}

# ===== COUCHE 6: LOGGING ET AUDIT =====

function Save-OperationLog {
    [CmdletBinding()]
    param(
        [hashtable]$Environment,
        [hashtable]$Analysis,
        [hashtable]$Validation,
        [hashtable]$Simulation,
        [hashtable]$Execution,
        [bool]$SimulateOnly
    )
    
    $logEntry = @{
        Metadata   = @{
            Timestamp      = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
            SessionId      = $Environment.SessionId
            ScriptVersion  = "organize-root-files-secure v2.0"
            PlanDevVersion = "v41"
            Mode           = if ($SimulateOnly) { "SIMULATION" } else { "EXECUTION" }
            ProjectRoot    = $Environment.ProjectRoot
        }
        
        Analysis   = @{
            TotalFiles             = $Analysis.TotalFiles
            CriticalFilesProtected = $Analysis.CriticalFiles.Count
            MovableFiles           = $Analysis.MovableFiles.Count
            TotalSizeMB            = $Analysis.TotalSizeMB
            WarningsCount          = $Analysis.Warnings.Count
        }
        
        Validation = @{
            IsValid              = $Validation.IsValid
            ErrorsCount          = $Validation.Errors.Count
            RequiredConfirmation = $Validation.Summary.RequiresConfirmation
        }
        
        Simulation = @{
            Success           = $Simulation.Success
            RiskLevel         = $Simulation.Summary.RiskLevel
            ConflictsCount    = $Simulation.Conflicts.Count
            EstimatedDuration = $Simulation.Summary.EstimatedDuration
        }
        
        Execution  = if ($Execution) {
            @{
                Success         = $Execution.Success
                MovedFilesCount = ($Execution.MovedFiles | Where-Object { $_.Status -eq 'Success' }).Count
                ErrorsCount     = $Execution.Errors.Count
                DurationSeconds = if ($Execution.Duration) { [math]::Round($Execution.Duration.TotalSeconds, 2) } else { 0 }
            }
        }
        else { $null }
    }
    
    # Sauvegarde dans le fichier de log
    $logDirectory = Join-Path $Environment.ProjectRoot "projet\security\logs"
    if (-not (Test-Path $logDirectory)) {
        New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null
    }
    
    $logFileName = "operation-log_$($Environment.SessionId)_$(Get-Date -Format 'yyyyMMdd_HHmmss').json"
    $logPath = Join-Path $logDirectory $logFileName
    
    try {
        $logEntry | ConvertTo-Json -Depth 10 | Out-File $logPath -Encoding UTF8
        Write-Information "📝 Log sauvegardé: $logPath"
    }
    catch {
        Write-Warning "⚠️  Impossible de sauvegarder le log: $_"
    }
    
    return $logPath
}

# ===== FONCTION PRINCIPALE =====

function Start-SecureFileOrganization {
    [CmdletBinding()]
    param()
    
    try {
        # Phase 1: Initialisation sécurisée
        $environment = Initialize-SecureEnvironment
        Write-Information "🔧 Environment initialized - Session: $($environment.SessionId)"
        
        # Phase 2: Chargement de la configuration
        $protectionConfig = Get-ProtectionConfiguration -ConfigPath $ConfigPath -ProjectRoot $environment.ProjectRoot
        Write-Information "⚙️  Protection configuration loaded"
        
        # Phase 3: Analyse des fichiers
        $analysis = Invoke-FileAnalysis -ProjectRoot $environment.ProjectRoot -ProtectionConfig $protectionConfig
        Write-Information "🔍 File analysis completed"
        
        # Phase 4: Validation de sécurité
        $targetPath = Join-Path $environment.ProjectRoot $TargetFolder
        $validation = Test-MoveOperationSafety -FilesToMove $analysis.MovableFiles -TargetPath $targetPath -SecurityThresholds $protectionConfig.SecurityThresholds
        Write-Information "🔒 Security validation completed"
        
        # Phase 5: Simulation
        $simulation = Invoke-SimulationEngine -FilesToMove $analysis.MovableFiles -TargetPath $targetPath -ProjectRoot $environment.ProjectRoot
        Write-Information "🎮 Simulation completed"
        
        # Phase 6: Confirmation utilisateur (si nécessaire)
        $userConfirmed = $true
        if (-not $NoConfirmation -and ($validation.Summary.RequiresConfirmation -or $analysis.MovableFiles.Count -gt 0)) {
            $userConfirmed = Request-UserConfirmation -Analysis $analysis -Validation $validation -Simulation $simulation -TargetFolder $TargetFolder
        }
        
        # Phase 7: Exécution ou simulation uniquement
        $execution = $null
        if ($userConfirmed -and -not $SimulateOnly) {
            if ($validation.IsValid) {
                $execution = Invoke-SecureFileMove -FilesToMove $analysis.MovableFiles -TargetPath $targetPath -SessionId $environment.SessionId
                Write-Information "🚀 Secure execution completed"
            }
            else {
                Write-Error "❌ Impossible d'exécuter: échec de validation de sécurité"
                return 1
            }
        }
        elseif ($SimulateOnly) {
            Write-Information "🎮 Mode simulation uniquement - Aucune modification effectuée"
        }
        elseif (-not $userConfirmed) {
            Write-Information "👤 Opération annulée par l'utilisateur"
        }
        
        # Phase 8: Logging et audit
        $logPath = Save-OperationLog -Environment $environment -Analysis $analysis -Validation $validation -Simulation $simulation -Execution $execution -SimulateOnly $SimulateOnly
        Write-Information "📝 Operation logged successfully"
        
        # Résumé final
        Write-Host "`n" -NoNewline
        Write-Host "╔════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║                           OPÉRATION TERMINÉE                                  ║" -ForegroundColor Green
        Write-Host "╚════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green
        
        if ($execution) {
            $successCount = ($execution.MovedFiles | Where-Object { $_.Status -eq 'Success' }).Count
            Write-Host "✅ Fichiers déplacés avec succès: $successCount" -ForegroundColor Green
            if ($execution.Errors.Count -gt 0) {
                Write-Host "❌ Erreurs rencontrées: $($execution.Errors.Count)" -ForegroundColor Red
            }
        }
        elseif ($SimulateOnly) {
            Write-Host "🎮 Simulation terminée - Aucune modification effectuée" -ForegroundColor Blue
        }
        else {
            Write-Host "ℹ️  Aucune action effectuée" -ForegroundColor Yellow
        }
        
        Write-Host "📝 Log de l'opération: $logPath" -ForegroundColor Cyan
        Write-Host "🔒 Session sécurisée: $($environment.SessionId)" -ForegroundColor Cyan
        
        return 0
        
    }
    catch {
        Write-Error "💥 ERREUR CRITIQUE: $_"
        Write-Error "   Session: $($environment.SessionId)"
        Write-Error "   Timestamp: $(Get-Date)"
        return 2
    }
}

# ===== POINT D'ENTRÉE =====

# Affichage de l'en-tête de sécurité
Write-Host "╔════════════════════════════════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "║                  ORGANIZE-ROOT-FILES-SECURE v2.0                              ║" -ForegroundColor Green
Write-Host "║                     Plan Dev v41 - Phase 1.1.1.2                             ║" -ForegroundColor Green
Write-Host "║              Système de Protection Multi-Couches Activé                       ║" -ForegroundColor Green
Write-Host "╚════════════════════════════════════════════════════════════════════════════════╝" -ForegroundColor Green

if ($SimulateOnly) {
    Write-Host "🎮 MODE SIMULATION ACTIVÉ - Aucune modification réelle ne sera effectuée" -ForegroundColor Blue
}

# Exécution du script sécurisé
exit (Start-SecureFileOrganization)