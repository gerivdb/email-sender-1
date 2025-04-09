


# Configuration de la gestion d'erreurs
$ErrorActionPreference = 'Stop'
$Error.Clear()
# Fonction de journalisation
function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"
    
    # Afficher dans la console
    switch ($Level) {
        "INFO" { Write-Host $logEntry -ForegroundColor White }
        "WARNING" { Write-Host $logEntry -ForegroundColor Yellow }
        "ERROR" { Write-Host $logEntry -ForegroundColor Red }
        "DEBUG" { Write-Verbose $logEntry }
    }
    
    # Écrire dans le fichier journal
    try {
        $logDir = Split-Path -Path $PSScriptRoot -Parent
        $logPath = Join-Path -Path $logDir -ChildPath "logs\$(Get-Date -Format 'yyyy-MM-dd').log"
        
        # Créer le répertoire de logs si nécessaire
        $logDirPath = Split-Path -Path $logPath -Parent
        if (-not (Test-Path -Path $logDirPath -PathType Container)) {
            New-Item -Path $logDirPath -ItemType Directory -Force | Out-Null
        }
        
        Add-Content -Path $logPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        # Ignorer les erreurs d'écriture dans le journal
    }
}
try {
    # Script principal
# Update-Roadmap-NewFeatures.ps1
# Script pour mettre a jour la roadmap avec les nouvelles fonctionnalites suggerees

# Chemin de la roadmap
$RoadmapPath = "Roadmap\roadmap_perso.md"""

# Verifier que le fichier roadmap existe
if (-not (Test-Path -Path $RoadmapPath)) {
    Write-Error "Fichier roadmap non trouve: $RoadmapPath"
    exit 1
}

# Lire le contenu de la roadmap
$RoadmapContent = Get-Content -Path $RoadmapPath -Raw

# Diviser le contenu en lignes
$RoadmapLines = $RoadmapContent -split "`r?`n"

# Trouver l'index de la section 2.c
$Section2cIndex = -1
for ($i = 0; $i -lt $RoadmapLines.Count; $i++) {
    if ($RoadmapLines[$i] -match "^## 2\.c") {
        $Section2cIndex = $i
        break
    }
}

if ($Section2cIndex -eq -1) {
    Write-Error "Section 2.c non trouvee dans la roadmap"
    exit 1
}

# Trouver la fin de la section 2.c
$EndOfSection2cIndex = -1
for ($i = $Section2cIndex + 1; $i -lt $RoadmapLines.Count; $i++) {
    if ($RoadmapLines[$i] -match "^## ") {
        $EndOfSection2cIndex = $i - 1
        break
    }
}

if ($EndOfSection2cIndex -eq -1) {
    $EndOfSection2cIndex = $RoadmapLines.Count - 1
}

# Ajouter les nouvelles taches a la section 2.c
$NewTasks = @"
- [ ] Support pour plus de formats (XML, HTML) - *Suggere le $(Get-Date -Format "dd/MM/yyyy")*
  - [ ] **Phase 1: Analyse et conception**
    - [ ] Analyser la structure des formats XML et HTML
    - [ ] Definir les regles de conversion entre ces formats et le format roadmap
    - [ ] Concevoir les algorithmes de conversion
  - [ ] **Phase 2: Implementation des convertisseurs XML**
    - [ ] Developper la fonction de conversion depuis XML
    - [ ] Implementer la detection des elements XML (balises, attributs)
    - [ ] Creer la logique de mappage entre elements XML et taches de roadmap
    - [ ] Developper la fonction de conversion vers XML
    - [ ] Implementer la generation de structure XML a partir des taches
  - [ ] **Phase 3: Implementation des convertisseurs HTML**
    - [ ] Developper la fonction de conversion depuis HTML
    - [ ] Implementer la detection des elements HTML (titres, listes, paragraphes)
    - [ ] Creer la logique de mappage entre elements HTML et taches de roadmap
    - [ ] Developper la fonction de conversion vers HTML
    - [ ] Implementer la generation de structure HTML a partir des taches
    - [ ] Ajouter des options de style CSS pour la sortie HTML
  - [ ] **Phase 4: Integration et tests**
    - [ ] Integrer les nouveaux convertisseurs dans le module Format-Converters
    - [ ] Mettre a jour l'interface utilisateur pour inclure les nouveaux formats
    - [ ] Creer des exemples pour les formats XML et HTML
    - [ ] Developper des tests unitaires pour les nouveaux convertisseurs
    - [ ] Tester les conversions dans differents scenarios
  - [ ] **Phase 5: Documentation et finalisation**
    - [ ] Documenter les nouveaux formats supportes
    - [ ] Mettre a jour le README avec des exemples
    - [ ] Creer des guides d'utilisation pour les nouveaux formats
    - [ ] Optimiser les performances des convertisseurs

- [ ] Amelioration de la detection automatique des formats - *Suggere le $(Get-Date -Format "dd/MM/yyyy")*
  - [ ] **Phase 1: Analyse des problemes actuels**
    - [ ] Identifier les limitations de la detection automatique actuelle
    - [ ] Analyser les cas d'echec de detection
    - [ ] Definir les criteres de detection pour chaque format
  - [ ] **Phase 2: Implementation des ameliorations**
    - [ ] Developper des algorithmes de detection plus robustes
    - [ ] Implementer l'analyse de contenu basee sur des expressions regulieres avancees
    - [ ] Ajouter la detection basee sur les signatures de format (en-tetes, structure)
    - [ ] Creer un systeme de score pour determiner le format le plus probable
    - [ ] Implementer la detection des encodages de caracteres
  - [ ] **Phase 3: Gestion des cas ambigus**
    - [ ] Developper un mecanisme pour gerer les cas ou plusieurs formats sont possibles
    - [ ] Implementer un systeme de confirmation utilisateur pour les cas ambigus
    - [ ] Creer une interface pour afficher les formats detectes avec leur score de confiance
  - [ ] **Phase 4: Tests et validation**
    - [ ] Creer une suite de tests avec des exemples varies
    - [ ] Tester la detection avec des fichiers malformes ou incomplets
    - [ ] Mesurer le taux de reussite de la detection automatique
    - [ ] Optimiser les algorithmes en fonction des resultats
  - [ ] **Phase 5: Integration et documentation**
    - [ ] Integrer le nouveau systeme de detection dans le module Format-Converters
    - [ ] Mettre a jour l'interface utilisateur
    - [ ] Documenter les ameliorations et les limitations
    - [ ] Creer des exemples de cas d'utilisation
"@

# Inserer les nouvelles taches avant la fin de la section 2.c
$NewRoadmapLines = $RoadmapLines[0..$EndOfSection2cIndex]
$NewRoadmapLines += $NewTasks -split "`r?`n"
$NewRoadmapLines += $RoadmapLines[($EndOfSection2cIndex + 1)..($RoadmapLines.Count - 1)]

# Mettre a jour la date de derniere mise a jour
$NewRoadmapContent = $NewRoadmapLines -join "`n"
$NewRoadmapContent = $NewRoadmapContent -replace "\*Derniere mise a jour: .*\*", "*Derniere mise a jour: $(Get-Date -Format "dd/MM/yyyy HH:mm")*"

# Ecrire le contenu mis a jour dans le fichier roadmap
Set-Content -Path $RoadmapPath -Value $NewRoadmapContent

Write-Host "La roadmap a ete mise a jour avec les nouvelles fonctionnalites suggerees" -ForegroundColor Green

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "Exécution du script terminée."
}
