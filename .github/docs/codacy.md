# Utilisation de Codacy dans ce projet

## Analyse statique et sécurité

Ce projet utilise Codacy pour l'analyse statique du code et la détection des vulnérabilités.

### Intégration CI/CD
L'analyse Codacy est principalement intégrée via l'application GitHub de Codacy. Celle-ci analyse automatiquement le code lors des pull requests et des pushes vers les branches principales. La configuration des outils et des fichiers analysés par l'application GitHub est définie dans le fichier `.codacy.yaml` à la racine du référentiel.

Les résultats de l'analyse sont visibles directement sur les pull requests (via les "Checks" GitHub) et sur le tableau de bord Codacy du projet.

### Utilisation locale de Codacy CLI (Optionnel)

Pour les développeurs souhaitant exécuter des analyses localement avant de pousser leur code, Codacy Analysis CLI peut être utilisée.

**Note sur l'installation locale :** Les exemples ci-dessous utilisent un chemin d'installation Windows par défaut. Si vous utilisez un autre système d'exploitation ou avez installé la CLI différemment, veuillez adapter le chemin vers `codacy-analysis-cli-assembly.jar` ou vous assurer que `codacy-analysis-cli` est dans votre PATH. Consultez la [documentation officielle](https://docs.codacy.com/codacy-analysis-cli/installation/) pour l'installation.

#### Lancer une analyse sur un fichier spécifique

Permet de cibler une analyse sur des fichiers modifiés avant de committer. Par exemple, pour un fichier Go :
```sh
java -jar "<chemin/vers/codacy-analysis-cli-assembly.jar>" analyze --directory . --files <chemin/vers/fichier.go> --output result-<nom>.json
```
Ou si `codacy-analysis-cli` est dans le PATH :
```sh
codacy-analysis-cli analyze --directory . --files <chemin/vers/fichier.go> --output result-<nom>.json
```

#### Lancer une analyse de sécurité des dépendances (Trivy)

Pour vérifier les dépendances du projet avec Trivy via la CLI Codacy :
```sh
java -jar "<chemin/vers/codacy-analysis-cli-assembly.jar>" analyze --tool trivy --directory . --output trivy-results.json
```
Ou si `codacy-analysis-cli` est dans le PATH :
```sh
codacy-analysis-cli analyze --tool trivy --directory . --output trivy-results.json
```
**Note:** L'analyse des dépendances par Trivy peut aussi être configurée pour s'exécuter automatiquement via les paramètres du projet sur Codacy Cloud.

### Bonnes pratiques
- Consulter les résultats d'analyse Codacy sur les pull requests avant de merger.
- Corriger les problèmes signalés par Codacy pour maintenir la qualité et la sécurité du code.
- Pour une analyse locale optionnelle, assurez-vous que votre copie locale de `.codacy.yaml` est à jour pour refléter la configuration du projet.

### Répertoire de sortie (pour analyses locales)
Lors d'une exécution locale de la CLI, les résultats sont générés dans des fichiers `result-*.json` ou `trivy-results.json` à la racine du projet (ou selon le paramètre `--output`).

---

Pour toute question ou problème avec Codacy, contacter l’équipe DevOps ou consulter la documentation officielle : https://docs.codacy.com/codacy-analysis-cli/
