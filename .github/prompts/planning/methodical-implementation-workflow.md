# 🚀 **Prompt Structuré pour Implémentation Méthodique du Plan-dev-v55**

## 📋 **Structure du Workflow par Section**

### **🔄 DÉBUT DE CHAQUE TÂCHE**

#### **1. Vérification Pré-Tâche**
```bash
# 1.1 Vérifier état des fichiers non suivis
git status --porcelain | Where-Object { $_ -match "^\?\?" } | Measure-Object | ForEach-Object { if ($_.Count -eq 0) { Write-Host "✅ Aucun fichier non suivi" -ForegroundColor Green } else { Write-Host "⚠️ $($_.Count) fichiers non suivis détectés" -ForegroundColor Yellow } }

# 1.2 Si fichiers non suivis détectés
$untrackedFiles = git status --porcelain | Where-Object { $_ -match "^\?\?" }
if ($untrackedFiles.Count -gt 0) {
    Write-Host "⚠️ Fichiers non suivis détectés - analyse requise" -ForegroundColor Yellow
    git status
}
```

#### **2. Classification et Commit des Untracked Files**
```powershell
# Script PowerShell pour classification automatique
$untrackedFiles = git status --porcelain | Where-Object { $_ -match "^\?\?" }

if ($untrackedFiles.Count -gt 0) {
    Write-Host "📁 Classification des fichiers non suivis:" -ForegroundColor Cyan
    
    # Créer hashtable pour regrouper par domaine
    $domainGroups = @{}
    
    foreach ($file in $untrackedFiles) {
        $filePath = $file.Substring(3)  # Enlever "?? "
        
        # Déterminer domaine thématique
        $domain = switch -Regex ($filePath) {
            "^tools/" { "sync-tools" }
            "^config/" { "configuration" }
            "^docs/" { "documentation" }
            "^tests/" { "testing" }
            "^scripts/" { "automation" }
            "^web/" { "interface" }
            "\.ps1$" { "powershell-scripts" }
            "\.go$" { "core-development" }
            "\.md$" { "documentation" }
            "^\.github/" { "github-workflows" }
            "^planning-ecosystem-sync/" { "planning-sync" }
            default { "miscellaneous" }
        }
        
        if (-not $domainGroups.ContainsKey($domain)) {
            $domainGroups[$domain] = @()
        }
        $domainGroups[$domain] += $filePath
        
        Write-Host "  📄 $filePath → $domain" -ForegroundColor Yellow
    }
    
    # Proposition de commits thématiques
    Write-Host "`n💡 Commits thématiques suggérés:" -ForegroundColor Cyan
    foreach ($domain in $domainGroups.Keys) {
        $fileCount = $domainGroups[$domain].Count
        Write-Host "  🎯 $domain ($fileCount fichiers):" -ForegroundColor White
        Write-Host "     git add $($domainGroups[$domain] -join ' ')" -ForegroundColor Gray
        Write-Host "     git commit -m 'feat($domain): add untracked files for plan-dev-v55'" -ForegroundColor Gray
        Write-Host ""
    }
    
    # Demander confirmation pour commits automatiques
    $autoCommit = Read-Host "Effectuer les commits automatiquement? (y/N)"
    if ($autoCommit -eq 'y' -or $autoCommit -eq 'Y') {
        foreach ($domain in $domainGroups.Keys) {
            $files = $domainGroups[$domain] -join ' '
            git add $files
            git commit -m "feat($domain): add untracked files for plan-dev-v55

- Added $($domainGroups[$domain].Count) files in $domain domain
- Files: $($domainGroups[$domain] -join ', ')

Refs: plan-dev-v55-planning-ecosystem-sync.md"
            
            Write-Host "✅ Commit créé pour domaine: $domain" -ForegroundColor Green
        }
    }
}
```

#### **3. Vérification de la Branche Appropriée**
```powershell
# 3.1 Obtenir branche actuelle
$currentBranch = git branch --show-current

# 3.2 Déterminer branche appropriée selon la tâche
$taskType = $env:TASK_TYPE
if (-not $taskType) {
    $taskType = Read-Host "Type de tâche (plan-dev-v55/sync-tools/validation/documentation)"
}

$targetBranch = switch ($taskType) {
    "plan-dev-v55" { "planning-ecosystem-sync" }
    "sync-tools" { "planning-ecosystem-sync" }
    "validation" { "planning-ecosystem-sync" }
    "documentation" { "planning-ecosystem-sync" }
    "testing" { "planning-ecosystem-sync" }
    "interface" { "planning-ecosystem-sync" }
    default { "planning-ecosystem-sync" }
}

