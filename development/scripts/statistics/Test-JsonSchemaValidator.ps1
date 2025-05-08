# Test-JsonSchemaValidator.ps1
# Ce script valide un rapport JSON par rapport à un schéma JSON

# Importer le module Newtonsoft.Json.Schema si disponible, sinon l'installer
function Install-NewtonsoftJsonSchema {
    if (-not (Get-Module -ListAvailable -Name Newtonsoft.Json.Schema)) {
        Write-Host "Le module Newtonsoft.Json.Schema n'est pas installé. Installation en cours..." -ForegroundColor Yellow
        
        # Vérifier si NuGet est disponible
        if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
            Write-Host "Installation du fournisseur de packages NuGet..." -ForegroundColor Yellow
            Install-PackageProvider -Name NuGet -Force -Scope CurrentUser
        }
        
        # Vérifier si le référentiel PSGallery est enregistré
        if (-not (Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue)) {
            Write-Host "Enregistrement du référentiel PSGallery..." -ForegroundColor Yellow
            Register-PSRepository -Default
        }
        
        # Installer le module
        Install-Module -Name Newtonsoft.Json.Schema -Force -Scope CurrentUser
        
        Write-Host "Module Newtonsoft.Json.Schema installé avec succès." -ForegroundColor Green
    }
    
    # Importer le module
    Import-Module Newtonsoft.Json.Schema
}

function Test-JsonAgainstSchema {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$JsonFilePath,
        
        [Parameter(Mandatory = $true)]
        [string]$SchemaFilePath
    )
    
    # Vérifier que les fichiers existent
    if (-not (Test-Path -Path $JsonFilePath)) {
        Write-Error "Le fichier JSON n'existe pas: $JsonFilePath"
        return $false
    }
    
    if (-not (Test-Path -Path $SchemaFilePath)) {
        Write-Error "Le fichier de schéma n'existe pas: $SchemaFilePath"
        return $false
    }
    
    try {
        # Charger le schéma et le JSON
        $schemaContent = Get-Content -Path $SchemaFilePath -Raw
        $jsonContent = Get-Content -Path $JsonFilePath -Raw
        
        # Utiliser .NET pour valider le JSON par rapport au schéma
        Add-Type -AssemblyName System.Web.Extensions
        
        $jsonSerializer = New-Object System.Web.Script.Serialization.JavaScriptSerializer
        $jsonObject = $jsonSerializer.DeserializeObject($jsonContent)
        
        # Validation simple (sans bibliothèque spécifique de validation de schéma)
        $isValid = $true
        $errors = @()
        
        # Vérifier les propriétés requises de premier niveau
        $schemaObject = $jsonSerializer.DeserializeObject($schemaContent)
        $requiredProperties = $schemaObject.required
        
        foreach ($prop in $requiredProperties) {
            if (-not $jsonObject.ContainsKey($prop)) {
                $isValid = $false
                $errors += "Propriété requise manquante: $prop"
            }
        }
        
        # Retourner le résultat
        if ($isValid) {
            Write-Host "Le JSON est conforme au schéma." -ForegroundColor Green
            return $true
        } else {
            Write-Host "Le JSON n'est pas conforme au schéma:" -ForegroundColor Red
            foreach ($error in $errors) {
                Write-Host "- $error" -ForegroundColor Red
            }
            return $false
        }
    } catch {
        Write-Error "Erreur lors de la validation du JSON: $_"
        return $false
    }
}

