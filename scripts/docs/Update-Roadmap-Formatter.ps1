


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
# Update-Roadmap-Formatter.ps1
# Script pour mettre a jour la roadmap avec les ameliorations du formateur de texte

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
- [x] Ameliorer la detection des phases - *Termine le $(Get-Date -Format "dd/MM/yyyy")*
  - [x] Ajouter la detection des titres en majuscules suivis de ":"
  - [x] Ajouter la detection des titres en majuscules suivis d'un chiffre
  - [x] Ajouter la detection des titres commencant par des symboles de titre (#, ##, ###)
- [x] Ajouter le support pour les estimations de temps pour les taches individuelles - *Termine le $(Get-Date -Format "dd/MM/yyyy")*
  - [x] Detecter les estimations de temps au format (Xh), (X jours), etc.
  - [x] Afficher les estimations de temps apres le nom de la tache
  - [x] Supporter differentes unites de temps (heures, jours, semaines, mois)
- [x] Ajouter le support pour les taches prioritaires - *Termine le $(Get-Date -Format "dd/MM/yyyy")*
  - [x] Detecter les taches marquees comme prioritaires
  - [x] Mettre en evidence les taches prioritaires dans la roadmap
  - [x] Supporter differentes notations de priorite (prioritaire, urgent, important, !, *)
- [x] Ameliorer l'interface utilisateur - *Termine le $(Get-Date -Format "dd/MM/yyyy")*
  - [x] Creer une interface utilisateur plus conviviale
  - [x] Ajouter une section d'aide et d'exemples
  - [x] Ajouter la possibilite de copier le texte formate dans le presse-papiers
  - [x] Ameliorer la mise en page et les couleurs
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

Write-Host "La roadmap a ete mise a jour avec les ameliorations du formateur de texte" -ForegroundColor Green

}
catch {
    Write-Log -Level ERROR -Message "Une erreur critique s'est produite: $_"
    exit 1
}
finally {
    # Nettoyage final
    Write-Log -Level INFO -Message "Exécution du script terminée."
}
