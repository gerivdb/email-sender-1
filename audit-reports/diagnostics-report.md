# Rapport d’audit automatisé
## Diagnostics Go (golangci-lint)
```
>>> golangci-lint run ./...
level=warning msg="[linters_context] copyloopvar: this linter is disabled because the Go version (1.20) of your project is lower than Go 1.22"
level=error msg="[linters_context] typechecking error: d:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1\\development\\managers\\smart-variable-manager\\interfaces\\smart_variable_manager.go:7:1: missing import path"
level=error msg="[linters_context] typechecking error: d:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1\\development\\managers\\smart-variable-manager\\interfaces\\smart_variable_manager.go:8:1: missing import path"
level=error msg="[linters_context] typechecking error: d:\\DO\\WEB\\N8N_tests\\PROJETS\\EMAIL_SENDER_1\\development\\managers\\smart-variable-manager\\interfaces\\smart_variable_manager.go:11:1: missing import path"
level=warning msg="[linters_context] intrange: this linter is disabled because the Go version (1.20) of your project is lower than Go 1.22"
development\managers\smart-variable-manager\interfaces\smart_variable_manager.go:7:1: missing import path (typecheck)
<<<<<<< HEAD
^
1 issues:
* typecheck: 1
Erreur d'exécution : exit status 1

```
## Diagnostics Go Vet
```
>>> go vet ./...
main.go:10:2: no required module provides package github.com/gin-gonic/gin; to add it:
	go get github.com/gin-gonic/gin
found packages main (auth_bench_test.go) and docmodule (doc_example.go) in d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1
cmd\backup-qdrant\backup_qdrant.go:7:2: no required module provides package github.com/qdrant/go-client/qdrant; to add it:
	go get github.com/qdrant/go-client/qdrant
cmd\cli\cli.go:9:2: no required module provides package github.com/spf13/cobra; to add it:
	go get github.com/spf13/cobra
cmd\cli\cli.go:10:2: no required module provides package go.uber.org/zap; to add it:
	go get go.uber.org/zap
cmd\configapi\configapi.go:7:2: no required module provides package github.com/gerivdb/email-sender-1/core/config; to add it:
	go get github.com/gerivdb/email-sender-1/core/config
cmd\debug_cache\debug_cache.go:7:2: no required module provides package github.com/gerivdb/email-sender-1/src/providers; to add it:
	go get github.com/gerivdb/email-sender-1/src/providers
cmd\email-server\email_server.go:5:2: no required module provides package github.com/gerivdb/email-sender-1/pkg/email; to add it:
	go get github.com/gerivdb/email-sender-1/pkg/email
cmd\email-server\email_server.go:16:2: no required module provides package github.com/gorilla/mux; to add it:
	go get github.com/gorilla/mux
cmd\email-server\email_server.go:17:2: no required module provides package github.com/prometheus/client_golang/prometheus/promhttp; to add it:
	go get github.com/prometheus/client_golang/prometheus/promhttp
cmd\email-server\email_server.go:18:2: no required module provides package github.com/redis/go-redis/v9; to add it:
	go get github.com/redis/go-redis/v9
cmd\event-listener-service\main.go:11:2: package email_sender/eventbus is not in std (C:\Program Files\Go\src\email_sender\eventbus)
cmd\gateway-manager-cli\main.go:7:2: no required module provides package github.com/gerivdb/email-sender-1/development/managers/gateway-manager; to add it:
	go get github.com/gerivdb/email-sender-1/development/managers/gateway-manager
cmd\go\dependency-manager\auditor\audit_modules.go:11:2: no required module provides package github.com/gerivdb/email-sender-1/cmd/go/dependency-manager/utils; to add it:
	go get github.com/gerivdb/email-sender-1/cmd/go/dependency-manager/utils
cmd\go\extractionparser\extractionparser.go:10:2: no required module provides package github.com/gerivdb/email-sender-1/core/extraction; to add it:
	go get github.com/gerivdb/email-sender-1/core/extraction
cmd\go\extractionparser\extractionparser.go:12:2: no required module provides package github.com/gerivdb/email-sender-1/core/ports; to add it:
	go get github.com/gerivdb/email-sender-1/core/ports
cmd\go\graphgenerator\graphgenerator.go:10:2: no required module provides package github.com/gerivdb/email-sender-1/core/graphgen; to add it:
	go get github.com/gerivdb/email-sender-1/core/graphgen
found packages roadmap_orchestrator (roadmap_orchestrator.go) and main (roadmap_orchestrator_test.go) in d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\cmd\go\roadmap-orchestrator
cmd\hub-central\test.go:1:1: expected 'package', found 'EOF'
cmd\infrastructure-api-server\infrastructure_api_server.go:13:2: no required module provides package github.com/gerivdb/email-sender-1/internal/api; to add it:
	go get github.com/gerivdb/email-sender-1/internal/api
cmd\infrastructure-api-server\infrastructure_api_server.go:14:2: no required module provides package github.com/gerivdb/email-sender-1/internal/infrastructure; to add it:
	go get github.com/gerivdb/email-sender-1/internal/infrastructure
cmd\integration_test_v49\integration_test_v49.go:9:2: package EMAIL_SENDER_1/tools/core/toolkit is not in std (C:\Program Files\Go\src\EMAIL_SENDER_1\tools\core\toolkit)
cmd\migrate-embeddings\migrate_embeddings.go:11:2: no required module provides package github.com/prometheus/client_golang/prometheus; to add it:
	go get github.com/prometheus/client_golang/prometheus
cmd\migrate-embeddings\migrate_embeddings.go:12:2: no required module provides package github.com/prometheus/client_golang/prometheus/promauto; to add it:
	go get github.com/prometheus/client_golang/prometheus/promauto
cmd\needs\needs.go:4:2: package core/reporting is not in std (C:\Program Files\Go\src\core\reporting)
cmd\performance-test-gateway\main.go:13:2: no required module provides package github.com/gerivdb/email-sender-1/internal/core; to add it:
	go get github.com/gerivdb/email-sender-1/internal/core
cmd\phase8\final_validation.go:7:2: no required module provides package github.com/gerivdb/email-sender-1/development/managers/dependencymanager; to add it:
	go get github.com/gerivdb/email-sender-1/development/managers/dependencymanager
cmd\phase8\final_validation.go:8:2: no required module provides package github.com/gerivdb/email-sender-1/development/managers/security-manager; to add it:
	go get github.com/gerivdb/email-sender-1/development/managers/security-manager
cmd\phase8\final_validation.go:9:2: no required module provides package github.com/gerivdb/email-sender-1/development/managers/storage-manager; to add it:
	go get github.com/gerivdb/email-sender-1/development/managers/storage-manager
cmd\qdrant-demo\qdrant_demo.go:8:2: no required module provides package github.com/gerivdb/email-sender-1/src/qdrant; to add it:
	go get github.com/gerivdb/email-sender-1/src/qdrant
cmd\redis-demo\redis_demo.go:10:2: no required module provides package github.com/gerivdb/email-sender-1/streaming/redis_streaming; to add it:
	go get github.com/gerivdb/email-sender-1/streaming/redis_streaming
cmd\redis-fallback-test\redis_fallback_test.go:1:1: expected 'package', found '<<'
cmd\redis-test\redis_test.go:1:1: expected 'package', found '<<'
cmd\scanmodules\scanmodules.go:7:2: package EMAIL_SENDER_1/scripts is not in std (C:\Program Files\Go\src\EMAIL_SENDER_1\scripts)
found packages main (main.go) and scanmodules (scanmodules.go) in d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\cmd\scanmodules
cmd\server\server.go:1:1: expected 'package', found '<<'
cmd\test_compile\test_compile.go:7:2: package EMAIL_SENDER_1/tools/pkg/manager is not in std (C:\Program Files\Go\src\EMAIL_SENDER_1\tools\pkg\manager)
cmd\test_imports\test_imports.go:7:2: package EMAIL_SENDER_1/tools/operations/validation is not in std (C:\Program Files\Go\src\EMAIL_SENDER_1\tools\operations\validation)
cmd\testgen\testgen.go:1:1: expected 'package', found '<<'
cmd\validate_components\validate_components.go:8:2: no required module provides package github.com/gerivdb/email-sender-1/tools; to add it:
	go get github.com/gerivdb/email-sender-1/tools
found packages main (main.go) and validatecomponents (validate_components.go) in d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\cmd\validate_components
cmd\vscode-diagnostic\vscode_diagnostic.go:11:2: package vscode-diagnostic-cli/config is not in std (C:\Program Files\Go\src\vscode-diagnostic-cli\config)
core\config\validate.go:6:2: no required module provides package github.com/xeipuuv/gojsonschema; to add it:
	go get github.com/xeipuuv/gojsonschema
core\config\config.go:7:2: no required module provides package gopkg.in/yaml.v2; to add it:
	go get gopkg.in/yaml.v2
core\conflict\realtime_detector.go:6:2: no required module provides package github.com/fsnotify/fsnotify; to add it:
	go get github.com/fsnotify/fsnotify
demo\ttl-demo-simple.go:10:2: package email_sender/pkg/cache/ttl is not in std (C:\Program Files\Go\src\email_sender\pkg\cache\ttl)
development\api\cache_manager_api.go:11:2: no required module provides package github.com/gerivdb/email-sender-1/development/managers/cache-manager; to add it:
	go get github.com/gerivdb/email-sender-1/development/managers/cache-manager
development\hooks\commit-interceptor\advanced_classifier.go:15:2: no required module provides package github.com/gerivdb/email-sender-1/development/hooks/commit-interceptor/analyzer; to add it:
	go get github.com/gerivdb/email-sender-1/development/hooks/commit-interceptor/analyzer
development\hooks\commit-interceptor\advanced_classifier.go:16:2: no required module provides package github.com/gerivdb/email-sender-1/development/hooks/commit-interceptor/commitinterceptortypes; to add it:
	go get github.com/gerivdb/email-sender-1/development/hooks/commit-interceptor/commitinterceptortypes
development\hooks\commit-interceptor\advanced_classifier_test.go:13:1: missing import path
development\hooks\commit-interceptor\main\advanced_classifier_test_main.go:13:2: no required module provides package github.com/gerivdb/email-sender-1/development/hooks/commit-interceptor; to add it:
	go get github.com/gerivdb/email-sender-1/development/hooks/commit-interceptor
development\hooks\commit-interceptor\main\advanced_classifier_test_main.go:10:2: no required module provides package github.com/stretchr/testify/assert; to add it:
	go get github.com/stretchr/testify/assert
development\hooks\commit-interceptor\main\advanced_classifier_test_main.go:11:2: no required module provides package github.com/stretchr/testify/require; to add it:
	go get github.com/stretchr/testify/require
development\managers\test_import_management_integration.go:9:2: "D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/development/managers/interfaces" is not a package path; see 'go help packages'
development\managers\final_validation.go:8:2: no required module provides package github.com/gerivdb/email-sender-1/development/managers/dependency-manager; to add it:
	go get github.com/gerivdb/email-sender-1/development/managers/dependency-manager
found packages managers (audit_stack_phase_1_1_2.go) and main (phase_8_final_validation.go) in d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\managers
development\managers\advanced-autonomy-manager\main_simple.go:14:2: package advanced-autonomy-manager/interfaces is not in std (C:\Program Files\Go\src\advanced-autonomy-manager\interfaces)
development\managers\advanced-autonomy-manager\main_simple.go:15:2: package advanced-autonomy-manager/internal/config is not in std (C:\Program Files\Go\src\advanced-autonomy-manager\internal\config)
development\managers\advanced-autonomy-manager\main_simple.go:16:2: package advanced-autonomy-manager/internal/discovery is not in std (C:\Program Files\Go\src\advanced-autonomy-manager\internal\discovery)
development\managers\advanced-autonomy-manager\advanced_autonomy_manager.go:11:2: no required module provides package github.com/gerivdb/email-sender-1/development/managers/advanced-autonomy-manager/interfaces; to add it:
	go get github.com/gerivdb/email-sender-1/development/managers/advanced-autonomy-manager/interfaces
development\managers\advanced-autonomy-manager\advanced_autonomy_manager.go:12:2: no required module provides package github.com/gerivdb/email-sender-1/development/managers/advanced-autonomy-manager/internal/coordination; to add it:
	go get github.com/gerivdb/email-sender-1/development/managers/advanced-autonomy-manager/internal/coordination
development\managers\advanced-autonomy-manager\advanced_autonomy_manager.go:13:2: no required module provides package github.com/gerivdb/email-sender-1/development/managers/advanced-autonomy-manager/internal/decision; to add it:
	go get github.com/gerivdb/email-sender-1/development/managers/advanced-autonomy-manager/internal/decision
development\managers\advanced-autonomy-manager\advanced_autonomy_manager.go:14:2: no required module provides package github.com/gerivdb/email-sender-1/development/managers/advanced-autonomy-manager/internal/discovery; to add it:
	go get github.com/gerivdb/email-sender-1/development/managers/advanced-autonomy-manager/internal/discovery
development\managers\advanced-autonomy-manager\advanced_autonomy_manager.go:15:2: no required module provides package github.com/gerivdb/email-sender-1/development/managers/advanced-autonomy-manager/internal/healing; to add it:
	go get github.com/gerivdb/email-sender-1/development/managers/advanced-autonomy-manager/internal/healing
development\managers\advanced-autonomy-manager\advanced_autonomy_manager.go:16:2: no required module provides package github.com/gerivdb/email-sender-1/development/managers/advanced-autonomy-manager/internal/monitoring; to add it:
	go get github.com/gerivdb/email-sender-1/development/managers/advanced-autonomy-manager/internal/monitoring
development\managers\advanced-autonomy-manager\advanced_autonomy_manager.go:17:2: no required module provides package github.com/gerivdb/email-sender-1/development/managers/advanced-autonomy-manager/internal/predictive; to add it:
	go get github.com/gerivdb/email-sender-1/development/managers/advanced-autonomy-manager/internal/predictive
development\managers\advanced-autonomy-manager\freeze_fix_core_test.go:1:1: expected 'package', found 'EOF'
development\managers\advanced-autonomy-manager\cmd\main.go:13:2: package advanced-autonomy-manager is not in std (C:\Program Files\Go\src\advanced-autonomy-manager)
development\managers\advanced-autonomy-manager\internal\discovery\infrastructure_discovery.go:15:2: package EMAIL_SENDER_1/development/managers/advanced-autonomy-manager/internal/config is not in std (C:\Program Files\Go\src\EMAIL_SENDER_1\development\managers\advanced-autonomy-manager\internal\config)
development\managers\advanced-autonomy-manager\internal\discovery\infrastructure_discovery.go:16:2: package EMAIL_SENDER_1/development/managers/advanced-autonomy-manager/internal/logging is not in std (C:\Program Files\Go\src\EMAIL_SENDER_1\development\managers\advanced-autonomy-manager\internal\logging)
development\managers\advanced-autonomy-manager\internal\monitoring\manager_collector.go:1:1: expected 'package', found n
found packages advanced_autonomy_manager (simple_freeze_fix.go) and validation (validate_arch.go) in d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\development\managers\advanced-autonomy-manager\validation
development\managers\ai-template-manager\ai_template_manager.go:14:1: missing import path
development\managers\ai-template-manager\interfaces\ai_template_manager.go:6:1: missing import path
development\managers\ai-template-manager\internal\ai\pattern_processor.go:11:1: missing import path
development\managers\api-gateway\gateway.go:13:2: no required module provides package github.com/swaggo/files; to add it:
	go get github.com/swaggo/files
development\managers\api-gateway\gateway.go:14:2: no required module provides package github.com/swaggo/gin-swagger; to add it:
	go get github.com/swaggo/gin-swagger
development\managers\api-gateway\gateway.go:16:2: no required module provides package golang.org/x/time/rate; to add it:
	go get golang.org/x/time/rate
development\managers\branching-manager\demo-complete-8-levels.go:7:2: package EMAIL_SENDER_1/development/managers/branching-manager/interfaces is not in std (C:\Program Files\Go\src\EMAIL_SENDER_1\development\managers\branching-manager\interfaces)
development\managers\branching-manager\handlers.go:1:1: expected 'package', found 'EOF'
development\managers\branching-manager\ai\predictor.go:11:2: no required module provides package github.com/gerivdb/email-sender-1/development/managers/branching-manager/interfaces; to add it:
	go get github.com/gerivdb/email-sender-1/development/managers/branching-manager/interfaces
development\managers\branching-manager\cmd\main.go:11:2: package EMAIL_SENDER_1/development/managers/branching-manager/development is not in std (C:\Program Files\Go\src\EMAIL_SENDER_1\development\managers\branching-manager\development)
development\managers\branching-manager\database\postgresql_storage.go:9:2: no required module provides package github.com/google/uuid; to add it:
	go get github.com/google/uuid
development\managers\branching-manager\database\postgresql_storage.go:10:2: no required module provides package github.com/lib/pq; to add it:
	go get github.com/lib/pq
development\managers\branching-manager\demo\demo_complete_system.go:9:2: package EMAIL_SENDER_1/development/managers/branching-manager/ai is not in std (C:\Program Files\Go\src\EMAIL_SENDER_1\development\managers\branching-manager\ai)
development\managers\branching-manager\demo\demo_complete_system.go:10:2: package EMAIL_SENDER_1/development/managers/branching-manager/database is not in std (C:\Program Files\Go\src\EMAIL_SENDER_1\development\managers\branching-manager\database)
development\managers\branching-manager\demo\demo_complete_system.go:12:2: package EMAIL_SENDER_1/development/managers/branching-manager/git is not in std (C:\Program Files\Go\src\EMAIL_SENDER_1\development\managers\branching-manager\git)
development\managers\branching-manager\demo\demo_complete_system.go:13:2: package EMAIL_SENDER_1/development/managers/branching-manager/integrations is not in std (C:\Program Files\Go\src\EMAIL_SENDER_1\development\managers\branching-manager\integrations)
development\managers\branching-manager\levels\level-1\main.go:1:1: expected 'package', found 'EOF'
development\managers\config-manager\loader.go:10:2: no required module provides package github.com/BurntSushi/toml; to add it:
	go get github.com/BurntSushi/toml
development\managers\config-manager\config_manager.go:12:2: no required module provides package github.com/mitchellh/mapstructure; to add it:
	go get github.com/mitchellh/mapstructure
development\managers\dependencymanager\config.go:3:8: no required module provides package github.com/gerivdb/email-sender-1/development/managers/interfaces; to add it:
	go get github.com/gerivdb/email-sender-1/development/managers/interfaces
development\managers\dependencymanager\base_methods.go:3:4: expected 'package', found 'EOF'
development\managers\gateway-manager\discovery.go:8:2: no required module provides package github.com/gerivdb/email-sender-1/development/managers/gateway-manager/discovery; to add it:
	go get github.com/gerivdb/email-sender-1/development/managers/gateway-manager/discovery
development\managers\git-workflow-manager\git_workflow_manager.go:10:2: package EMAIL_SENDER_1/git-workflow-manager/internal/branch is not in std (C:\Program Files\Go\src\EMAIL_SENDER_1\git-workflow-manager\internal\branch)
development\managers\git-workflow-manager\git_workflow_manager.go:11:2: package EMAIL_SENDER_1/git-workflow-manager/internal/commit is not in std (C:\Program Files\Go\src\EMAIL_SENDER_1\git-workflow-manager\internal\commit)
development\managers\git-workflow-manager\git_workflow_manager.go:12:2: package EMAIL_SENDER_1/git-workflow-manager/internal/pr is not in std (C:\Program Files\Go\src\EMAIL_SENDER_1\git-workflow-manager\internal\pr)
development\managers\git-workflow-manager\git_workflow_manager.go:13:2: package EMAIL_SENDER_1/git-workflow-manager/internal/webhook is not in std (C:\Program Files\Go\src\EMAIL_SENDER_1\git-workflow-manager\internal\webhook)
development\managers\git-workflow-manager\git_workflow_manager.go:14:2: package EMAIL_SENDER_1/managers/interfaces is not in std (C:\Program Files\Go\src\EMAIL_SENDER_1\managers\interfaces)
development\managers\git-workflow-manager\internal\branch\manager.go:12:2: no required module provides package github.com/go-git/go-git/v5; to add it:
	go get github.com/go-git/go-git/v5
development\managers\git-workflow-manager\internal\branch\manager.go:13:2: no required module provides package github.com/go-git/go-git/v5/plumbing; to add it:
	go get github.com/go-git/go-git/v5/plumbing
development\managers\git-workflow-manager\internal\commit\manager.go:15:2: no required module provides package github.com/go-git/go-git/v5/plumbing/object; to add it:
	go get github.com/go-git/go-git/v5/plumbing/object
development\managers\git-workflow-manager\internal\pr\manager.go:12:2: no required module provides package github.com/google/go-github/v58/github; to add it:
	go get github.com/google/go-github/v58/github
development\managers\git-workflow-manager\internal\pr\manager.go:13:2: no required module provides package golang.org/x/oauth2; to add it:
	go get golang.org/x/oauth2
development\managers\integrated-manager\error_integration.go:12:2: no required module provides package github.com/pkg/errors; to add it:
	go get github.com/pkg/errors
development\managers\integrated-manager\demos\demo_api.go:4:2: package EMAIL_SENDER_1/managers/integrated-manager is not in std (C:\Program Files\Go\src\EMAIL_SENDER_1\managers\integrated-manager)
development\managers\integration-manager\webhook_management.go:4:2: package EMAIL_SENDER_1/development/managers/interfaces is not in std (C:\Program Files\Go\src\EMAIL_SENDER_1\development\managers\interfaces)
development\managers\integration-manager\api_management.go:13:2: no required module provides package github.com/sirupsen/logrus; to add it:
	go get github.com/sirupsen/logrus
development\managers\integration-manager\data_transformation.go:13:1: missing import path
development\managers\maintenance-manager\maintenance_manager.go:13:2: package EMAIL_SENDER_1/maintenance-manager/src/ai is not in std (C:\Program Files\Go\src\EMAIL_SENDER_1\maintenance-manager\src\ai)
development\managers\maintenance-manager\maintenance_manager.go:14:2: package EMAIL_SENDER_1/maintenance-manager/src/cleanup is not in std (C:\Program Files\Go\src\EMAIL_SENDER_1\maintenance-manager\src\cleanup)
development\managers\maintenance-manager\maintenance_manager.go:15:2: package EMAIL_SENDER_1/maintenance-manager/src/core is not in std (C:\Program Files\Go\src\EMAIL_SENDER_1\maintenance-manager\src\core)
development\managers\maintenance-manager\test_integration.go:5:2: package EMAIL_SENDER_1/maintenance-manager/src/generator is not in std (C:\Program Files\Go\src\EMAIL_SENDER_1\maintenance-manager\src\generator)
development\managers\maintenance-manager\maintenance_manager.go:16:2: package EMAIL_SENDER_1/maintenance-manager/src/integration is not in std (C:\Program Files\Go\src\EMAIL_SENDER_1\maintenance-manager\src\integration)
development\managers\maintenance-manager\maintenance_manager.go:17:2: package EMAIL_SENDER_1/maintenance-manager/src/templates is not in std (C:\Program Files\Go\src\EMAIL_SENDER_1\maintenance-manager\src\templates)
development\managers\maintenance-manager\maintenance_manager.go:18:2: package EMAIL_SENDER_1/maintenance-manager/src/vector is not in std (C:\Program Files\Go\src\EMAIL_SENDER_1\maintenance-manager\src\vector)
development\managers\maintenance-manager\maintenance_manager.go:10:2: no required module provides package github.com/spf13/viper; to add it:
	go get github.com/spf13/viper
development\managers\maintenance-manager\src\ai\ai_analyzer_new.go:16:2: package maintenance-manager/src/core is not in std (C:\Program Files\Go\src\maintenance-manager\src\core)
development\managers\maintenance-manager\src\ai\ai_analyzer_new.go:17:2: package maintenance-manager/src/vector is not in std (C:\Program Files\Go\src\maintenance-manager\src\vector)
development\managers\maintenance-manager\src\vector\qdrant_manager.go:9:2: no required module provides package github.com/gerivdb/email-sender-1/development/managers/maintenance-manager/src/core; to add it:
	go get github.com/gerivdb/email-sender-1/development/managers/maintenance-manager/src/core
development\managers\maintenance-manager\src\vector\qdrant_manager.go:10:2: no required module provides package github.com/gerivdb/email-sender-1/development/managers/maintenance-manager/src/vector/qdrant; to add it:
	go get github.com/gerivdb/email-sender-1/development/managers/maintenance-manager/src/vector/qdrant
development\managers\maintenance-manager\src\vector\vector_registry.go:11:2: no required module provides package google.golang.org/grpc; to add it:
	go get google.golang.org/grpc
development\managers\maintenance-manager\src\vector\vector_registry.go:12:2: no required module provides package google.golang.org/grpc/credentials/insecure; to add it:
	go get google.golang.org/grpc/credentials/insecure
development\managers\n8n-manager\n8n_manager.go:13:2: package EMAIL_SENDER_1/managers/error-manager is not in std (C:\Program Files\Go\src\EMAIL_SENDER_1\managers\error-manager)
development\managers\notification-manager\alert_manager.go:9:2: no required module provides package github.com/gerivdb/email-sender-1/managers/notification-manager/interfaces; to add it:
	go get github.com/gerivdb/email-sender-1/managers/notification-manager/interfaces
development\managers\notification-manager\notification_manager.go:11:2: no required module provides package github.com/robfig/cron/v3; to add it:
	go get github.com/robfig/cron/v3
development\managers\roadmap-manager\roadmap-cli\panel_demo.go:3:5: expected 'package', found 'EOF'
development\managers\roadmap-manager\roadmap-cli\cmd\priority-test.go:8:2: no required module provides package github.com/gerivdb/email-sender-1/cmd/roadmap-cli/priority; to add it:
	go get github.com/gerivdb/email-sender-1/cmd/roadmap-cli/priority
development\managers\roadmap-manager\roadmap-cli\cmd\priority-test.go:9:2: no required module provides package github.com/gerivdb/email-sender-1/cmd/roadmap-cli/types; to add it:
	go get github.com/gerivdb/email-sender-1/cmd/roadmap-cli/types
development\managers\roadmap-manager\roadmap-cli\commands\advanced_ingest.go:9:2: package email_sender/cmd/roadmap-cli/ingestion is not in std (C:\Program Files\Go\src\email_sender\cmd\roadmap-cli\ingestion)
development\managers\roadmap-manager\roadmap-cli\commands\advanced_ingest.go:10:2: package email_sender/cmd/roadmap-cli/storage is not in std (C:\Program Files\Go\src\email_sender\cmd\roadmap-cli\storage)
development\managers\roadmap-manager\roadmap-cli\commands\advanced_ingest.go:11:2: package email_sender/cmd/roadmap-cli/types is not in std (C:\Program Files\Go\src\email_sender\cmd\roadmap-cli\types)
development\managers\roadmap-manager\roadmap-cli\commands\hierarchy.go:7:2: no required module provides package github.com/charmbracelet/bubbletea; to add it:
	go get github.com/charmbracelet/bubbletea
development\managers\roadmap-manager\roadmap-cli\commands\intelligence.go:10:2: no required module provides package github.com/gerivdb/email-sender-1/cmd/roadmap-cli/rag; to add it:
	go get github.com/gerivdb/email-sender-1/cmd/roadmap-cli/rag
development\managers\roadmap-manager\roadmap-cli\commands\hierarchy.go:8:2: no required module provides package github.com/gerivdb/email-sender-1/cmd/roadmap-cli/storage; to add it:
	go get github.com/gerivdb/email-sender-1/cmd/roadmap-cli/storage
development\managers\roadmap-manager\roadmap-cli\commands\hierarchy.go:9:2: no required module provides package github.com/gerivdb/email-sender-1/cmd/roadmap-cli/tui; to add it:
	go get github.com/gerivdb/email-sender-1/cmd/roadmap-cli/tui
development\managers\roadmap-manager\roadmap-cli\commands\ingest.go:11:2: no required module provides package github.com/gerivdb/email-sender-1/development/managers/roadmap-manager/roadmap-cli/ingestion; to add it:
	go get github.com/gerivdb/email-sender-1/development/managers/roadmap-manager/roadmap-cli/ingestion
development\managers\roadmap-manager\roadmap-cli\commands\ingest.go:12:2: no required module provides package github.com/gerivdb/email-sender-1/development/managers/roadmap-manager/roadmap-cli/parallel; to add it:
	go get github.com/gerivdb/email-sender-1/development/managers/roadmap-manager/roadmap-cli/parallel
development\managers\roadmap-manager\roadmap-cli\commands\ingest.go:13:2: no required module provides package github.com/gerivdb/email-sender-1/development/managers/roadmap-manager/roadmap-cli/rag; to add it:
	go get github.com/gerivdb/email-sender-1/development/managers/roadmap-manager/roadmap-cli/rag
development\managers\roadmap-manager\roadmap-cli\commands\ingest.go:14:2: no required module provides package github.com/gerivdb/email-sender-1/development/managers/roadmap-manager/roadmap-cli/storage; to add it:
	go get github.com/gerivdb/email-sender-1/development/managers/roadmap-manager/roadmap-cli/storage
development\managers\roadmap-manager\roadmap-cli\commands\create.go:3:4: expected 'package', found 'EOF'
development\managers\roadmap-manager\roadmap-cli\parallel\processor.go:11:2: no required module provides package github.com/gerivdb/email-sender-1/cmd/roadmap-cli/ingestion; to add it:
	go get github.com/gerivdb/email-sender-1/cmd/roadmap-cli/ingestion
development\managers\roadmap-manager\roadmap-cli\tools\keybind-tester\keybind_tester.go:15:2: no required module provides package github.com/charmbracelet/lipgloss; to add it:
	go get github.com/charmbracelet/lipgloss
development\managers\roadmap-manager\roadmap-cli\tools\keybind-tester\keybind_tester.go:17:2: no required module provides package github.com/gerivdb/email-sender-1/cmd/roadmap-cli/keybinds; to add it:
	go get github.com/gerivdb/email-sender-1/cmd/roadmap-cli/keybinds
development\managers\roadmap-manager\roadmap-cli\tui\hierarchy.go:11:2: no required module provides package github.com/charmbracelet/bubbles/help; to add it:
	go get github.com/charmbracelet/bubbles/help
development\managers\roadmap-manager\roadmap-cli\tui\hierarchy.go:12:2: no required module provides package github.com/charmbracelet/bubbles/key; to add it:
	go get github.com/charmbracelet/bubbles/key
development\managers\roadmap-manager\roadmap-cli\tui\hierarchy.go:13:2: no required module provides package github.com/charmbracelet/bubbles/viewport; to add it:
	go get github.com/charmbracelet/bubbles/viewport
development\managers\roadmap-manager\roadmap-cli\tui\init.go:8:2: no required module provides package github.com/gerivdb/email-sender-1/cmd/roadmap-cli/tui/models; to add it:
	go get github.com/gerivdb/email-sender-1/cmd/roadmap-cli/tui/models
development\managers\security-manager\helpers.go:17:2: no required module provides package github.com/gerivdb/email-sender-1/managers/interfaces; to add it:
	go get github.com/gerivdb/email-sender-1/managers/interfaces
development\managers\security-manager\security_manager.go:20:2: no required module provides package golang.org/x/crypto/bcrypt; to add it:
	go get golang.org/x/crypto/bcrypt
development\managers\security-manager\development\security_manager.go:18:2: "./interfaces" is relative, but relative import paths are not supported in module mode
development\managers\security-manager\development\security_manager.go:18:2: local import "./interfaces" in non-local package
development\managers\smart-variable-manager\smart_variable_manager.go:11:1: missing import path
development\managers\smart-variable-manager\interfaces\smart_variable_manager.go:7:1: missing import path
development\managers\smart-variable-manager\internal\analyzer\context_analyzer.go:15:1: missing import path
development\managers\storage-manager\vectorization_utils.go:12:2: no required module provides package github.com/stretchr/testify/assert/yaml; to add it:
	go get github.com/stretchr/testify/assert/yaml
development\managers\storage-manager\development\storage_manager.go:12:2: local import "./interfaces" in non-local package
development\managers\template-performance-manager\manager.go:17:1: missing import path
development\managers\template-performance-manager\examples\complete_demo.go:12:1: missing import path
development\managers\template-performance-manager\internal\analytics\metrics_collector.go:9:1: missing import path
development\managers\template-performance-manager\internal\neural\processor.go:9:1: missing import path
development\managers\template-performance-manager\internal\optimization\adaptive_engine.go:9:1: missing import path
development\managers\template-performance-manager\tests\manager_test.go:12:1: missing import path
development\managers\template-performance-manager\tests\analytics\metrics_collector_test.go:13:1: missing import path
development\managers\template-performance-manager\tests\neural\processor_test.go:12:1: missing import path
development\managers\template-performance-manager\tests\optimization\adaptive_engine_test.go:13:1: missing import path
development\tools\plan-generator\cmd\main.go:10:2: package plan-generator/pkg/generator is not in std (C:\Program Files\Go\src\plan-generator\pkg\generator)
development\tools\plan-generator\cmd\main.go:11:2: package plan-generator/pkg/interactive is not in std (C:\Program Files\Go\src\plan-generator\pkg\interactive)
development\tools\plan-generator\cmd\main.go:12:2: package plan-generator/pkg/io is not in std (C:\Program Files\Go\src\plan-generator\pkg\io)
development\tools\plan-generator\cmd\main.go:13:2: package plan-generator/pkg/models is not in std (C:\Program Files\Go\src\plan-generator\pkg\models)
development\tools\plan-generator\pkg\generator\generator.go:9:2: package plan-generator/pkg/utils is not in std (C:\Program Files\Go\src\plan-generator\pkg\utils)
integration\export.go:7:2: no required module provides package github.com/gerivdb/email-sender-1/integration/visualizer; to add it:
	go get github.com/gerivdb/email-sender-1/integration/visualizer
integration\cmd\docmanager\main.go:8:2: no required module provides package github.com/gerivdb/email-sender-1/integration; to add it:
	go get github.com/gerivdb/email-sender-1/integration
integration_tests\container_integration.go:8:2: no required module provides package github.com/gerivdb/email-sender-1/projet/cred; to add it:
	go get github.com/gerivdb/email-sender-1/projet/cred
integration_tests\dependency_manager_integration_test.go:1:74: expected 'package', found 'EOF'
internal\api\handlers.go:11:2: no required module provides package github.com/oapi-codegen/runtime; to add it:
	go get github.com/oapi-codegen/runtime
internal\infrastructure\smart_orchestrator.go:13:2: no required module provides package github.com/gerivdb/email-sender-1/internal/monitoring; to add it:
	go get github.com/gerivdb/email-sender-1/internal/monitoring
internal\infrastructure\smart_orchestrator.go:14:2: no required module provides package github.com/prometheus/client_golang/api; to add it:
	go get github.com/prometheus/client_golang/api
internal\infrastructure\smart_orchestrator.go:15:2: no required module provides package github.com/prometheus/client_golang/api/prometheus/v1; to add it:
	go get github.com/prometheus/client_golang/api/prometheus/v1
internal\report\generator.go:11:2: no required module provides package github.com/gerivdb/email-sender-1/internal/report/diff; to add it:
	go get github.com/gerivdb/email-sender-1/internal/report/diff
internal\report\generator.go:12:2: no required module provides package github.com/gerivdb/email-sender-1/internal/report/stats; to add it:
	go get github.com/gerivdb/email-sender-1/internal/report/stats
internal\report\presentation\server.go:12:2: no required module provides package github.com/gerivdb/email-sender-1/internal/report; to add it:
	go get github.com/gerivdb/email-sender-1/internal/report
planning-ecosystem-sync\cmd\validate-vectors\main.go:16:2: no required module provides package go.uber.org/zap/zapcore; to add it:
	go get go.uber.org/zap/zapcore
planning-ecosystem-sync\tools\sync-core\qdrant_legacy.go:8:2: no required module provides package github.com/gerivdb/email-sender-1/planning-ecosystem-sync/pkg/qdrant; to add it:
	go get github.com/gerivdb/email-sender-1/planning-ecosystem-sync/pkg/qdrant
planning-ecosystem-sync\tools\sync-core\sql_storage.go:10:2: no required module provides package github.com/go-sql-driver/mysql; to add it:
	go get github.com/go-sql-driver/mysql
planning-ecosystem-sync\tools\sync-core\sql_storage.go:12:2: no required module provides package github.com/mattn/go-sqlite3; to add it:
	go get github.com/mattn/go-sqlite3
planning-ecosystem-sync\tools\sync-core\sql_storage.go:13:2: no required module provides package modernc.org/sqlite; to add it:
	go get modernc.org/sqlite
found packages core (conflict_detector.go) and sync_core (conflict_resolver.go) in d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\planning-ecosystem-sync\tools\sync-core
planning-ecosystem-sync\tools\validation\consistency-validator_test.go:1:1: expected 'package', found 'EOF'
planning-ecosystem-sync\tools\validation\cmd\validator\main.go:12:2: package planning-ecosystem-sync/tools/validation is not in std (C:\Program Files\Go\src\planning-ecosystem-sync\tools\validation)
planning-ecosystem-sync\tools\workflow-orchestrator\cmd\main.go:15:2: no required module provides package github.com/gerivdb/email-sender-1/planning-ecosystem-sync/tools/workflow-orchestrator; to add it:
	go get github.com/gerivdb/email-sender-1/planning-ecosystem-sync/tools/workflow-orchestrator
projet\cred\dependency_manager.go:18:2: no required module provides package golang.org/x/mod/modfile; to add it:
	go get golang.org/x/mod/modfile
scripts\error-resolution-pipeline\cmd\pipeline\main.go:18:2: no required module provides package github.com/gerivdb/email-sender-1/scripts/error-resolution-pipeline/pkg/detector; to add it:
	go get github.com/gerivdb/email-sender-1/scripts/error-resolution-pipeline/pkg/detector
scripts\error-resolution-pipeline\cmd\pipeline\main.go:19:2: no required module provides package github.com/gerivdb/email-sender-1/scripts/error-resolution-pipeline/pkg/resolver; to add it:
	go get github.com/gerivdb/email-sender-1/scripts/error-resolution-pipeline/pkg/resolver
src\indexing\markdown_reader.go:6:2: no required module provides package github.com/gomarkdown/markdown/ast; to add it:
	go get github.com/gomarkdown/markdown/ast
src\indexing\markdown_reader.go:7:2: no required module provides package github.com/gomarkdown/markdown/parser; to add it:
	go get github.com/gomarkdown/markdown/parser
src\indexing\pdf_reader.go:7:2: no required module provides package github.com/pdfcpu/pdfcpu/pkg/api; to add it:
	go get github.com/pdfcpu/pdfcpu/pkg/api
src\indexing\text_reader.go:10:2: no required module provides package github.com/saintfish/chardet; to add it:
	go get github.com/saintfish/chardet
src\indexing\text_reader.go:11:2: no required module provides package golang.org/x/text/encoding; to add it:
	go get golang.org/x/text/encoding
src\indexing\text_reader.go:12:2: no required module provides package golang.org/x/text/encoding/charmap; to add it:
	go get golang.org/x/text/encoding/charmap
src\indexing\text_reader.go:13:2: no required module provides package golang.org/x/text/encoding/unicode; to add it:
	go get golang.org/x/text/encoding/unicode
src\indexing\cmd\indexer\main.go:12:2: no required module provides package github.com/gerivdb/email-sender-1/src/indexing; to add it:
	go get github.com/gerivdb/email-sender-1/src/indexing
src\indexing\cmd\indexer\main.go:14:2: no required module provides package github.com/schollz/progressbar/v3; to add it:
	go get github.com/schollz/progressbar/v3
src\qdrant\embedded_client.go:9:2: no required module provides package github.com/gerivdb/email-sender-1/mocks; to add it:
	go get github.com/gerivdb/email-sender-1/mocks
standalone-scripts-archive\demo_chunking_ameliore.go:8:2: no required module provides package github.com/gerivdb/email-sender-1/src/chunking; to add it:
	go get github.com/gerivdb/email-sender-1/src/chunking
streaming\redis_streaming\intelligent_cache.go:8:2: no required module provides package github.com/go-redis/redis/v8; to add it:
	go get github.com/go-redis/redis/v8
tests\sync-integration-test.go:16:2: no required module provides package github.com/stretchr/testify/suite; to add it:
	go get github.com/stretchr/testify/suite
tests\interface_validation\main_test.go:3:5: expected 'package', found 'EOF'
tests\test_runners\simple_test.go:3:4: expected 'package', found 'EOF'
tests\validation\validation_test.go:3:4: expected 'package', found 'EOF'
tools\realtime-dashboard.go:11:2: no required module provides package github.com/gorilla/websocket; to add it:
	go get github.com/gorilla/websocket
found packages tools (alert-manager.go) and main (debug_project_structure.go) in d:\DO\WEB\N8N_tests\PROJETS\EMAIL_SENDER_1\tools
tools\db-integration-tests\testdb\setup.go:4:2: no required module provides package github.com/jmoiron/sqlx; to add it:
	go get github.com/jmoiron/sqlx
tools\diff_edit\go\main.go:8:2: no required module provides package github.com/gerivdb/email-sender-1/tools/diff_edit/go/diffeditgo; to add it:
	go get github.com/gerivdb/email-sender-1/tools/diff_edit/go/diffeditgo
tools\qdrant\rag-go\rag_go.go:7:2: package rag-go-system/pkg/client is not in std (C:\Program Files\Go\src\rag-go-system\pkg\client)
Erreur d'exécution : exit status 1

```
## Diagnostics YAML
```
Fichier : .codacy.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\copilot.config.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\docs\WORKFLOWS\exemple_workflow.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\docs\gemini-cli\gemini.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\jules-config.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\notification-config.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\workflows\auto-doc.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\workflows\ci-cd.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\workflows\ci-go-yaml-automation.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\workflows\ci-pipeline.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\workflows\ci.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\workflows\compatibility.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\workflows\deploy-docmanager.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\workflows\email-notification.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\workflows\error-analysis.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\workflows\full-ci.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\workflows\gapanalyzer_remediation.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\workflows\gateway-manager-ci.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\workflows\go-quality.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\workflows\jules-bot-redirect.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\workflows\jules-bot-validator.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\workflows\jules-contributions.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\workflows\jules-integration.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\workflows\jules-review-approval.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\workflows\load-tests.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\workflows\main.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\workflows\minimal.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\workflows\mode-manager-tests.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\workflows\move-files-ci.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\workflows\n8n-deploy.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\workflows\pr-analysis.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\workflows\pr-error-analysis.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\workflows\rag-pipeline.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\workflows\read_file.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\workflows\refs_sync.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\workflows\roadmap-migration-ci.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\workflows\run-tests.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\workflows\testomnibus.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\workflows\v101-pipeline.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .github\workflows\validate.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .golangci.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .golangci.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .kilocode\workflows\orchestrator_autonomous_error_resolution.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .roo\config\recensement.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : .roo\tools\refs_sync.config.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : api\openapi.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : azure-pipelines\mode-manager-tests.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : besoins-automatisation-doc.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : besoins.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : ci\pipeline-backup.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : ci\scripts\roadmap-pipeline.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : config\fmoua.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : config.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : configs\development.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : configs\grafana\provisioning\dashboards\dashboards.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : configs\grafana\provisioning\datasources\prometheus.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : configs\production.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : configs\prometheus\rules\smart-infrastructure-alerts.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : configs\prometheus.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : configs\staging.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : core\docmanager\config\docmanager-config.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : deployment\config\prometheus\prometheus.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : deployment\docker-compose.production.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : deployment\helm\go-n8n-infra\values.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : deployment\staging\docker-compose.staging.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : deployment\staging\k8s\deployment.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : deployment\staging\k8s\namespace.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : development\managers\advanced-autonomy-manager\config\config.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : development\managers\advanced-autonomy-manager\config\infrastructure_config.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : development\managers\advanced-autonomy-manager\config.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : development\managers\branching-manager\config\branching_config.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : development\managers\branching-manager\k8s\deployment.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : development\managers\cache-manager\lmc_config_example.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : development\managers\config-manager\test_config.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : development\managers\contextual-memory-manager\config\hybrid_production.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : development\managers\contextual-memory-manager\config\local.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : development\managers\contextual-memory-manager\config\performance_targets.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : development\managers\contextual-memory-manager\config\production.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : development\managers\contextual-memory-manager\docker-compose.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : development\managers\git-workflow-manager\config\config.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : development\managers\maintenance-manager\config\maintenance-config.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : development\managers\vectorization-go\config.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : development\scripts\maintenance\error-learning\CI-CD\github-workflow-tests.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : development\scripts\maintenance\error-learning\CI-CD\github-workflow.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : development\scripts\script-manager\testing\ci\azure-pipelines.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : development\scripts\utils\Tests\TestData\test.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : development\scripts\utils\Tests\format_samples\sample.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : development\scripts\utils\Tests\samples\formats\sample.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : development\tools\testing-tools\TestData\test.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : development\tools\testing-tools\format_samples\sample.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : development\tools\testing-tools\samples\formats\sample.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : devops\pipelines\azure-pipelines.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : docker-compose-backup.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : docker-compose-corrupt.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : docker-compose-new.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : docker-compose-old.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : docker-compose-temp.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : docker-compose.memory-optimized.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : docker-compose.qdrant.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : docker-compose.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : exigences-interoperabilite.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : file-moves.schema.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : file-moves.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : gemini.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : git-workflow-config.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : indie-booking-crm\pnpm-lock.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : kubernetes\database\postgresql.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : kubernetes\database\qdrant.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : kubernetes\database\redis.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : kubernetes\edge\edge-computing.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : kubernetes\enterprise\api-gateway.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : kubernetes\enterprise\auth.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : kubernetes\enterprise\configmap.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : kubernetes\enterprise\deployment.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : kubernetes\enterprise\ingress.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : kubernetes\enterprise\multi-region.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : kubernetes\enterprise\namespace.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : kubernetes\enterprise\security.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : kubernetes\loadtest\advanced-load-testing.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : kubernetes\monitoring\grafana.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : kubernetes\monitoring\prometheus.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : kubernetes\optimization\performance-optimization.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\.github\ISSUE_TEMPLATE\bug_report.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\.github\ISSUE_TEMPLATE\config.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\.github\ISSUE_TEMPLATE\documentation_issue.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\.github\ISSUE_TEMPLATE\feature_request.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\.github\workflows\cd.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\.github\workflows\ci.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\.pre-commit-config.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\embedchain\configs\anthropic.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\embedchain\configs\aws_bedrock.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\embedchain\configs\azure_openai.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\embedchain\configs\chroma.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\embedchain\configs\chunker.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\embedchain\configs\clarifai.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\embedchain\configs\cohere.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\embedchain\configs\full-stack.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\embedchain\configs\google.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\embedchain\configs\gpt4.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\embedchain\configs\gpt4all.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\embedchain\configs\huggingface.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\embedchain\configs\jina.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\embedchain\configs\llama2.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\embedchain\configs\ollama.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\embedchain\configs\opensearch.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\embedchain\configs\opensource.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\embedchain\configs\pinecone.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\embedchain\configs\pipeline.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\embedchain\configs\together.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\embedchain\configs\vertexai.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\embedchain\configs\vllm.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\embedchain\configs\weaviate.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\embedchain\embedchain\deployment\render.com\render.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\embedchain\examples\api_server\docker-compose.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\embedchain\examples\discord_bot\docker-compose.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\embedchain\examples\full_stack\docker-compose.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\embedchain\examples\mistral-streamlit\config.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\embedchain\examples\private-ai\config.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\embedchain\examples\rest-api\default.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\embedchain\examples\rest-api\sample-config.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\embedchain\notebooks\azure_openai.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\embedchain\notebooks\openai_azure.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\mem0-ts\pnpm-lock.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\openmemory\api\docker-compose.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\openmemory\ui\docker-compose.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\openmemory\ui\pnpm-lock.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\server\docker-compose.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : mem0-analysis\repo\vercel-ai-sdk\pnpm-lock.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : node_modules\@eslint\eslintrc\node_modules\ajv\scripts\.eslintrc.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : node_modules\@eslint\eslintrc\node_modules\json-schema-traverse\.eslintrc.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : node_modules\@eslint\eslintrc\node_modules\json-schema-traverse\.travis.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : node_modules\@eslint\eslintrc\node_modules\json-schema-traverse\spec\.eslintrc.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : node_modules\@ungap\structured-clone\.github\workflows\node.js.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : node_modules\balanced-match\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : node_modules\concat-map\.travis.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : node_modules\deep-is\.travis.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : node_modules\eslint\node_modules\ajv\scripts\.eslintrc.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : node_modules\eslint\node_modules\json-schema-traverse\.eslintrc.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : node_modules\eslint\node_modules\json-schema-traverse\.travis.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : node_modules\eslint\node_modules\json-schema-traverse\spec\.eslintrc.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : node_modules\fast-json-stable-stringify\.eslintrc.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : node_modules\fast-json-stable-stringify\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : node_modules\fast-json-stable-stringify\.travis.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : node_modules\fastq\.github\dependabot.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : node_modules\fastq\.github\workflows\ci.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : node_modules\json-buffer\.travis.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : node_modules\json-stable-stringify-without-jsonify\.travis.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : node_modules\reusify\.github\dependabot.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : node_modules\reusify\.github\workflows\ci.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : node_modules\text-table\.travis.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : opencode\.github\workflows\build.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : opencode\.github\workflows\release.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : opencode\.goreleaser.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : opencode\sqlc.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : output\phase1\communication-points.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : pkg\templategen\config.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : planning-ecosystem-sync\config\roadmap-connector.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : planning-ecosystem-sync\config\sync-config.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : planning-ecosystem-sync\config\validation-rules\default-rules.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : planning-ecosystem-sync\config\validation-rules.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : planning-ecosystem-sync\config\workflow-orchestrator.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : planning-ecosystem-sync\tools\validation\testdata\sample_plan.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : projet\config\conformity\conformity-rules.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : projet\config\docker-compose.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : projet\mcp\config\servers\gateway.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : projet\security\backups\sessions\20250603-113746-0474c679-7b01-4b48-8859-d7628ad37ba1\critical\docker-compose.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : projet\security\backups\sessions\20250603-114531-4b17a7b1-b99b-4358-a47a-bc5b8168b8df\critical\docker-compose.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : projet\security\backups\sessions\20250603-114716-77f4019f-bcfc-4325-bcca-ee3e05ba4873\critical\docker-compose.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : scripts\automatisation_doc\batch_manager_schema.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : scripts\automatisation_doc\batch_schema.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : scripts\automatisation_doc\besoins_automatisation.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : scripts\automatisation_doc\config.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : scripts\automatisation_doc\error_manager_schema.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : scripts\automatisation_doc\fallback_schema.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : scripts\automatisation_doc\monitoring_schema.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : scripts\automatisation_doc\pipeline_schema.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : scripts\automatisation_doc\session_schema.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : scripts\automatisation_doc\storage_manager_schema.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : scripts\automatisation_doc\synchronisation_schema.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : scripts\fix-github-workflows\.github\workflows\test-workflow.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : servers\node_modules\brace-expansion\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : servers\node_modules\call-bind-apply-helpers\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : servers\node_modules\dunder-proto\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : servers\node_modules\es-define-property\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : servers\node_modules\es-errors\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : servers\node_modules\es-object-atoms\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : servers\node_modules\fast-json-stable-stringify\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : servers\node_modules\fast-json-stable-stringify\.travis.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : servers\node_modules\function-bind\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : servers\node_modules\get-intrinsic\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : servers\node_modules\get-proto\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : servers\node_modules\gopd\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : servers\node_modules\has-symbols\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : servers\node_modules\hasown\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : servers\node_modules\math-intrinsics\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\@humanwhocodes\object-schema\.github\workflows\nodejs-test.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\@humanwhocodes\object-schema\.github\workflows\release-please.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\ajv\scripts\.eslintrc.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\balanced-match\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\binary\.travis.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\buffer-indexof-polyfill\.travis.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\concat-map\.travis.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\deep-is\.travis.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\fast-json-stable-stringify\.eslintrc.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\fast-json-stable-stringify\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\fast-json-stable-stringify\.travis.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\fast-uri\.github\.stale.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\fast-uri\.github\dependabot.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\fast-uri\.github\tests_checker.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\fast-uri\.github\workflows\ci.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\fast-uri\.github\workflows\package-manager-ci.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\fastq\.github\dependabot.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\fastq\.github\workflows\ci.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\flat\.travis.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\fstream\.travis.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\growl\.travis.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\isarray\.travis.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\json-buffer\.travis.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\json-schema-traverse\.eslintrc.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\json-schema-traverse\.travis.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\json-schema-traverse\spec\.eslintrc.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\json-stable-stringify-without-jsonify\.travis.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\listenercount\circle.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\minimist\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\randombytes\.travis.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\randombytes\.zuul.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\readable-stream\.travis.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\require-directory\.travis.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\reusify\.github\dependabot.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\reusify\.github\workflows\ci.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\string_decoder\.travis.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\table\node_modules\json-schema-traverse\.eslintrc.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\table\node_modules\json-schema-traverse\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\table\node_modules\json-schema-traverse\.github\workflows\build.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\table\node_modules\json-schema-traverse\.github\workflows\publish.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\table\node_modules\json-schema-traverse\spec\.eslintrc.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\text-table\.travis.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\unzipper\.circleci\config.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\unzipper\.travis.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\extensions\error-pattern-analyzer\node_modules\vscode-test\.github\workflows\ci.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\indexing\monitoring\prometheus\rules\indexing_alerts.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\mcp\config\gateway.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\mcp\gateway\gateway.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\mcp\proxy\docker-compose.dev.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : src\mcp\proxy\docker-compose.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\.github\workflows\release.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\ajv\scripts\.eslintrc.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\balanced-match\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\brace-expansion\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\call-bind-apply-helpers\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\call-bound\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\concat-map\.travis.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\deep-is\.travis.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\dunder-proto\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\es-define-property\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\es-errors\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\es-object-atoms\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\fast-json-stable-stringify\.eslintrc.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\fast-json-stable-stringify\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\fast-json-stable-stringify\.travis.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\fastq\.github\dependabot.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\fastq\.github\workflows\ci.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\function-bind\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\get-intrinsic\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\get-proto\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\gopd\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\has-symbols\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\hasown\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\iconv-lite\.github\dependabot.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\json-buffer\.travis.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\json-schema-traverse\.eslintrc.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\json-schema-traverse\.travis.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\json-schema-traverse\spec\.eslintrc.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\json-stable-stringify-without-jsonify\.travis.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\math-intrinsics\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\object-inspect\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\qs\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\reusify\.github\dependabot.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\reusify\.github\workflows\ci.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\side-channel\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\side-channel-list\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\side-channel-map\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\side-channel-weakmap\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\node_modules\zod-to-json-schema\.github\FUNDING.yml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : submodules\context7\smithery.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

Fichier : tools\qdrant\config.yaml
>>> go run scripts/lint-yaml.go
CreateFile scripts/lint-yaml.go: Le fichier spécifié est introuvable.
Erreur d'exécution : exit status 1

```
