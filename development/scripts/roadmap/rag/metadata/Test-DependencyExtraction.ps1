# Test-DependencyExtraction.ps1
# Script pour tester l'extraction des attributs de dépendances et relations
# Version: 1.0
# Date: 2025-05-15

[CmdletBinding()]
param (
    [Parameter(Mandatory = $false)]
    [string]$RoadmapPath = "projet\roadmaps\plans\plan-dev-v8-RAG-roadmap.md",

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "projet\roadmaps\analysis\dependency-analysis.md",

    [Parameter(Mandatory = $false)]
    [ValidateSet("JSON", "Markdown", "CSV")]
    [string]$OutputFormat = "Markdown"
)

# Importer le script d'extraction des dépendances
$scriptPath = $PSScriptRoot
$dependencyScriptPath = Join-Path -Path $scriptPath -ChildPath "Extract-DependencyAttributes.ps1"

if (-not (Test-Path -Path $dependencyScriptPath)) {
    Write-Error "Le script d'extraction des dépendances n'existe pas: $dependencyScriptPath"
    exit 1
}

# Créer un exemple de contenu pour les tests
function New-TestContent {
    $content = @'
# Test de dépendances

## Section 1

- [ ] **1.1** Tâche 1.1
- [ ] **1.2** Tâche 1.2 #blockedBy:1.1
- [ ] **1.3** Tâche 1.3 dépend de: 1.1, 1.2
- [ ] **1.4** Tâche 1.4 requis pour: 1.5, 1.6
- [ ] **1.5** Tâche 1.5 #dependsOn:1.4
- [ ] **1.6** Tâche 1.6 #required_for:2.1
- [ ] **1.7** Tâche 1.7 #customTag:1.1,1.2 #priority:high

## Section 2

- [ ] **2.1** Tâche 2.1 référence à 1.1 et 1.3
- [ ] **2.2** Tâche 2.2 bloqué par: 2.1
- [ ] **2.3** Tâche 2.3 #depends_on:2.2 #blocked_by:1.7
- [ ] **2.4** Tâche 2.4 #relatedTo:2.3,2.5 #milestone:true
- [ ] **2.5** Tâche 2.5
'@
    return $content
}

# Fonction principale de test
function Test-DependencyExtraction {
    [CmdletBinding()]
    param (
        [string]$RoadmapPath,
        [string]$OutputPath,
        [string]$OutputFormat
    )

    Write-Host "Test d'extraction des dépendances" -ForegroundColor Cyan

    # Vérifier si le chemin de la roadmap est spécifié et existe
    if (-not [string]::IsNullOrEmpty($RoadmapPath) -and (Test-Path -Path $RoadmapPath)) {
        Write-Host "Utilisation de la roadmap réelle: $RoadmapPath" -ForegroundColor Green

        # Charger le contenu du fichier
        try {
            $content = Get-Content -Path $RoadmapPath -Raw -Encoding UTF8

            if ([string]::IsNullOrEmpty($content)) {
                Write-Host "Le fichier est vide ou n'a pas pu être lu correctement." -ForegroundColor Red
                $content = New-TestContent
                Write-Host "Utilisation du contenu de test à la place." -ForegroundColor Yellow
            }
        } catch {
            Write-Host "Erreur lors de la lecture du fichier: $_" -ForegroundColor Red
            $content = New-TestContent
            Write-Host "Utilisation du contenu de test à la place." -ForegroundColor Yellow
        }
    } else {
        Write-Host "Utilisation d'un contenu de test" -ForegroundColor Yellow
        $content = New-TestContent
    }

    # Vérifier que le contenu n'est pas vide
    if ([string]::IsNullOrEmpty($content)) {
        Write-Host "ERREUR: Le contenu est vide." -ForegroundColor Red
        return
    }

    Write-Host "Contenu chargé avec succès. Longueur: $($content.Length) caractères." -ForegroundColor Green

    # Exécuter le script d'extraction des dépendances
    Write-Host "Exécution du script d'extraction des dépendances..." -ForegroundColor Cyan

    try {
        # Charger le script dans la portée actuelle
        . $dependencyScriptPath

        # Vérifier le contenu
        Write-Host "Longueur du contenu: $($content.Length) caractères" -ForegroundColor Cyan
        Write-Host "Début du contenu:" -ForegroundColor Cyan
        Write-Host ($content.Substring(0, [Math]::Min(100, $content.Length)))

        # Exécuter la fonction d'extraction des dépendances
        Write-Host "Exécution de Get-DependencyAttributes..." -ForegroundColor Cyan
        $result = Get-DependencyAttributes -Content $content -OutputFormat $OutputFormat

        # Vérifier si le résultat est null
        if ($null -eq $result) {
            Write-Host "ERREUR: La fonction Get-DependencyAttributes a retourné null" -ForegroundColor Red
            return
        }

        # Enregistrer les résultats si un chemin de sortie est spécifié
        if (-not [string]::IsNullOrEmpty($OutputPath)) {
            $outputDirectory = Split-Path -Path $OutputPath -Parent

            if (-not [string]::IsNullOrEmpty($outputDirectory) -and -not (Test-Path -Path $outputDirectory)) {
                New-Item -Path $outputDirectory -ItemType Directory -Force | Out-Null
            }

            Set-Content -Path $OutputPath -Value $result
            Write-Host "Résultats enregistrés dans $OutputPath" -ForegroundColor Green
        }

        # Afficher un aperçu des résultats
        if ($OutputFormat -eq "Markdown") {
            $previewLines = $result -split "`n" | Select-Object -First 20
            Write-Host "`nAperçu des résultats (20 premières lignes):" -ForegroundColor Cyan
            $previewLines | ForEach-Object { Write-Host $_ }
            Write-Host "..." -ForegroundColor DarkGray
        } elseif ($OutputFormat -eq "CSV") {
            $previewLines = $result -split "`n" | Select-Object -First 5
            Write-Host "`nAperçu des résultats (5 premières lignes):" -ForegroundColor Cyan
            $previewLines | ForEach-Object { Write-Host $_ }
            Write-Host "..." -ForegroundColor DarkGray
        } elseif ($OutputFormat -eq "JSON") {
            Write-Host "`nRésultats générés au format JSON" -ForegroundColor Cyan
        }

        Write-Host "`nTest d'extraction des dépendances terminé avec succès" -ForegroundColor Green
    } catch {
        Write-Host "Erreur lors de l'exécution du script d'extraction des dépendances: $_" -ForegroundColor Red
        exit 1
    }
}

# Exécuter la fonction de test
Test-DependencyExtraction -RoadmapPath $RoadmapPath -OutputPath $OutputPath -OutputFormat $OutputFormat
