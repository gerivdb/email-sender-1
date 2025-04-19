# Glossaire du système de journal de bord RAG

Ce glossaire définit les termes techniques utilisés dans le système de journal de bord RAG.

## A

### API (Application Programming Interface)
Interface permettant à des applications de communiquer entre elles. Dans notre système, l'API FastAPI expose les fonctionnalités du journal de bord.

### Analyse avancée
Ensemble de techniques d'analyse de texte et de visualisation permettant d'extraire des insights et d'identifier des tendances dans le journal de bord.

### Augment Memories
Système développé par Anthropic permettant aux modèles d'IA d'accéder à des connaissances persistantes. Notre système s'intègre avec Augment Memories pour enrichir le contexte des modèles.

### Automatisation
Processus permettant d'exécuter des tâches sans intervention humaine. Notre système utilise des tâches planifiées et des hooks Git pour automatiser certaines opérations.

## C

### Clustering
Technique d'analyse qui regroupe les entrées du journal par similarité de contenu. Notre système utilise K-means pour le clustering.

### Commit
Enregistrement d'un ensemble de modifications dans un dépôt Git. Notre système lie les entrées du journal aux commits pertinents.

## E

### Embeddings vectoriels
Représentations numériques de texte dans un espace vectoriel, permettant de capturer la sémantique du texte. Ils sont utilisés pour la recherche sémantique.

### Entrée de journal
Document Markdown structuré avec des métadonnées YAML qui capture les actions, erreurs, optimisations et enseignements liés au projet.

## F

### FastAPI
Framework web Python moderne et performant utilisé pour implémenter l'API REST du système.

## G

### GitHub
Plateforme de développement collaboratif basée sur Git. Notre système s'intègre avec GitHub pour lier les entrées du journal aux commits et issues.

## H

### Hook Git
Script exécuté automatiquement à certains moments du workflow Git. Notre système utilise un hook pre-commit pour maintenir à jour les liens entre le journal et GitHub.

## I

### Issue GitHub
Élément de suivi dans GitHub pour les bugs, fonctionnalités ou tâches. Notre système lie les entrées du journal aux issues pertinentes et peut créer des entrées à partir d'issues.

### Interface web
Interface utilisateur web permettant d'accéder à toutes les fonctionnalités du système de journal de bord.

## J

### Journal de bord
Ensemble d'entrées structurées qui documentent les actions, erreurs, optimisations et enseignements liés au projet.

## K

### K-means
Algorithme de clustering qui partitionne les données en K groupes en minimisant la distance entre les points et le centre de leur cluster. Utilisé pour le clustering des entrées.

## M

### Markdown
Langage de balisage léger utilisé pour formater les entrées du journal.

### MCP (Model Context Protocol)
Protocole développé par Anthropic permettant aux modèles d'IA d'interagir avec des systèmes externes. Notre système expose ses fonctionnalités via MCP.

### Métadonnées
Données décrivant d'autres données. Dans notre système, les métadonnées YAML en en-tête des entrées contiennent des informations comme la date, l'heure, le titre et les tags.

## N

### Nuage de mots
Visualisation qui représente les termes les plus fréquents, où la taille de chaque mot est proportionnelle à sa fréquence.

## P

### PowerShell
Langage de script et shell développé par Microsoft. Nos scripts d'automatisation sont écrits en PowerShell.

### Provider MCP
Composant qui expose des fonctionnalités à travers le protocole MCP. Notre système implémente un provider MCP pour le journal de bord.

## R

### RAG (Retrieval-Augmented Generation)
Technique qui combine la recherche d'informations pertinentes (retrieval) avec la génération de réponses contextuelles (generation). Notre système utilise RAG pour interroger le journal en langage naturel.

### Recherche sémantique
Technique de recherche qui comprend l'intention et le contexte de la requête, plutôt que de se limiter à la correspondance de mots-clés.

## S

### Slug
Version simplifiée d'un texte (sans accents, en minuscules, avec des tirets) utilisée pour les noms de fichiers.

### Système de tâches planifiées
Fonctionnalité de Windows permettant d'exécuter des tâches à des moments spécifiques. Notre système utilise des tâches planifiées pour l'automatisation.

## T

### Tag
Mot-clé associé à une entrée pour faciliter la catégorisation et la recherche.

### TF-IDF (Term Frequency-Inverse Document Frequency)
Mesure statistique qui évalue l'importance d'un terme dans un document par rapport à un corpus. Utilisée pour la vectorisation du texte dans le clustering.

## U

### Uvicorn
Serveur ASGI pour Python, utilisé pour exécuter l'application FastAPI.

## V

### Vectorisation
Processus de conversion de texte en vecteurs numériques pour l'analyse. Notre système utilise TF-IDF pour la vectorisation.

## W

### WebSockets
Protocole de communication bidirectionnelle en temps réel. Prévu pour les futures versions de l'interface web.

## Y

### YAML (YAML Ain't Markup Language)
Format de sérialisation de données lisible par les humains. Utilisé pour les métadonnées des entrées du journal.
