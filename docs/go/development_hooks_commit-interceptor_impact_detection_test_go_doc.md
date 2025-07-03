# Package commitinterceptor

advanced_classifier.go - Moteur de Classification Intelligente Multi-Critères
Phase 2.2 du Framework de Branchement Automatique


## Types

### AlternativeType

AlternativeType - Types alternatifs avec scores


### ClassificationMetrics

ClassificationMetrics - Métriques de performance


### ClassificationResult

ClassificationResult - Résultat enrichi avec facteurs de décision


### ClassificationWeights

ClassificationWeights - Pondération des facteurs de décision


### ConflictPrediction

ConflictPrediction - Prédiction de conflits


### MultiCriteriaClassifier

MultiCriteriaClassifier - Moteur de classification hybride


#### Methods

##### MultiCriteriaClassifier.ClassifyCommitAdvanced

ClassifyCommitAdvanced - Classification hybride multi-critères


```go
func (mc *MultiCriteriaClassifier) ClassifyCommitAdvanced(ctx context.Context,
	commitData *CommitData) (*ClassificationResult, error)
```

### SemanticEmbedding

SemanticEmbedding represents a semantic embedding for content


#### Methods

##### SemanticEmbedding.GetSimilarity

GetSimilarity returns a simple similarity score between two embeddings
This is a placeholder implementation


```go
func (se *SemanticEmbedding) GetSimilarity(other *SemanticEmbedding) float64
```

### SemanticInsights

SemanticInsights - Analyse sémantique détaillée


## Functions

### DebugConfidence

DebugConfidence provides debugging for confidence levels


```go
func DebugConfidence(confidence float64) string
```

### DebugRegex

DebugRegex provides debug information for regex matching


```go
func DebugRegex(pattern string, input string) (bool, []string)
```

### TestBranchingManager

```go
func TestBranchingManager(t *testing.T)
```

### TestRouter

```go
func TestRouter(t *testing.T)
```

# Package main

development/hooks/commit-interceptor/branching_manager.go

development/hooks/commit-interceptor/config.go

development/hooks/commit-interceptor/interceptor.go

development/hooks/commit-interceptor/main.go

development/hooks/commit-interceptor/router.go

development/hooks/commit-interceptor/semantic_embeddings.go


## Types

### AdvancedAutonomyManagerInterface

AdvancedAutonomyManagerInterface defines the interface for AI/ML integration


### BranchDecision

BranchDecision represents a routing decision for a commit


### BranchInfo

BranchInfo contains information about a Git branch


### BranchRouter

BranchRouter handles routing decisions for commits


#### Methods

##### BranchRouter.RouteCommit

RouteCommit makes routing decisions based on commit analysis


```go
func (br *BranchRouter) RouteCommit(analysis *CommitAnalysis) (*BranchDecision, error)
```

##### BranchRouter.ValidateRoutingDecision

ValidateRoutingDecision validates that a routing decision is valid


```go
func (br *BranchRouter) ValidateRoutingDecision(decision *BranchDecision) error
```

### BranchingManager

BranchingManager handles Git branching operations


#### Methods

##### BranchingManager.DeleteBranch

DeleteBranch deletes a Git branch


```go
func (bm *BranchingManager) DeleteBranch(branchName string) error
```

##### BranchingManager.ExecuteRouting

ExecuteRouting executes the routing decision


```go
func (bm *BranchingManager) ExecuteRouting(decision *BranchDecision) error
```

##### BranchingManager.GetBranchInfo

GetBranchInfo returns information about a branch


```go
func (bm *BranchingManager) GetBranchInfo(branchName string) (*BranchInfo, error)
```

##### BranchingManager.ListBranches

ListBranches returns a list of all branches


```go
func (bm *BranchingManager) ListBranches() ([]string, error)
```

### CommitContext

CommitContext represents the complete context of a commit for semantic analysis


### CommitData

CommitData represents the data extracted from a commit


### CommitInterceptor

#### Methods

##### CommitInterceptor.HandleHealth

HandleHealth provides health check endpoint


```go
func (ci *CommitInterceptor) HandleHealth(w http.ResponseWriter, r *http.Request)
```

##### CommitInterceptor.HandleMetrics

HandleMetrics provides metrics endpoint


```go
func (ci *CommitInterceptor) HandleMetrics(w http.ResponseWriter, r *http.Request)
```

##### CommitInterceptor.HandlePostCommit

HandlePostCommit handles post-commit webhook events


```go
func (ci *CommitInterceptor) HandlePostCommit(w http.ResponseWriter, r *http.Request)
```

##### CommitInterceptor.HandlePreCommit

HandlePreCommit handles pre-commit webhook events


```go
func (ci *CommitInterceptor) HandlePreCommit(w http.ResponseWriter, r *http.Request)
```

### Config

Config represents the configuration for the commit interceptor


#### Methods

