# Git Configuration for Planning Ecosystem Sync

## Branch Protection Rules

### planning-ecosystem-sync (Main Branch)
- **Require pull request reviews**: 1 reviewer minimum
- **Dismiss stale reviews**: Enabled
- **Require status checks**: All tests must pass
- **Require branches to be up to date**: Enabled
- **Restrict pushes**: Only maintainers can push directly

### Feature Branches Pattern
- `feature/phase-{n}-{component}`: Development features
- `hotfix/planning-sync-{issue}`: Critical fixes
- `experimental/sync-{feature}`: Experimental features

## Commit Standards

### Commit Message Format
```
type(scope): brief description

- Detailed description of changes
- Include relevant context and reasoning
- Reference issues and pull requests

Refs: plan-dev-v55, Phase {n}, Task {x}.{y}
Co-authored-by: Team Member <email@example.com>
```

### Commit Types
- `feat`: New features and implementations
- `fix`: Bug fixes and corrections
- `docs`: Documentation updates
- `test`: Test additions and modifications
- `refactor`: Code refactoring without feature changes
- `style`: Code style and formatting changes
- `ci`: CI/CD pipeline changes

### Scope Examples
- `phase-1`: Phase 1 related changes
- `sync-core`: Core synchronization engine
- `config`: Configuration changes
- `validation`: Validation system changes

## Workflow Configuration

### Pre-commit Hooks
```bash
#!/bin/sh
# .git/hooks/pre-commit

# Run Go formatting
gofmt -w .

# Run linting
golangci-lint run

# Run unit tests
go test ./tests/unit/... -short

# Check for sensitive data
git diff --cached --name-only | xargs grep -l "password\|secret\|key" && {
    echo "⚠️  Potential sensitive data detected in commit"
    exit 1
}
```

### Automated Testing Pipeline
```yaml
# .github/workflows/planning-sync-ci.yml
name: Planning Ecosystem Sync CI

on:
  push:
    branches: [ planning-ecosystem-sync ]
  pull_request:
    branches: [ planning-ecosystem-sync ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:13
        env:
          POSTGRES_DB: plans_db
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Set up Go
      uses: actions/setup-go@v3
      with:
        go-version: 1.21
    
    - name: Install dependencies
      run: go mod download
    
    - name: Run linting
      run: golangci-lint run
    
    - name: Run unit tests
      run: go test ./tests/unit/... -v
    
    - name: Run integration tests
      run: go test ./tests/integration/... -v
      env:
        DATABASE_URL: postgresql://postgres:postgres@localhost/plans_db
```

## Security Guidelines

### Access Control
- **Repository Access**: Team members only
- **Branch Protection**: Enforce on main branches
- **Secret Management**: Use environment variables
- **Code Review**: Mandatory for all changes

### Sensitive Data Prevention
- **API Keys**: Store in environment variables only
- **Database Credentials**: Never commit to repository
- **Configuration Secrets**: Use external secret management
- **Local Testing**: Use .env files (gitignored)

## Development Workflow

### 1. Feature Development
```bash
# Create feature branch
git checkout -b feature/phase-1-sync-engine

# Make changes and commit
git add .
git commit -m "feat(phase-1): implement core sync engine

- Add SyncEngine struct with ToolkitOperation compliance
- Implement configuration loading and validation
- Add error handling and logging

Refs: plan-dev-v55, Phase 1, Task 1.1"

# Push and create PR
git push origin feature/phase-1-sync-engine
```

### 2. Code Review Process
1. **Self Review**: Check code quality and tests
2. **Automated Checks**: CI/CD pipeline validation
3. **Peer Review**: Team member review and approval
4. **Integration Testing**: Full system validation
5. **Merge**: Squash and merge to main branch

### 3. Release Management
```bash
# Tag releases for major milestones
git tag -a v1.0.0-phase1 -m "Phase 1: Core Infrastructure Complete"
git push origin v1.0.0-phase1
```

## Quality Gates

### Code Quality Standards
- **Test Coverage**: Minimum 95%
- **Linting**: Zero warnings or errors
- **Documentation**: All public APIs documented
- **Performance**: Benchmarks within target ranges

### Security Checks
- **Dependency Scanning**: Automated vulnerability checks
- **Secret Detection**: Pre-commit and CI validation
- **Code Analysis**: Static analysis for security issues
- **Access Review**: Regular permission audits

---

**Note**: This configuration ensures code quality, security, and proper collaboration workflows for the Planning Ecosystem Synchronization project.
