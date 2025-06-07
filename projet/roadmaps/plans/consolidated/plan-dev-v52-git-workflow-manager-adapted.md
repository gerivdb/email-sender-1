# Plan GitWorkflowManager Adapté - Version Go Architecture Manager
*Version adaptée - 2025-06-07 - Progression globale : 0%*

## Introduction

Ce plan adapte le GitWorkflowManager original pour s'intégrer parfaitement dans l'écosystème de managers Go existant du projet EMAIL_SENDER_1. Le GitWorkflowManager suivra les patterns établis et s'intégrera avec ErrorManager, ConfigManager, StorageManager, et les autres composants existants.

## Architecture et Intégration

### Positionnement dans l'Écosystème

Le GitWorkflowManager sera un **Development Tool Manager** selon la hiérarchie établie :

```
IntegratedManager
└── Development Tools
    ├── ScriptManager
    ├── DeploymentManager
    ├── DependencyManager
    ├── RoadmapManager
    └── GitWorkflowManager (NOUVEAU)
```

### Interface GitWorkflowManager

```go
// interfaces/git_workflow.go
package interfaces

import (
    "context"
    "time"
)

type GitWorkflowManager interface {
    BaseManager
    
    // Branch Management
    CreateBranch(ctx context.Context, branchName string, parentBranch string) error
    SwitchBranch(ctx context.Context, branchName string) error
    DeleteBranch(ctx context.Context, branchName string) error
    ListBranches(ctx context.Context) ([]string, error)
    
    // Commit Management
    ValidateCommitMessage(ctx context.Context, message string) error
    CreateTimestampedCommit(ctx context.Context, message string) (*CommitInfo, error)
    GetCommitHistory(ctx context.Context, branch string, limit int) ([]*CommitInfo, error)
    
    // Sub-branch Management
    CreateSubBranch(ctx context.Context, parentBranch string, description string) (*SubBranchInfo, error)
    MergeSubBranch(ctx context.Context, subBranch string, parentBranch string) error
    
    // Pull Request Management
    CreatePullRequest(ctx context.Context, sourceBranch string, targetBranch string) (*PullRequestInfo, error)
    GetPullRequestStatus(ctx context.Context, prID string) (*PullRequestStatus, error)
    
    // Webhook Integration
    SendWebhook(ctx context.Context, payload *WebhookPayload) error
    ConfigureWebhook(ctx context.Context, config *WebhookConfig) error
    
    // Workflow Operations
    ExecuteWorkflow(ctx context.Context, workflowType WorkflowType) (*WorkflowResult, error)
    ValidateWorkflow(ctx context.Context, workflowType WorkflowType) error
}

// Types spécifiques
type CommitInfo struct {
    Hash        string    `json:"hash"`
    Message     string    `json:"message"`
    Author      string    `json:"author"`
    Timestamp   time.Time `json:"timestamp"`
    Branch      string    `json:"branch"`
}

type SubBranchInfo struct {
    Name        string    `json:"name"`
    ParentBranch string   `json:"parent_branch"`
    CreatedAt   time.Time `json:"created_at"`
    Description string    `json:"description"`
}

type PullRequestInfo struct {
    ID          string `json:"id"`
    Title       string `json:"title"`
    SourceBranch string `json:"source_branch"`
    TargetBranch string `json:"target_branch"`
    Status      string `json:"status"`
    URL         string `json:"url"`
}

type WebhookPayload struct {
    Branch    string                 `json:"branch"`
    Message   string                 `json:"message"`
    Timestamp time.Time              `json:"timestamp"`
    Metadata  map[string]interface{} `json:"metadata"`
}

type WorkflowType string

const (
    WorkflowTypeDevCommit    WorkflowType = "dev_commit"
    WorkflowTypeJulesCommit  WorkflowType = "jules_commit"
    WorkflowTypeSubBranch    WorkflowType = "sub_branch"
    WorkflowTypePullRequest  WorkflowType = "pull_request"
)
```

## Table des Matières