##### Config.GetRoutingRule

GetRoutingRule returns the routing rule for a given change type


```go
func (c *Config) GetRoutingRule(changeType string) (RoutingRule, bool)
```

##### Config.SaveConfig

SaveConfig saves the current configuration to file


```go
func (c *Config) SaveConfig(filename string) error
```

##### Config.ValidateConfig

ValidateConfig validates the configuration


```go
func (c *Config) ValidateConfig() error
```

### ContextualMemoryInterface

ContextualMemoryInterface defines the interface for contextual memory operations


### GitConfig

GitConfig contains Git-specific configuration


### GitWebhookPayload

GitWebhookPayload represents the incoming Git webhook payload


### LoggingConfig

LoggingConfig contains logging configuration


### MockAdvancedAutonomyManager

MockAdvancedAutonomyManager provides a mock implementation for testing


#### Methods

##### MockAdvancedAutonomyManager.AnalyzeSimilarity

AnalyzeSimilarity analyzes similarity between two embeddings using cosine similarity


```go
func (m *MockAdvancedAutonomyManager) AnalyzeSimilarity(ctx context.Context, embeddings1, embeddings2 []float64) (float64, error)
```

##### MockAdvancedAutonomyManager.DetectConflicts

DetectConflicts predicts potential conflicts based on file patterns and embeddings


```go
func (m *MockAdvancedAutonomyManager) DetectConflicts(ctx context.Context, files []string, embeddings []float64) (float64, error)
```

##### MockAdvancedAutonomyManager.GenerateEmbeddings

GenerateEmbeddings generates mock embeddings based on text content


```go
func (m *MockAdvancedAutonomyManager) GenerateEmbeddings(ctx context.Context, text string) ([]float64, error)
```

##### MockAdvancedAutonomyManager.PredictCommitType

PredictCommitType predicts the commit type based on embeddings and history


```go
func (m *MockAdvancedAutonomyManager) PredictCommitType(ctx context.Context, embeddings []float64, history *ProjectHistory) (string, float64, error)
```

##### MockAdvancedAutonomyManager.TrainOnHistory

TrainOnHistory trains the model on historical commits


```go
func (m *MockAdvancedAutonomyManager) TrainOnHistory(ctx context.Context, history []*CommitContext) error
```

### MockContextualMemory

MockContextualMemory provides a mock implementation for testing


#### Methods

##### MockContextualMemory.CacheEmbeddings

CacheEmbeddings caches embeddings


```go
func (m *MockContextualMemory) CacheEmbeddings(key string, embeddings []float64) error
```

##### MockContextualMemory.GetCachedEmbeddings

GetCachedEmbeddings retrieves cached embeddings


```go
func (m *MockContextualMemory) GetCachedEmbeddings(key string) ([]float64, bool)
```

##### MockContextualMemory.GetProjectHistory

GetProjectHistory retrieves the project history


```go
func (m *MockContextualMemory) GetProjectHistory(ctx context.Context) (*ProjectHistory, error)
```

##### MockContextualMemory.RetrieveSimilarCommits

RetrieveSimilarCommits retrieves commits similar to the given embeddings


```go
func (m *MockContextualMemory) RetrieveSimilarCommits(ctx context.Context, embeddings []float64, limit int) ([]*CommitContext, error)
```

##### MockContextualMemory.StoreCommitContext

StoreCommitContext stores a commit context


```go
func (m *MockContextualMemory) StoreCommitContext(ctx context.Context, commitCtx *CommitContext) error
```

##### MockContextualMemory.UpdateProjectHistory

UpdateProjectHistory updates the project history with new commit


```go
func (m *MockContextualMemory) UpdateProjectHistory(ctx context.Context, commitCtx *CommitContext) error
```

### ProjectHistory

ProjectHistory represents historical patterns for the project


### RoutingConfig

RoutingConfig contains routing rules configuration


### RoutingRule

RoutingRule defines how specific types of commits should be routed


### SemanticEmbeddingManager

SemanticEmbeddingManager manages semantic analysis and embeddings


#### Methods

##### SemanticEmbeddingManager.CreateCommitContext

CreateCommitContext creates a comprehensive commit context for semantic analysis


```go
func (sem *SemanticEmbeddingManager) CreateCommitContext(ctx context.Context, data *CommitData) (*CommitContext, error)
```

##### SemanticEmbeddingManager.TrainOnCommitHistory

TrainOnCommitHistory trains the semantic system on historical commits


```go
func (sem *SemanticEmbeddingManager) TrainOnCommitHistory(ctx context.Context, commits []*CommitData) error
```

### ServerConfig

ServerConfig contains server-specific configuration


### WebhookConfig

WebhookConfig contains webhook configuration


## Functions

### ValidateCommitData

ValidateCommitData validates that commit data is complete and valid


```go
func ValidateCommitData(data *CommitData) error
```

