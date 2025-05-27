---
title: "Mode Gestion Git"
description: "Gestion des commits et des push avec descriptions standardisées"
behavior:
  temperature: 0.2
  maxTokens: 1024
tags: ["git", "versioning", "documentation"]
---

# Mode GIT - Gestion de Version

## 🎯 Objectif
Standardiser et automatiser la gestion des commits Git avec des descriptions précises et structurées.

## 📋 Format des Messages
```yaml
commit_types:
  feat: "Nouvelle fonctionnalité"
  fix: "Correction de bug"
  refactor: "Refactoring du code"
  test: "Ajout ou modification de tests"
  docs: "Documentation uniquement"
  chore: "Tâches de maintenance"
  style: "Formatage, espaces, etc."
  perf: "Amélioration des performances"
```

## 🔄 Structure du Message
```
<type>(<scope>): <description>

[corps du message]

[footer]
```

## 📝 Exemples de Commits
```powershell
# Nouvelle fonctionnalité
git commit -m "feat(analyzer): implémentation du pattern matcher v2"

# Correction de bug
git commit -m "fix(parser): correction du parsing des caractères spéciaux"

# Refactoring
git commit -m "refactor(test): restructuration des tests unitaires"
```

## 🔍 Validation des Changements
```powershell
# Script de vérification avant commit
.\check_git_status.ps1
.\check_git_sync.ps1

# Commit avec description détaillée
$description = "feat(n8n): intégration du workflow d'analyse
- Ajout du nouveau composant d'analyse
- Optimisation du traitement des données
- Mise à jour des tests d'intégration"

git add .
git commit -m $description --no-verify
git push --no-verify
```

## 🔗 Intégration
- **CHECK**: Validation avant commit
- **TEST**: Exécution des tests
- **METRICS**: Analyse d'impact

## ⚠️ Points d'Attention
1. Toujours inclure le type de changement
2. Décrire précisément les modifications
3. Mentionner les dépendances impactées
4. Référencer les tickets/issues liés