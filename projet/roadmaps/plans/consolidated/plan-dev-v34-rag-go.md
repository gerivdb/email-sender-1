git add . && git commit -m "commit all changes" --no-verify && git push --no-verify

remplace "commit all changes" par un descriptif adéquat reflétant la ou les implémentations, modifs, etc# Plan de Développement v34 - Système RAG en Go avec QDrant

## Projet : Système RAG Ultra-Rapide en Go
**Date de création :** 25 Mai 2025  
**Version :** v34  
**Objectif :** Créer un système RAG performant en Go intégré avec QDrant standalone

---

## PHASE 1 : Setup et Architecture Initiale

### 1.1 Création du projet Go
- [ ] **1.1** Création du projet Go
  - [ ] **1.1.1** Créer le dossier `tools/qdrant/rag-go`
    - [ ] **1.1.1.1** Créer le répertoire principal
      - [ ] **1.1.1.1.1** Vérifier l'emplacement de destination
        - [ ] **1.1.1.1.1.1** Naviguer vers `tools/qdrant/`
          - [x] **1.1.1.1.1.1.1** Ouvrir le terminal PowerShell
          - [x] **1.1.1.1.1.1.2** Exécuter `cd tools/qdrant/`
        - [x] **1.1.1.1.1.2** Vérifier les permissions d'écriture
        - [x] **1.1.1.1.1.2.1** Tester avec `Test-Path -PathType Container`
        - [x] **1.1.1.1.1.2.2** Vérifier les droits administrateur si nécessaire
        - [x] **1.1.1.1.1.2.3** Tester l'écriture avec `New-Item -ItemType File -Path .\_test_write.tmp -Force; Remove-Item .\_test_write.tmp -Force`
      - [ ] **1.1.1.1.2** Créer le dossier rag-go
        - [x] **1.1.1.1.2.1** Exécuter `mkdir rag-go`
        - [x] **1.1.1.1.2.2** Vérifier la création avec `ls`
    - [x] **1.1.1.2** Initialiser le module Go
      - [x] **1.1.1.2.1** Naviguer dans le dossier      
      - [x] **1.1.1.2.1.1** Exécuter `cd rag-go`
      - [x] **1.1.1.2.1.2** Vérifier le répertoire courant avec `pwd`
      - [x] **1.1.1.2.2** Initialiser le module      
      - [x] **1.1.1.2.2.1** Exécuter `go mod init rag-go-system`
      - [x] **1.1.1.2.2.2** Vérifier la création du fichier `go.mod`
      - [x] **1.1.1.2.2.3** Inspecter le contenu du fichier go.mod
    - [ ] **1.1.1.3** Créer la structure de dossiers
      - [ ] **1.1.1.3.1** Créer le dossier `cmd/`
        - [x] **1.1.1.3.1.1** Exécuter `mkdir cmd`
        - [x] **1.1.1.3.1.2** Créer le sous-dossier `cmd/rag-go/`
          - [x] **1.1.1.3.1.2.1** Exécuter `mkdir cmd/rag-go`
          - [x] **1.1.1.3.1.2.2** Vérifier la structure avec `tree cmd`
      - [x] **1.1.1.3.2** Créer le dossier `pkg/`
        - [x] **1.1.1.3.2.1** Exécuter `mkdir pkg`
        - [x] **1.1.1.3.2.2** Créer les sous-dossiers pkg
          - [x] **1.1.1.3.2.2.1** `mkdir pkg/client`
          - [x] **1.1.1.3.2.2.2** `mkdir pkg/embeddings`
          - [x] **1.1.1.3.2.2.3** `mkdir pkg/indexer`
          - [x] **1.1.1.3.2.2.4** `mkdir pkg/search`
      - [x] **1.1.1.3.3** Créer le dossier `internal/`
        - [x] **1.1.1.3.3.1** Exécuter `mkdir internal`
        - [x] **1.1.1.3.3.2** Créer les sous-dossiers internal
          - [x] **1.1.1.3.3.2.1** `mkdir internal/config`
          - [x] **1.1.1.3.3.2.2** `mkdir internal/server`
    - [ ] **1.1.1.4** Setup du `.gitignore` pour Go
      - [x] **1.1.1.4.1** Créer le fichier .gitignore
        - [x] **1.1.1.4.1.1** Ajouter les binaires Go (`*.exe`, `rag-go`)
        - [x] **1.1.1.4.1.2** Ajouter les fichiers temporaires (`*.tmp`, `*.temp`)
        - [x] **1.1.1.4.1.3** Ajouter les logs (`*.log`, `logs/`)
      - [x] **1.1.1.4.2** Ajouter les exclusions spécifiques
        - [x] **1.1.1.4.2.1** Ajouter `vendor/` pour les dépendances
        - [x] **1.1.1.4.2.2** Ajouter `.env` pour les configurations
        - [x] **1.1.1.4.2.3** Ajouter les fichiers de test (`coverage.out`)

### 1.2 Configuration de base
- [x] **1.2** Configuration de base
  - [x] **1.2.1** Créer le fichier de configuration
    - [x] **1.2.1.1** Définir les paramètres QDrant
      - [x] **1.2.1.1.1** Configuration de l'hôte
        - [x] **1.2.1.1.1.1** Définir le host par défaut (localhost)
          - [x] **1.2.1.1.1.1.1** Créer la struct Config
          - [x] **1.2.1.1.1.1.2** Ajouter le champ QdrantHost string
        - [x] **1.2.1.1.1.2** Permettre la configuration via variables d'environnement
          - [x] **1.2.1.1.1.2.1** Importer le package os
          - [x] **1.2.1.1.1.2.2** Utiliser `os.Getenv("QDRANT_HOST")`
      - [x] **1.2.1.1.2** Configuration du port
        - [x] **1.2.1.1.2.1** Définir le port par défaut (6333)
          - [x] **1.2.1.1.2.1.1** Ajouter le champ QdrantPort int
          - [x] **1.2.1.1.2.1.2** Valeur par défaut 6333
        - [x] **1.2.1.1.2.2** Validation du port
          - [x] **1.2.1.1.2.2.1** Vérifier que le port est dans la plage valide (1-65535)
          - [x] **1.2.1.1.2.2.2** Gérer les erreurs de configuration
      - [x] **1.2.1.1.3** Configuration du timeout
        - [x] **1.2.1.1.3.1** Définir le timeout par défaut (30s)
          - [x] **1.2.1.1.3.1.1** Ajouter le champ Timeout time.Duration
          - [x] **1.2.1.1.3.1.2** Importer le package time
        - [x] **1.2.1.1.3.2** Permettre la personnalisation
          - [x] **1.2.1.1.3.2.1** Parser depuis string vers Duration
          - [x] **1.2.1.1.3.2.2** Gérer les erreurs de parsing
    - [x] **1.2.1.2** Configuration des embeddings
      - [x] **1.2.1.2.1** Choix du provider
        - [x] **1.2.1.2.1.1** Définir les providers supportés
          - [x] **1.2.1.2.1.1.1** Créer un enum/type Provider
          - [x] **1.2.1.2.1.1.2** Ajouter "simulation", "openai", "huggingface"
        - [x] **1.2.1.2.1.2** Configuration par provider
          - [x] **1.2.1.2.1.2.1** Structure pour OpenAI (API key, model)
          - [x] **1.2.1.2.1.2.2** Structure pour HuggingFace (API key, model)
      - [x] **1.2.1.2.2** Configuration du modèle
        - [x] **1.2.1.2.2.1** Modèle par défaut (all-MiniLM-L6-v2)
          - [x] **1.2.1.2.2.1.1** Ajouter le champ EmbeddingModel string
          - [x] **1.2.1.2.2.1.2** Valeur par défaut appropriée
        - [x] **1.2.1.2.2.2** Validation du modèle
          - [x] **1.2.1.2.2.2.1** Vérifier la compatibilité avec le provider
          - [x] **1.2.1.2.2.2.2** Liste des modèles supportés
      - [x] **1.2.1.2.3** Configuration des dimensions
        - [x] **1.2.1.2.3.1** Dimensions par défaut (384)
          - [x] **1.2.1.2.3.1.1** Ajouter le champ VectorDimensions int
          - [x] **1.2.1.2.3.1.2** Correspondance modèle->dimensions
        - [x] **1.2.1.2.3.2** Validation des dimensions
          - [x] **1.2.1.2.3.2.1** Plage valide (50-4096)
          - [x] **1.2.1.2.3.2.2** Cohérence avec le modèle choisi
    - [x] **1.2.1.3** Configuration des logs et debug
      - [x] **1.2.1.3.1** Niveau de log
        - [x] **1.2.1.3.1.1** Définir les niveaux (DEBUG, INFO, WARN, ERROR)
          - [x] **1.2.1.3.1.1.1** Créer un type LogLevel
          - [x] **1.2.1.3.1.1.2** Constantes pour chaque niveau
        - [x] **1.2.1.3.1.2** Configuration par défaut (INFO)
          - [x] **1.2.1.3.1.2.1** Ajouter le champ LogLevel
          - [x] **1.2.1.3.1.2.2** Méthode pour changer le niveau
      - [x] **1.2.1.3.2** Sortie des logs
        - [x] **1.2.1.3.2.1** Console par défaut
          - [x] **1.2.1.3.2.1.1** Configuration du logger standard
          - [x] **1.2.1.3.2.1.2** Format des messages de log
        - [x] **1.2.1.3.2.2** Fichier optionnel
          - [x] **1.2.1.3.2.2.1** Chemin du fichier de log
          - [x] **1.2.1.3.2.2.2** Rotation des logs

