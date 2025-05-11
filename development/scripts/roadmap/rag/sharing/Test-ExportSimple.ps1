<#
.SYNOPSIS
    Test simple des fonctionnalités d'export pour le partage des vues.

.DESCRIPTION
    Ce script teste les fonctionnalités d'export pour le partage des vues
    avec une approche simplifiée.

.NOTES
    Version:        1.0
    Author:         Augment Agent
    Creation Date:  2025-05-15
#>

#Requires -Version 5.1

# Importer le module ExportManager
$scriptPath = $MyInvocation.MyCommand.Path
$scriptDir = Split-Path -Path $scriptPath -Parent
$exportManagerPath = Join-Path -Path $scriptDir -ChildPath "ExportManager.ps1"

Write-Host "Chargement du module ExportManager depuis: $exportManagerPath"
. $exportManagerPath

# Créer un répertoire de test
$testDir = Join-Path -Path $env:TEMP -ChildPath "ExportTest_$(Get-Date -Format 'yyyyMMddHHmmss')"
New-Item -Path $testDir -ItemType Directory -Force | Out-Null
Write-Host "Répertoire de test créé: $testDir"

# Créer des données de vue de test
$viewId = [guid]::NewGuid().ToString()
$now = Get-Date

$viewData = [PSCustomObject]@{
    Id = $viewId
    Title = "Vue de test pour l'export"
    Type = "RAG_SEARCH_RESULTS"
    Metadata = [PSCustomObject]@{
        Creator = "Utilisateur de test"
        CreatedAt = $now.ToString('o')
        Description = "Cette vue a été créée pour tester les fonctionnalités d'export"
        Tags = @("test", "export", "rag")
        Query = "requête de test"
    }
    Items = @(
        [PSCustomObject]@{
            Id = [guid]::NewGuid().ToString()
            Title = "Premier résultat"
            Content = "Ceci est le contenu du premier résultat de recherche."
            Source = "Source 1"
            Tags = @("important", "prioritaire")
            Score = 0.95
            Metadata = [PSCustomObject]@{
                Type = "document"
                CreatedAt = $now.AddDays(-5).ToString('o')
            }
        },
        [PSCustomObject]@{
            Id = [guid]::NewGuid().ToString()
            Title = "Deuxième résultat"
            Content = "Ceci est le contenu du deuxième résultat de recherche."
            Source = "Source 2"
            Tags = @("secondaire")
            Score = 0.85
            Metadata = [PSCustomObject]@{
                Type = "document"
                CreatedAt = $now.AddDays(-3).ToString('o')
            }
        }
    )
}

Write-Host "Données de vue de test créées avec l'ID: $viewId"

# Créer un gestionnaire d'export
$exportManager = New-ExportManager -ExportStorePath $testDir -EnableDebug
Write-Host "Gestionnaire d'export créé"

