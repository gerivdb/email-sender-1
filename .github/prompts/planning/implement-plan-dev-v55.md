# Plan-dev-v55 Planning Ecosystem Synchronization Implementation Prompt

## Context

This prompt is designed to guide the implementation of plan-dev-v55 Planning Ecosystem Synchronization, a comprehensive 8-phase project that creates a unified planning ecosystem with synchronized task management, roadmap integration, and intelligent monitoring.

## Plan Reference

**Plan Document**: `d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\projet\roadmaps\plans\consolidated\plan-dev-v55-planning-ecosystem-sync.md`

## Implementation Strategy

### Phase-by-Phase Implementation Approach

Execute each phase sequentially, ensuring completion before moving to the next:

1. **Phase 1: Core Synchronization Foundation**
2. **Phase 2: Task Management Integration**
3. **Phase 3: Configuration Validation System**
4. **Phase 4: Migration Assistant**
5. **Phase 5: Roadmap Manager Integration**
6. **Phase 6: Interface & Monitoring**
7. **Phase 7: Testing & Validation**
8. **Phase 8: Deployment & Documentation**

### Git Workflow Requirements

#### Branch Strategy

- **Main branch**: `planning-ecosystem-sync`
- **Feature branches**: `feature/phase-{n}-{component}`
- **Hotfix branches**: `hotfix/planning-sync-{issue}`

#### Commit Standards

```plaintext
feat(phase-{n}): implement {component} for {micro-task}

- Add {specific functionality}
- Integrate with {system/component}
- Include {tests/documentation}

Refs: plan-dev-v55, Phase {n}, Task {x}.{y}
```plaintext
## Implementation Instructions

### Step 1: Environment Setup

```plaintext
Please implement Phase 1 of plan-dev-v55 Planning Ecosystem Synchronization:

1. **Create the branch structure**:
   - Switch to or create branch: `planning-ecosystem-sync`
   - Ensure proper upstream tracking

2. **Set up the directory structure**:
   ```
   planning-ecosystem-sync/
   ├── tools/
   │   ├── sync-core/
   │   ├── task-manager/
   │   ├── config-validator/
   │   └── migration-assistant/
   ├── config/
   │   ├── sync-mappings/
   │   ├── validation-rules/
   │   └── templates/
   ├── scripts/
   │   ├── powershell/
   │   └── automation/
   ├── tests/
   │   ├── unit/
   │   ├── integration/
   │   └── performance/
   ├── web/
   │   ├── dashboard/
   │   └── api/
   └── docs/
       ├── user-guides/
       ├── technical/
       └── api-reference/
   ```

3. **Initialize core Go modules**:
   - Create `go.mod` files for each tool component
   - Set up proper dependency management
   - Ensure ToolkitOperation v3.0.0 compliance
```plaintext
### Step 2: Core Implementation Loop

For each phase, follow this pattern:

```plaintext
I need to implement Phase {N} of plan-dev-v55. Please:

1. **Read the phase details** from the plan document
2. **Create all required files** as specified in the micro-tasks
3. **Implement the Go code** with proper ToolkitOperation compliance
4. **Add configuration files** and templates
5. **Create PowerShell scripts** for administration
6. **Write comprehensive tests** (unit, integration, performance)
7. **Update documentation** and user guides
8. **Commit changes** with proper Git workflow

Focus on {specific micro-task} from Phase {N}, Task {X}.{Y}
```plaintext
### Step 3: Quality Assurance Loop

After each phase implementation:

```plaintext
Please validate the implementation of Phase {N}:

1. **Run all tests** and ensure they pass
2. **Check code quality** with linting and formatting
3. **Verify integration points** with other phases
4. **Test configuration validation** and error handling
5. **Update progress tracking** in the plan document
6. **Document any issues** or deviations from the plan
```plaintext
## Specific Implementation Requests

### Phase 1: Core Synchronization Foundation