- [Phase 1: Architecture et Setup](#phase-1)
- [Phase 2: Implémentation Core](#phase-2)
- [Phase 3: Intégration Managers](#phase-3)
- [Phase 4: Workflows Git](#phase-4)
- [Phase 5: Tests et Validation](#phase-5)
- [Phase 6: Documentation](#phase-6)

## Phase 1: Architecture et Setup {#phase-1}
*Progression: 0%*

### 1.1 Structure du Manager
*Progression: 0%*

#### 1.1.1 Création de l'arborescence
*Progression: 0%*

- [ ] Créer la structure de fichiers du GitWorkflowManager
  - Structure :
    ```
    development/managers/git-workflow-manager/
    ├── cmd/
    │   └── main.go
    ├── modules/
    │   ├── git_workflow_manager.go
    │   ├── branch_manager.go
    │   ├── commit_manager.go
    │   ├── webhook_manager.go
    │   └── pr_manager.go
    ├── config/
    │   └── git_config.go
    ├── tests/
    │   ├── git_workflow_manager_test.go
    │   ├── branch_manager_test.go
    │   ├── commit_manager_test.go
    │   └── integration_test.go
    ├── docs/
    │   └── README.md
    ├── go.mod
    └── go.sum
    ```
  - Entrée : Structure vide
  - Sortie : Arborescence complète créée
  - Outils : mkdir, touch

#### 1.1.2 Configuration go.mod
*Progression: 0%*

- [ ] Créer go.mod avec dépendances appropriées
  - Entrée : Arborescence créée
  - Sortie : go.mod configuré avec replace directives
  - Contenu :
    ```go
    module git-workflow-manager
    
    go 1.21
    
    require (
        github.com/go-git/go-git/v5 v5.8.1
        github.com/google/go-github/v53 v53.2.0
        golang.org/x/oauth2 v0.10.0
    )
    
    replace error-manager => ../error-manager
    replace integrated-manager => ../integrated-manager
    replace config-manager => ../config-manager
    replace storage-manager => ../storage-manager
    ```

### 1.2 Interface Integration
*Progression: 0%*

#### 1.2.1 Ajout à interfaces/git_workflow.go
*Progression: 0%*

- [ ] Créer le fichier d'interface GitWorkflowManager
  - Fichier : `development/managers/interfaces/git_workflow.go`
  - Entrée : Package interfaces existant
  - Sortie : Interface GitWorkflowManager définie
  - Intégration : Import dans `interfaces/types.go`

#### 1.2.2 Mise à jour interfaces/common.go
*Progression: 0%*

- [ ] Étendre BaseManager si nécessaire
  - Entrée : Interface BaseManager existante
  - Sortie : BaseManager étendu pour GitWorkflow
  - Validation : Compatibilité avec tous les managers existants

## Phase 2: Implémentation Core {#phase-2}
*Progression: 0%*

### 2.1 GitWorkflowManager Principal
*Progression: 0%*

#### 2.1.1 Structure principale
*Progression: 0%*

- [ ] Implémenter la structure GitWorkflowManager
  - Fichier : `modules/git_workflow_manager.go`
  - Structure :
    ```go
    type GitWorkflowManager struct {
        errorManager    interfaces.ErrorManager
        configManager   interfaces.ConfigManager
        storageManager  interfaces.StorageManager
        
        branchManager   *BranchManager
        commitManager   *CommitManager
        webhookManager  *WebhookManager
        prManager       *PullRequestManager
        
        config         *GitWorkflowConfig
        repository     *git.Repository
        githubClient   *github.Client
        
        mu             sync.RWMutex
        initialized    bool
    }
    ```

#### 2.1.2 Constructeur et initialisation
*Progression: 0%*

- [ ] Implémenter NewGitWorkflowManager
  - Signature :
    ```go
    func NewGitWorkflowManager(
        errorMgr interfaces.ErrorManager,
        configMgr interfaces.ConfigManager,
        storageMgr interfaces.StorageManager,
    ) (interfaces.GitWorkflowManager, error)
    ```
  - Pattern : Factory Pattern comme les autres managers
  - Validation : Vérification des dépendances injectées

- [ ] Implémenter Initialize()
  - Fonctionnalités :
    - Initialisation du repository Git
    - Configuration GitHub client
    - Setup des sous-managers
    - Validation de la configuration
  - ErrorManager : Intégration complète pour tous les échecs

### 2.2 Modules Spécialisés
*Progression: 0%*

#### 2.2.1 BranchManager
*Progression: 0%*

- [ ] Implémenter modules/branch_manager.go
  - Fonctionnalités :
    ```go
    type BranchManager struct {
        repo         *git.Repository
        errorManager interfaces.ErrorManager
    }
    
    func (bm *BranchManager) CreateBranch(ctx context.Context, name, parent string) error
    func (bm *BranchManager) SwitchBranch(ctx context.Context, name string) error
    func (bm *BranchManager) DeleteBranch(ctx context.Context, name string) error
    func (bm *BranchManager) ListBranches(ctx context.Context) ([]string, error)
    ```
  - Intégration ErrorManager : Toutes les opérations Git

#### 2.2.2 CommitManager
*Progression: 0%*

- [ ] Implémenter modules/commit_manager.go
  - Fonctionnalités :
    - Validation des messages de commit selon format `YYYYMMDD-HHMM-<hash> - description`
    - Création de commits horodatés
    - Gestion des métadonnées de commit
  - Intégration StorageManager : Sauvegarde des métadonnées

#### 2.2.3 WebhookManager
*Progression: 0%*

- [ ] Implémenter modules/webhook_manager.go
  - Fonctionnalités :
    - Envoi webhooks vers jules.googles.com
    - Retry mechanism (3 tentatives)
    - Configuration webhooks
  - Intégration ConfigManager : URLs et secrets webhooks

#### 2.2.4 PullRequestManager
*Progression: 0%*

- [ ] Implémenter modules/pr_manager.go
  - Fonctionnalités :
    - Création PR automatiques
    - Monitoring statut PR
    - Intégration GitHub API
  - Dépendances : GitHub client configuré

## Phase 3: Intégration Managers {#phase-3}
*Progression: 0%*

### 3.1 ErrorManager Integration
*Progression: 0%*

#### 3.1.1 Contextes d'erreur spécifiques
*Progression: 0%*

- [ ] Définir les contextes d'erreur GitWorkflow
  - Types d'erreurs :
    ```go
    const (
        GitWorkflowErrorBranchCreation   = "GIT_WORKFLOW_BRANCH_CREATION"
        GitWorkflowErrorCommitValidation = "GIT_WORKFLOW_COMMIT_VALIDATION"
        GitWorkflowErrorWebhookSend     = "GIT_WORKFLOW_WEBHOOK_SEND"
        GitWorkflowErrorPRCreation      = "GIT_WORKFLOW_PR_CREATION"
        GitWorkflowErrorRepository      = "GIT_WORKFLOW_REPOSITORY"
    )
    ```
  - Intégration : Tous les appels à errorManager.ProcessError()

#### 3.1.2 Patterns de récupération
*Progression: 0%*

- [ ] Implémenter la récupération automatique
  - Scenarios :
    - Retry pour webhooks échoués
    - Récupération après conflit de merge
    - Fallback en cas d'échec GitHub API
  - Pattern : Circuit Breaker pour les appels externes

### 3.2 ConfigManager Integration
*Progression: 0%*

#### 3.2.1 Configuration GitWorkflow
*Progression: 0%*

- [ ] Créer config/git_config.go
  - Structure :
    ```go
    type GitWorkflowConfig struct {
        Repository    RepositoryConfig    `yaml:"repository"`
        GitHub        GitHubConfig        `yaml:"github"`
        Webhooks      WebhookConfig       `yaml:"webhooks"`
        Branches      BranchConfig        `yaml:"branches"`
        CommitFormat  CommitFormatConfig  `yaml:"commit_format"`
    }
    ```
  - Source : ConfigManager.LoadConfigFile("git_workflow.yaml")

#### 3.2.2 Fichier de configuration
*Progression: 0%*

- [ ] Créer projet/config/managers/git_workflow.yaml
  - Contenu :
    ```yaml
    repository:
      path: "."
      remote_name: "origin"
      
    github:
      api_url: "https://api.github.com"
      token_secret: "GITHUB_TOKEN"
      
    webhooks:
      jules_google:
        url: "https://jules.googles.com/webhook/git"
        timeout: "30s"
        retry_count: 3
        retry_delay: "5s"
        
    branches:
      main_branches: ["dev", "jules-google", "main"]
      sub_branch_prefix: "feature/"
      
    commit_format:
      pattern: "^\\d{8}-\\d{4}-[a-f0-9]{6,} - .+"
      timezone: "UTC"
    ```

### 3.3 StorageManager Integration
*Progression: 0%*

#### 3.3.1 Métadonnées Git
*Progression: 0%*

- [ ] Définir le schéma de données GitWorkflow
  - Tables PostgreSQL :
    ```sql
    CREATE TABLE git_workflows (
        id SERIAL PRIMARY KEY,
        workflow_type VARCHAR(50) NOT NULL,
        branch_name VARCHAR(255) NOT NULL,
        commit_hash VARCHAR(40),
        status VARCHAR(50) NOT NULL,
        metadata JSONB,
        created_at TIMESTAMP DEFAULT NOW(),
        updated_at TIMESTAMP DEFAULT NOW()
    );
    
    CREATE TABLE git_commits (
        id SERIAL PRIMARY KEY,
        hash VARCHAR(40) UNIQUE NOT NULL,
        message TEXT NOT NULL,
        author VARCHAR(255) NOT NULL,
        branch VARCHAR(255) NOT NULL,
        timestamp TIMESTAMP NOT NULL,
        workflow_id INTEGER REFERENCES git_workflows(id)
    );
    ```

#### 3.3.2 Repository pattern
*Progression: 0%*

- [ ] Implémenter GitWorkflowRepository
  - Interface :
    ```go
    type GitWorkflowRepository interface {
        SaveWorkflow(ctx context.Context, workflow *GitWorkflow) error
        GetWorkflow(ctx context.Context, id int) (*GitWorkflow, error)
        SaveCommit(ctx context.Context, commit *GitCommit) error
        GetCommitsByBranch(ctx context.Context, branch string) ([]*GitCommit, error)
    }
    ```
  - Intégration : StorageManager pour les connexions

## Phase 4: Workflows Git {#phase-4}
*Progression: 0%*

### 4.1 Workflow Dev Branch
*Progression: 0%*

#### 4.1.1 Implémentation DevWorkflow
*Progression: 0%*

- [ ] Créer le workflow pour la branche dev
  - Étapes :
    1. Validation des fichiers staged
    2. Création commit horodaté
    3. Sauvegarde métadonnées (StorageManager)
    4. Notification optionnelle
  - Code :
    ```go
    func (gwm *GitWorkflowManager) ExecuteDevWorkflow(ctx context.Context, message string) (*WorkflowResult, error) {
        // 1. Validate staged files
        if err := gwm.validateStagedFiles(ctx); err != nil {
            return nil, gwm.errorManager.ProcessError(ctx, GitWorkflowErrorRepository, err)
        }
        
        // 2. Create timestamped commit
        commit, err := gwm.commitManager.CreateTimestampedCommit(ctx, message)
        if err != nil {
            return nil, gwm.errorManager.ProcessError(ctx, GitWorkflowErrorCommitValidation, err)
        }
        
        // 3. Save metadata
        if err := gwm.storageManager.SaveCommit(ctx, commit); err != nil {
            return nil, gwm.errorManager.ProcessError(ctx, GitWorkflowErrorRepository, err)
        }
        
        return &WorkflowResult{CommitHash: commit.Hash, Status: "success"}, nil
    }
    ```

#### 4.1.2 Sub-branch workflow
*Progression: 0%*

- [ ] Implémenter la gestion des sous-branches
  - Format : `feature/YYYYMMDD-HHMM-description`
  - Workflow :
    1. Création depuis dev/jules-google
    2. Développement sur sub-branch
    3. Merge automatique vers branche parent
    4. Nettoyage sub-branch

### 4.2 Webhook Integration
*Progression: 0%*

#### 4.2.1 Jules Google Webhook
*Progression: 0%*

- [ ] Implémenter l'envoi vers jules.googles.com
  - Payload :
    ```go
    type JulesWebhookPayload struct {
        Branch      string            `json:"branch"`
        CommitHash  string            `json:"commit_hash"`
        Message     string            `json:"message"`
        Timestamp   time.Time         `json:"timestamp"`
        Author      string            `json:"author"`
        Files       []string          `json:"files"`
        Metadata    map[string]string `json:"metadata"`
    }
    ```
  - Retry Logic : 3 tentatives avec backoff exponentiel

#### 4.2.2 Webhook Configuration
*Progression: 0%*

- [ ] Système de configuration webhooks
  - Source : ConfigManager pour URLs et secrets
  - Validation : Ping webhook lors de l'initialisation
  - Monitoring : Métriques d'envoi webhook

### 4.3 Pull Request Automation
*Progression: 0%*

#### 4.3.1 GitHub Actions Integration
*Progression: 0%*

- [ ] Créer .github/workflows/git-workflow-manager.yml
  - Déclencheur : Push sur dev/jules-google
  - Actions :
    1. Tests automatiques
    2. Validation workflow
    3. Création PR vers main
  - Intégration : GitWorkflowManager pour validation

#### 4.3.2 PR Template
*Progression: 0%*

- [ ] Créer template PR automatique
  - Template :
    ```markdown
    ## Auto PR from {{ .SourceBranch }}
    
    **Workflow Type:** {{ .WorkflowType }}
    **Commit Range:** {{ .CommitRange }}
    **Generated:** {{ .Timestamp }}
    
    ### Changes
    {{ range .Commits }}
    - {{ .Message }} ({{ .Hash }})
    {{ end }}
    
    ### Validation
    - [x] Tests passed
    - [x] GitWorkflowManager validation
    - [x] ErrorManager integration
    ```

## Phase 5: Tests et Validation {#phase-5}
*Progression: 0%*

### 5.1 Tests Unitaires
*Progression: 0%*

#### 5.1.1 Tests Manager Principal
*Progression: 0%*

- [ ] Tests GitWorkflowManager
  - Fichier : `tests/git_workflow_manager_test.go`
  - Coverage :
    - Initialisation avec dépendances mockées
    - Tous les workflows (dev, jules, sub-branch, PR)
    - Gestion des erreurs avec ErrorManager
    - Configuration via ConfigManager
  - Mocks : ErrorManager, ConfigManager, StorageManager

#### 5.1.2 Tests Modules Spécialisés
*Progression: 0%*

- [ ] Tests BranchManager
  - Tests :
    - Création/suppression branches
    - Switch branches
    - Validation existence branches
    - Gestion erreurs Git

- [ ] Tests CommitManager
  - Tests :
    - Validation format messages
    - Création commits horodatés
    - Métadonnées commits
    - Intégration StorageManager

- [ ] Tests WebhookManager
  - Tests :
    - Envoi webhooks avec retry
    - Configuration webhooks
    - Gestion erreurs réseau
    - Validation payloads

### 5.2 Tests d'Intégration
*Progression: 0%*

#### 5.2.1 Tests Repository Temporaire
*Progression: 0%*

- [ ] Tests avec repository Git temporaire
  - Setup :
    ```go
    func setupTestRepo(t *testing.T) string {
        tempDir := t.TempDir()
        cmd := exec.Command("git", "init", tempDir)
        err := cmd.Run()
        require.NoError(t, err)
        return tempDir
    }
    ```
  - Tests : Workflow complet dans repository isolé

#### 5.2.2 Tests IntegratedManager
*Progression: 0%*

- [ ] Tests intégration avec l'écosystème
  - Scenario :
    1. Initialisation via IntegratedManager
    2. Exécution workflow complet
    3. Vérification état dans ErrorManager
    4. Validation données StorageManager
  - Validation : Comportement dans l'écosystème réel

### 5.3 Tests de Performance
*Progression: 0%*

#### 5.3.1 Benchmarks
*Progression: 0%*

- [ ] Benchmarks opérations Git
  - Métriques :
    - Temps création/merge branches
    - Performance commits en masse
    - Latence webhooks
    - Mémoire utilisée
  - Outils : Go testing.B, pprof

#### 5.3.2 Tests de Charge
*Progression: 0%*

- [ ] Tests simulation usage intensif
  - Scenarios :
    - 100 commits/minute
    - Création simultanée de sub-branches
    - Webhooks en parallèle
  - Validation : Stabilité et performance

## Phase 6: Documentation {#phase-6}
*Progression: 0%*

### 6.1 Documentation Technique
*Progression: 0%*

#### 6.1.1 README et Architecture
*Progression: 0%*

- [ ] Créer docs/README.md
  - Contenu :
    - Architecture GitWorkflowManager
    - Intégration écosystème managers
    - Workflows supportés
    - Configuration requise
    - Examples d'utilisation

#### 6.1.2 API Documentation
*Progression: 0%*

- [ ] Documentation GoDoc complète
  - Coverage : Toutes les interfaces publiques
  - Examples : Code examples pour chaque méthode
  - Integration : Liens vers autres managers

### 6.2 Guide Utilisateur
*Progression: 0%*

#### 6.2.1 Guide de Démarrage
*Progression: 0%*

- [ ] Créer guide utilisateur
  - Sections :
    - Installation et configuration
    - Workflows pas-à-pas
    - Intégration VS Code
    - Troubleshooting
  - Format : Markdown avec diagrammes Mermaid

#### 6.2.2 Diagrammes Workflow
*Progression: 0%*

- [ ] Diagrammes Mermaid des workflows
  - Dev Workflow :
    ```mermaid
    graph TD
        A[Files Staged] --> B[Validate Format]
        B --> C[Create Timestamped Commit]
        C --> D[Save Metadata]
        D --> E[Success]
        B --> F[Validation Error]
        C --> G[Git Error]
        D --> H[Storage Error]
    ```

## Intégration avec l'Écosystème Existant

### Dependencies Tree
```
GitWorkflowManager
├── ErrorManager (Core Service)
├── ConfigManager (Service)
├── StorageManager (Infrastructure)
├── IntegratedManager (Coordination)
└── GitHub API (External)
```

### Error Integration Points
- Toutes les opérations Git via ErrorManager
- Webhooks failures avec retry automatique
- Configuration errors avec fallbacks
- Storage errors avec circuit breaker

### Configuration Integration
- git_workflow.yaml via ConfigManager
- Secrets via ConfigManager (GitHub tokens)
- Environment-specific config
- Runtime reconfiguration

### Storage Integration
- Métadonnées workflows dans PostgreSQL
- Commit history tracking
- Webhook delivery status
- Performance metrics storage

## Prochaines Étapes

1. **Immédiat** : Créer la structure de fichiers et go.mod
2. **Phase 1** : Implémenter l'interface et l'architecture de base
3. **Phase 2** : Développer les modules core (Branch, Commit, Webhook)
4. **Phase 3** : Intégrer avec l'écosystème de managers existant
5. **Phase 4** : Implémenter les workflows complets
6. **Phase 5** : Tests exhaustifs et validation
7. **Phase 6** : Documentation complète

## Critères de Succès

- [ ] Interface GitWorkflowManager conforme aux patterns existants
- [ ] Intégration complète avec ErrorManager, ConfigManager, StorageManager
- [ ] Workflows dev et jules-google opérationnels
- [ ] Tests unitaires > 90% coverage
- [ ] Tests d'intégration avec écosystème complet
- [ ] Documentation complète et à jour
- [ ] Performance acceptable (< 2s pour workflow complet)
- [ ] Gestion d'erreurs robuste avec récupération automatique

Ce plan adapté respecte parfaitement l'architecture existante du projet et s'intègre harmonieusement avec l'écosystème de managers déjà en place.
