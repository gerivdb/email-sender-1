---
mode: 'edit'
description: 'Analyser la conformité aux standards du projet'
---

# Analyse de Conformité aux Standards

Analyser le code ou la structure pour vérifier la conformité aux standards définis dans `docs/guides/standards/`.

## Standards à Vérifier

1. **Conventions de nommage** : `docs/guides/standards/Conventions-Nommage.md`
2. **Style de codage** : `docs/guides/standards/Guide-Style-Codage.md`
3. **Organisation des fichiers** : `docs/guides/standards/Organisation-Fichiers-Dossiers.md`
4. **Longueur des fichiers** : `docs/guides/standards/Gestion-Longueur-Fichiers.md`
5. **Verbes PowerShell** : `docs/guides/standards/PowerShell-Verbes-Approuves.md`

## Processus d'Analyse

1. Examiner le fichier/dossier actuel
2. Comparer avec les standards de référence
3. Identifier les écarts et non-conformités
4. Proposer des corrections spécifiques
5. Générer un rapport de conformité

## Format du Rapport

```markdown
## Rapport de Conformité - [Fichier/Dossier]

**Date** : [Timestamp]
**Standards appliqués** : [Liste des standards vérifiés]

### ✅ Conformités Détectées

- [Liste des points conformes]

### ❌ Non-Conformités Détectées

- **[Type]** : [Description du problème]
  - **Localisation** : [Ligne/Section]
  - **Standard violé** : [Référence au guide]
  - **Correction suggérée** : [Action recommandée]

### 🔧 Actions Recommandées

1. [Action prioritaire 1]
2. [Action prioritaire 2]
...
```plaintext
Commencer l'analyse du fichier ou dossier en cours d'édition.