# Fonction principale pour tester la validation du schéma
function Test-AsymmetryJsonSchema {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$ReportsFolder = (Join-Path -Path $PSScriptRoot -ChildPath "reports"),
        
        [Parameter(Mandatory = $false)]
        [string]$SchemaPath = (Join-Path -Path $PSScriptRoot -ChildPath "schemas\AsymmetryReportSchema.json")
    )
    
    # Créer le dossier de rapports s'il n'existe pas
    if (-not (Test-Path -Path $ReportsFolder)) {
        New-Item -Path $ReportsFolder -ItemType Directory | Out-Null
    }
    
    # Importer le module TailSlopeAsymmetry
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "TailSlopeAsymmetry.psm1"
    if (-not (Test-Path -Path $modulePath)) {
        Write-Error "Le module TailSlopeAsymmetry.psm1 n'a pas été trouvé: $modulePath"
        return
    }
    
    Import-Module $modulePath -Force
    
    # Générer des données de test
    Write-Host "`n=== Génération des données de test ===" -ForegroundColor Magenta
    
    # Distribution normale
    $normalData = 1..1000 | ForEach-Object { [Math]::Round([System.Random]::new().NextDouble() * 10 - 5, 2) }
    
    # Distribution asymétrique positive
    $positiveSkewData = 1..1000 | ForEach-Object { 
        $value = [Math]::Pow([System.Random]::new().NextDouble(), 2) * 10
        [Math]::Round($value, 2)
    }
    
    # Distribution asymétrique négative
    $negativeSkewData = 1..1000 | ForEach-Object { 
        $value = 10 - [Math]::Pow([System.Random]::new().NextDouble(), 2) * 10
        [Math]::Round($value, 2)
    }
    
    Write-Host "Données générées:" -ForegroundColor White
    Write-Host "- Distribution normale: $($normalData.Count) points" -ForegroundColor White
    Write-Host "- Distribution asymétrique positive: $($positiveSkewData.Count) points" -ForegroundColor White
    Write-Host "- Distribution asymétrique négative: $($negativeSkewData.Count) points" -ForegroundColor White
    
    # Générer les rapports JSON
    Write-Host "`n=== Génération des rapports JSON ===" -ForegroundColor Magenta
    
    $normalJsonReportPath = Join-Path -Path $ReportsFolder -ChildPath "normal_report.json"
    $positiveSkewJsonReportPath = Join-Path -Path $ReportsFolder -ChildPath "positive_skew_report.json"
    $negativeSkewJsonReportPath = Join-Path -Path $ReportsFolder -ChildPath "negative_skew_report.json"
    $histogramDataJsonReportPath = Join-Path -Path $ReportsFolder -ChildPath "histogram_data_report.json"
    
    # Générer les rapports
    Get-AsymmetryJsonReport -Data $normalData -Methods @("Slope", "Moments", "Quantiles") -OutputPath $normalJsonReportPath
    Get-AsymmetryJsonReport -Data $positiveSkewData -Methods @("Slope", "Moments", "Quantiles") -OutputPath $positiveSkewJsonReportPath
    Get-AsymmetryJsonReport -Data $negativeSkewData -Methods @("Slope", "Moments", "Quantiles") -OutputPath $negativeSkewJsonReportPath
    Get-AsymmetryJsonReport -Data $positiveSkewData -Methods @("All") -IncludeHistogramData -OutputPath $histogramDataJsonReportPath
    
    Write-Host "Rapports JSON générés:" -ForegroundColor White
    Write-Host "- Rapport pour distribution normale: $normalJsonReportPath" -ForegroundColor White
    Write-Host "- Rapport pour distribution asymétrique positive: $positiveSkewJsonReportPath" -ForegroundColor White
    Write-Host "- Rapport pour distribution asymétrique négative: $negativeSkewJsonReportPath" -ForegroundColor White
    Write-Host "- Rapport avec données d'histogramme: $histogramDataJsonReportPath" -ForegroundColor White
    
    # Valider les rapports par rapport au schéma
    Write-Host "`n=== Validation des rapports JSON par rapport au schéma ===" -ForegroundColor Magenta
    
    $normalValid = Test-JsonAgainstSchema -JsonFilePath $normalJsonReportPath -SchemaFilePath $SchemaPath
    $positiveSkewValid = Test-JsonAgainstSchema -JsonFilePath $positiveSkewJsonReportPath -SchemaFilePath $SchemaPath
    $negativeSkewValid = Test-JsonAgainstSchema -JsonFilePath $negativeSkewJsonReportPath -SchemaFilePath $SchemaPath
    $histogramDataValid = Test-JsonAgainstSchema -JsonFilePath $histogramDataJsonReportPath -SchemaFilePath $SchemaPath
    
    # Résumé des tests
    Write-Host "`n=== Résumé des tests ===" -ForegroundColor Cyan
    if ($normalValid -and $positiveSkewValid -and $negativeSkewValid -and $histogramDataValid) {
        Write-Host "Tous les rapports JSON sont conformes au schéma." -ForegroundColor Green
    } else {
        Write-Host "Certains rapports JSON ne sont pas conformes au schéma." -ForegroundColor Red
    }
    
    Write-Host "Les rapports ont été écrits dans le dossier: $ReportsFolder" -ForegroundColor Green
}

# Exécuter le test
Test-AsymmetryJsonSchema
