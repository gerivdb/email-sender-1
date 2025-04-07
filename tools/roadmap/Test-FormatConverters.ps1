# Test-FormatConverters.ps1
# Script pour tester les convertisseurs de format

# Importer le module Format-Converters
$ConvertersModule = Join-Path -Path $PSScriptRoot -ChildPath "Format-Converters.psm1"
if (Test-Path -Path $ConvertersModule) {
    Import-Module $ConvertersModule -Force
} else {
    Write-Error "Module Format-Converters non trouve: $ConvertersModule"
    exit 1
}

# Fonction pour tester la conversion depuis un format vers le format roadmap
function Test-ConversionFromFormat {
    param (
        [string]$Format,
        [string]$InputText,
        [string]$ExpectedOutput
    )
    
    Write-Host "Test de conversion depuis $Format" -ForegroundColor Yellow
    
    $result = ConvertFrom-TextFormat -InputText $InputText -Format $Format
    
    Write-Host "Texte d'entree:" -ForegroundColor Cyan
    Write-Host $InputText
    
    Write-Host "Resultat:" -ForegroundColor Cyan
    Write-Host $result
    
    Write-Host "Resultat attendu:" -ForegroundColor Cyan
    Write-Host $ExpectedOutput
    
    if ($result -eq $ExpectedOutput) {
        Write-Host "Test reussi!" -ForegroundColor Green
    } else {
        Write-Host "Test echoue!" -ForegroundColor Red
    }
    
    Write-Host ""
}

# Fonction pour tester la conversion depuis le format roadmap vers un autre format
function Test-ConversionToFormat {
    param (
        [string]$Format,
        [string]$InputText
    )
    
    Write-Host "Test de conversion vers $Format" -ForegroundColor Yellow
    
    $result = ConvertTo-TextFormat -RoadmapText $InputText -Format $Format
    
    Write-Host "Texte d'entree:" -ForegroundColor Cyan
    Write-Host $InputText
    
    Write-Host "Resultat ($Format):" -ForegroundColor Cyan
    Write-Host $result
    
    Write-Host ""
}

# Exemples de texte pour les tests
$markdownText = @"
# Projet de developpement

## Phase 1: Analyse
- Identifier les besoins
- Documenter les cas d'utilisation
- Definir les criteres de succes

## Phase 2: Conception
- Creer les maquettes
- Definir l'architecture
- Choisir les technologies
  - Framework frontend
  - Base de donnees
  - Services backend
"@

$csvText = @"
Task,Level,Priority,TimeEstimate
Analyse,0,False,
Identifier les besoins,1,False,2 jours
Documenter les cas d'utilisation,1,True,3 jours
Definir les criteres de succes,1,False,1 jour
Conception,0,False,
Creer les maquettes,1,False,5 jours
Definir l'architecture,1,True,3 jours
Choisir les technologies,1,False,
Framework frontend,2,False,2 jours
Base de donnees,2,True,1 jour
Services backend,2,False,4 jours
"@

$jsonText = @"
[
  {
    "name": "Analyse",
    "isPhase": true,
    "subtasks": [
      {
        "name": "Identifier les besoins",
        "timeEstimate": "2 jours"
      },
      {
        "name": "Documenter les cas d'utilisation",
        "priority": true,
        "timeEstimate": "3 jours"
      },
      {
        "name": "Definir les criteres de succes",
        "timeEstimate": "1 jour"
      }
    ]
  },
  {
    "name": "Conception",
    "isPhase": true,
    "subtasks": [
      {
        "name": "Creer les maquettes",
        "timeEstimate": "5 jours"
      },
      {
        "name": "Definir l'architecture",
        "priority": true,
        "timeEstimate": "3 jours"
      },
      {
        "name": "Choisir les technologies",
        "subtasks": [
          {
            "name": "Framework frontend",
            "timeEstimate": "2 jours"
          },
          {
            "name": "Base de donnees",
            "priority": true,
            "timeEstimate": "1 jour"
          },
          {
            "name": "Services backend",
            "timeEstimate": "4 jours"
          }
        ]
      }
    ]
  }
]
"@

$roadmapText = @"
## Test de conversion
**Complexite**: Moyenne
**Temps estime**: 2-3 semaines
**Progression**: 0%

- [ ] **Phase: Analyse**
  - [ ] Identifier les besoins (2 jours)
  - [ ] **Documenter les cas d'utilisation** [PRIORITAIRE] (3 jours)
  - [ ] Definir les criteres de succes (1 jour)
- [ ] **Phase: Conception**
  - [ ] Creer les maquettes (5 jours)
  - [ ] **Definir l'architecture** [PRIORITAIRE] (3 jours)
  - [ ] Choisir les technologies
    - [ ] Framework frontend (2 jours)
    - [ ] **Base de donnees** [PRIORITAIRE] (1 jour)
    - [ ] Services backend (4 jours)
"@

# Tester les conversions depuis differents formats
Test-ConversionFromFormat -Format "Markdown" -InputText $markdownText -ExpectedOutput "Projet de developpement

Phase 1: Analyse
Identifier les besoins
Documenter les cas d'utilisation
Definir les criteres de succes

Phase 2: Conception
Creer les maquettes
Definir l'architecture
Choisir les technologies
  Framework frontend
  Base de donnees
  Services backend"

Test-ConversionFromFormat -Format "CSV" -InputText $csvText -ExpectedOutput "Analyse
  Identifier les besoins (2 jours)
  Documenter les cas d'utilisation prioritaire (3 jours)
  Definir les criteres de succes (1 jour)
Conception
  Creer les maquettes (5 jours)
  Definir l'architecture prioritaire (3 jours)
  Choisir les technologies
    Framework frontend (2 jours)
    Base de donnees prioritaire (1 jour)
    Services backend (4 jours)"

Test-ConversionFromFormat -Format "JSON" -InputText $jsonText -ExpectedOutput "Analyse
  Identifier les besoins (2 jours)
  Documenter les cas d'utilisation prioritaire (3 jours)
  Definir les criteres de succes (1 jour)
Conception
  Creer les maquettes (5 jours)
  Definir l'architecture prioritaire (3 jours)
  Choisir les technologies
    Framework frontend (2 jours)
    Base de donnees prioritaire (1 jour)
    Services backend (4 jours)"

# Tester les conversions vers differents formats
Test-ConversionToFormat -Format "Markdown" -InputText $roadmapText
Test-ConversionToFormat -Format "CSV" -InputText $roadmapText
Test-ConversionToFormat -Format "JSON" -InputText $roadmapText
Test-ConversionToFormat -Format "YAML" -InputText $roadmapText
