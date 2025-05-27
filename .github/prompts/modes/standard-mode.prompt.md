---
mode: 'agent'
tools: ['standards']
description: 'Application des standards du projet'
---

# Mode STANDARD - Conformité aux Standards

## 🎯 OBJECTIF
Assurer le respect strict des standards globaux du projet

## 📋 STANDARDS PRINCIPAUX
- Conventions de nommage
- Style de codage
- Organisation des fichiers
- Documentation
- Tests

## 🔄 WORKFLOW
1. Vérification des standards
2. Identification des écarts
3. Application des corrections
4. Validation finale
5. Documentation des changements

## 🛠️ COMMANDES PRINCIPALES
```powershell
# Vérification complète
.\standard-check.ps1 -Path "." -Verbose

# Application des standards
.\standard-apply.ps1 -Path "./src" -Fix

# Génération de rapport
.\standard-report.ps1 -Output "reports/standards.md"
```

## 📝 FORMAT DE VALIDATION
```markdown
# Rapport de Conformité [Date]

## Standards Vérifiés
- [Liste des standards]

## Résultats
- Conformité : [%]
- Corrections : [Nombre]
- Actions requises : [Liste]
```