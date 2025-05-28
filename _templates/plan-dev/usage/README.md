# 🚀 Guide Plan-Dev Templates

## 📖 Comment utiliser les templates

### 1️⃣ Création d'un nouveau plan
\\\powershell
hygen plan-dev new
\\\

### 2️⃣ Mise à jour d'un script
\\\powershell
hygen plan-dev update add-script
\\\

### 3️⃣ Génération d'un rapport
\\\powershell
hygen plan-dev report weekly
\\\

## 📝 Structure des fichiers

\\\
_templates/plan-dev/
├── new/
│   ├── index.ejs.t    # Template principal
│   ├── warnings.ejs.t # Gestion des alertes
│   └── prompt.js      # Questions interactives
├── update/
│   ├── add-script.ejs.t
│   └── prompt.js
├── report/
│   ├── weekly.ejs.t
│   └── prompt.js
└── usage/
    └── README.md
\\\

## ⚠️ Points de vigilance

Les warnings peuvent être ajoutés avec la structure suivante :

\\\javascript
{
    warnings: [
        { message: "Message d'alerte", severity: "HAUTE" },
        { message: "Autre alerte", severity: "MOYENNE" }
    ]
}
\\\

## 🆘 Support

En cas de problème :
1. Vérifiez que vous êtes dans le bon dossier
2. Exécutez \hygen plan-dev new --help\
3. Consultez la documentation Hygen

*Installation réalisée le 2025-05-28*
