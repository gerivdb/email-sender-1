# Modules et extensions diff Edit

Cette section documente la structure recommandée pour l’ajout de nouveaux modules ou extensions à l’écosystème diff Edit (Go natif).

## Objectif

Permettre l’extension du système diff Edit à d’autres formats de fichiers, à l’intégration avec des outils externes, ou à l’ajout de fonctionnalités avancées, tout en garantissant la cohérence, la robustesse et la simplicité d’usage.

## Procédure d’ajout d’un module

1. **Définir le besoin** :
   - Exemple : support d’un nouveau format (YAML, TOML, XML), intégration CI/CD, automatisation VS Code, etc.
2. **Créer un dossier dédié** dans `tools/diff_edit/modules/<nom_module>` si le module est conséquent.
3. **Documenter le module** dans une fiche markdown :
   - Description, cas d’usage, contraintes, exemples, limitations, procédure d’intégration.
4. **Respecter la convention Go natif** :
   - Scripts, outils, ou wrappers doivent être en Go natif, sans dépendance Python/Node.js.
5. **Ajouter des tests réels** (fichiers d’exemple, patchs, dry-run, rollback).
6. **Mettre à jour le plan principal et le README** pour référencer le module.

## Template fiche module

---

### Nom du module : <À compléter>

- **Description** :
- **Cas d’usage** :
- **Contraintes** :
- **Exemples** :
- **Limitations** :
- **Procédure d’intégration** :

---

## Exemple : Support YAML

- **Description** : Permet d’appliquer des diff Edit sur des fichiers YAML (config, CI/CD, etc.).
- **Cas d’usage** : Mise à jour de paramètres dans des fichiers de déploiement, automatisation DevOps.
- **Contraintes** : Respecter l’indentation YAML, éviter les modifications sur des blocs non scalaires.
- **Exemples** :
  - Avant :

    ```yaml
    key: old_value
    ```

  - Bloc diff Edit :

    ```
    ------- SEARCH
    key: old_value
    =======
    key: new_value
    +++++++ REPLACE
    ```

  - Après :

    ```yaml
    key: new_value
    ```

- **Limitations** : Ne pas utiliser sur des fichiers YAML multi-documents.
- **Procédure d’intégration** :
  1. Copier le module dans `tools/diff_edit/modules/yaml_support/`.
  2. Ajouter un test dans `go/test_yaml_diffedit.go`.
  3. Référencer dans le README et le plan principal.