# 3.3 Vérifier et changer de branche si nécessaire
if ($currentBranch -ne $targetBranch) {
    Write-Host "🔄 Changement de branche: $currentBranch → $targetBranch" -ForegroundColor Yellow
    
    # Vérifier si la branche existe
    $branchExists = git branch --list $targetBranch
    if ($branchExists) {
        git checkout $targetBranch
    } else {
        Write-Host "📝 Création de la nouvelle branche: $targetBranch" -ForegroundColor Cyan
        git checkout -b $targetBranch
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Basculement réussi vers: $targetBranch" -ForegroundColor Green
    } else {
        Write-Host "❌ Échec du basculement vers: $targetBranch" -ForegroundColor Red
        exit 1
    }
}

$currentBranch = git branch --show-current
Write-Host "✅ Branche active: $currentBranch" -ForegroundColor Green
```

---

### **✅ FIN DE CHAQUE TÂCHE**

#### **4. Commit de la Tâche Terminée**
```powershell
# 4.1 Vérifier modifications en cours
git add .

# 4.2 Status avant commit
Write-Host "📊 État avant commit:" -ForegroundColor Cyan
git status --short

# 4.3 Paramètres du commit (à adapter selon la tâche)
$taskId = $env:TASK_ID
$section = $env:SECTION
$description = $env:DESCRIPTION

if (-not $taskId) { $taskId = Read-Host "ID de la tâche (ex: 4.1.1.2)" }
if (-not $section) { $section = Read-Host "Section (ex: migration-assistant)" }
if (-not $description) { $description = Read-Host "Description courte" }

# 4.4 Commit avec message structuré
$commitMessage = @"
feat($section): complete $taskId - $description

- ✅ Implémentation terminée
- ✅ Tests passants  
- ✅ Documentation mise à jour
- ✅ Code review effectué

Refs: plan-dev-v55-planning-ecosystem-sync.md#phase-4
"@

git commit -m $commitMessage

if ($LASTEXITCODE -eq 0) {
    $lastCommit = git log -1 --oneline
    Write-Host "✅ Commit créé: $lastCommit" -ForegroundColor Green
} else {
    Write-Host "❌ Échec de la création du commit" -ForegroundColor Red
    exit 1
}
```

#### **5. Push vers la Branche Appropriée**
```powershell
# 5.1 Push avec suivi de la branche distante
$currentBranch = git branch --show-current
git push -u origin $currentBranch

# 5.2 Vérification push
if ($LASTEXITCODE -eq 0) {
    Write-Host "🚀 Push réussi vers $currentBranch" -ForegroundColor Green
} else {
    Write-Host "❌ Échec du push - intervention manuelle requise" -ForegroundColor Red
    Write-Host "Vérifiez la connectivité réseau et les permissions" -ForegroundColor Yellow
}

# 5.3 Afficher hash du commit pour référence
$commitHash = git rev-parse --short HEAD
Write-Host "📝 Commit hash: $commitHash" -ForegroundColor Cyan
Write-Host "🌐 URL commit: https://github.com/your-repo/commit/$commitHash" -ForegroundColor Blue
```

---

### **📊 FIN DE CHAQUE SECTION**

#### **6. Mise à Jour du Plan-dev-v55**
```powershell
# Script de mise à jour automatique des cases à cocher
param(
    [string]$PlanFile = "projet\roadmaps\plans\consolidated\plan-dev-v55-planning-ecosystem-sync.md",
    [string]$Section,
    [string[]]$CompletedTasks
)

Write-Host "📝 Mise à jour du plan: $Section" -ForegroundColor Green

# Vérifier que le fichier existe
if (-not (Test-Path $PlanFile)) {
    Write-Error "❌ Fichier plan non trouvé: $PlanFile"
    exit 1
}

# Lire le contenu du plan
$content = Get-Content $PlanFile -Raw -Encoding UTF8

# Sauvegarde avant modification
$backupFile = "$PlanFile.backup.$(Get-Date -Format 'yyyyMMdd-HHmmss')"
Copy-Item $PlanFile $backupFile
Write-Host "💾 Backup créé: $backupFile" -ForegroundColor Blue

# Mise à jour des cases à cocher pour les tâches terminées
$updatedCount = 0
foreach ($task in $CompletedTasks) {
    $pattern = "- \[ \] $([regex]::Escape($task))"
    $replacement = "- [x] $task"
    
    if ($content -match $pattern) {
        $content = $content -replace $pattern, $replacement
        $updatedCount++
        Write-Host "  ✅ Tâche cochée: $task" -ForegroundColor Green
    } else {
        Write-Host "  ⚠️ Tâche non trouvée: $task" -ForegroundColor Yellow
    }
}

