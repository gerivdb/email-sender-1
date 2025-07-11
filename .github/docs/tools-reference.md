# Référence des outils

Ce document décrit les outils disponibles pour interagir avec le système.

## read_file

**But** : Lire le contenu d'un ou plusieurs fichiers.

**Utilisation** : Permet d'obtenir le contenu actuel d'un fichier avant de le modifier. Ceci est crucial pour comprendre le contexte et s'assurer que les modifications sont basées sur la version la plus récente du fichier.

**Paramètres** :

*   `path` : Chemin d'accès au fichier (obligatoire).
*   `line_range` : Permet de spécifier les lignes à lire (facultatif, mais recommandé pour les grands fichiers).

**Note**: Cline a contribué à des améliorations pour la lecture de fichiers larges avec cet outil.

**Sortie** : Le contenu du fichier, avec les numéros de ligne.

## apply_diff

**But** : Appliquer une modification (diff) à un fichier existant.

**Utilisation** : Permet de modifier un fichier en remplaçant des lignes spécifiques par un nouveau contenu. L'outil compare le contenu recherché avec le contenu actuel du fichier et applique la modification uniquement si la correspondance est parfaite.

**Paramètres** :

*   `path` : Chemin d'accès au fichier (obligatoire).
*   `diff` : Contient les informations sur la modification à effectuer.
    *   `content` : Contient le contenu à rechercher (SEARCH) et le contenu de remplacement (REPLACE).
    *   `start_line` : Numéro de la première ligne à remplacer.

**Compréhension essentielle** :

*   La correspondance entre le contenu recherché (SEARCH) et le contenu actuel du fichier doit être *exacte* (y compris les espaces, les sauts de ligne, etc.). Sinon, la modification échouera.
*   Il est *impératif* d'utiliser `read_file` pour obtenir le contenu actuel du fichier avant d'utiliser `apply_diff`. Cela permet de s'assurer que le contenu recherché correspond bien à la version actuelle du fichier.
*   Si des modifications ont été apportées au fichier entre le moment où vous avez lu le contenu et le moment où vous essayez d'appliquer le diff, la modification échouera.

## write_file

**But** : Écrire (ou remplacer) le contenu complet d'un fichier.

**Utilisation** : Permet de créer un nouveau fichier ou de remplacer complètement le contenu d'un fichier existant.

**Paramètres** :

*   `path` : Chemin d'accès au fichier (obligatoire).
*   `content` : Le contenu complet à écrire dans le fichier (obligatoire).

**Compréhension essentielle** :

*   Cet outil *remplace* tout le contenu existant du fichier. Il est donc crucial de fournir le contenu *complet* du fichier, et non seulement les parties modifiées.
*   Contrairement à `apply_diff`, il n'y a pas de vérification de correspondance. Le contenu fourni est simplement écrit dans le fichier.
*   Cet outil est plus lent que `apply_diff` et ne peut pas gérer les fichiers de très grande taille.

**Quand utiliser `apply_diff` vs `write_file` ?**

*   Utiliser `apply_diff` pour des modifications ciblées et précises, lorsque vous connaissez exactement le contenu à remplacer. C'est idéal pour les modifications de code où vous voulez éviter de remplacer tout le fichier.
*   Utiliser `write_file` pour créer de nouveaux fichiers ou pour remplacer *entièrement* le contenu d'un fichier existant. À utiliser avec prudence, car cela peut écraser des modifications non sauvegardées.

## Approche "Atomic Replacement" (Remplacement Atomique)

Une autre approche pour modifier des fichiers consiste à :

1.  Créer une copie temporaire du fichier original.
2.  Effectuer les modifications souhaitées sur la copie temporaire.
3.  Une fois les modifications validées, renommer la copie temporaire pour remplacer le fichier original.
4.  Supprimer le fichier original.

Cette approche garantit que le fichier est modifié de manière atomique, c'est-à-dire que soit toutes les modifications sont appliquées avec succès, soit aucune ne l'est. Cela permet d'éviter les problèmes de corruption de données ou d'état incohérent en cas d'interruption pendant la modification.

**Quand utiliser cette approche ?**

*   Lorsque la cohérence des données est primordiale.
*   Lorsque le risque d'interruption pendant la modification est élevé.
*   Lorsque les modifications sont complexes et qu'il est difficile de garantir leur intégrité avec `apply_diff`.

