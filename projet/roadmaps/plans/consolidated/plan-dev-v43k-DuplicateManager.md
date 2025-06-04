Plan de Développement v43h - DuplicateManager
Version 1.0 - 2025-06-04 - Progression globale : 0%
Ce plan détaille l'implémentation du DuplicateManager pour le projet EMAIL_SENDER_1, chargé de détecter, journaliser, et prévenir les duplications de scripts et de fonctions dans le dépôt. Il surveille les déclarations, compare les contenus des scripts (Go, PowerShell, Python), et maintient une base de données synchronisée pour visualiser les fichiers similaires. Le gestionnaire s'intègre avec ConfigManager, ErrorManager, MonitoringManager, et d'autres managers définis dans plan-dev-v43-managers-plan.md, tout en offrant des fonctionnalités avancées par rapport à des outils comme VS Code et GitHub Copilot. L'implémentation privilégie Go natif avec des bibliothèques standard (hash, filepath, sql) et utilise une base de données (PostgreSQL) pour stocker les métadonnées des fichiers.
Table des matières

[1] Phase 1: Analyse et Surveillance des Fichiers
[2] Phase 2: Comparaison et Détection des Duplications
[3] Phase 3: Journalisation et Base de Données
[4] Phase 4: Intégration avec les Autres Managers
[5] Phase 5: Visualisation des Duplications
[6] Phase 6: Tests et Validation
[7] Phase 7: Documentation et Guides
[8] Phase 8: Déploiement et Maintenance

Phase 1: Analyse et Surveillance des Fichiers
Progression: 0%
1.1 Mise en place du Watcher de Fichiers
Progression: 0%
1.1.1 Configuration du Watcher avec fsnotify

[ ] Implémenter un watcher pour surveiller les modifications dans le dépôt.
[ ] Utiliser la bibliothèque github.com/fsnotify/fsnotify pour détecter les créations, modifications, et suppressions de fichiers.
[ ] Configurer le watcher pour cibler les extensions .go, .ps1, et .py.
[ ] Créer une méthode WatchFiles dans duplicate_manager.go.


Entrées : Chemin du dépôt (./projet).
Sorties : Événements de fichiers (création, modification, suppression).
Conditions préalables : Bibliothèque fsnotify installée via go.mod.
Tests unitaires :
Cas nominal : Simuler la création d’un fichier .go et vérifier la capture de l’événement.
Cas limite : Tester avec un dépôt vide.
Erreur simulée : Simuler une erreur de permission sur un dossier.


Dry-run : Exécuter le watcher en mode simulation sans enregistrer les événements.

1.1.2 Analyse des Déclarations de Fichiers

[ ] Parser les fichiers pour extraire les déclarations (fonctions, classes, scripts).
[ ] Utiliser go/parser pour les fichiers Go.
[ ] Utiliser un parseur PowerShell personnalisé pour .ps1.
[ ] Utiliser ast de Python pour .py.
[ ] Créer une méthode ParseDeclarations dans duplicate_manager.go.


Entrées : Fichiers .go, .ps1, .py.
Sorties : Liste des déclarations (nom, type, contenu).
Conditions préalables : Fichiers accessibles en lecture.
Tests unitaires :
Cas nominal : Parser un fichier Go avec une fonction exampleFunc.
Cas limite : Parser un fichier vide.
Erreur simulée : Parser un fichier mal formé.


Dry-run : Simuler le parsing sans stocker les résultats.

1.2 Mise à jour

[ ] Mettre à jour le fichier Markdown en cochant les tâches terminées.
[ ] Ajuster la progression de la phase (ex. : 50% après 1.1.1 et 1.1.2).

Phase 2: Comparaison et Détection des Duplications
Progression: 0%
2.1 Calcul des Signatures de Fichiers

[ ] Générer des hachages pour identifier les similarités.
[ ] Utiliser hash/fnv pour créer des hachages rapides des déclarations.
[ ] Normaliser le contenu (ignorer les espaces, commentaires) avant hachage.
[ ] Créer une méthode ComputeFileSignature dans duplicate_manager.go.


Entrées : Contenu des déclarations extraites.
Sorties : Hachage unique par déclaration.
Tests unitaires :
Cas nominal : Deux fonctions identiques génèrent le même hachage.
Cas limite : Deux fonctions avec des commentaires différents.
Erreur simulée : Contenu non parsable.


