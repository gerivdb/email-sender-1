# Guide de Contribution

## Setup Développement

### Prérequis

- Go 1.21+
- Node.js 18+
- PostgreSQL 15+
- QDrant 1.7+
- Git 2.40+

### 1. Fork et Clone

```bash
# Fork le repository sur GitHub

# Puis clone votre fork

git clone https://github.com/VOTRE_USERNAME/planning-ecosystem-sync.git
cd planning-ecosystem-sync

# Ajouter l'upstream

git remote add upstream https://github.com/planning-ecosystem/sync.git
```plaintext
### 2. Installation des Dépendances

#### Dependencies Go

```powershell
# Dependencies principales

go mod download

# Outils de développement

go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
go install github.com/swaggo/swag/cmd/swag@latest
go install github.com/golang/mock/mockgen@latest
```plaintext
#### Dependencies Node.js (Frontend)

```powershell
cd web/dashboard
npm install
```plaintext
#### Dependencies Python (Scripts)

```powershell
python -m pip install -r scripts/requirements.txt
```plaintext
### 3. Configuration Développement

```powershell
# Copier configuration par défaut

Copy-Item config/config.example.yaml config/config.dev.yaml

# Éditer avec vos paramètres

notepad config/config.dev.yaml
```plaintext
**Configuration minimale pour développement :**
```yaml
# config/config.dev.yaml

database:
  postgres:
    host: localhost
    port: 5432
    dbname: planning_sync_dev
    user: dev_user
    password: dev_password
  
  qdrant:
    host: localhost
    port: 6333
    collection: plans_dev

development:
  hot_reload: true
  debug_logs: true
  mock_services: true

testing:
  use_test_db: true
  cleanup_after_tests: true
```plaintext
### 4. Setup Base de Données

```powershell
# PostgreSQL

psql -U postgres -c "CREATE DATABASE planning_sync_dev;"
psql -U postgres -d planning_sync_dev -f scripts/sql/schema.sql

# QDrant (via Docker)

docker run -p 6333:6333 qdrant/qdrant:latest
```plaintext
### 5. Setup Pre-commit Hooks

```powershell
# Copier hooks

Copy-Item scripts/hooks/pre-commit.sh .git/hooks/pre-commit
# Sur Windows, créer un script .bat

@echo off
bash .git/hooks/pre-commit
```plaintext
**Contenu pre-commit hook :**
```bash
#!/bin/sh

# Pre-commit hook pour validation code

echo "Running pre-commit validations..."

# 1. Format Go code

gofmt -w .
if [ $? -ne 0 ]; then
    echo "❌ gofmt failed"
    exit 1
fi

# 2. Lint Go code

golangci-lint run
if [ $? -ne 0 ]; then
    echo "❌ golangci-lint failed"
    exit 1
fi

# 3. Run tests

go test ./... -short
if [ $? -ne 0 ]; then
    echo "❌ Tests failed"
    exit 1
fi

# 4. Validate commit message

commit_regex="^(feat|fix|docs|style|refactor|test|chore)(\(.+\))?: .{1,50}"
commit_msg=$(cat .git/COMMIT_EDITMSG)
if ! echo "$commit_msg" | grep -qE "$commit_regex"; then
    echo "❌ Invalid commit message format"
    echo "Use: type(scope): description"
    exit 1
fi

echo "✅ All pre-commit validations passed"
```plaintext
## Standards de Code

### Go Code Style

#### 1. Conventions de Nommage

```go
// ✅ Correct
type PlanSynchronizer struct {
    validator ValidationEngine
    storage   StorageRepository
}

func (p *PlanSynchronizer) SyncToDatabase(ctx context.Context, plan *Plan) error {
    // Implementation
}

// ❌ Incorrect
type plan_synchronizer struct {
    Validator validation_engine
    storage   storage_repo
}

func (p *plan_synchronizer) sync_to_db(plan *plan_type) error {
    // Implementation
}
```plaintext
#### 2. Structure des Packages

```plaintext
internal/
├── api/           # API handlers

├── core/          # Business logic

├── repository/    # Data access

├── service/       # Application services

└── util/          # Utilities

cmd/
├── server/        # Main server

├── cli/           # CLI tools

└── migrate/       # Migration tools

```plaintext
#### 3. Documentation GoDoc

```go
// PlanSynchronizer handles synchronization between Markdown plans and dynamic systems.
// It provides bidirectional sync capabilities with conflict detection and resolution.
type PlanSynchronizer struct {
    // validator ensures data integrity during synchronization
    validator ValidationEngine
    // storage provides access to persistent data storage
    storage StorageRepository
}

// SyncToDatabase synchronizes a parsed plan to the dynamic storage system.
// It returns an error if validation fails or if conflicts cannot be resolved.
//
// Example usage:
//   syncer := NewPlanSynchronizer(validator, storage)
//   err := syncer.SyncToDatabase(ctx, plan)
//   if err != nil {
//       log.Printf("Sync failed: %v", err)
//   }
func (p *PlanSynchronizer) SyncToDatabase(ctx context.Context, plan *Plan) error {
    // Implementation
}
```plaintext
#### 4. Tests Unitaires