### 1.3 Client QDrant
- [x] **1.3** Client QDrant
  - [x] **1.3.1** Implémenter le client HTTP QDrant
    - [x] **1.3.1.1** Struct `QdrantClient` avec méthodes de base
      - [x] **1.3.1.1.1** Définition de la structure
        - [x] **1.3.1.1.1.1** Champs de base
          - [x] **1.3.1.1.1.1.1** BaseURL string pour l'adresse QDrant
          - [x] **1.3.1.1.1.1.2** HTTPClient *http.Client pour les requêtes
        - [x] **1.3.1.1.1.2** Configuration avancée
          - [x] **1.3.1.1.1.2.1** Timeout personnalisable
          - [x] **1.3.1.1.1.2.2** Headers par défaut
          - [x] **1.3.1.1.1.2.3** Configuration TLS si nécessaire
      - [x] **1.3.1.1.2** Constructeur NewQdrantClient
        - [x] **1.3.1.1.2.1** Paramètres d'entrée
          - [x] **1.3.1.1.2.1.1** baseURL string obligatoire
          - [x] **1.3.1.1.2.1.2** options ...Option pour la flexibilité
        - [x] **1.3.1.1.2.2** Initialisation
          - [x] **1.3.1.1.2.2.1** Création du client HTTP avec timeout
          - [x] **1.3.1.1.2.2.2** Configuration des headers par défaut
          - [x] **1.3.1.1.2.2.3** Validation de l'URL de base
    - [x] **1.3.1.2** Connexion et health check
      - [x] **1.3.1.2.1** Méthode HealthCheck()
        - [x] **1.3.1.2.1.1** Implémentation de base
          - [x] **1.3.1.1.1.1** Requête GET vers /healthz
          - [x] **1.3.1.2.1.1.2** Vérification du status code 200
        - [x] **1.3.1.2.1.2** Gestion avancée
          - [x] **1.3.1.2.1.2.1** Timeout spécifique pour health check
          - [x] **1.3.1.2.1.2.2** Retry automatique en cas d'échec
          - [x] **1.3.1.2.1.2.3** Logging des tentatives de connexion
      - [x] **1.3.1.2.2** Méthode IsAlive()
        - [x] **1.3.1.2.2.1** Version simplifiée du health check
          - [x] **1.3.1.2.2.1.1** Retourne bool au lieu d'error
          - [x] **1.3.1.2.2.1.2** Timeout court (5s)
        - [x] **1.3.1.2.2.2** Utilisation pour les checks périodiques
          - [x] **1.3.1.2.2.2.1** Cache du statut pendant quelques secondes
          - [x] **1.3.1.2.2.2.2** Éviter les requêtes trop fréquentes
    - [x] **1.3.1.3** Gestion des erreurs et timeouts
      - [x] **1.3.1.3.1** Types d'erreurs personnalisés
        - [x] **1.3.1.3.1.1** QdrantConnectionError
          - [x] **1.3.1.3.1.1.1** Struct avec message et cause
          - [x] **1.3.1.3.1.1.2** Méthode Error() string
        - [x] **1.3.1.3.1.2** QdrantTimeoutError
          - [x] **1.3.1.3.1.2.1** Spécifique aux timeouts
          - [x] **1.3.1.3.1.2.2** Durée du timeout dépassé
        - [x] **1.3.1.3.1.3** QdrantAPIError
          - [x] **1.3.1.3.1.3.1** Erreurs de l'API QDrant
          - [x] **1.3.1.3.1.3.2** Status code et message
      - [x] **1.3.1.3.2** Stratégies de retry
        - [x] **1.3.1.3.2.1** Retry automatique
          - [x] **1.3.1.3.2.1.1** Nombre maximum de tentatives (3)
          - [x] **1.3.1.3.2.1.2** Délai exponentiel entre tentatives
        - [x] **1.3.1.3.2.2** Conditions de retry
          - [x] **1.3.1.3.2.2.1** Erreurs réseau (timeout, connection refused)
          - [x] **1.3.1.3.2.2.2** Status codes 5xx du serveur
          - [x] **1.3.1.3.2.2.3** Ne pas retenter sur 4xx (erreurs client)

---

## PHASE 2 : Core RAG Engine