# Calculer nouvelle progression de la section si spécifiée
if ($Section) {
    # Extraire la section spécifique pour calculer la progression
    $sectionPattern = "### $([regex]::Escape($Section)).*?(?=###|\z)"
    $sectionMatch = [regex]::Match($content, $sectionPattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    
    if ($sectionMatch.Success) {
        $sectionContent = $sectionMatch.Value
        $totalTasks = ([regex]::Matches($sectionContent, "- \[[x ]\]")).Count
        $completedTasks = ([regex]::Matches($sectionContent, "- \[x\]")).Count
        
        if ($totalTasks -gt 0) {
            $progressPercent = [math]::Round(($completedTasks / $totalTasks) * 100, 0)
            
            # Mettre à jour la progression de la section
            $progressPattern = "(\*Progression: )\d+(%)(\*)"
            $progressReplacement = "`${1}$progressPercent`${2}`${3}"
            $content = [regex]::Replace($content, $progressPattern, $progressReplacement)
            
            Write-Host "📊 Progression $Section: $completedTasks/$totalTasks ($progressPercent%)" -ForegroundColor Cyan
        }
    }
}

# Calculer progression globale
$allTasks = ([regex]::Matches($content, "- \[[x ]\]")).Count
$allCompleted = ([regex]::Matches($content, "- \[x\]")).Count
$globalProgress = if ($allTasks -gt 0) { [math]::Round(($allCompleted / $allTasks) * 100, 0) } else { 0 }

# Mettre à jour progression globale
$globalPattern = "(\*\*Version.*?Progression globale : )\d+(%)(\*\*)"
$globalReplacement = "`${1}$globalProgress`${2}`${3}"
$content = [regex]::Replace($content, $globalPattern, $globalReplacement)

# Sauvegarder le fichier mis à jour
Set-Content -Path $PlanFile -Value $content -Encoding UTF8

Write-Host "✅ Plan mis à jour - Progression globale: $globalProgress%" -ForegroundColor Cyan
Write-Host "📈 Tâches mises à jour: $updatedCount" -ForegroundColor Green

# Commit de la mise à jour du plan
git add $PlanFile
$planCommitMessage = @"
docs(planning): update progress for $Section - $globalProgress% global completion

- Updated task checkboxes: $updatedCount tasks completed
- Section progress updated
- Global progress: $globalProgress%

Refs: plan-dev-v55-planning-ecosystem-sync.md
"@

git commit -m $planCommitMessage

if ($LASTEXITCODE -eq 0) {
    Write-Host "📊 Progression commitée avec succès" -ForegroundColor Green
    
    # Push automatique des mises à jour du plan
    git push origin $(git branch --show-current)
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "🚀 Mise à jour du plan poussée vers le remote" -ForegroundColor Green
    }
} else {
    Write-Host "❌ Échec du commit de la mise à jour" -ForegroundColor Red
}
```

---

## 🎯 **Template de Prompt par Section**

### **Format Standardisé pour Chaque Section**

```markdown
## 🚀 IMPLÉMENTATION SECTION [X.Y] - [NOM_SECTION]

### PRÉ-REQUIS
- [ ] Vérifier fichiers non suivis et les committer par domaine
- [ ] Confirmer branche: `planning-ecosystem-sync`
- [ ] État propre du workspace: `git status`
- [ ] Variables d'environnement définies:
  ```powershell
  $env:TASK_TYPE = "plan-dev-v55"
  $env:SECTION = "migration-assistant"
  $env:TASK_ID = "4.1.1.2"
  $env:DESCRIPTION = "Planification séquence de migration"
  ```

### TÂCHES À IMPLÉMENTER
**Phase [X]**: [Nom Phase]
**Section [X.Y]**: [Nom Section]  
**Objectif**: [Description objectif]

#### Tâche [X.Y.Z] - [Nom Tâche]
- [ ] **Micro-étape [X.Y.Z.1]**: [Description]
  ```[language]
  [Code example avec contexte]
  ```
  - **Fichiers concernés**: `[liste des fichiers]`
  - **Tests requis**: [Description des tests]
  - **Critères d'acceptation**: [Liste des critères]

- [ ] **Micro-étape [X.Y.Z.2]**: [Description]
  - **Dépendances**: [X.Y.Z.1]
  - **Estimation**: [temps estimé]