```go
func TestPlanSynchronizer_SyncToDatabase(t *testing.T) {
    tests := []struct {
        name        string
        plan        *Plan
        setupMocks  func(*MockValidator, *MockStorage)
        wantErr     bool
        wantErrType error
    }{
        {
            name: "successful sync",
            plan: &Plan{ID: "test-1", Version: "1.0"},
            setupMocks: func(mv *MockValidator, ms *MockStorage) {
                mv.EXPECT().Validate(gomock.Any()).Return(nil)
                ms.EXPECT().Save(gomock.Any()).Return(nil)
            },
            wantErr: false,
        },
        {
            name: "validation failure",
            plan: &Plan{ID: "invalid"},
            setupMocks: func(mv *MockValidator, ms *MockStorage) {
                mv.EXPECT().Validate(gomock.Any()).Return(ErrInvalidPlan)
            },
            wantErr:     true,
            wantErrType: ErrInvalidPlan,
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            ctrl := gomock.NewController(t)
            defer ctrl.Finish()

            mockValidator := NewMockValidator(ctrl)
            mockStorage := NewMockStorage(ctrl)
            tt.setupMocks(mockValidator, mockStorage)

            syncer := NewPlanSynchronizer(mockValidator, mockStorage)
            err := syncer.SyncToDatabase(context.Background(), tt.plan)

            if tt.wantErr {
                assert.Error(t, err)
                if tt.wantErrType != nil {
                    assert.ErrorIs(t, err, tt.wantErrType)
                }
            } else {
                assert.NoError(t, err)
            }
        })
    }
}
```plaintext
#### 5. Coverage Requirements

- **Minimum coverage :** 80%
- **Critical paths :** 95%+ (sync, validation, conflict resolution)
- **Error paths :** 100% (toutes les erreurs testées)

```powershell
# Vérifier coverage

go test ./... -coverprofile=coverage.out
go tool cover -html=coverage.out -o coverage.html

# Coverage par package

go test ./... -coverprofile=coverage.out
go tool cover -func=coverage.out
```plaintext
### Frontend Code Style (TypeScript/React)

#### 1. Conventions TypeScript

```typescript
// ✅ Correct
interface PlanSyncStatus {
  planId: string;
  status: 'syncing' | 'completed' | 'failed';
  lastSync: Date;
  conflicts: ConflictInfo[];
}

const usePlanSync = (planId: string): PlanSyncStatus => {
  // Implementation
};

// ❌ Incorrect
interface planSyncStatus {
  plan_id: string;
  Status: string;
  last_sync: any;
}
```plaintext
#### 2. Composants React

```typescript
interface PlanDashboardProps {
  plans: Plan[];
  onSyncPlan: (planId: string) => Promise<void>;
  loading?: boolean;
}

export const PlanDashboard: React.FC<PlanDashboardProps> = ({
  plans,
  onSyncPlan,
  loading = false
}) => {
  const [selectedPlan, setSelectedPlan] = useState<Plan | null>(null);
  
  return (
    <div className="plan-dashboard">
      {/* Component JSX */}
    </div>
  );
};
```plaintext
## Workflow de Contribution

### 1. Types de Commits