### 2.1 Structures de données
- [ ] **2.1** Structures de données
  - [ ] **2.1.1** Définir les types principaux
    - [ ] **2.1.1.1** `Document` struct
      - [ ] **2.1.1.1.1** Champs de base
        - [ ] **2.1.1.1.1.1** ID string - identifiant unique
          - [ ] **2.1.1.1.1.1.1** Format UUID ou hash
          - [ ] **2.1.1.1.1.1.2** Validation de l'unicité
        - [ ] **2.1.1.1.1.2** Content string - contenu textuel
          - [ ] **2.1.1.1.1.2.1** Limite de taille (ex: 100KB)
          - [ ] **2.1.1.1.1.2.2** Validation de l'encodage UTF-8
        - [ ] **2.1.1.1.1.3** Metadata map[string]interface{}
          - [ ] **2.1.1.1.1.3.1** Source du document (path, URL)
          - [ ] **2.1.1.1.1.3.2** Timestamp de création/modification
          - [ ] **2.1.1.1.1.3.3** Type de fichier (txt, md, pdf)
          - [ ] **2.1.1.1.1.3.4** Taille du document original
        - [ ] **2.1.1.1.1.4** Vector []float32 - vecteur d'embedding
          - [ ] **2.1.1.1.1.4.1** Dimension configurable
          - [ ] **2.1.1.1.1.4.2** Validation de la dimension
      - [ ] **2.1.1.1.2** Méthodes associées
        - [ ] **2.1.1.1.2.1** Validate() error
          - [ ] **2.1.1.1.2.1.1** Vérifier que l'ID n'est pas vide
          - [ ] **2.1.1.1.2.1.2** Vérifier la taille du contenu
          - [ ] **2.1.1.1.2.1.3** Valider la dimension du vecteur
        - [ ] **2.1.1.1.2.2** ToJSON() ([]byte, error)
          - [ ] **2.1.1.1.2.2.1** Sérialisation complète
          - [ ] **2.1.1.1.2.2.2** Gestion des erreurs d'encodage
        - [ ] **2.1.1.1.2.3** FromJSON([]byte) error
          - [ ] **2.1.1.1.2.3.1** Désérialisation depuis JSON
          - [ ] **2.1.1.1.2.3.2** Validation après désérialisation
    - [ ] **2.1.1.2** `SearchResult` struct
      - [ ] **2.1.1.2.1** Champs de résultat
        - [ ] **2.1.1.2.1.1** Score float32 - score de similarité
          - [ ] **2.1.1.2.1.1.1** Plage 0.0 à 1.0
          - [ ] **2.1.1.2.1.1.2** Validation de la plage
        - [ ] **2.1.1.2.1.2** Document *Document - document trouvé
          - [ ] **2.1.1.2.1.2.1** Référence complète
          - [ ] **2.1.1.2.1.2.2** Lazy loading optionnel
        - [ ] **2.1.1.2.1.3** Snippet string - extrait pertinent
          - [ ] **2.1.1.2.1.3.1** Longueur limitée (200 chars)
          - [ ] **2.1.1.2.1.3.2** Highlighting des termes
        - [ ] **2.1.1.2.1.4** Distance float32 - distance vectorielle
          - [ ] **2.1.1.2.1.4.1** Métrique utilisée (cosine, euclidean)
          - [ ] **2.1.1.2.1.4.2** Conversion score <-> distance
      - [ ] **2.1.1.2.2** Méthodes de manipulation
        - [ ] **2.1.1.2.2.1** IsRelevant(threshold float32) bool
          - [ ] **2.1.1.2.2.1.1** Comparaison avec seuil
          - [ ] **2.1.1.2.2.1.2** Seuil configurable par contexte
        - [ ] **2.1.1.2.2.2** GenerateSnippet(query string) string
          - [ ] **2.1.1.2.2.2.1** Extraction autour des mots-clés
          - [ ] **2.1.1.2.2.2.2** Highlighting HTML ou markdown
    - [ ] **2.1.1.3** `Collection` management
      - [ ] **2.1.1.3.1** Struct Collection
        - [ ] **2.1.1.3.1.1** Métadonnées de collection
          - [ ] **2.1.1.3.1.1.1** Name string - nom de la collection
          - [ ] **2.1.1.3.1.1.2** VectorSize int - dimension des vecteurs
          - [ ] **2.1.1.3.1.1.3** Distance string - métrique de distance
          - [ ] **2.1.1.3.1.1.4** DocumentCount int - nombre de documents
        - [ ] **2.1.1.3.1.2** Configuration avancée
          - [ ] **2.1.1.3.1.2.1** IndexingConfig - paramètres d'indexation
          - [ ] **2.1.1.3.1.2.2** OptimizationConfig - paramètres d'optimisation
      - [ ] **2.1.1.3.2** Opérations sur collections
        - [ ] **2.1.1.3.2.1** Create(config CollectionConfig) error
          - [ ] **2.1.1.3.2.1.1** Validation de la configuration
          - [ ] **2.1.1.3.2.1.2** Création via API QDrant
          - [ ] **2.1.1.3.2.1.3** Gestion des erreurs de création
        - [ ] **2.1.1.3.2.2** Delete(name string) error
          - [ ] **2.1.1.3.2.2.1** Confirmation avant suppression
          - [ ] **2.1.1.3.2.2.2** Suppression via API QDrant
        - [ ] **2.1.1.3.2.3** GetInfo(name string) (*Collection, error)
          - [ ] **2.1.1.3.2.3.1** Récupération des métadonnées
          - [ ] **2.1.1.3.2.3.2** Calcul des statistiques

### 2.2 Vectorisation
- [ ] **2.2** Vectorisation
  - [ ] **2.2.1** Service d'embeddings
    - [ ] **2.2.1.1** Interface `EmbeddingProvider`
      - [ ] **2.2.1.1.1** Définition de l'interface
        - [ ] **2.2.1.1.1.1** Méthode Embed(text string) ([]float32, error)
          - [ ] **2.2.1.1.1.1.1** Signature de base
          - [ ] **2.2.1.1.1.1.2** Gestion des textes vides
          - [ ] **2.2.1.1.1.1.3** Limite de longueur de texte
        - [ ] **2.2.1.1.1.2** Méthode EmbedBatch(texts []string) ([][]float32, error)
          - [ ] **2.2.1.1.1.2.1** Traitement par lots pour performance
          - [ ] **2.2.1.1.1.2.2** Gestion des erreurs partielles
          - [ ] **2.2.1.1.1.2.3** Limitation de la taille du batch
        - [ ] **2.2.1.1.1.3** Méthode GetDimensions() int
          - [ ] **2.2.1.1.1.3.1** Retourne la dimension des vecteurs
          - [ ] **2.2.1.1.1.3.2** Constante pour chaque provider
        - [ ] **2.2.1.1.1.4** Méthode GetModelInfo() ModelInfo
          - [ ] **2.2.1.1.1.4.1** Informations sur le modèle utilisé
          - [ ] **2.2.1.1.1.4.2** Version et paramètres
      - [ ] **2.2.1.1.2** Struct ModelInfo
        - [ ] **2.2.1.1.2.1** Métadonnées du modèle
          - [ ] **2.2.1.1.2.1.1** Name string - nom du modèle
          - [ ] **2.2.1.1.2.1.2** Version string - version du modèle
          - [ ] **2.2.1.1.2.1.3** Provider string - fournisseur
          - [ ] **2.2.1.1.2.1.4** Dimensions int - dimensions des vecteurs
        - [ ] **2.2.1.1.2.2** Limites et capacités
          - [ ] **2.2.1.1.2.2.1** MaxTokens int - longueur max de texte
          - [ ] **2.2.1.1.2.2.2** BatchSize int - taille max des batches
    - [ ] **2.2.1.2** Implémentation simulée (pour tests)
      - [ ] **2.2.1.2.1** Struct SimulatedProvider
        - [ ] **2.2.1.2.1.1** Configuration
          - [ ] **2.2.1.2.1.1.1** Dimensions int - nombre de dimensions
          - [ ] **2.2.1.2.1.1.2** Seed int64 - seed pour la reproductibilité
          - [ ] **2.2.1.2.1.1.3** Latency time.Duration - simulation de latence
        - [ ] **2.2.1.2.1.2** État interne
          - [ ] **2.2.1.2.1.2.1** rng *rand.Rand - générateur aléatoire
          - [ ] **2.2.1.2.1.2.2** cache map[string][]float32 - cache des embeddings
      - [ ] **2.2.1.2.2** Implémentation des méthodes
        - [ ] **2.2.1.2.2.1** Embed(text string) ([]float32, error)
          - [ ] **2.2.1.2.2.1.1** Hash du texte pour consistance
          - [ ] **2.2.1.2.2.1.2** Génération pseudo-aléatoire basée sur le hash
          - [ ] **2.2.1.2.2.1.3** Normalisation du vecteur
          - [ ] **2.2.1.2.2.1.4** Simulation de latence
        - [ ] **2.2.1.2.2.2** EmbedBatch(texts []string) ([][]float32, error)
          - [ ] **2.2.1.2.2.2.1** Traitement séquentiel pour simulation
          - [ ] **2.2.1.2.2.2.2** Accumulation des latences
        - [ ] **2.2.1.2.2.3** Cache management
          - [ ] **2.2.1.2.2.3.1** Vérification du cache avant calcul
          - [ ] **2.2.1.2.2.3.2** Limitation de la taille du cache
    - [ ] **2.2.1.3** Chunking intelligent des documents
      - [ ] **2.2.1.3.1** Stratégies de chunking
        - [ ] **2.2.1.3.1.1** Chunking par taille fixe
          - [ ] **2.2.1.3.1.1.1** Taille par défaut (500 caractères)
          - [ ] **2.2.1.3.1.1.2** Overlap entre chunks (50 caractères)
          - [ ] **2.2.1.3.1.1.3** Respect des limites de phrases
        - [ ] **2.2.1.3.1.2** Chunking sémantique
          - [ ] **2.2.1.3.1.2.1** Détection des paragraphes
          - [ ] **2.2.1.3.1.2.2** Analyse des titres et sections
          - [ ] **2.2.1.3.1.2.3** Préservation du contexte
        - [ ] **2.2.1.3.1.3** Chunking adaptatif
          - [ ] **2.2.1.3.1.3.1** Ajustement selon le type de contenu
          - [ ] **2.2.1.3.1.3.2** Optimisation pour la recherche
      - [ ] **2.2.1.3.2** Struct DocumentChunk
        - [ ] **2.2.1.3.2.1** Métadonnées du chunk
          - [ ] **2.2.1.3.2.1.1** ParentDocumentID string
          - [ ] **2.2.1.3.2.1.2** ChunkIndex int - position dans le document
          - [ ] **2.2.1.3.2.1.3** StartOffset int - position de début
          - [ ] **2.2.1.3.2.1.4** EndOffset int - position de fin
        - [ ] **2.2.1.3.2.2** Contenu du chunk
          - [ ] **2.2.1.3.2.2.1** Text string - texte du chunk
          - [ ] **2.2.1.3.2.2.2** Context string - contexte précédent/suivant
          - [ ] **2.2.1.3.2.2.3** Vector []float32 - embedding du chunk