## Autres méthodes de modification de fichiers

*   **In-place editing** : Modification du fichier directement, sans copie temporaire. Rapide, mais risque de corruption.
*   **Copy-on-write (COW)** : Seules les parties modifiées sont copiées. Efficace pour les modifications partielles.
*   **Journaling** : Enregistrement des modifications dans un journal avant de les appliquer. Permet de restaurer l'état en cas d'erreur.
*   **Shadowing (Copie fantôme)** : Modifications sur une copie "fantôme" fusionnée avec la version principale. Permet de gérer les conflits.
*   **Méthodes basées sur des transactions** : Utilisation de transactions pour garantir l'atomicité des opérations.

## Commandes de base pour la manipulation de fichiers et de répertoires

Bien que le système fournisse des outils spécifiques, il est utile de connaître les commandes de base pour la manipulation de fichiers et de répertoires :

*   `cp` : Copier un fichier ou un répertoire.
*   `mv` : Déplacer (renommer) un fichier ou un répertoire.
*   `rm` : Supprimer un fichier ou un répertoire.
*   `mkdir` : Créer un répertoire.
*   `touch` : Créer un fichier vide ou mettre à jour la date de modification d'un fichier existant.

Ces commandes peuvent être exécutées à l'aide de l'outil `execute_command`.

## Opérations par lot et sélection de fichiers

Certains outils permettent d'effectuer des opérations sur plusieurs fichiers à la fois, en utilisant des techniques comme :

*   **Globbing** : Utilisation de caractères spéciaux (comme `*` et `?`) pour sélectionner des fichiers correspondant à un motif. Par exemple, `*.txt` sélectionne tous les fichiers avec l'extension `.txt`.
*   **Sélection par lot** : Spécification d'une liste de fichiers ou de répertoires sur lesquels effectuer une opération.
*   **Exécution de commandes en boucle** : Utilisation de scripts ou de commandes shell pour itérer sur une liste de fichiers et effectuer une opération sur chacun d'eux.

Consultez la documentation de chaque outil pour savoir s'il prend en charge ces fonctionnalités.

## search_and_replace

**But** : Rechercher et remplacer du texte dans un fichier.

**Utilisation** : Permet de trouver une chaîne de caractères (ou une expression régulière) dans un fichier et de la remplacer par une autre chaîne.

**Paramètres** :

