#Requires -Version 5.1
<#
.SYNOPSIS
    Test de débogage pour le module MetricsConfiguration avec une configuration invalide.
.DESCRIPTION
    Ce script teste le comportement du module MetricsConfiguration
    lorsqu'il est confronté à une configuration invalide.
.NOTES
    Version: 1.0
    Auteur: Augment Agent
    Date de création: 2025-05-15
#>

[CmdletBinding()]
param()

# Chemin du module à tester
$modulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\MetricsConfiguration.psm1'

# Vérifier si le module existe
if (-not (Test-Path -Path $modulePath)) {
    throw "Le module MetricsConfiguration.psm1 n'existe pas au chemin spécifié: $modulePath"
}

# Importer le module à tester
Import-Module -Name $modulePath -Force

# Créer un dossier temporaire pour les tests
$tempDir = Join-Path -Path $PSScriptRoot -ChildPath 'temp'
if (-not (Test-Path -Path $tempDir)) {
    New-Item -Path $tempDir -ItemType Directory -Force | Out-Null
    Write-Verbose "Dossier temporaire créé : $tempDir"
}

# Chemin du fichier de configuration de test invalide
$invalidConfigPath = Join-Path -Path $tempDir -ChildPath 'InvalidComplexityMetrics.json'

# Créer une configuration invalide
$invalidConfig = @"
{
  "InvalidRoot": {
    "CyclomaticComplexity": {
      "Enabled": true,
      "Description": "Mesure le nombre de chemins d'exécution indépendants dans une fonction",
      "Thresholds": {
        "Low": {
          "Value": 10,
          "Severity": "Information",
          "Message": "Complexité cyclomatique acceptable"
        }
      }
    }
  }
}
"@

$invalidConfig | Out-File -FilePath $invalidConfigPath -Encoding utf8

# Test 1: Vérifier que la validation de configuration détecte une configuration invalide
Write-Host "Test 1: Vérifier que la validation de configuration détecte une configuration invalide" -ForegroundColor Cyan
$config = Import-ComplexityMetricsConfiguration -ConfigPath $invalidConfigPath
if ($null -eq $config) {
    Write-Host "  Réussi: La configuration invalide a été rejetée" -ForegroundColor Green
} else {
    Write-Host "  Échoué: La configuration invalide a été acceptée" -ForegroundColor Red
}

# Créer une configuration avec une métrique manquante
$missingMetricConfigPath = Join-Path -Path $tempDir -ChildPath 'MissingMetricConfig.json'
$missingMetricConfig = @"
{
  "ComplexityMetrics": {
    "CyclomaticComplexity": {
      "Enabled": true,
      "Description": "Mesure le nombre de chemins d'exécution indépendants dans une fonction",
      "Thresholds": {
        "Low": {
          "Value": 10,
          "Severity": "Information",
          "Message": "Complexité cyclomatique acceptable"
        },
        "Medium": {
          "Value": 20,
          "Severity": "Warning",
          "Message": "Complexité cyclomatique à surveiller"
        },
        "High": {
          "Value": 30,
          "Severity": "Error",
          "Message": "Complexité cyclomatique problématique"
        }
      }
    }
  }
}
"@

$missingMetricConfig | Out-File -FilePath $missingMetricConfigPath -Encoding utf8

# Test 2: Vérifier que la validation de configuration détecte une métrique manquante
Write-Host "Test 2: Vérifier que la validation de configuration détecte une métrique manquante" -ForegroundColor Cyan
$config = Import-ComplexityMetricsConfiguration -ConfigPath $missingMetricConfigPath
if ($null -eq $config) {
    Write-Host "  Réussi: La configuration avec métrique manquante a été rejetée" -ForegroundColor Green
} else {
    Write-Host "  Échoué: La configuration avec métrique manquante a été acceptée" -ForegroundColor Red
}