### 2.3 Indexation
- [ ] **2.3** Indexation
  - [ ] **2.3.1** Système d'indexation
    - [ ] **2.3.1.1** Lecture de fichiers
      - [ ] **2.3.1.1.1** Support TXT
        - [ ] **2.3.1.1.1.1** Détection de l'encodage
          - [ ] **2.3.1.1.1.1.1** UTF-8 par défaut
          - [ ] **2.3.1.1.1.1.2** Fallback vers ISO-8859-1
          - [ ] **2.3.1.1.1.1.3** Détection automatique avec chardet
        - [ ] **2.3.1.1.1.2** Lecture optimisée
          - [ ] **2.3.1.1.1.2.1** Lecture par chunks pour gros fichiers
          - [ ] **2.3.1.1.1.2.2** Gestion de la mémoire
          - [ ] **2.3.1.1.1.2.3** Validation de la taille max
        - [ ] **2.3.1.1.1.3** Extraction des métadonnées
          - [ ] **2.3.1.1.1.3.1** Taille du fichier
          - [ ] **2.3.1.1.1.3.2** Date de modification
          - [ ] **2.3.1.1.1.3.3** Chemin complet
      - [ ] **2.3.1.1.2** Support MD (Markdown)
        - [ ] **2.3.1.1.2.1** Parsing de la structure
          - [ ] **2.3.1.1.2.1.1** Extraction des titres (H1-H6)
          - [ ] **2.3.1.1.2.1.2** Préservation de la hiérarchie
          - [ ] **2.3.1.1.2.1.3** Gestion des métadonnées YAML
        - [ ] **2.3.1.1.2.2** Traitement du contenu
          - [ ] **2.3.1.1.2.2.1** Suppression des balises Markdown
          - [ ] **2.3.1.1.2.2.2** Extraction du texte pur
          - [ ] **2.3.1.1.2.2.3** Préservation des liens et images
        - [ ] **2.3.1.1.2.3** Chunking spécialisé
          - [ ] **2.3.1.1.2.3.1** Respect de la structure des sections
          - [ ] **2.3.1.1.2.3.2** Gestion des listes et tableaux
      - [ ] **2.3.1.1.3** Support PDF
        - [ ] **2.3.1.1.3.1** Extraction de texte basique
          - [ ] **2.3.1.1.3.1.1** Utilisation d'une bibliothèque PDF
          - [ ] **2.3.1.1.3.1.2** Gestion des erreurs de parsing
          - [ ] **2.3.1.1.3.1.3** Limitation à du texte sélectionnable
        - [ ] **2.3.1.1.3.2** Métadonnées PDF
          - [ ] **2.3.1.1.3.2.1** Titre et auteur du document
          - [ ] **2.3.1.1.3.2.2** Nombre de pages
          - [ ] **2.3.1.1.3.2.3** Date de création
        - [ ] **2.3.1.1.3.3** Optimisations futures
          - [ ] **2.3.1.1.3.3.1** OCR pour les PDFs scannés
          - [ ] **2.3.1.1.3.3.2** Extraction des images et diagrammes
    - [ ] **2.3.1.2** Chunking avec overlap
      - [ ] **2.3.1.2.1** Configuration du chunking
        - [ ] **2.3.1.2.1.1** Taille des chunks
          - [ ] **2.3.1.2.1.1.1** Par caractères (défaut: 500)
          - [ ] **2.3.1.2.1.1.2** Par mots (défaut: 100)
          - [ ] **2.3.1.2.1.1.3** Par phrases (défaut: 5)
        - [ ] **2.3.1.2.1.2** Overlap entre chunks
          - [ ] **2.3.1.2.1.2.1** Pourcentage d'overlap (défaut: 10%)
          - [ ] **2.3.1.2.1.2.2** Minimum et maximum en caractères
          - [ ] **2.3.1.2.1.2.3** Respect des limites de phrases
        - [ ] **2.3.1.2.1.3** Stratégies adaptatives
          - [ ] **2.3.1.2.1.3.1** Ajustement selon le type de contenu
          - [ ] **2.3.1.2.1.3.2** Optimisation pour la cohérence
      - [ ] **2.3.1.2.2** Algorithme de chunking
        - [ ] **2.3.1.2.2.1** Préparation du texte
          - [ ] **2.3.1.2.2.1.1** Nettoyage des caractères spéciaux
          - [ ] **2.3.1.2.2.1.2** Normalisation des espaces
          - [ ] **2.3.1.2.2.1.3** Détection des limites de phrases
        - [ ] **2.3.1.2.2.2** Génération des chunks
          - [ ] **2.3.1.2.2.2.1** Itération avec fenêtre glissante
          - [ ] **2.3.1.2.2.2.2** Respect des limites naturelles
          - [ ] **2.3.1.2.2.2.3** Ajustement dynamique de la taille
        - [ ] **2.3.1.2.2.3** Post-traitement
          - [ ] **2.3.1.2.2.3.1** Validation de la qualité des chunks
          - [ ] **2.3.1.2.2.3.2** Fusion des chunks trop petits
          - [ ] **2.3.1.2.2.3.3** Division des chunks trop grands
    - [ ] **2.3.1.3** Insertion batch dans QDrant
      - [ ] **2.3.1.3.1** Configuration des batches
        - [ ] **2.3.1.3.1.1** Taille des batches
          - [ ] **2.3.1.3.1.1.1** Nombre de documents par batch (défaut: 100)
          - [ ] **2.3.1.3.1.1.2** Taille mémoire max par batch
          - [ ] **2.3.1.3.1.1.3** Ajustement dynamique selon les performances
        - [ ] **2.3.1.3.1.2** Gestion des erreurs
          - [ ] **2.3.1.3.1.2.1** Retry des batches échoués
          - [ ] **2.3.1.3.1.2.2** Isolation des documents problématiques
          - [ ] **2.3.1.3.1.2.3** Logging détaillé des erreurs
      - [ ] **2.3.1.3.2** Optimisations de performance
        - [ ] **2.3.1.3.2.1** Parallélisation
          - [ ] **2.3.1.3.2.1.1** Workers concurrents pour l'embedding
          - [ ] **2.3.1.3.2.1.2** Queue des batches à traiter
          - [ ] **2.3.1.3.2.1.3** Limitation du nombre de goroutines
        - [ ] **2.3.1.3.2.2** Monitoring des performances
          - [ ] **2.3.1.3.2.2.1** Métriques de débit (docs/sec)
          - [ ] **2.3.1.3.2.2.2** Temps moyen par document
          - [ ] **2.3.1.3.2.2.3** Utilisation mémoire et CPU

