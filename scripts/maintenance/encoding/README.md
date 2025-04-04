# Outils de gestion des caractÃ¨res accentuÃ©s franÃ§ais dans n8n

Ce rÃ©pertoire contient des scripts et des outils pour rÃ©soudre les problÃ¨mes d'encodage des caractÃ¨res accentuÃ©s franÃ§ais dans les workflows n8n.

## Utilisation rapide

Utilisez le script encoding-tools.ps1 pour lancer rapidement les outils :

`powershell
# Correction des caractÃ¨res accentuÃ©s
.\encoding-tools.ps1 -Action fix

# Importation des workflows corrigÃ©s
.\encoding-tools.ps1 -Action import

# Suppression des doublons et des workflows mal encodÃ©s
.\encoding-tools.ps1 -Action remove-duplicates

# Liste des workflows existants
.\encoding-tools.ps1 -Action list

# Suppression de tous les workflows existants
.\encoding-tools.ps1 -Action delete-all
`

## Structure du rÃ©pertoire

- **python/** - Scripts Python pour la correction des caractÃ¨res accentuÃ©s
  - ix_all_workflows.py - Remplace les caractÃ¨res accentuÃ©s dans les fichiers JSON
  - ix_encoding_simple.py - Version simplifiÃ©e du script de correction d'encodage
  - ix_workflow_names.py - Se concentre sur la correction des noms des workflows
  - list_n8n_workflows.py - Liste les workflows prÃ©sents dans l'instance n8n
  - emove_accents.py - Utilitaire pour remplacer les caractÃ¨res accentuÃ©s

- **powershell/** - Scripts PowerShell pour l'interaction avec n8n
  - import-fixed-all-workflows.ps1 - Importe les workflows corrigÃ©s dans n8n
  - emove-duplicate-workflows.ps1 - Supprime les workflows en double ou mal encodÃ©s
  - delete-all-workflows-auto.ps1 - Supprime tous les workflows existants sans confirmation
  - list-workflows.ps1 - Liste les workflows existants dans n8n
  - get-workflows.ps1 - RÃ©cupÃ¨re les dÃ©tails des workflows via l'API n8n
  - ix-encoding-utf8.ps1 - Corrige l'encodage des fichiers JSON en UTF-8 avec BOM
  - ix-workflow-names.ps1 - Corrige les noms des workflows

- **logs/** - Logs des opÃ©rations effectuÃ©es

## Documentation

Pour plus d'informations, consultez le guide complet : [Guide de gestion des caractÃ¨res accentuÃ©s franÃ§ais dans n8n](../../../docs/guides/GUIDE_GESTION_CARACTERES_ACCENTES.md)