Dry-run : Simuler le calcul des hachages sans stockage.

2.2 Détection des Duplications

[ ] Comparer les hachages pour détecter les duplications.
[ ] Créer une méthode DetectDuplicates pour regrouper les fichiers similaires.
[ ] Générer un rapport duplicates-report.json avec les paires de fichiers similaires.


Entrées : Liste des hachages.
Sorties : Fichier JSON (duplicates-report.json).
Tests unitaires :
Cas nominal : Détecter deux fonctions identiques dans des fichiers différents.
Cas limite : Aucun doublon détecté.
Erreur simulée : Fichier corrompu.


Dry-run : Simuler la détection sans écrire le rapport.

2.3 Mise à jour

[ ] Mettre à jour le fichier Markdown en cochant les tâches terminées.
[ ] Ajuster la progression de la phase.

Phase 3: Journalisation et Base de Données
Progression: 0%
3.1 Configuration de la Base de Données

[ ] Créer une table PostgreSQL pour stocker les métadonnées des fichiers.
[ ] Schéma : files (id, path, hash, declaration_type, declaration_name, timestamp).
[ ] Créer un script SQL init_duplicate_db.sql pour initialiser la table.


Entrées : Connexion PostgreSQL via StorageManager.
Sorties : Table créée.
Tests unitaires :
Cas nominal : Création réussie de la table.
Cas limite : Table déjà existante.
Erreur simulée : Connexion à la base échouée.


Dry-run : Simuler la création sans modifier la base.

3.2 Synchronisation des Métadonnées

[ ] Enregistrer les événements du watcher dans la base.
[ ] Créer une méthode SyncFileMetadata dans duplicate_manager.go.
[ ] Utiliser StorageManager pour les opérations CRUD.


Entrées : Événements du watcher, hachages.
Sorties : Enregistrements dans la table files.
Tests unitaires :
Cas nominal : Enregistrer un fichier créé.
Cas limite : Aucun événement à synchroniser.
Erreur simulée : Erreur d’insertion SQL.


Dry-run : Simuler l’insertion sans modification.

3.3 Mise à jour

[ ] Mettre à jour le fichier Markdown en cochant les tâches terminées.
[ ] Ajuster la progression de la phase.

Phase 4: Intégration avec les Autres Managers
Progression: 0%
4.1 Intégration avec ConfigManager

[ ] Charger les configurations du watcher depuis ConfigManager.
[ ] Créer une méthode LoadWatcherConfig pour récupérer les chemins surveillés et extensions.


Entrées : Configurations via ConfigManager.
Sorties : Paramètres du watcher.
Tests unitaires :
Cas nominal : Charger une configuration valide.
Cas limite : Configuration vide.
Erreur simulée : Clé de configuration manquante.



4.2 Intégration avec ErrorManager

[ ] Journaliser les erreurs de détection dans ErrorManager.
[ ] Créer une méthode LogDuplicateError pour signaler les duplications.


Entrées : Erreurs détectées (ex. : parsing échoué).
Sorties : Logs dans ErrorManager.
Tests unitaires :
Cas nominal : Journaliser une erreur de parsing.
Cas limite : Aucune erreur à journaliser.
Erreur simulée : Connexion à ErrorManager échouée.



4.3 Intégration avec MonitoringManager

[ ] Exposer les métriques de duplication via MonitoringManager.
[ ] Créer une méthode ExposeDuplicateMetrics pour les statistiques (nombre de doublons, fichiers surveillés).


Entrées : Données de la base.
Sorties : Métriques exposées.
Tests unitaires :
Cas nominal : Exposer 10 doublons détectés.
Cas limite : Aucune métrique à exposer.
Erreur simulée : Échec de connexion à MonitoringManager.



4.4 Mise à jour

[ ] Mettre à jour le fichier Markdown en cochant les tâches terminées.
[ ] Ajuster la progression de la phase.

Phase 5: Visualisation des Duplications
Progression: 0%
5.1 Génération de Rapports Visuels

[ ] Créer un rapport Markdown duplicates-visual-report.md pour visualiser les doublons.
[ ] Inclure des tableaux et des graphiques (via Mermaid si intégré).
[ ] Créer une méthode GenerateVisualReport dans duplicate_manager.go.