---

## PHASE 3 : API et Recherche

### 3.1 Moteur de recherche
- [ ] **3.1** Moteur de recherche
  - [ ] **3.1.1** Recherche vectorielle
    - [ ] **3.1.1.1** Query embedding
      - [ ] **3.1.1.1.1** Générer l'embedding de la requête
        - [ ] **3.1.1.1.1.1** Nettoyer la requête utilisateur
        - [ ] **3.1.1.1.1.2** Appeler le provider d'embedding
        - [ ] **3.1.1.1.1.3** Vérifier la dimension du vecteur
      - [ ] **3.1.1.1.2** Gestion des erreurs d'embedding
        - [ ] **3.1.1.1.2.1** Timeout embedding
        - [ ] **3.1.1.1.2.2** Logging des erreurs
    - [ ] **3.1.1.2** Recherche similarity dans QDrant
      - [ ] **3.1.1.2.1** Construire la requête QDrant
        - [ ] **3.1.1.2.1.1** Format JSON pour la recherche
        - [ ] **3.1.1.2.1.2** Paramètres : limit, with_payload
      - [ ] **3.1.1.2.2** Appeler l'API QDrant
        - [ ] **3.1.1.2.2.1** Gérer les erreurs réseau
        - [ ] **3.1.1.2.2.2** Vérifier le status code
      - [ ] **3.1.1.2.3** Parser les résultats
        - [ ] **3.1.1.2.3.1** Extraire les scores
        - [ ] **3.1.1.2.3.2** Extraire les payloads
    - [ ] **3.1.1.3** Re-ranking des résultats
      - [ ] **3.1.1.3.1** Appliquer un re-ranking local
        - [ ] **3.1.1.3.1.1** Calculer la similarité contextuelle
        - [ ] **3.1.1.3.1.2** Trier les résultats
      - [ ] **3.1.1.3.2** Générer les snippets de contexte
        - [ ] **3.1.1.3.2.1** Extraire les passages pertinents
        - [ ] **3.1.1.3.2.2** Mettre en surbrillance les mots-clés

### 3.2 API REST
- [ ] **3.2** API REST
  - [ ] **3.2.1** Serveur HTTP avec Gin
    - [ ] **3.2.1.1** Endpoint `/health` - Status de l'API
      - [ ] **3.2.1.1.1** Retourner un JSON status: ok
      - [ ] **3.2.1.1.2** Ajouter version de l'API
    - [ ] **3.2.1.2** Endpoint `/index` - Indexer des documents
      - [ ] **3.2.1.2.1** Recevoir un fichier ou texte
      - [ ] **3.2.1.2.2** Lancer la vectorisation et l'indexation
      - [ ] **3.2.1.2.3** Retourner le nombre de documents indexés
    - [ ] **3.2.1.3** Endpoint `/search` - Recherche RAG
      - [ ] **3.2.1.3.1** Recevoir la requête utilisateur
      - [ ] **3.2.1.3.2** Générer l'embedding de la requête
      - [ ] **3.2.1.3.3** Lancer la recherche vectorielle
      - [ ] **3.2.1.3.4** Retourner les résultats formatés
    - [ ] **3.2.1.4** Endpoint `/collections` - Gestion des collections
      - [ ] **3.2.1.4.1** Lister les collections existantes
      - [ ] **3.2.1.4.2** Créer une nouvelle collection
      - [ ] **3.2.1.4.3** Supprimer une collection
      - [ ] **3.2.1.4.4** Retourner les métadonnées de collection

### 3.3 CLI Interface
- [ ] **3.3** Command Line Interface
  - [ ] **3.3.1** Commandes CLI
    - [ ] **3.3.1.1** `rag-go index <path>` - Indexer
      - [ ] **3.3.1.1.1** Vérifier le chemin fourni
      - [ ] **3.3.1.1.2** Lancer l'indexation via l'API ou en local
      - [ ] **3.3.1.1.3** Afficher le nombre de documents indexés
    - [ ] **3.3.1.2** `rag-go search <query>` - Rechercher
      - [ ] **3.3.1.2.1** Vérifier la requête utilisateur
      - [ ] **3.3.1.2.2** Lancer la recherche via l'API ou en local
      - [ ] **3.3.1.2.3** Afficher les résultats formatés
    - [ ] **3.3.1.3** `rag-go status` - État du système
      - [ ] **3.3.1.3.1** Vérifier la connexion à QDrant
      - [ ] **3.3.1.3.2** Afficher le statut des collections
      - [ ] **3.3.1.3.3** Afficher la version du système

---

## PHASE 4 : Performance et Optimisation

### 4.1 Optimisations
- [ ] **4.1.1** Performance tuning
  - [ ] **4.1.1.1** Connection pooling
    - [ ] **4.1.1.1.1** Analyse des besoins de pooling
      - [ ] **4.1.1.1.1.1** Identifier les points de connexion récurrents
      - [ ] **4.1.1.1.1.2** Évaluer la charge attendue
    - [ ] **4.1.1.1.2** Implémenter le pool de connexions HTTP
      - [ ] **4.1.1.1.2.1** Configurer le transport HTTP
      - [ ] **4.1.1.1.2.2** Définir le nombre max d'idle connections
      - [ ] **4.1.1.1.2.3** Tester la saturation du pool
    - [ ] **4.1.1.1.3** Monitoring et tuning
      - [ ] **4.1.1.1.3.1** Ajouter des métriques de pool
      - [ ] **4.1.1.1.3.2** Ajuster dynamiquement selon la charge
  - [ ] **4.1.1.2** Batch processing
    - [ ] **4.1.1.2.1** Définir la taille optimale des batches
      - [ ] **4.1.1.2.1.1** Benchmarks sur différentes tailles
      - [ ] **4.1.1.2.1.2** Analyse mémoire/CPU
    - [ ] **4.1.1.2.2** Implémenter l'envoi batch vers QDrant
      - [ ] **4.1.1.2.2.1** Structurer les requêtes batch
      - [ ] **4.1.1.2.2.2** Gérer les erreurs partielles
    - [ ] **4.1.1.2.3** Optimiser la parallélisation des batches
      - [ ] **4.1.1.2.3.1** Utiliser des workers concurrents
      - [ ] **4.1.1.2.3.2** Limiter le nombre de goroutines
  - [ ] **4.1.1.3** Memory optimization
    - [ ] **4.1.1.3.1** Profiling mémoire
      - [ ] **4.1.1.3.1.1** Utiliser pprof pour identifier les leaks
      - [ ] **4.1.1.3.1.2** Analyser les allocations majeures
    - [ ] **4.1.1.3.2** Optimiser la gestion des buffers
      - [ ] **4.1.1.3.2.1** Réutilisation des slices
      - [ ] **4.1.1.3.2.2** Limiter la taille des buffers
    - [ ] **4.1.1.3.3** Garbage collection tuning
      - [ ] **4.1.1.3.3.1** Ajuster GOGC si nécessaire
      - [ ] **4.1.1.3.3.2** Mesurer l'impact sur la latence
  - [ ] **4.1.1.4** Concurrent processing
    - [ ] **4.1.1.4.1** Identifier les tâches parallélisables
      - [ ] **4.1.1.4.1.1** Vectorisation concurrente
      - [ ] **4.1.1.4.1.2** Indexation concurrente
    - [ ] **4.1.1.4.2** Implémenter les workers
      - [ ] **4.1.1.4.2.1** Pool de goroutines
      - [ ] **4.1.1.4.2.2** Gestion des erreurs concurrentes
    - [ ] **4.1.1.4.3** Synchronisation et sécurité
      - [ ] **4.1.1.4.3.1** Utiliser des mutex/channels
      - [ ] **4.1.1.4.3.2** Éviter les data races

