# Documentation Projet

Ce dossier contient la documentation relative au projet lui-même.

## Structure

- **architecture/** : Diagrammes et décisions d'architecture
  - **decisions/** : Décisions d'architecture
  - **diagrams/** : Diagrammes d'architecture
- **documentation/** : Documentation générale du projet
  - **api/** : Documentation de l'API
  - **technique/** : Documentation technique
  - **workflow/** : Documentation des workflows
- **guides/** : Guides d'utilisation et d'installation
  - **installation/** : Guides d'installation
  - **utilisation/** : Guides d'utilisation
  - **integrations/** : Guides d'intégration
- **roadmaps/** : Plans de développement et feuilles de route
  - **plans/** : Plans de développement
  - **journal/** : Journal de développement
  - **tasks/** : Tâches de développement
- **specifications/** : Spécifications fonctionnelles et techniques
  - **fonctionnelles/** : Spécifications fonctionnelles
  - **techniques/** : Spécifications techniques
- **tutorials/** : Tutoriels et exemples d'utilisation
  - **examples/** : Exemples d'utilisation

## Utilisation

Pour ajouter de nouveaux documents à cette structure, utilisez Hygen :

```powershell
# Créer un nouveau document dans la structure

hygen doc-structure new --docType "projet" --category "guides" --subcategory "installation"
```plaintext