*   `path` : Chemin d'accès au fichier (obligatoire).
*   `search` : La chaîne de caractères (ou l'expression régulière) à rechercher (obligatoire).
*   `replace` : La chaîne de caractères de remplacement (obligatoire).
*    `start_line` : ligne de début de la recherche.
*    `end_line` : ligne de fin de la recherche.

**Compréhension essentielle** :

*   Cet outil est utile pour remplacer des occurrences spécifiques de texte, mais il ne permet pas de faire des modifications complexes basées sur le contexte.
*   Les expressions régulières peuvent être utilisées pour des recherches plus flexibles, mais il est important de bien les maîtriser pour éviter des remplacements involontaires.

## list_files

**But** : Lister les fichiers et répertoires dans un répertoire donné.

**Utilisation** : Permet d'explorer la structure du projet, de vérifier l'existence de fichiers, de trouver des fichiers spécifiques, etc.

**Paramètres** :

*   `path` : Chemin d'accès au répertoire (obligatoire).
*   `recursive` : Indique si la liste doit être récursive (facultatif).

**Compréhension essentielle** :

*   Cet outil est utile pour obtenir une vue d'ensemble de la structure du projet, mais il ne fournit pas le contenu des fichiers.

## list_code_definition_names

**But** : Lister les noms des définitions de code (classes, fonctions, méthodes, etc.) dans un fichier ou un répertoire.

**Utilisation** : Permet d'obtenir une vue d'ensemble des composants d'un module ou d'un fichier, de comprendre les relations entre les différents éléments du code, etc.

**Paramètres** :

*   `path` : Chemin d'accès au fichier ou au répertoire (obligatoire).

**Compréhension essentielle** :

*   Cet outil est utile pour comprendre la structure et l'organisation du code, mais il ne fournit pas le code lui-même.

## execute_command

**But** : Exécuter une commande dans un terminal.

**Utilisation** : Permet d'automatiser des tâches, d'exécuter des scripts, de compiler du code, etc.

**Paramètres** :

*   `command` : La commande à exécuter (obligatoire).

**Compréhension essentielle** :

*   Cet outil est très puissant, mais il doit être utilisé avec précaution. Il est important de bien comprendre la commande à exécuter et de s'assurer qu'elle ne causera pas de problèmes.
*   Il est important de bien comprendre l'environnement d'exécution (système d'exploitation, shell, etc.) pour s'assurer que la commande est exécutée correctement.

## install_dependencies

**But** : Installer ou mettre à jour les dépendances d'un projet dans un environnement donné.

**Utilisation** : Permet d'automatiser l'installation des dépendances définies dans des fichiers comme `requirements.txt` (Python), `package.json` (Node.js), `go.mod` (Go), ou autres, en tenant compte des environnements (dev, prod, staging).

**Paramètres** :

*   `path` : Chemin vers le répertoire contenant le fichier de dépendances (obligatoire).
*   `env` : Environnement cible (`dev`, `prod`, `staging`) (facultatif).
*   `package_manager` : Gestionnaire de paquets à utiliser (`pip`, `npm`, `yarn`, `go`, etc.) (facultatif, autodétection par défaut).
*   `version` : Version spécifique des dépendances à installer (facultatif).

**Sortie** : Résultat de l'installation (succès, erreurs, versions installées).

**Compréhension essentielle** :

*   Cet outil garantit que les dépendances sont cohérentes avec l'environnement cible, évitant les problèmes liés à des versions incompatibles.
*   Il peut être intégré dans un pipeline CI/CD pour automatiser la configuration d'un projet.
*   Respecte le principe DRY en centralisant la gestion des dépendances.

**Exemple d'utilisation** :

```bash
install_dependencies --path ./my_project --env prod --package_manager npm
```

Installe les dépendances listées dans `package.json` pour un environnement de production.

## run_tests

**But** : Exécuter des tests unitaires, d'intégration ou de performance dans un projet.

**Utilisation** : Permet de valider le code avant un déploiement ou une modification, en exécutant des suites de tests définies dans des frameworks comme `pytest` (Python), `Jest` (JavaScript/TypeScript), ou `go test` (Go).

**Paramètres** :

*   `path` : Chemin vers le répertoire ou fichier contenant les tests (obligatoire).
*   `test_type` : Type de tests à exécuter (`unit`, `integration`, `performance`) (facultatif).
*   `framework` : Framework de test à utiliser (`pytest`, `jest`, `go test`, etc.) (facultatif, autodétection par défaut).
*   `coverage` : Générer un rapport de couverture de code (booléen, facultatif).

**Sortie** : Résultats des tests (succès/échecs, rapport de couverture si activé).

**Compréhension essentielle** :

*   Cet outil renforce la qualité du code et s'inscrit dans une démarche SOLID en validant les responsabilités des modules.
*   Il peut être intégré à des pipelines CI/CD pour des tests automatisés.
*   Utile pour détecter les régressions après des modifications via `apply_diff` ou `write_file`.

**Exemple d'utilisation** :

```bash
run_tests --path ./tests --test_type unit --framework pytest --coverage true
```

Exécute les tests unitaires avec `pytest` et génère un rapport de couverture.

## generate_docs

**But** : Générer automatiquement la documentation d'un projet (README, commentaires de code, API docs).

**Utilisation** : Crée ou met à jour la documentation à partir du code source ou de fichiers de configuration (par exemple, OpenAPI pour les API, docstrings pour Python, JSDoc pour JavaScript).

**Paramètres** :

*   `path` : Chemin vers le projet ou fichier à documenter (obligatoire).
*   `format` : Format de sortie (`markdown`, `html`, `pdf`) (facultatif).
*   `tool` : Outil de génération de documentation (`pydoc`, `jsdoc`, `godoc`, etc.) (facultatif).

**Sortie** : Fichiers de documentation générés ou mise à jour d'un répertoire de documentation.

**Compréhension essentielle** :

*   Cet outil améliore la maintenabilité et la lisibilité du code, en respectant KISS (simplicité de la génération) et DRY (éviter la duplication manuelle).
*   Essentiel pour les équipes collaboratives et les intégrations avec des outils comme Notion ou Confluence.
*   Peut être combiné avec `list_code_definition_names` pour identifier les éléments à documenter.

**Exemple d'utilisation** :

```bash
generate_docs --path ./src --format markdown --tool pydoc
```

Génère une documentation Markdown à partir des docstrings Python dans le répertoire `src`.

## deploy_project

**But** : Déployer un projet vers un environnement cible (serveur, cloud, conteneur).

**Utilisation** : Automatise le déploiement d'une application via des outils comme Docker, Kubernetes, ou des services cloud (AWS, GCP, Azure).

**Paramètres** :

*   `path` : Chemin vers le projet à déployer (obligatoire).
*   `target` : Environnement cible (`local`, `aws`, `kubernetes`, etc.) (obligatoire).
*   `rollback` : Activer la possibilité de rollback en cas d'échec (booléen, facultatif).
*   `monitor` : Activer la surveillance post-déploiement (booléen, facultatif).

**Sortie** : Statut du déploiement (succès, échec, logs).

**Compréhension essentielle** :

*   Intègre les principes SOLID en isolant la logique de déploiement dans un outil dédié.
*   Permet une gestion robuste des déploiements avec rollback et monitoring, essentiel pour les environnements de production.
*   Peut être combiné avec `execute_command` pour des tâches spécifiques dans le pipeline de déploiement.

**Exemple d'utilisation** :

```bash
deploy_project --path ./my_app --target aws --rollback true --monitor true
```

Déploie l'application sur AWS avec rollback et monitoring activés.

## analyze_performance

**But** : Analyser les performances d'un script ou d'une application (CPU, mémoire, latence).

**Utilisation** : Mesure les métriques de performance pour identifier les goulots d'étranglement, optimiser les scripts, ou valider la scalabilité.

**Paramètres** :

*   `path` : Chemin vers le script ou l'application à analyser (obligatoire).
*   `metrics` : Métriques à collecter (`cpu`, `memory`, `latency`) (facultatif, toutes par défaut).
*   `load` : Simuler une charge (par exemple, 100 utilisateurs) (facultatif).
*   `duration` : Durée de l'analyse en secondes (facultatif).

**Sortie** : Rapport des performances (métriques, graphiques si demandé).

**Compréhension essentielle** :

*   Cet outil est crucial pour optimiser les performances, un aspect clé du *vibe coding* pour garantir la scalabilité.
*   Peut être utilisé après `apply_diff` ou `write_file` pour valider l'impact des modifications.
*   Respecte KISS en fournissant des métriques claires et exploitables.

**Exemple d'utilisation** :

```bash
analyze_performance --path ./api_server.py --metrics cpu,memory --load 100 --duration 60
```

Analyse l'utilisation CPU et mémoire du script `api_server.py` sous une charge de 100 utilisateurs pendant 60 secondes.

## Autres méthodes de modification de fichiers

*   **Atomic Replacement** : Créer une copie temporaire, modifier, renommer et supprimer l'original.
*   **In-place editing** : Modification du fichier directement, sans copie temporaire. Rapide, mais risque de corruption.
*   **Copy-on-write (COW)** : Seules les parties modifiées sont copiées. Efficace pour les modifications partielles.
*   **Journaling** : Enregistrement des modifications dans un journal avant de les appliquer. Permet de restaurer l'état en cas d'erreur.
*   **Shadowing (Copie fantôme)** : Modifications sur une copie "fantôme" fusionnée avec la version principale. Permet de gérer les conflits.
*   **Méthodes basées sur des transactions** : Utilisation de transactions pour garantir l'atomicité des opérations.


## Opérations par lot et sélection de fichiers

Certains outils permettent d'effectuer des opérations sur plusieurs fichiers à la fois, en utilisant des techniques comme :

*   **Globbing** : Utilisation de caractères spéciaux (comme `*` et `?`) pour sélectionner des fichiers correspondant à un motif. Par exemple, `*.txt` sélectionne tous les fichiers avec l'extension `.txt`.
*   **Sélection par lot** : Spécification d'une liste de fichiers ou de répertoires sur lesquels effectuer une opération.
*   **Exécution de commandes en boucle** : Utilisation de scripts ou de commandes shell pour itérer sur une liste de fichiers et effectuer une opération sur chacun d'eux.

Consultez la documentation de chaque outil pour savoir s'il prend en charge ces fonctionnalités.

L'outil `search_files` permet d'utiliser des expressions régulières et le paramètre `file_pattern`, ce qui inclut la fonctionnalité de globbing pour la sélection de fichiers. Pour d'autres opérations par lots, il est nécessaire de combiner `list_files` avec `execute_command` et des scripts shell.