### 4.2 Cache et persistance
- [ ] **4.2.1** Système de cache
  - [ ] **4.2.1.1** Cache des embeddings
    - [ ] **4.2.1.1.1** Définir la structure du cache (in-memory, LRU)
    - [ ] **4.2.1.1.2** Implémenter le cache d'embeddings
      - [ ] **4.2.1.1.2.1** Ajout lors de la vectorisation
      - [ ] **4.2.1.1.2.2** Recherche dans le cache avant calcul
    - [ ] **4.2.1.1.3** Limiter la taille et éviction
      - [ ] **4.2.1.1.3.1** Politique d'éviction (LRU/FIFO)
      - [ ] **4.2.1.1.3.2** Monitoring du taux de hit/miss
  - [ ] **4.2.1.2** Cache des résultats fréquents
    - [ ] **4.2.1.2.1** Identifier les requêtes fréquentes
    - [ ] **4.2.1.2.2** Implémenter le cache de résultats
      - [ ] **4.2.1.2.2.1** Stockage des résultats de recherche
      - [ ] **4.2.1.2.2.2** Invalidation sur update/indexation
    - [ ] **4.2.1.2.3** Optimiser la persistance du cache
      - [ ] **4.2.1.2.3.1** Sauvegarde périodique sur disque
      - [ ] **4.2.1.2.3.2** Restauration au démarrage
  - [ ] **4.2.1.3** Persistence configuration
    - [ ] **4.2.1.3.1** Définir les paramètres de persistance
      - [ ] **4.2.1.3.1.1** Fichiers de config pour le cache
      - [ ] **4.2.1.3.1.2** Format de sérialisation (JSON, gob)
    - [ ] **4.2.1.3.2** Implémenter la sauvegarde/restauration
      - [ ] **4.2.1.3.2.1** Sauvegarde automatique à l'arrêt
      - [ ] **4.2.1.3.2.2** Chargement au démarrage
    - [ ] **4.2.1.3.3** Tests de robustesse
      - [ ] **4.2.1.3.3.1** Simulation de crash/reprise
      - [ ] **4.2.1.3.3.2** Vérification de l'intégrité des données

---

## PHASE 5 : Tests et Validation

### 5.1 Tests unitaires
- [ ] **5.1** Tests unitaires
  - [ ] **5.1.1** Coverage complète
    - [ ] **5.1.1.1** Tests pour chaque module
      - [ ] **5.1.1.1.1** Tests du client QDrant
        - [ ] **5.1.1.1.1.1** Tester les connexions
          - [ ] **5.1.1.1.1.1.1** Test de connexion réussie
          - [ ] **5.1.1.1.1.1.2** Test de timeout de connexion
          - [ ] **5.1.1.1.1.1.3** Test d'erreur serveur
        - [ ] **5.1.1.1.1.2** Tester les opérations CRUD
          - [ ] **5.1.1.1.1.2.1** Create collection
          - [ ] **5.1.1.1.1.2.2** Read collection info
          - [ ] **5.1.1.1.1.2.3** Update collection params
          - [ ] **5.1.1.1.1.2.4** Delete collection
      - [ ] **5.1.1.1.2** Tests des providers d'embeddings
        - [ ] **5.1.1.1.2.1** Tests du provider simulé
          - [ ] **5.1.1.1.2.1.1** Vérifier la consistance des embeddings
          - [ ] **5.1.1.1.2.1.2** Vérifier la normalisation des vecteurs
          - [ ] **5.1.1.1.2.1.3** Tester le cache interne
        - [ ] **5.1.1.1.2.2** Tests des dimensions
          - [ ] **5.1.1.1.2.2.1** Vérifier les dimensions correctes
          - [ ] **5.1.1.1.2.2.2** Tester les erreurs de dimension
        - [ ] **5.1.1.1.2.3** Tests du traitement par lots
          - [ ] **5.1.1.1.2.3.1** Vérifier la gestion des lots vides
          - [ ] **5.1.1.1.2.3.2** Tester les grands lots (>100 items)
      - [ ] **5.1.1.1.3** Tests du module d'indexation
        - [ ] **5.1.1.1.3.1** Tests de lecture de fichiers
          - [ ] **5.1.1.1.3.1.1** Tests des fichiers TXT
          - [ ] **5.1.1.1.3.1.2** Tests des fichiers Markdown
          - [ ] **5.1.1.1.3.1.3** Tests des fichiers PDF
        - [ ] **5.1.1.1.3.2** Tests de chunking
          - [ ] **5.1.1.1.3.2.1** Vérifier l'overlap correct
          - [ ] **5.1.1.1.3.2.2** Tester le respect des limites de phrase
          - [ ] **5.1.1.1.3.2.3** Tester les cas extrêmes (très court/long)
        - [ ] **5.1.1.1.3.3** Tests d'insertion batch
          - [ ] **5.1.1.1.3.3.1** Vérifier la gestion des erreurs partielles
          - [ ] **5.1.1.1.3.3.2** Tester la récupération après échec
      - [ ] **5.1.1.1.4** Tests du moteur de recherche
        - [ ] **5.1.1.1.4.1** Tests de recherche vectorielle
          - [ ] **5.1.1.1.4.1.1** Tester la recherche simple
          - [ ] **5.1.1.1.4.1.2** Tester les filtres de metadata
          - [ ] **5.1.1.1.4.1.3** Tester les limites et pagination
        - [ ] **5.1.1.1.4.2** Tests de re-ranking
          - [ ] **5.1.1.1.4.2.1** Vérifier l'ordre des résultats
          - [ ] **5.1.1.1.4.2.2** Tester la pertinence des snippets
    - [ ] **5.1.1.2** Mocks pour QDrant
      - [ ] **5.1.1.2.1** Créer un mock serveur QDrant
        - [ ] **5.1.1.2.1.1** Implémenter les endpoints principaux
          - [ ] **5.1.1.2.1.1.1** `/collections` endpoint
          - [ ] **5.1.1.2.1.1.2** `/points` endpoint
          - [ ] **5.1.1.2.1.1.3** `/search` endpoint
        - [ ] **5.1.1.2.1.2** Simuler les réponses typiques
          - [ ] **5.1.1.2.1.2.1** Réponses de succès
          - [ ] **5.1.1.2.1.2.2** Réponses d'erreur communes
        - [ ] **5.1.1.2.1.3** Intercepter les requêtes HTTP
          - [ ] **5.1.1.2.1.3.1** Valider le format des requêtes
          - [ ] **5.1.1.2.1.3.2** Enregistrer les requêtes pour analyse
      - [ ] **5.1.1.2.2** Tests avec le mock
        - [ ] **5.1.1.2.2.1** Tester les scénarios d'erreur
          - [ ] **5.1.1.2.2.1.1** Erreurs serveur (5xx)
          - [ ] **5.1.1.2.2.1.2** Erreurs client (4xx)
          - [ ] **5.1.1.2.2.1.3** Timeouts et erreurs réseau
        - [ ] **5.1.1.2.2.2** Tester les limites du système
          - [ ] **5.1.1.2.2.2.1** Grand nombre de collections
          - [ ] **5.1.1.2.2.2.2** Grand nombre de points (>10k)
    - [ ] **5.1.1.3** Tests de performance
      - [ ] **5.1.1.3.1** Benchmarks d'indexation
        - [ ] **5.1.1.3.1.1** Mesurer le débit d'indexation
          - [ ] **5.1.1.3.1.1.1** Documents par seconde
          - [ ] **5.1.1.3.1.1.2** Temps total d'indexation
        - [ ] **5.1.1.3.1.2** Profiler l'utilisation mémoire
          - [ ] **5.1.1.3.1.2.1** Utilisation mémoire par document
          - [ ] **5.1.1.3.1.2.2** Pics mémoire pendant l'indexation
        - [ ] **5.1.1.3.1.3** Mesurer l'impact des optimisations
          - [ ] **5.1.1.3.1.3.1** Impact du chunking parallèle
          - [ ] **5.1.1.3.1.3.2** Impact de la taille des batches
      - [ ] **5.1.1.3.2** Benchmarks de recherche
        - [ ] **5.1.1.3.2.1** Latence des requêtes
          - [ ] **5.1.1.3.2.1.1** Latence moyenne (p50)
          - [ ] **5.1.1.3.2.1.2** Latence percentile 95 (p95)
          - [ ] **5.1.1.3.2.1.3** Latence percentile 99 (p99)
        - [ ] **5.1.1.3.2.2** Throughput maximal
          - [ ] **5.1.1.3.2.2.1** Requêtes par seconde
          - [ ] **5.1.1.3.2.2.2** Dégradation sous charge
        - [ ] **5.1.1.3.2.3** Temps de réponse par composant
          - [ ] **5.1.1.3.2.3.1** Temps d'embedding de requête
          - [ ] **5.1.1.3.2.3.2** Temps de recherche QDrant
          - [ ] **5.1.1.3.2.3.3** Temps de re-ranking local

