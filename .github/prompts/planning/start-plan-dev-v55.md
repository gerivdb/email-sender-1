# Implementation Starter Prompt for Plan-dev-v55

## Quick Start Command

Copy and paste this prompt to begin implementing plan-dev-v55:

---

## Implementation Request

I need to implement **plan-dev-v55 Planning Ecosystem Synchronization** following the methodical workflow approach.

### Context

- **Plan Document**: `d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\projet\roadmaps\plans\consolidated\plan-dev-v55-planning-ecosystem-sync.md`
- **Workflow Guide**: `.github\prompts\planning\methodical-implementation-workflow.md`
- **Implementation Prompt**: `.github\prompts\planning\implement-plan-dev-v55.md`

### Current Request

Please begin with **Phase 1: Core Synchronization Foundation** implementation:

1. **Set up the Git workflow**:
   - Switch to or create branch: `planning-ecosystem-sync`
   - Set up proper branch tracking

2. **Create the directory structure** as specified in the plan:
   ```
   planning-ecosystem-sync/
   ├── tools/sync-core/
   ├── tools/task-manager/
   ├── tools/config-validator/
   ├── tools/migration-assistant/
   ├── config/sync-mappings/
   ├── config/validation-rules/
   ├── config/templates/
   ├── scripts/powershell/
   ├── scripts/automation/
   ├── tests/unit/
   ├── tests/integration/
   ├── tests/performance/
   ├── web/dashboard/
   ├── web/api/
   ├── docs/user-guides/
   ├── docs/technical/
   └── docs/api-reference/
   ```

3. **Implement Task 1.1: Core Sync Engine**:
   - Create `tools/sync-core/engine.go` with SyncEngine struct
   - Implement ToolkitOperation v3.0.0 interface (String(), GetDescription(), Stop())
   - Add configuration loading and validation
   - Create sync pipeline with error handling

4. **Implement Task 1.2: Data Models**:
   - Create `tools/sync-core/models.go` with shared structures
   - Implement Task, Project, Roadmap, and Sync structs
   - Add JSON/YAML serialization support
   - Include validation tags and helper methods

5. **Implement Task 1.3: Configuration System**:
   - Create `config/sync-mappings/default.yaml`
   - Implement field mapping configurations
   - Add source/target system definitions
   - Create validation schemas

6. **Create Go modules**:
   - Set up `go.mod` files for each tool component
   - Configure proper dependency management
   - Ensure ToolkitOperation compliance

7. **Add initial tests**:
   - Unit tests for core engine functionality
   - Configuration validation tests
   - Data model serialization tests

Please follow the exact specifications from the plan document and implement all code examples as shown. Use the methodical workflow approach with proper Git commits and progress tracking.

---

## Alternative Focused Requests

If you prefer to start with a specific component, use these targeted prompts:

### Just the Core Engine

```plaintext
Please implement just the Core Sync Engine (Task 1.1) from plan-dev-v55:
- Create the branch and directory structure
- Implement `tools/sync-core/engine.go` with full functionality
- Add proper ToolkitOperation compliance
- Include comprehensive error handling and logging
```plaintext
### Just the Data Models

```plaintext
Please implement just the Data Models (Task 1.2) from plan-dev-v55:
- Create `tools/sync-core/models.go` with all structs
- Implement JSON/YAML serialization
- Add validation tags and helper methods
- Include unit tests for all models
```plaintext
### Just the Configuration System

```plaintext
Please implement just the Configuration System (Task 1.3) from plan-dev-v55:
- Create configuration files and schemas
- Implement validation logic
- Add template system
- Include configuration loading tests
```plaintext
## Progress Tracking

After implementation, please update the plan document with:
- [x] Completed tasks marked as done
- Progress percentages updated
- Any issues or deviations noted
- Next steps clearly identified

## Quality Requirements

Ensure all implementations include:
- ✅ ToolkitOperation v3.0.0 compliance
- ✅ Comprehensive error handling
- ✅ Proper logging integration
- ✅ Unit test coverage >95%
- ✅ Clear documentation
- ✅ Configuration validation
- ✅ Performance optimization

---

**Ready to start**: Copy the main "Implementation Request" section above to begin the systematic implementation of plan-dev-v55.