# Tester l'export en JSON
try {
    Write-Host "Test d'export en JSON standard..."
    $jsonPath = $exportManager.ExportToJSON($viewData, $false)
    
    if (Test-Path -Path $jsonPath) {
        Write-Host "Vue exportée avec succès en JSON standard: $jsonPath" -ForegroundColor Green
        
        # Vérifier le contenu du fichier
        $jsonContent = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json
        
        if ($jsonContent.Id -eq $viewData.Id) {
            Write-Host "Le contenu du fichier JSON est valide" -ForegroundColor Green
        }
        else {
            Write-Host "Le contenu du fichier JSON n'est pas valide" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Échec de l'export en JSON standard" -ForegroundColor Red
    }
}
catch {
    Write-Host "Erreur lors de l'export en JSON standard: $($_.Exception.Message)" -ForegroundColor Red
}

# Tester l'export en JSON compact
try {
    Write-Host "Test d'export en JSON compact..."
    $jsonCompactPath = $exportManager.ExportToJSON($viewData, $true)
    
    if (Test-Path -Path $jsonCompactPath) {
        Write-Host "Vue exportée avec succès en JSON compact: $jsonCompactPath" -ForegroundColor Green
        
        # Vérifier le contenu du fichier
        $jsonCompactContent = Get-Content -Path $jsonCompactPath -Raw | ConvertFrom-Json
        
        if ($jsonCompactContent.Id -eq $viewData.Id) {
            Write-Host "Le contenu du fichier JSON compact est valide" -ForegroundColor Green
        }
        else {
            Write-Host "Le contenu du fichier JSON compact n'est pas valide" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Échec de l'export en JSON compact" -ForegroundColor Red
    }
}
catch {
    Write-Host "Erreur lors de l'export en JSON compact: $($_.Exception.Message)" -ForegroundColor Red
}

# Tester l'export en URL paramétré
try {
    Write-Host "Test d'export en URL paramétré..."
    $baseURL = "https://example.com/view"
    $urlPath = $exportManager.ExportToURL($viewData, $baseURL)
    
    if (Test-Path -Path $urlPath) {
        Write-Host "Vue exportée avec succès en URL paramétré: $urlPath" -ForegroundColor Green
        
        # Vérifier le contenu du fichier
        $urlContent = Get-Content -Path $urlPath -Raw
        
        if ($urlContent.StartsWith($baseURL)) {
            Write-Host "Le contenu du fichier URL est valide" -ForegroundColor Green
        }
        else {
            Write-Host "Le contenu du fichier URL n'est pas valide" -ForegroundColor Red
        }
    }
    else {
        Write-Host "Échec de l'export en URL paramétré" -ForegroundColor Red
    }
}
catch {
    Write-Host "Erreur lors de l'export en URL paramétré: $($_.Exception.Message)" -ForegroundColor Red
}

# Tester l'export en fichier autonome
try {
    Write-Host "Test d'export en fichier autonome..."
    $templatePath = Join-Path -Path $scriptDir -ChildPath "templates\standalone-template.html"
    
    if (-not (Test-Path -Path $templatePath)) {
        Write-Host "Le template pour le fichier autonome n'existe pas: $templatePath" -ForegroundColor Red
    }
    else {
        $standalonePath = $exportManager.ExportToStandalone($viewData, $templatePath)
        
        if (Test-Path -Path $standalonePath) {
            Write-Host "Vue exportée avec succès en fichier autonome: $standalonePath" -ForegroundColor Green
            
            # Vérifier le contenu du fichier
            $standaloneContent = Get-Content -Path $standalonePath -Raw
            
            if ($standaloneContent.Contains($viewData.Id)) {
                Write-Host "Le contenu du fichier autonome est valide" -ForegroundColor Green
            }
            else {
                Write-Host "Le contenu du fichier autonome n'est pas valide" -ForegroundColor Red
            }
        }
        else {
            Write-Host "Échec de l'export en fichier autonome" -ForegroundColor Red
        }
    }
}
catch {
    Write-Host "Erreur lors de l'export en fichier autonome: $($_.Exception.Message)" -ForegroundColor Red
}

# Tester l'export chiffré
try {
    Write-Host "Test d'export chiffré..."
    $passwordSecure = ConvertTo-SecureString "MotDePasse123!" -AsPlainText -Force
    $encryptedPath = $exportManager.ExportEncrypted($viewData, "JSON", $passwordSecure)
    
    if (Test-Path -Path $encryptedPath) {
        Write-Host "Vue exportée avec succès en fichier chiffré: $encryptedPath" -ForegroundColor Green
    }
    else {
        Write-Host "Échec de l'export en fichier chiffré" -ForegroundColor Red
    }
}
catch {
    Write-Host "Erreur lors de l'export chiffré: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "Tests terminés"

# Nettoyage
Remove-Item -Path $testDir -Recurse -Force -ErrorAction SilentlyContinue
Write-Host "Répertoire de test supprimé: $testDir"