```plaintext
Implement Phase 1 of plan-dev-v55:

1. **Task 1.1: Core Sync Engine**
   - Create `tools/sync-core/engine.go` with SyncEngine struct
   - Implement ToolkitOperation interface (String, GetDescription, Stop)
   - Add configuration loading and validation
   - Create sync pipeline with proper error handling

2. **Task 1.2: Data Models**
   - Create shared data structures in `tools/sync-core/models.go`
   - Implement Task, Project, Roadmap, and Sync structs
   - Add JSON/YAML serialization support
   - Include validation tags and helper methods

3. **Task 1.3: Configuration System**
   - Create `config/sync-mappings/default.yaml`
   - Implement field mapping configurations
   - Add source/target system definitions
   - Create validation schemas

Please ensure all code follows the patterns shown in the plan document.
```plaintext
### Phase 2: Task Management Integration

```plaintext
Implement Phase 2 of plan-dev-v55:

1. **Task 2.1: TaskMaster-CLI Integration**
   - Create `tools/task-manager/taskmaster.go`
   - Implement TaskMasterConnector with CLI automation
   - Add task creation, updating, and status tracking
   - Include error handling and retry logic

2. **Task 2.2: Bidirectional Sync**
   - Implement sync conflict resolution
   - Add change detection and delta processing
   - Create sync scheduling and triggers
   - Include audit logging and history tracking

Continue with all micro-tasks as specified in the plan.
```plaintext
## Progress Tracking

### Implementation Checklist Template

Use this template to track progress:

```markdown
## Phase {N} Implementation Progress

### Micro-tasks Completed:

- [ ] Task {N}.1: {Name} - {Description}
- [ ] Task {N}.2: {Name} - {Description}
- [ ] Task {N}.3: {Name} - {Description}

### Files Created:

- [ ] `{file-path}` - {purpose}
- [ ] `{file-path}` - {purpose}

### Tests Added:

- [ ] Unit tests for {component}
- [ ] Integration tests for {feature}
- [ ] Performance benchmarks

### Documentation Updated:

- [ ] User guide for {feature}
- [ ] Technical documentation
- [ ] API reference

### Quality Checks:

- [ ] All tests passing
- [ ] Code linting clean
- [ ] Performance benchmarks met
- [ ] Integration points verified
```plaintext
## Success Criteria

### Phase Completion Requirements

Each phase is considered complete when:

1. **All micro-tasks implemented** with working code
2. **Tests passing** at >95% coverage
3. **Documentation updated** and accurate
4. **Integration verified** with existing systems
5. **Performance benchmarks met** as specified
6. **Code quality standards** maintained
7. **Git workflow followed** with proper commits

### Overall Project Success

The project is successful when:

1. **All 8 phases completed** with full functionality
2. **Synchronization working** between all systems
3. **Performance targets met** (sub-second sync, <100MB memory)
4. **User acceptance achieved** with intuitive interfaces
5. **Monitoring operational** with real-time insights
6. **Documentation complete** for users and developers

## Common Implementation Patterns

### Go Code Structure

```go
type {Component}Tool struct {
    config *{Component}Config
    logger *log.Logger
    // ... other fields
}

func (t *{Component}Tool) String() string {
    return "{Component} Tool v1.0.0"
}

func (t *{Component}Tool) GetDescription() string {
    return "{Description of tool functionality}"
}

func (t *{Component}Tool) Stop() error {
    // Cleanup logic
    return nil
}
```plaintext
### Configuration Pattern

```yaml
{component}:
  enabled: true
  settings:
    # Component-specific settings

  mappings:
    # Field mappings

  validation:
    # Validation rules

```plaintext
### PowerShell Script Pattern

```powershell
# {Script-Name}.ps1

# Purpose: {Description}

param(
    [Parameter(Mandatory=$true)]
    [string]$TargetPath,
    # Other parameters

)

# Implementation with proper error handling

```plaintext
## Usage Instructions

### Starting Implementation

1. Copy this prompt to a new conversation
2. Reference the plan document location
3. Request specific phase implementation
4. Follow the Git workflow requirements
5. Track progress using the checklist template

### Continuing Implementation

1. Check current branch status
2. Review completed phases
3. Request next phase implementation
4. Validate integration points
5. Update documentation and tests

### Troubleshooting

- Always reference the plan document for specifications
- Follow the established patterns and conventions
- Ensure proper error handling and logging
- Validate against ToolkitOperation compliance
- Test integration points thoroughly

---

**Note**: This prompt is designed to be used with an AI assistant that has access to file system operations, Git commands, and can read/write code files. Ensure proper workspace setup before beginning implementation.