### 5.2 Tests d'intégration
- [ ] **5.2** Tests d'intégration
  - [ ] **5.2.1** Tests bout-en-bout
    - [ ] **5.2.1.1** Tests avec QDrant réel
      - [ ] **5.2.1.1.1** Setup de l'environnement de test
        - [ ] **5.2.1.1.1.1** Déployer QDrant via Docker
          - [ ] **5.2.1.1.1.1.1** Créer un docker-compose.yml
          - [ ] **5.2.1.1.1.1.2** Configurer le volume de persistance
          - [ ] **5.2.1.1.1.1.3** Exposer les ports nécessaires
        - [ ] **5.2.1.1.1.2** Configuration de test
          - [ ] **5.2.1.1.1.2.1** Collection pour tests
          - [ ] **5.2.1.1.1.2.2** Données de test initiales
        - [ ] **5.2.1.1.1.3** Scripts d'initialisation
          - [ ] **5.2.1.1.1.3.1** Script de reset
          - [ ] **5.2.1.1.1.3.2** Script de seeding
      - [ ] **5.2.1.1.2** Scénarios d'intégration
        - [ ] **5.2.1.1.2.1** Index puis recherche
          - [ ] **5.2.1.1.2.1.1** Vérifier les documents indexés
          - [ ] **5.2.1.1.2.1.2** Rechercher des termes spécifiques
        - [ ] **5.2.1.1.2.2** Mise à jour et réindexation
          - [ ] **5.2.1.1.2.2.1** Modifier des documents
          - [ ] **5.2.1.1.2.2.2** Vérifier la mise à jour des embeddings
        - [ ] **5.2.1.1.2.3** Interaction API complète
          - [ ] **5.2.1.1.2.3.1** Création de collections
          - [ ] **5.2.1.1.2.3.2** Indexation via l'API
          - [ ] **5.2.1.1.2.3.3** Recherche via l'API
    - [ ] **5.2.1.2** Tests de charge
      - [ ] **5.2.1.2.1** Tests de montée en charge
        - [ ] **5.2.1.2.1.1** Préparer les jeux de données
          - [ ] **5.2.1.2.1.1.1** Petit jeu (100 documents)
          - [ ] **5.2.1.2.1.1.2** Jeu moyen (10,000 documents)
          - [ ] **5.2.1.2.1.1.3** Grand jeu (100,000+ documents)
        - [ ] **5.2.1.2.1.2** Tests de scalabilité
          - [ ] **5.2.1.2.1.2.1** Mesurer le temps d'indexation
          - [ ] **5.2.1.2.1.2.2** Mesurer le temps de recherche
          - [ ] **5.2.1.2.1.2.3** Analyser la courbe de scalabilité
      - [ ] **5.2.1.2.2** Tests de concurrence
        - [ ] **5.2.1.2.2.1** Requêtes de recherche simultanées
          - [ ] **5.2.1.2.2.1.1** 10 requêtes simultanées
          - [ ] **5.2.1.2.2.1.2** 100 requêtes simultanées
          - [ ] **5.2.1.2.2.1.3** 1000 requêtes simultanées
        - [ ] **5.2.1.2.2.2** Opérations mixtes
          - [ ] **5.2.1.2.2.2.1** Indexation et recherche simultanées
          - [ ] **5.2.1.2.2.2.2** CRUD collections simultané
        - [ ] **5.2.1.2.2.3** Stress tests extrêmes
          - [ ] **5.2.1.2.2.3.1** Test de durée (24h)
          - [ ] **5.2.1.2.2.3.2** Test de charge maximale
    - [ ] **5.2.1.3** Validation des résultats
      - [ ] **5.2.1.3.1** Précision des recherches
        - [ ] **5.2.1.3.1.1** Évaluation manuelle
          - [ ] **5.2.1.3.1.1.1** Vérifier la pertinence top-5
          - [ ] **5.2.1.3.1.1.2** Évaluer la diversité des résultats
        - [ ] **5.2.1.3.1.2** Métriques de qualité
          - [ ] **5.2.1.3.1.2.1** Précision@k (P@5, P@10)
          - [ ] **5.2.1.3.1.2.2** Mean Average Precision (MAP)
          - [ ] **5.2.1.3.1.2.3** Normalized Discounted Cumulative Gain (nDCG)
      - [ ] **5.2.1.3.2** Robustesse du système
        - [ ] **5.2.1.3.2.1** Tests de récupération
          - [ ] **5.2.1.3.2.1.1** Reprise après crash
          - [ ] **5.2.1.3.2.1.2** Tolérance aux fautes réseau
          - [ ] **5.2.1.3.2.1.3** Redémarrage propre
        - [ ] **5.2.1.3.2.2** Tests de limites
          - [ ] **5.2.1.3.2.2.1** Documents très volumineux
          - [ ] **5.2.1.3.2.2.2** Requêtes très complexes
          - [ ] **5.2.1.3.2.2.3** Encodages et caractères spéciaux

---

## PHASE 6 : Documentation et Déploiement

