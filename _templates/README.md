# Templates Hygen 📁

Ce dossier contient tous les templates Hygen pour la génération automatique de fichiers dans le projet EMAIL_SENDER_1.

## 🌟 Structure des templates

### Templates principaux

- `plan-dev/` : Templates pour les plans de développement
  - `new/` : Création de nouveaux plans
  - `update/` : Mise à jour et suivi
  - `report/` : Rapports de progression
  - `usage/` : Documentation d'utilisation

### Templates de documentation

- `doc-structure/` : Documentation de structure et migration
- `prd/` : Documentation PRD (Product Requirements Document)
- `roadmap/` : Génération de roadmaps
- `roadmap-parser/` : Outils d'analyse de roadmaps

### Templates de développement

- `mcp-server/` : Configuration et génération de serveurs MCP
- `mode/` : Génération de modes et commandes
- `powershell-module/` : Modules PowerShell

### Templates de scripts

- `script/` : Scripts PowerShell standard
- `script-analysis/` : Analyse de scripts
- `script-automation/` : Automatisation
- `script-integration/` : Intégration
- `script-test/` : Tests de scripts

### Templates de maintenance

- `maintenance/` : Scripts et utilitaires
- `init/` : Initialisation de projets
- `generator/` : Générateurs personnalisés
- `backup/` : Templates de sauvegarde

## 🚀 Utilisation

### Génération d'un plan de développement

```powershell
hygen plan-dev new --version "v1" --title "Mon Plan" --description "Description"
```plaintext
### Création de scripts

```powershell
hygen script new --name "mon-script" --category "maintenance" --description "Description"
```plaintext
### Génération de documentation

```powershell
hygen doc-structure new --name "architecture" --type "system"
```plaintext
## ⚙️ Configuration

Les templates utilisent la configuration dans `.hygen.js` à la racine du projet. Les chemins sont relatifs à la racine du projet.

## 📝 Notes importantes

1. Utilisez toujours des chemins absolus dans les templates
2. Préférez l'UTF-8 pour l'encodage des fichiers
3. Testez vos templates avant de les committer

## 🔄 Migration

Les templates ont été migrés depuis :
\`D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/development/templates/hygen\`
vers :
\`D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/_templates\`

## 🆘 Support

En cas de problème :
1. Vérifiez la configuration dans `.hygen.js`
2. Assurez-vous d'être dans le bon dossier
3. Utilisez `hygen [template] help`

---

Dernière mise à jour : 2025-05-28