Entrées : Données de la base files.
Sorties : Fichier duplicates-visual-report.md.
Tests unitaires :
Cas nominal : Générer un rapport avec 5 doublons.
Cas limite : Aucun doublon à visualiser.
Erreur simulée : Échec d’écriture du fichier.



5.2 Interface CLI pour Visualisation

[ ] Implémenter une commande CLI pour interroger les doublons.
[ ] Créer une méthode RunCLIVisualization dans duplicate_manager.go.


Entrées : Arguments CLI (ex. : --path, --type).
Sorties : Affichage tabulaire des doublons.
Tests unitaires :
Cas nominal : Afficher les doublons pour .go.
Cas limite : Aucun doublon trouvé.
Erreur simulée : Argument CLI invalide.



5.3 Mise à jour

[ ] Mettre à jour le fichier Markdown en cochant les tâches terminées.
[ ] Ajuster la progression de la phase.

Phase 6: Tests et Validation
Progression: 0%
6.1 Tests Intégrés

[ ] Exécuter des tests d’intégration pour le DuplicateManager.
[ ] Simuler un dépôt avec des fichiers dupliqués.
[ ] Vérifier la détection, la journalisation, et la visualisation.


Entrées : Dépôt de test avec fichiers .go, .ps1, .py.
Sorties : Résultats des tests (succès/échec).
Tests unitaires :
Cas nominal : Détection correcte de 3 doublons.
Cas limite : Dépôt sans doublons.
Erreur simulée : Échec du watcher.



6.2 Validation Dry-Run

[ ] Exécuter un dry-run complet pour toutes les opérations.
[ ] Créer une méthode RunDryRun pour simuler toutes les étapes.


Entrées : Configurations et dépôt.
Sorties : Rapport de simulation.
Tests unitaires :
Cas nominal : Dry-run sans erreur.
Cas limite : Aucun fichier à analyser.
Erreur simulée : Échec simulé du watcher.



6.3 Mise à jour

[ ] Mettre à jour le fichier Markdown en cochant les tâches terminées.
[ ] Ajuster la progression de la phase.

Phase 7: Documentation et Guides
Progression: 0%
7.1 Documentation Technique

[ ] Rédiger duplicate-manager-docs.md pour les développeurs.
[ ] Décrire les méthodes, interfaces, et intégrations.


Entrées : Code source du DuplicateManager.
Sorties : Fichier duplicate-manager-docs.md.
Tests unitaires : Vérifier la présence du fichier généré.

7.2 Guide Utilisateur

[ ] Rédiger duplicate-user-guide.md pour les utilisateurs finaux.
[ ] Expliquer comment utiliser la CLI et interpréter les rapports.


Entrées : Rapports générés.
Sorties : Fichier duplicate-user-guide.md.
Tests unitaires : Vérifier la présence du fichier généré.

7.3 Mise à jour

[ ] Mettre à jour le fichier Markdown en cochant les tâches terminées.
[ ] Ajuster la progression de la phase.

Phase 8: Déploiement et Maintenance
Progression: 0%
8.1 Intégration CI/CD

[ ] Configurer des pipelines GitHub Actions pour tester et déployer le DuplicateManager.
[ ] Créer un fichier .github/workflows/duplicate-manager.yml.


Entrées : Code source et tests.
Sorties : Pipeline fonctionnel.
Tests unitaires :
Cas nominal : Pipeline exécuté avec succès.
Cas limite : Échec d’un test unitaire.
Erreur simulée : Échec de connexion à PostgreSQL.



8.2 Maintenance Continue

[ ] Planifier des mises à jour régulières du watcher et de la base.
[ ] Créer une méthode UpdateDuplicateManager pour gérer les migrations.


Entrées : Nouvelles versions des dépendances.
Sorties : Gestionnaire mis à jour.
Tests unitaires :
Cas nominal : Mise à jour sans erreur.
Cas limite : Aucune mise à jour nécessaire.
Erreur simulée : Dépendance incompatible.



8.3 Mise à jour

[ ] Mettre à jour le fichier Markdown en cochant les tâches terminées.
[ ] Ajuster la progression de la phase.