Utiliser la convention [Conventional Commits](https://conventionalcommits.org/) :

```plaintext
feat(sync): add bidirectional sync support
fix(validation): handle edge case in progress calculation  
docs(api): update API reference for v2.5
style(dashboard): improve responsive layout
refactor(parser): extract metadata parsing logic
test(sync): add integration tests for conflict resolution
chore(deps): update Go dependencies
```plaintext
**Types autorisés :**
- `feat`: Nouvelle fonctionnalité
- `fix`: Correction de bug
- `docs`: Documentation
- `style`: Formatage, pas de changement de code
- `refactor`: Refactoring sans changement fonctionnel
- `test`: Ajout ou modification de tests
- `chore`: Maintenance, dépendances

### 2. Workflow de Développement

#### Branches

```bash
main              # Production stable

develop          # Intégration des features

feature/*        # Nouvelles fonctionnalités

fix/*           # Corrections de bugs

hotfix/*        # Corrections urgentes production

release/*       # Préparation des releases

```plaintext
#### Processus Feature

```powershell
# 1. Créer feature branch

git checkout develop
git pull upstream develop
git checkout -b feature/bidirectional-sync

# 2. Développer avec commits atomiques

git add .
git commit -m "feat(sync): implement basic bidirectional logic"

# 3. Tenir à jour avec develop

git fetch upstream
git rebase upstream/develop

# 4. Push et créer PR

git push origin feature/bidirectional-sync
# Créer Pull Request sur GitHub

```plaintext
### 3. Pull Requests

#### Template PR

```markdown
## Description

Brief description of changes

## Type of Change

- [ ] Bug fix
- [ ] New feature  
- [ ] Breaking change
- [ ] Documentation update

## Testing

- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

## Checklist

- [ ] Code follows style guidelines
- [ ] Self-review completed
- [ ] Documentation updated
- [ ] No merge conflicts
```plaintext
#### Review Requirements

- **Minimum reviewers :** 2
- **Required reviews :** Lead developer + domain expert
- **Auto-merge conditions :**
  - All tests pass
  - All requested changes addressed
  - No merge conflicts

## Tests et Qualité

### 1. Pyramide de Tests

```plaintext
    ┌──────────────┐
    │ E2E Tests    │  10%
    │ (Selenium)   │
    ├──────────────┤
    │ Integration  │  20%
    │ Tests        │
    ├──────────────┤
    │ Unit Tests   │  70%
    └──────────────┘
```plaintext
### 2. Commandes de Test

```powershell
# Tests unitaires

go test ./... -short

# Tests d'intégration

go test ./... -tags=integration

# Tests E2E

go test ./tests/e2e/... -tags=e2e

# Tous les tests

go test ./... -tags="integration,e2e"

# Tests avec coverage

go test ./... -coverprofile=coverage.out

# Tests de performance

go test ./... -bench=. -benchmem
```plaintext
### 3. Mocking Strategy

```go
//go:generate mockgen -source=interfaces.go -destination=mocks/mock_interfaces.go

// Générer tous les mocks
go generate ./...

// Utilisation dans les tests
func TestService(t *testing.T) {
    ctrl := gomock.NewController(t)
    defer ctrl.Finish()
    
    mockRepo := mocks.NewMockRepository(ctrl)
    service := NewService(mockRepo)
    
    // Test logic
}
```plaintext
## Documentation

### 1. Documentation API

```go
// UpdatePlan updates an existing plan with new content
// @Summary Update plan
// @Description Update an existing plan with new content and metadata
// @Tags plans
// @Accept json
// @Produce json
// @Param id path string true "Plan ID"
// @Param plan body UpdatePlanRequest true "Plan data"
// @Success 200 {object} Plan
// @Failure 400 {object} ErrorResponse
// @Failure 404 {object} ErrorResponse
// @Router /api/v1/plans/{id} [put]
func (h *PlanHandler) UpdatePlan(c *gin.Context) {
    // Implementation
}
```plaintext
### 2. README Updates

Lors d'ajout de fonctionnalités, mettre à jour :
- `README.md` principal
- `docs/` spécifiques
- Exemples de code
- Changelog

### 3. Architecture Decision Records (ADR)

```markdown
# ADR-001: Choice of QDrant for Vector Database

## Status

Accepted

## Context

Need vector database for semantic search in plans...

## Decision

Use QDrant for vector storage and similarity search

## Consequences

- Pros: Fast semantic search, good Go SDK
- Cons: Additional dependency, learning curve
```plaintext
## Débogage et Profiling

### 1. Logging Levels

```go
// Utiliser structured logging
log.WithFields(logrus.Fields{
    "plan_id": planID,
    "operation": "sync",
    "duration": duration,
}).Info("Sync completed successfully")

// Debug pour développement
log.Debug("Starting validation process", 
    "validator", validator.Name(),
    "rules_count", len(rules))
```plaintext
### 2. Profiling Performance

```powershell
# CPU profiling

go test -cpuprofile=cpu.prof -bench=.

# Memory profiling  

go test -memprofile=mem.prof -bench=.

# Analyser profiles

go tool pprof cpu.prof
go tool pprof mem.prof
```plaintext
### 3. Débogage avec Delve

```powershell
# Installer delve

go install github.com/go-delve/delve/cmd/dlv@latest

# Debug tests

dlv test -- -test.run TestSpecificFunction

# Debug application

dlv debug cmd/server/main.go
```plaintext
## Support et Escalade

### Channels de Communication

- **Questions générales :** [GitHub Discussions](https://github.com/planning-ecosystem/sync/discussions)
- **Bugs :** [GitHub Issues](https://github.com/planning-ecosystem/sync/issues)
- **Chat développeurs :** [Discord #dev-channel](https://discord.gg/planning-sync-dev)

- **Reviews :** [GitHub Pull Requests](https://github.com/planning-ecosystem/sync/pulls)

### Contacts

- **Lead Developer :** dev-lead@planning-ecosystem.com
- **Architecture :** architecture@planning-ecosystem.com
- **DevOps :** devops@planning-ecosystem.com

### Resources

- **Wiki interne :** [Development Wiki](https://wiki.planning-ecosystem.com/dev)
- **Coding Standards :** [Style Guide](https://github.com/planning-ecosystem/sync/wiki/style-guide)
- **API Docs :** [OpenAPI Spec](https://api.planning-ecosystem.com/docs)

## Reconnaissance

### Contributors

Nous reconnaissons toutes les contributions via :
- [All Contributors](https://allcontributors.org/) dans le README
- Monthly contributor highlights
- Annual contributor awards

### Code of Conduct

Ce projet adhère au [Contributor Covenant](https://www.contributor-covenant.org/). En participant, vous vous engagez à respecter ce code de conduite.
