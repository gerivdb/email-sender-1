# Workflow d’audit initial Go – gapanalyzer

## Description
Ce workflow automatise l’audit initial du dépôt Go via le script [`run_gapanalyzer_audit.ps1`](./run_gapanalyzer_audit.ps1), générant les rapports d’écart (JSON/Markdown) et les logs, puis archivant systématiquement les livrables.

## Étapes
1. Exécution du script PowerShell :
   - Analyse des modules via gapanalyzer
   - Génération des rapports JSON et Markdown
   - Création d’un log d’exécution
2. Vérification des livrables
3. Archivage automatique dans `_templates/backup/plan-dev/new/`

## Paramètres du script
- `InputFile` : Fichier JSON d’entrée (modules existants)
- `OutputFile` : Rapport JSON d’analyse d’écart
- `MarkdownFile` : Rapport Markdown
- `LogFile` : Log d’exécution

## Livrables générés
- Rapport JSON : `gap-analysis.json`
- Rapport Markdown : `gap-analysis.md`
- Log d’audit : `audit-log.txt`
- Archivage dans : `_templates/backup/plan-dev/new/`

## Exemple d’intégration CI/CD (YAML)
```yaml
- name: Audit Go – gapanalyzer
  shell: pwsh
  run: |
    ./_templates/script-automation/new/run_gapanalyzer_audit.ps1 -InputFile modules.json -OutputFile gap-analysis.json -MarkdownFile gap-analysis.md -LogFile audit-log.txt
```

## Traçabilité et robustesse
- Tous les livrables sont archivés et logués systématiquement.
- Les erreurs et avertissements sont capturés dans le log d’audit.