### 6.1 Documentation
- [ ] **6.1** Documentation
  - [ ] **6.1.1** Documentation complète
    - [ ] **6.1.1.1** README principal
      - [ ] **6.1.1.1.1** Vue d'ensemble du projet
        - [ ] **6.1.1.1.1.1** Description du système RAG
          - [ ] **6.1.1.1.1.1.1** Architecture générale
          - [ ] **6.1.1.1.1.1.2** Composants principaux
          - [ ] **6.1.1.1.1.1.3** Intégration avec QDrant
        - [ ] **6.1.1.1.1.2** Prérequis système
          - [ ] **6.1.1.1.1.2.1** Version Go requise
          - [ ] **6.1.1.1.1.2.2** Dépendances externes
          - [ ] **6.1.1.1.1.2.3** Configuration système recommandée
      - [ ] **6.1.1.1.2** Guide de démarrage rapide
        - [ ] **6.1.1.1.2.1** Installation
          - [ ] **6.1.1.1.2.1.1** Installation via go get
          - [ ] **6.1.1.1.2.1.2** Installation depuis les sources
          - [ ] **6.1.1.1.2.1.3** Installation via Docker
        - [ ] **6.1.1.1.2.2** Configuration initiale
          - [ ] **6.1.1.1.2.2.1** Fichier de configuration
          - [ ] **6.1.1.1.2.2.2** Variables d'environnement
          - [ ] **6.1.1.1.2.2.3** Options de ligne de commande
        - [ ] **6.1.1.1.2.3** Exemples d'utilisation
          - [ ] **6.1.1.1.2.3.1** Indexation de documents
          - [ ] **6.1.1.1.2.3.2** Recherche simple
          - [ ] **6.1.1.1.2.3.3** Utilisation de l'API
    - [ ] **6.1.1.2** Documentation API
      - [ ] **6.1.1.2.1** Référence API REST
        - [ ] **6.1.1.2.1.1** Endpoints
          - [ ] **6.1.1.2.1.1.1** Documentation `/health`
          - [ ] **6.1.1.2.1.1.2** Documentation `/index`
          - [ ] **6.1.1.2.1.1.3** Documentation `/search`
          - [ ] **6.1.1.2.1.1.4** Documentation `/collections`
        - [ ] **6.1.1.2.1.2** Formats de requête/réponse
          - [ ] **6.1.1.2.1.2.1** Schémas JSON
          - [ ] **6.1.1.2.1.2.2** Exemples de payload
          - [ ] **6.1.1.2.1.2.3** Codes de statut HTTP
        - [ ] **6.1.1.2.1.3** Authentification et sécurité
          - [ ] **6.1.1.2.1.3.1** Méthodes d'authentification
          - [ ] **6.1.1.2.1.3.2** Gestion des tokens
          - [ ] **6.1.1.2.1.3.3** Bonnes pratiques sécurité
      - [ ] **6.1.1.2.2** Documentation SDK
        - [ ] **6.1.1.2.2.1** Client Go
          - [ ] **6.1.1.2.2.1.1** Installation du package
          - [ ] **6.1.1.2.2.1.2** Exemples d'utilisation
          - [ ] **6.1.1.2.2.1.3** Documentation des types
        - [ ] **6.1.1.2.2.2** Exemples de code
          - [ ] **6.1.1.2.2.2.1** Exemples basiques
          - [ ] **6.1.1.2.2.2.2** Cas d'utilisation avancés
          - [ ] **6.1.1.2.2.2.3** Gestion des erreurs
    - [ ] **6.1.1.3** Guides détaillés
      - [ ] **6.1.1.3.1** Guide d'installation
        - [ ] **6.1.1.3.1.1** Installation standard
          - [ ] **6.1.1.3.1.1.1** Prérequis détaillés
          - [ ] **6.1.1.3.1.1.2** Installation pas à pas
          - [ ] **6.1.1.3.1.1.3** Vérification de l'installation
        - [ ] **6.1.1.3.1.2** Installation Docker
          - [ ] **6.1.1.3.1.2.1** Image Docker officielle
          - [ ] **6.1.1.3.1.2.2** Docker Compose setup
          - [ ] **6.1.1.3.1.2.3** Configuration Docker
      - [ ] **6.1.1.3.2** Guide d'administration
        - [ ] **6.1.1.3.2.1** Configuration système
          - [ ] **6.1.1.3.2.1.1** Optimisation des performances
          - [ ] **6.1.1.3.2.1.2** Monitoring et logs
          - [ ] **6.1.1.3.2.1.3** Backup et restauration
        - [ ] **6.1.1.3.2.2** Maintenance
          - [ ] **6.1.1.3.2.2.1** Tâches périodiques
          - [ ] **6.1.1.3.2.2.2** Résolution des problèmes
          - [ ] **6.1.1.3.2.2.3** Mise à jour du système

### 6.2 Scripts de déploiement
- [ ] **6.2** Scripts de déploiement
  - [ ] **6.2.1** Automatisation
    - [ ] **6.2.1.1** Scripts de build
      - [ ] **6.2.1.1.1** Script de build principal
        - [ ] **6.2.1.1.1.1** Configuration du build
          - [ ] **6.2.1.1.1.1.1** Variables d'environnement
          - [ ] **6.2.1.1.1.1.2** Flags de compilation
          - [ ] **6.2.1.1.1.1.3** Optimisations
        - [ ] **6.2.1.1.1.2** Étapes de build
          - [ ] **6.2.1.1.1.2.1** Nettoyage des fichiers
          - [ ] **6.2.1.1.1.2.2** Compilation du code
          - [ ] **6.2.1.1.1.2.3** Génération des assets
        - [ ] **6.2.1.1.1.3** Tests post-build
          - [ ] **6.2.1.1.1.3.1** Tests unitaires
          - [ ] **6.2.1.1.1.3.2** Tests d'intégration
          - [ ] **6.2.1.1.1.3.3** Vérification des binaires
    - [ ] **6.2.1.2** Scripts d'installation
      - [ ] **6.2.1.2.1** Installation système
        - [ ] **6.2.1.2.1.1** Vérification prérequis
          - [ ] **6.2.1.2.1.1.1** Check Go version
          - [ ] **6.2.1.2.1.1.2** Check dépendances
          - [ ] **6.2.1.2.1.1.3** Check permissions
        - [ ] **6.2.1.2.1.2** Installation des composants
          - [ ] **6.2.1.2.1.2.1** Copie des binaires
          - [ ] **6.2.1.2.1.2.2** Configuration système
          - [ ] **6.2.1.2.1.2.3** Création des dossiers
        - [ ] **6.2.1.2.1.3** Configuration post-installation
          - [ ] **6.2.1.2.1.3.1** Permissions fichiers
          - [ ] **6.2.1.2.1.3.2** Variables d'environnement
          - [ ] **6.2.1.2.1.3.3** Tests post-installation
    - [ ] **6.2.1.3** Service Windows
      - [ ] **6.2.1.3.1** Configuration du service
        - [ ] **6.2.1.3.1.1** Création du service
          - [ ] **6.2.1.3.1.1.1** Nom et description
          - [ ] **6.2.1.3.1.1.2** Paramètres de démarrage
          - [ ] **6.2.1.3.1.1.3** Dépendances services
        - [ ] **6.2.1.3.1.2** Paramètres d'exécution
          - [ ] **6.2.1.3.1.2.1** Compte de service
          - [ ] **6.2.1.3.1.2.2** Redémarrage auto
          - [ ] **6.2.1.3.1.2.3** Timeouts
        - [ ] **6.2.1.3.1.3** Logging service
          - [ ] **6.2.1.3.1.3.1** Configuration EventLog
          - [ ] **6.2.1.3.1.3.2** Rotation des logs
          - [ ] **6.2.1.3.1.3.3** Niveaux de log

---

## LIVRABLE FINAL

### Fichiers principaux à créer :

```
tools/qdrant/rag-go/
├── go.mod
├── go.sum
├── main.go
├── cmd/
│   └── rag-go/
│       └── main.go
├── pkg/
│   ├── client/
│   │   └── qdrant.go
│   ├── embeddings/
│   │   └── provider.go
│   ├── indexer/
│   │   └── document.go
│   └── search/
│       └── engine.go
├── internal/
│   ├── config/
│   │   └── config.go
│   └── server/
│       └── handlers.go
└── README.md
```

### Commandes de test finales :
```bash
# Build
go build -o rag-go cmd/rag-go/main.go

# Test d'indexation
./rag-go index documents/

# Test de recherche
./rag-go search "Comment utiliser QDrant?"

# Lancer le serveur API
./rag-go server --port 8080
```

---

**PRIORITÉ :** Commencer par la Phase 1 pour avoir un prototype fonctionnel rapidement