# Créer une configuration avec un seuil manquant
$missingThresholdConfigPath = Join-Path -Path $tempDir -ChildPath 'MissingThresholdConfig.json'
$missingThresholdConfig = @"
{
  "ComplexityMetrics": {
    "CyclomaticComplexity": {
      "Enabled": true,
      "Description": "Mesure le nombre de chemins d'exécution indépendants dans une fonction",
      "Thresholds": {
        "Low": {
          "Value": 10,
          "Severity": "Information",
          "Message": "Complexité cyclomatique acceptable"
        },
        "Medium": {
          "Value": 20,
          "Severity": "Warning",
          "Message": "Complexité cyclomatique à surveiller"
        }
      }
    },
    "NestingDepth": {
      "Enabled": true,
      "Description": "Mesure le nombre de niveaux de structures de contrôle imbriquées",
      "Thresholds": {
        "Low": {
          "Value": 3,
          "Severity": "Information",
          "Message": "Profondeur d'imbrication acceptable"
        },
        "Medium": {
          "Value": 5,
          "Severity": "Warning",
          "Message": "Profondeur d'imbrication à surveiller"
        }
      }
    },
    "FunctionLength": {
      "Enabled": true,
      "Description": "Mesure le nombre de lignes de code dans une fonction",
      "Thresholds": {
        "Low": {
          "Value": 50,
          "Severity": "Information",
          "Message": "Longueur de fonction acceptable"
        },
        "Medium": {
          "Value": 100,
          "Severity": "Warning",
          "Message": "Longueur de fonction à surveiller"
        },
        "High": {
          "Value": 200,
          "Severity": "Error",
          "Message": "Longueur de fonction problématique"
        }
      }
    },
    "ParameterCount": {
      "Enabled": true,
      "Description": "Mesure le nombre de paramètres d'une fonction",
      "Thresholds": {
        "Low": {
          "Value": 4,
          "Severity": "Information",
          "Message": "Nombre de paramètres acceptable"
        },
        "Medium": {
          "Value": 7,
          "Severity": "Warning",
          "Message": "Nombre de paramètres à surveiller"
        },
        "High": {
          "Value": 10,
          "Severity": "Error",
          "Message": "Nombre de paramètres problématique"
        }
      }
    }
  }
}
"@

$missingThresholdConfig | Out-File -FilePath $missingThresholdConfigPath -Encoding utf8

# Test 3: Vérifier que la validation de configuration détecte un seuil manquant
Write-Host "Test 3: Vérifier que la validation de configuration détecte un seuil manquant" -ForegroundColor Cyan
$config = Import-ComplexityMetricsConfiguration -ConfigPath $missingThresholdConfigPath
if ($null -eq $config) {
    Write-Host "  Réussi: La configuration avec seuil manquant a été rejetée" -ForegroundColor Green
} else {
    Write-Host "  Échoué: La configuration avec seuil manquant a été acceptée" -ForegroundColor Red
}

# Test 4: Vérifier que la fonction Set-ComplexityMetricsThreshold rejette une métrique inexistante
Write-Host "Test 4: Vérifier que la fonction Set-ComplexityMetricsThreshold rejette une métrique inexistante" -ForegroundColor Cyan
$result = Set-ComplexityMetricsThreshold -MetricName "MetriqueInexistante" -ThresholdName "Medium" -Value 42
if (-not $result) {
    Write-Host "  Réussi: La métrique inexistante a été rejetée" -ForegroundColor Green
} else {
    Write-Host "  Échoué: La métrique inexistante a été acceptée" -ForegroundColor Red
}

# Test 5: Vérifier que la fonction Set-ComplexityMetricsThreshold rejette un seuil inexistant
Write-Host "Test 5: Vérifier que la fonction Set-ComplexityMetricsThreshold rejette un seuil inexistant" -ForegroundColor Cyan
$result = Set-ComplexityMetricsThreshold -MetricName "CyclomaticComplexity" -ThresholdName "SeuilInexistant" -Value 42
if (-not $result) {
    Write-Host "  Réussi: Le seuil inexistant a été rejeté" -ForegroundColor Green
} else {
    Write-Host "  Échoué: Le seuil inexistant a été accepté" -ForegroundColor Red
}

# Nettoyer les fichiers temporaires
if (Test-Path -Path $tempDir) {
    Remove-Item -Path $tempDir -Recurse -Force
    Write-Verbose "Dossier temporaire supprimé : $tempDir"
}

Write-Host "`nTests de débogage terminés." -ForegroundColor Yellow
