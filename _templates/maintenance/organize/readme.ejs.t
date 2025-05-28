<#
---
to: D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/scripts/maintenance/organize/README.md
unless_exists: true
---
# Scripts d'organisation

Ce répertoire contient des scripts pour organiser les différents dossiers du projet selon une structure prédéfinie.

## Scripts disponibles

- `<%= name %>.ps1` - <%= description %>
<% if (createCleanup) { %>
- `cleanup-<%= name %>.ps1` - Script de nettoyage pour <%= description.toLowerCase() %>
<% } %>

## Utilisation

```powershell
# Exécuter en mode simulation (dry run)
.\<%= name %>.ps1 -DryRun

# Exécuter avec confirmation pour chaque action
.\<%= name %>.ps1

# Exécuter sans confirmation
.\<%= name %>.ps1 -Force
<% if (createCleanup) { %>

# Nettoyer les fichiers originaux (après vérification)
.\cleanup-<%= name %>.ps1
<% } %>
```

## Structure créée

Le script crée la structure de dossiers suivante dans le répertoire cible (`<%= targetDir %>`):

```
<%= targetDir %>/
<% if (type === 'structure') { %>
├── core/
│   ├── parser/
│   ├── model/
│   ├── converter/
│   └── structure/
├── utils/
│   ├── helpers/
│   ├── export/
│   └── import/
└── docs/
    ├── examples/
    └── guides/
<% } else if (type === 'modules') { %>
├── modules/
│   ├── core/
│   ├── utils/
│   ├── analysis/
│   ├── reporting/
│   └── tests/
<% } else if (type === 'scripts') { %>
├── scripts/
│   ├── daily/
│   ├── weekly/
│   ├── monthly/
│   └── on-demand/
<% } else if (type === 'docs') { %>
├── docs/
│   ├── guides/
│   ├── api/
│   ├── examples/
│   ├── tutorials/
│   └── references/
<% } else { %>
├── custom_folder_1/
├── custom_folder_2/
└── custom_folder_3/
<% } %>
```

## Mappages de fichiers

Le script déplace les fichiers selon les mappages suivants :

<% if (type === 'structure') { %>
- `*.ps1` → `core/`
- `*.psm1` → `core/modules/`
- `*.psd1` → `core/modules/`
- `*.md` → `docs/`
- `README.md` → `.` (racine)
<% } else if (type === 'modules') { %>
- `*-core-*.ps1` → `modules/core/`
- `*-utils-*.ps1` → `modules/utils/`
- `*-analysis-*.ps1` → `modules/analysis/`
- `*-report-*.ps1` → `modules/reporting/`
- `*-test-*.ps1` → `modules/tests/`
<% } else if (type === 'scripts') { %>
- `*-daily-*.ps1` → `scripts/daily/`
- `*-weekly-*.ps1` → `scripts/weekly/`
- `*-monthly-*.ps1` → `scripts/monthly/`
- `*-ondemand-*.ps1` → `scripts/on-demand/`
<% } else if (type === 'docs') { %>
- `guide-*.md` → `docs/guides/`
- `api-*.md` → `docs/api/`
- `example-*.md` → `docs/examples/`
- `tutorial-*.md` → `docs/tutorials/`
- `reference-*.md` → `docs/references/`
<% } else { %>
- `*.txt` → `custom_folder_1/`
- `*.csv` → `custom_folder_2/`
- `*.json` → `custom_folder_3/`
<% } %>