### POST-IMPLÉMENTATION
- [ ] **Tests unitaires passants**: `go test ./... -v`
- [ ] **Linting propre**: `golangci-lint run`
- [ ] **Commit structuré**: 
  ```
  feat(section-X-Y): complete [X.Y.Z] - [description]
  
  - ✅ [Détail implémentation]
  - ✅ [Tests ajoutés]
  - ✅ [Documentation mise à jour]
  
  Refs: plan-dev-v55-planning-ecosystem-sync.md#phase-X
  ```
- [ ] **Push vers branche**: `planning-ecosystem-sync`
- [ ] **Mise à jour plan**: Cases à cocher + progression
- [ ] **Nettoyage**: Aucun fichier non suivi restant

### VALIDATION
- [ ] **Fonctionnalité testée**: Manuel + automatique
- [ ] **Code review**: Si requis par l'équipe
- [ ] **Documentation à jour**: Inline + externe
- [ ] **Intégration validée**: Avec composants existants
- [ ] **Performance acceptable**: Selon métriques définies
```

---

## 📋 **Checklist Globale d'Application**

### **🔍 Avant de Commencer une Section**
```powershell
# Checklist automatisée
Write-Host "🔍 VÉRIFICATION PRÉ-IMPLÉMENTATION" -ForegroundColor Cyan

# 1. État workspace propre
$gitStatus = git status --porcelain
if ($gitStatus) {
    Write-Host "⚠️ Workspace non propre - fichiers modifiés détectés" -ForegroundColor Yellow
    git status
} else {
    Write-Host "✅ Workspace propre" -ForegroundColor Green
}

# 2. Branche correcte
$currentBranch = git branch --show-current
if ($currentBranch -eq "planning-ecosystem-sync") {
    Write-Host "✅ Branche correcte: $currentBranch" -ForegroundColor Green
} else {
    Write-Host "⚠️ Branche incorrecte: $currentBranch (attendu: planning-ecosystem-sync)" -ForegroundColor Yellow
}

# 3. Dernière version du plan
$planFile = "projet\roadmaps\plans\consolidated\plan-dev-v55-planning-ecosystem-sync.md"
if (Test-Path $planFile) {
    $lastModified = (Get-Item $planFile).LastWriteTime
    Write-Host "✅ Plan trouvé - dernière modification: $lastModified" -ForegroundColor Green
} else {
    Write-Host "❌ Plan non trouvé: $planFile" -ForegroundColor Red
}

# 4. Environnement Go fonctionnel
$goVersion = go version 2>$null
if ($goVersion) {
    Write-Host "✅ Go disponible: $goVersion" -ForegroundColor Green
} else {
    Write-Host "❌ Go non disponible ou mal configuré" -ForegroundColor Red
}

Write-Host "`n🚀 PRÊT POUR L'IMPLÉMENTATION" -ForegroundColor Green
```

### **🔄 Pendant l'Implémentation**
1. **🔄 Commits atomiques** - Une micro-tâche = un commit
2. **🔄 Messages descriptifs** - Format standardisé avec référence
3. **🔄 Tests continus** - Validation après chaque modification
4. **🔄 Documentation inline** - Code auto-documenté + commentaires

### **✅ Fin de Section**
```powershell
# Checklist automatisée de fin de section
Write-Host "✅ VÉRIFICATION POST-IMPLÉMENTATION" -ForegroundColor Cyan

# 1. Toutes tâches commitées
$uncommittedFiles = git status --porcelain
if (-not $uncommittedFiles) {
    Write-Host "✅ Toutes modifications commitées" -ForegroundColor Green
} else {
    Write-Host "⚠️ Fichiers non commitées:" -ForegroundColor Yellow
    git status --short
}

# 2. Push réussi
$lastCommit = git log -1 --oneline
Write-Host "📝 Dernier commit: $lastCommit" -ForegroundColor Cyan

# 3. Tests section passent
Write-Host "🧪 Exécution des tests..." -ForegroundColor Yellow
go test ./... -short
if ($LASTEXITCODE -eq 0) {
    Write-Host "✅ Tous les tests passent" -ForegroundColor Green
} else {
    Write-Host "❌ Certains tests échouent" -ForegroundColor Red
}

# 4. Plan mis à jour
$planContent = Get-Content $planFile -Raw
$completedTasks = ([regex]::Matches($planContent, "- \[x\]")).Count
$totalTasks = ([regex]::Matches($planContent, "- \[[x ]\]")).Count
$progress = [math]::Round(($completedTasks / $totalTasks) * 100, 0)

