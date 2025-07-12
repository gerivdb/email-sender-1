# Référence des outils

**Table des matières**

*   [read_file](#read_file)
*   [apply_diff](#apply_diff)
*   [write_file](#write_file)
*   [search_and_replace](#search_and_replace)
*   [list_files](#list_files)
*   [list_code_definition_names](#list_code_definition_names)
*   [execute_command](#execute_command)

Ce document décrit les outils disponibles pour interagir avec le système.

========

## read_file

### But : Lire le contenu d'un ou plusieurs fichiers.

### Utilisation : Permet d'obtenir le contenu actuel d'un fichier avant de le modifier. Ceci est crucial pour comprendre le contexte et s'assurer que les modifications sont basées sur la version la plus récente du fichier.

### Paramètres :

*   `path` : Chemin d'accès au fichier (obligatoire).

*   `line_range` : Permet de spécifier les lignes à lire (facultatif, mais recommandé pour les grands fichiers).

**Note :** Cline a contribué à des améliorations pour la lecture de fichiers larges avec cet outil.

**Sortie :** Le contenu du fichier, avec les numéros de ligne.

========

#### Erreurs courantes et comment les éviter :

*   **Erreur : Le fichier n'existe pas.**

    *   Cause : Le chemin d'accès au fichier est incorrect.
    *   Solution : Vérifiez que le chemin d'accès au fichier est correct.

*   **Erreur : Le fichier est trop grand pour être lu.**

    *   Cause : Le fichier dépasse la limite de taille autorisée.
    *   Solution : Utilisez le paramètre `line_range` pour lire seulement une partie du fichier.

**Exemples d'utilisation** :

**Exemple 1 : Lire le contenu d'un fichier**

```
<read_file>
<path>monfichier.txt</path>
</read_file>
```

**Exemple 2 : Lire seulement les 10 premières lignes d'un fichier**

```
<read_file>
<path>monfichier.txt</path>
<line_range>1-10</line_range>
</read_file>
```

========

## apply_diff

### But : Appliquer une modification (diff) à un fichier existant.

### Utilisation : Permet de modifier un fichier en remplaçant des lignes spécifiques par un nouveau contenu. L'outil compare le contenu recherché avec le contenu actuel du fichier et applique la modification uniquement si la correspondance est parfaite.

### Paramètres :

*   `path` : Chemin d'accès au fichier (obligatoire).
*   `diff` : Contient les informations sur la modification à effectuer.
    *   `content` : Contient le contenu à rechercher (SEARCH) et le contenu de remplacement (REPLACE).
*   `start_line` : Numéro de la première ligne à remplacer.

========

#### Erreurs courantes et comment les éviter :

*   **Erreur : La modification échoue car le contenu recherché ne correspond pas exactement au contenu du fichier.**

    *   Cause : Des espaces, des sauts de ligne ou d'autres caractères invisibles peuvent être différents.
    *   Solution : Utilisez `read_file` pour obtenir le contenu exact du fichier et assurez-vous que le contenu recherché dans `apply_diff` est identique.

*   **Erreur : La modification échoue car le fichier a été modifié entre le moment où vous avez lu le contenu et le moment où vous avez essayé d'appliquer le diff.**

    *   Cause : Un autre processus ou utilisateur a modifié le fichier.
    *   Solution : Relisez le fichier avant d'appliquer le diff pour vous assurer que vous travaillez avec la version la plus récente.

*   **Erreur : Utilisation incorrecte de `start_line`.**

    *   Cause : `start_line` ne correspond pas à la ligne où le contenu recherché se trouve.
    *   Solution : Utilisez `read_file` pour vérifier les numéros de ligne et assurez-vous que `start_line` est correct.

**Exemples d'utilisation** :

**Exemple 1 : Remplacer une ligne spécifique dans un fichier**

Supposons que vous ayez le fichier suivant `monfichier.txt` :

```
ligne 1
ligne 2
ligne 3
```

Et vous voulez remplacer "ligne 2" par "nouvelle ligne 2". Vous devez d'abord lire le fichier :

```
<read_file>
<path>monfichier.txt</path>
</read_file>
```

La sortie de `read_file` sera :

```
ligne 1
ligne 2
ligne 3
```

Ensuite, vous pouvez utiliser `apply_diff` pour remplacer la ligne :

```
<apply_diff>
<path>monfichier.txt</path>
<diff>
------- SEARCH
ligne 2
=======
nouvelle ligne 2
+++++++ REPLACE
</diff>
</apply_diff>
```

**Exemple 2 : Ajouter une nouvelle ligne après une ligne existante**

Supposons que vous ayez le même fichier `monfichier.txt` :

```
ligne 1
ligne 2
ligne 3
```

Et vous voulez ajouter une nouvelle ligne après "ligne 2". Vous devez d'abord lire le fichier :

```
<read_file>
<path>monfichier.txt</path>
</read_file>
```

La sortie de `read_file` sera :

```
ligne 1
ligne 2
ligne 3
```

Ensuite, vous pouvez utiliser `apply_diff` pour ajouter la nouvelle ligne :

```
<apply_diff>
<path>monfichier.txt</path>
<diff>
------- SEARCH
ligne 2
=======
ligne 2
nouvelle ligne
+++++++ REPLACE
</diff>
</apply_diff>
```

**Compréhension essentielle** :

*   La correspondance entre le contenu recherché (SEARCH) et le contenu actuel du fichier doit être *exacte* (y compris les espaces, les sauts de ligne, etc.). Sinon, la modification échouera.
*   Il est *impératif* d'utiliser `read_file` pour obtenir le contenu actuel du fichier avant d'utiliser `apply_diff`. Cela permet de s'assurer que le contenu recherché correspond bien à la version actuelle du fichier.
*   Si des modifications ont été apportées au fichier entre le moment où vous avez lu le contenu et le moment où vous essayez d'appliquer le diff, la modification échouera.

========

## write_file

### But : Écrire (ou remplacer) le contenu complet d'un fichier.

### Utilisation : Permet de créer un nouveau fichier ou de remplacer complètement le contenu d'un fichier existant.

### Paramètres :

*   `path` : Chemin d'accès au fichier (obligatoire).
*   `content` : Le contenu complet à écrire dans le fichier (obligatoire).

**Compréhension essentielle** :

*   Cet outil *remplace* tout le contenu existant du fichier. Il est donc crucial de fournir le contenu *complet* du fichier, et non seulement les parties modifiées.
*   Contrairement à `apply_diff`, il n'y a pas de vérification de correspondance. Le contenu fourni est simplement écrit dans le fichier.
*   Cet outil est plus lent que `apply_diff` et ne peut pas gérer les fichiers de très grande taille.

**Quand utiliser `apply_diff` vs `write_file` ?**

*   Utiliser `apply_diff` pour des modifications ciblées et précises, lorsque vous connaissez exactement le contenu à remplacer. C'est idéal pour les modifications de code où vous voulez éviter de remplacer tout le fichier.
*   Utiliser `write_file` pour créer de nouveaux fichiers ou pour remplacer *entièrement* le contenu d'un fichier existant. À utiliser avec prudence, car cela peut écraser des modifications non sauvegardées.

========

#### Erreurs courantes et comment les éviter :

*   **Erreur : Le fichier est écrasé avec un contenu incorrect.**

    *   Cause : Le contenu fourni à `write_file` est incomplet ou incorrect.
    *   Solution : Vérifiez attentivement que le contenu fourni à `write_file` est complet et correct.

*   **Erreur : Le fichier est créé à un emplacement incorrect.**

    *   Cause : Le chemin d'accès au fichier est incorrect.
    *   Solution : Vérifiez que le chemin d'accès au fichier est correct.

**Exemples d'utilisation** :

**Exemple 1 : Créer un nouveau fichier**

```
<write_file>
<path>monfichier.txt</path>
<content>Ceci est le contenu du fichier.</content>
</write_file>
```

**Exemple 2 : Remplacer le contenu d'un fichier existant (ATTENTION : remplace tout le contenu !)**

**Important :** L'outil `write_file` *remplace complètement* le contenu du fichier. Assurez-vous de fournir le contenu *complet* du fichier, et non seulement les parties modifiées. Si vous ne fournissez pas le contenu complet, vous risquez d'écraser des données importantes.

```
<write_file>
<path>monfichier.txt</path>
<content>Ceci est le nouveau contenu complet du fichier.
Il inclut toutes les lignes, même celles qui n'ont pas été modifiées.
</content>
</write_file>
```

**Quand utiliser `apply_diff` vs `write_file` ?**

*   Utiliser `apply_diff` pour des modifications ciblées et précises, lorsque vous connaissez exactement le contenu à remplacer. C'est idéal pour les modifications de code où vous voulez éviter de remplacer tout le fichier.
*   Utiliser `write_file` pour créer de nouveaux fichiers ou pour remplacer *entièrement* le contenu d'un fichier existant. À utiliser avec prudence, car cela peut écraser des modifications non sauvegardées. De plus, cet outil est plus lent que `apply_diff` et ne peut pas gérer les fichiers de très grande taille.

========

## search_and_replace

### But : Rechercher et remplacer du texte dans un fichier.

### Utilisation : Permet de trouver une chaîne de caractères (ou une expression régulière) dans un fichier et de la remplacer par une autre chaîne.

### Paramètres :

*   `path` : Chemin d'accès au fichier (obligatoire).
*   `search` : La chaîne de caractères (ou l'expression régulière) à rechercher (obligatoire).
*   `replace` : La chaîne de caractères de remplacement (obligatoire).
*    `start_line` : ligne de début de la recherche.
*    `end_line` : ligne de fin de la recherche.

**Compréhension essentielle** :

*   Cet outil est utile pour remplacer des occurrences spécifiques de texte, mais il ne permet pas de faire des modifications complexes basées sur le contexte.
*   Les expressions régulières peuvent être utilisées pour des recherches plus flexibles, mais il est important de bien les maîtriser pour éviter des remplacements involontaires.

========

#### Erreurs courantes et comment les éviter :

*   **Erreur : La chaîne de caractères à rechercher n'est pas trouvée.**

    *   Cause : La chaîne de caractères à rechercher est incorrecte ou n'existe pas dans le fichier.
    *   Solution : Vérifiez que la chaîne de caractères à rechercher est correcte et qu'elle existe dans le fichier.

*   **Erreur : La chaîne de caractères de remplacement est incorrecte.**

    *   Cause : La chaîne de caractères de remplacement est incorrecte ou contient des erreurs de syntaxe.
    *   Solution : Vérifiez que la chaîne de caractères de remplacement est correcte et qu'elle ne contient pas d'erreurs de syntaxe.

**Exemples d'utilisation** :

**Exemple 1 : Remplacer une chaîne de caractères par une autre**

```
<search_and_replace>
<path>monfichier.txt</path>
<search>ancienne chaîne</search>
<replace>nouvelle chaîne</replace>
</search_and_replace>
```

**Exemple 2 : Remplacer une chaîne de caractères par une autre en utilisant une expression régulière**

```
<search_and_replace>
<path>monfichier.txt</path>
<search>[0-9]+</search>
<replace>nombre</replace>
</search_and_replace>
```

========
## list_files

### But : Lister les fichiers et répertoires dans un répertoire donné.

### Utilisation : Permet d'explorer la structure du projet, de vérifier l'existence de fichiers, de trouver des fichiers spécifiques, etc.

### Paramètres :

*   `path` : Chemin d'accès au répertoire (obligatoire).
*   `recursive` : Indique si la liste doit être récursive (facultatif).

**Compréhension essentielle** :

*   Cet outil est utile pour obtenir une vue d'ensemble de la structure du projet, mais il ne fournit pas le contenu des fichiers.

========

#### Erreurs courantes et comment les éviter :

*   **Erreur : Le répertoire n'existe pas.**

    *   Cause : Le chemin d'accès au répertoire est incorrect.
    *   Solution : Vérifiez que le chemin d'accès au répertoire est correct.

*   **Erreur : La liste des fichiers est trop longue.**

    *   Cause : Le répertoire contient un grand nombre de fichiers et de répertoires.
    *   Solution : Utilisez le paramètre `recursive` avec prudence, car il peut générer une liste très longue.

**Exemples d'utilisation** :

**Exemple 1 : Lister les fichiers et répertoires dans un répertoire**

```xml
  <list_files>
    <path>.</path>
  </list_files>
```

**Exemple 2 : Lister les fichiers et répertoires dans un répertoire de manière récursive**

```
<list_files>
<path>monrepertoire</path>
<recursive>true</recursive>
</list_files>
```

========
## list_code_definition_names

### But : Lister les noms des définitions de code (classes, fonctions, méthodes, etc.) dans un fichier ou un répertoire.

### Utilisation : Permet d'obtenir une vue d'ensemble des composants d'un module ou d'un fichier, de comprendre les relations entre les différents éléments du code, etc.

### Paramètres :

*   `path` : Chemin d'accès au fichier ou au répertoire (obligatoire).

**Compréhension essentielle** :

*   Cet outil est utile pour comprendre la structure et l'organisation du code, mais il ne fournit pas le code lui-même.

========

#### Erreurs courantes et comment les éviter :

*   **Erreur : Le fichier ou le répertoire n'existe pas.**

    *   Cause : Le chemin d'accès au fichier ou au répertoire est incorrect.
    *   Solution : Vérifiez que le chemin d'accès au fichier ou au répertoire est correct.

*   **Erreur : Le fichier n'est pas un fichier de code source.**

    *   Cause : Le fichier n'est pas un fichier de code source valide (par exemple, un fichier texte ou un fichier image).
    *   Solution : Utilisez cet outil seulement avec des fichiers de code source valides.

**Exemples d'utilisation** :

**Exemple 1 : Lister les noms des définitions de code dans un fichier**

```
<list_code_definition_names>
<path>monfichier.py</path>
</list_code_definition_names>
```

**Exemple 2 : Lister les noms des définitions de code dans un répertoire**

```
<list_code_definition_names>
<path>monrepertoire</path>
</list_code_definition_names>
```

========
## execute_command

### But : Exécuter une commande dans un terminal.

### Utilisation : Permet d'automatiser des tâches, d'exécuter des scripts, de compiler du code, etc.

### Paramètres :

*   `command` : La commande à exécuter (obligatoire).

**Compréhension essentielle** :

*   Cet outil est très puissant, mais il doit être utilisé avec précaution. Il est important de bien comprendre la commande à exécuter et de s'assurer qu'elle ne causera pas de problèmes.
*   Il est important de bien comprendre l'environnement d'exécution (système d'exploitation, shell, etc.) pour s'assurer que la commande est exécutée correctement.

========

#### Erreurs courantes et comment les éviter :

*   **Erreur : La commande n'est pas reconnue.**

    *   Cause : La commande n'est pas installée sur le système ou n'est pas dans le PATH.
    *   Solution : Vérifiez que la commande est installée et qu'elle est dans le PATH.

*   **Erreur : La commande échoue avec une erreur.**

    *   Cause : La commande a rencontré une erreur lors de son exécution.
    *   Solution : Analysez le message d'erreur pour comprendre la cause du problème et corrigez-le.

**Exemples d'utilisation** :

**Exemple 1 : Exécuter une commande simple**

```
<execute_command>
<command>ls -l</command>
</execute_command>
```

**Exemple 2 : Exécuter une commande qui prend des paramètres**

```
<execute_command>
<command>git commit -m "Ajout d'une nouvelle fonctionnalité"</command>
</execute_command>
```

## install_dependencies

### But : Installer ou mettre à jour les dépendances d'un projet dans un environnement donné.

### Utilisation : Permet d'automatiser l'installation des dépendances définies dans des fichiers comme `requirements.txt` (Python), `package.json` (Node.js), `go.mod` (Go), ou autres, en tenant compte des environnements (dev, prod, staging).

### Paramètres :

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

### But : Exécuter des tests unitaires, d'intégration ou de performance dans un projet.

### Utilisation : Permet de valider le code avant un déploiement ou une modification, en exécutant des suites de tests définies dans des frameworks comme `pytest` (Python), `Jest` (JavaScript/TypeScript), ou `go test` (Go).

### Paramètres :

*   `path` : Chemin vers le répertoire contenant le fichier de dépendances (obligatoire).
*   `env` : Environnement cible (`dev`, `prod`, `staging`) (facultatif).
*   `package_manager` : Gestionnaire de paquets à utiliser (`pip`, `npm`, `yarn`, `go`, etc.) (facultatif, autodétection par défaut).
*   `version` : Version spécifique des dépendances à installer (facultatif).

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

### But : Générer automatiquement la documentation d'un projet (README, commentaires de code, API docs).

### Utilisation : Crée ou met à jour la documentation à partir du code source ou de fichiers de configuration (par exemple, OpenAPI pour les API, docstrings pour Python, JSDoc pour JavaScript).

### Paramètres :

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

### But : Déployer un projet vers un environnement cible (serveur, cloud, conteneur).

### Utilisation : Automatise le déploiement d'une application via des outils comme Docker, Kubernetes, ou des services cloud (AWS, GCP, Azure).

### Paramètres :

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

### But : Analyser les performances d'un script ou d'une application (CPU, mémoire, latence).

### Utilisation : Mesure les métriques de performance pour identifier les goulots d'étranglement, optimiser les scripts, ou valider la scalabilité.

### Paramètres :

*   `path` : Chemin d'accès au script ou l'application à analyser (obligatoire).
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