Write-Host "📊 Progression globale: $completedTasks/$totalTasks ($progress%)" -ForegroundColor Cyan
```

---

## 🎯 **Application Pratique sur Plan-dev-v55**

### **Script Principal d'Exécution**
```powershell
# implement-section.ps1
param(
    [Parameter(Mandatory=$true)]
    [string]$Section,
    
    [Parameter(Mandatory=$true)]
    [string]$TaskId,
    
    [string]$Description = "",
    [string]$PlanFile = "projet\roadmaps\plans\consolidated\plan-dev-v55-planning-ecosystem-sync.md",
    [string]$Branch = "planning-ecosystem-sync",
    [switch]$ValidateUntracked,
    [switch]$AutoCommit,
    [switch]$UpdateProgress
)

Write-Host "🚀 IMPLÉMENTATION SECTION $Section - TÂCHE $TaskId" -ForegroundColor Cyan
Write-Host "📝 Description: $Description" -ForegroundColor White

# Définir variables d'environnement
$env:TASK_TYPE = "plan-dev-v55"
$env:SECTION = $Section
$env:TASK_ID = $TaskId
$env:DESCRIPTION = $Description

# 1. Vérifications pré-implémentation
Write-Host "`n🔍 PHASE 1: Vérifications pré-implémentation" -ForegroundColor Yellow

if ($ValidateUntracked) {
    # Exécuter script de gestion des fichiers non suivis
    & .\.github\prompts\planning\scripts\handle-untracked-files.ps1
}

# Vérifier/changer de branche
& .\.github\prompts\planning\scripts\ensure-correct-branch.ps1 -TargetBranch $Branch

# 2. Phase d'implémentation
Write-Host "`n🛠️ PHASE 2: Implémentation" -ForegroundColor Yellow
Write-Host "Veuillez implémenter la tâche $TaskId selon les spécifications du plan." -ForegroundColor White
Write-Host "Appuyez sur Entrée quand l'implémentation est terminée..."
Read-Host

# 3. Post-implémentation
Write-Host "`n✅ PHASE 3: Post-implémentation" -ForegroundColor Yellow

if ($AutoCommit) {
    & .\.github\prompts\planning\scripts\commit-completed-task.ps1 -TaskId $TaskId -Section $Section -Description $Description
}

if ($UpdateProgress) {
    & .\.github\prompts\planning\scripts\update-plan-progress.ps1 -PlanFile $PlanFile -Section $Section -CompletedTasks @($TaskId)
}

Write-Host "`n🎉 IMPLÉMENTATION TERMINÉE AVEC SUCCÈS!" -ForegroundColor Green
```

### **Utilisation Pratique**
```powershell
# Exemple d'utilisation pour la micro-étape 4.1.1.2
.\implement-section.ps1 `
  -Section "migration-assistant" `
  -TaskId "4.1.1.2" `
  -Description "Planification séquence de migration" `
  -ValidateUntracked `
  -AutoCommit `
  -UpdateProgress

# Pour une section complète
$tasks = @("4.1.1.1", "4.1.1.2", "4.1.1.3", "4.1.1.4")
foreach ($task in $tasks) {
    .\implement-section.ps1 -Section "migration-assistant" -TaskId $task -ValidateUntracked -AutoCommit -UpdateProgress
    Write-Host "Tâche $task terminée - Continuez avec la suivante..." -ForegroundColor Green
    Read-Host
}
```

---

## 📋 **Bénéfices de ce Workflow**

### **🔒 Traçabilité et Qualité**
- **Historique complet** de chaque modification avec contexte
- **Messages de commit standardisés** pour faciliter le suivi
- **Branches thématiques** pour isoler les développements
- **Validation automatique** à chaque étape

### **📊 Suivi et Reporting**
- **Progression en temps réel** du plan de développement
- **Métriques automatisées** (commits, tests, couverture)
- **Dashboard** de l'état du projet
- **Alertes** en cas de problème

### **🚀 Efficacité et Reproductibilité**
- **Workflow automatisé** réduisant les erreurs manuelles
- **Scripts réutilisables** pour toutes les sections
- **Validation continue** évitant l'accumulation de dette technique
- **Documentation maintenue** automatiquement

### **👥 Collaboration d'Équipe**
- **Standards uniformes** pour tous les développeurs
- **Code reviews** facilitées par les commits atomiques
- **Intégration continue** avec validation automatique
- **Partage de connaissances** via la documentation

---

**Ce prompt garantit une implémentation méthodique, traçable et de haute qualité du plan-dev-v55 Planning Ecosystem Synchronization.**