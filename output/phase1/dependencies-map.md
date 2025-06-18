# Dependencies Map - Imports Managers

**Date de scan**: 2025-06-18 20:34:34  
**Branche**: dev  
**Fichiers managers scannés**: 86  
**Total imports**: 614  
**Packages uniques**: 108

## 📋 Vue d'Ensemble des Dépendances

### TOP 10 Imports les Plus Utilisés
- `time`: 70 fichiers
- `context`: 69 fichiers
- `fmt`: 68 fichiers
- `sync`: 35 fichiers
- `encoding/json`: 27 fichiers
- `log`: 27 fichiers
- `go.uber.org/zap`: 27 fichiers
- `strings`: 27 fichiers
- `github.com/google/uuid`: 20 fichiers
- `os`: 15 fichiers

## 📦 Analyse par Fichier Manager

### `basetools\manager.go`

- **Package**: basetools
- **Total imports**: 1
- **Standard**: 1
- **Third-party**: 0 
- **Local**: 0

#### Standard Library
- `log`

#### Third-Party Dependencies  
- Aucune dépendance externe

#### Local Dependencies
- Aucune dépendance locale

### `development\hooks\commit-interceptor\branching_manager_test_new.go`

- **Package**: commitinterceptor
- **Total imports**: 1
- **Standard**: 0
- **Third-party**: 0 
- **Local**: 1

#### Standard Library
- Aucun import standard

#### Third-Party Dependencies  
- Aucune dépendance externe

#### Local Dependencies
- `testing`

### `development\hooks\commit-interceptor\branching_manager.go`

- **Package**: main
- **Total imports**: 4
- **Standard**: 4
- **Third-party**: 0 
- **Local**: 0

#### Standard Library
- `fmt`
- `os/exec`
- `strings`
- `time`

#### Third-Party Dependencies  
- Aucune dépendance externe

#### Local Dependencies
- Aucune dépendance locale

### `development\managers\advanced-autonomy-manager\advanced_autonomy_manager.go`

- **Package**: advanced_autonomy_manager
- **Total imports**: 11
- **Standard**: 4
- **Third-party**: 0 
- **Local**: 7

#### Standard Library
- `context`
- `fmt`
- `sync`
- `time`

#### Third-Party Dependencies  
- Aucune dépendance externe

#### Local Dependencies
- `advanced-autonomy-manager/interfaces`
- `advanced-autonomy-manager/internal/coordination`
- `advanced-autonomy-manager/internal/decision`
- `advanced-autonomy-manager/internal/discovery`
- `advanced-autonomy-manager/internal/healing`
- `advanced-autonomy-manager/internal/monitoring`
- `advanced-autonomy-manager/internal/predictive`

### `development\managers\advanced-autonomy-manager\interfaces\advanced_autonomy_manager.go`

- **Package**: interfaces
- **Total imports**: 2
- **Standard**: 2
- **Third-party**: 0 
- **Local**: 0

#### Standard Library
- `context`
- `time`

#### Third-Party Dependencies  
- Aucune dépendance externe

#### Local Dependencies
- Aucune dépendance locale

### `development\managers\advanced-autonomy-manager\internal\coordination\cross_manager_event_bus.go`

- **Package**: coordination
- **Total imports**: 5
- **Standard**: 4
- **Third-party**: 0 
- **Local**: 1

#### Standard Library
- `context`
- `fmt`
- `sync`
- `time`

#### Third-Party Dependencies  
- Aucune dépendance externe

#### Local Dependencies
- `advanced-autonomy-manager/interfaces`

### `development\managers\advanced-autonomy-manager\internal\coordination\global_state_manager.go`

- **Package**: coordination
- **Total imports**: 8
- **Standard**: 4
- **Third-party**: 0 
- **Local**: 4

#### Standard Library
- `context`
- `fmt`
- `sync`
- `time`

#### Third-Party Dependencies  
- Aucune dépendance externe

#### Local Dependencies
- `crypto/sha256`
- `encoding/hex`
- `encoding/json`
- `advanced-autonomy-manager/interfaces`

### `development\managers\advanced-autonomy-manager\internal\discovery\manager_discovery.go`

- **Package**: discovery
- **Total imports**: 10
- **Standard**: 8
- **Third-party**: 0 
- **Local**: 2

#### Standard Library
- `context`
- `fmt`
- `net`
- `net/http`
- `os`
- `strings`
- `sync`
- `time`

#### Third-Party Dependencies  
- Aucune dépendance externe

#### Local Dependencies
- `path/filepath`
- `advanced-autonomy-manager/interfaces`

### `development\managers\advanced-autonomy-manager\internal\discovery\manager_proxies.go`

- **Package**: discovery
- **Total imports**: 7
- **Standard**: 4
- **Third-party**: 0 
- **Local**: 3

#### Standard Library
- `context`
- `fmt`
- `net/http`
- `time`

#### Third-Party Dependencies  
- Aucune dépendance externe

#### Local Dependencies
- `bytes`
- `encoding/json`
- `advanced-autonomy-manager/interfaces`

### `development\managers\advanced-autonomy-manager\internal\infrastructure\security_manager.go`

- **Package**: infrastructure
- **Total imports**: 5
- **Standard**: 4
- **Third-party**: 0 
- **Local**: 1

#### Standard Library
- `context`
- `fmt`
- `sync`
- `time`

#### Third-Party Dependencies  
- Aucune dépendance externe

#### Local Dependencies
- `crypto/tls`

### `development\managers\ai-template-manager\ai_template_manager.go`

- **Package**: ai_template_manager
- **Total imports**: 10
- **Standard**: 6
- **Third-party**: 2 
- **Local**: 2

#### Standard Library
- `context`
- `fmt`
- `os`
- `strings`
- `sync`
- `time`

#### Third-Party Dependencies  
- `github.com/chrlesur/Email_Sender/development/managers/ai-template-manager/interfaces`
- `github.com/chrlesur/Email_Sender/development/managers/ai-template-manager/internal/ai`

#### Local Dependencies
- `encoding/json`
- `path/filepath`

### `development\managers\ai-template-manager\interfaces\ai_template_manager.go`

- **Package**: interfaces
- **Total imports**: 2
- **Standard**: 1
- **Third-party**: 1 
- **Local**: 0

#### Standard Library
- `time`

#### Third-Party Dependencies  
- `github.com/chrlesur/Email_Sender/development/managers/interfaces`

#### Local Dependencies
- Aucune dépendance locale

### `development\managers\branching-manager\development\branching_manager.go`

- **Package**: development
- **Total imports**: 11
- **Standard**: 7
- **Third-party**: 2 
- **Local**: 2

#### Standard Library
- `context`
- `fmt`
- `log`
- `os`
- `strings`
- `sync`
- `time`

#### Third-Party Dependencies  
- `github.com/google/uuid`
- `gopkg.in/yaml.v3`

#### Local Dependencies
- `encoding/json`
- `../interfaces`

### `development\managers\config-manager\config_manager.go`

- **Package**: configmanager
- **Total imports**: 9
- **Standard**: 5
- **Third-party**: 2 
- **Local**: 2

#### Standard Library
- `context`
- `fmt`
- `strconv`
- `strings`
- `time`

#### Third-Party Dependencies  
- `github.com/google/uuid`
- `github.com/mitchellh/mapstructure`

#### Local Dependencies
- `errors`
- `go.uber.org/zap`

### `development\managers\container-manager\development\container_manager.go`

- **Package**: main
- **Total imports**: 7
- **Standard**: 6
- **Third-party**: 0 
- **Local**: 1

#### Standard Library
- `context`
- `fmt`
- `log`
- `os/exec`
- `strings`
- `time`

#### Third-Party Dependencies  
- Aucune dépendance externe

#### Local Dependencies
- `go.uber.org/zap`

### `development\managers\contextual-memory-manager\development\contextual_memory_manager.go`

- **Package**: development
- **Total imports**: 10
- **Standard**: 4
- **Third-party**: 5 
- **Local**: 1

#### Standard Library
- `context`
- `fmt`
- `sync`
- `time`

#### Third-Party Dependencies  
- `github.com/email-sender/development/managers/contextual-memory-manager/interfaces`
- `github.com/email-sender/development/managers/contextual-memory-manager/internal/indexing`
- `github.com/email-sender/development/managers/contextual-memory-manager/internal/integration`
- `github.com/email-sender/development/managers/contextual-memory-manager/internal/monitoring`
- `github.com/email-sender/development/managers/contextual-memory-manager/internal/retrieval`

#### Local Dependencies
- `./interfaces`

### `development\managers\contextual-memory-manager\internal\indexing\index_manager.go`

- **Package**: indexing
- **Total imports**: 10
- **Standard**: 4
- **Third-party**: 2 
- **Local**: 4

#### Standard Library
- `context`
- `fmt`
- `log`
- `time`

#### Third-Party Dependencies  
- `github.com/email-sender/development/managers/contextual-memory-manager/interfaces`
- `github.com/google/uuid`

#### Local Dependencies
- `database/sql`
- `encoding/json`
- `math`
- `./interfaces`

### `development\managers\contextual-memory-manager\internal\integration\integration_manager.go`

- **Package**: integration
- **Total imports**: 10
- **Standard**: 5
- **Third-party**: 1 
- **Local**: 4

#### Standard Library
- `context`
- `fmt`
- `io`
- `net/http`
- `time`

#### Third-Party Dependencies  
- `github.com/email-sender/development/managers/contextual-memory-manager/interfaces`

#### Local Dependencies
- `bytes`
- `database/sql`
- `encoding/json`
- `./interfaces`

### `development\managers\contextual-memory-manager\internal\monitoring\monitoring_manager.go`

- **Package**: monitoring
- **Total imports**: 8
- **Standard**: 4
- **Third-party**: 3 
- **Local**: 1

#### Standard Library
- `context`
- `fmt`
- `sync`
- `time`

#### Third-Party Dependencies  
- `github.com/email-sender/development/managers/contextual-memory-manager/interfaces`
- `github.com/prometheus/client_golang/prometheus`
- `github.com/prometheus/client_golang/prometheus/promauto`

#### Local Dependencies
- `./interfaces`

### `development\managers\contextual-memory-manager\internal\retrieval\retrieval_manager.go`

- **Package**: retrieval
- **Total imports**: 6
- **Standard**: 3
- **Third-party**: 1 
- **Local**: 2

#### Standard Library
- `context`
- `fmt`
- `strings`

#### Third-Party Dependencies  
- `github.com/email-sender/development/managers/contextual-memory-manager/interfaces`

#### Local Dependencies
- `database/sql`
- `./interfaces`

### `development\managers\contextual-memory-manager\pkg\manager\contextual_memory_manager.go`

- **Package**: manager
- **Total imports**: 4
- **Standard**: 3
- **Third-party**: 1 
- **Local**: 0

#### Standard Library
- `context`
- `fmt`
- `log`

#### Third-Party Dependencies  
- `github.com/contextual-memory-manager/pkg/interfaces`

#### Local Dependencies
- Aucune dépendance locale

### `development\managers\contextual-memory-manager\pkg\manager\qdrant_retrieval_manager.go`

- **Package**: manager
- **Total imports**: 5
- **Standard**: 4
- **Third-party**: 1 
- **Local**: 0

#### Standard Library
- `context`
- `fmt`
- `log`
- `strings`

#### Third-Party Dependencies  
- `github.com/contextual-memory-manager/pkg/interfaces`

#### Local Dependencies
- Aucune dépendance locale

### `development\managers\contextual-memory-manager\pkg\manager\sqlite_index_manager.go`

- **Package**: manager
- **Total imports**: 8
- **Standard**: 4
- **Third-party**: 2 
- **Local**: 2

#### Standard Library
- `context`
- `fmt`
- `log`
- `time`

#### Third-Party Dependencies  
- `github.com/mattn/go-sqlite3`
- `github.com/contextual-memory-manager/pkg/interfaces`

#### Local Dependencies
- `database/sql`
- `encoding/json`

### `development\managers\contextual-memory-manager\pkg\manager\webhook_integration_manager.go`

- **Package**: manager
- **Total imports**: 9
- **Standard**: 6
- **Third-party**: 1 
- **Local**: 2

#### Standard Library
- `context`
- `fmt`
- `io`
- `log`
- `net/http`
- `time`

#### Third-Party Dependencies  
- `github.com/contextual-memory-manager/pkg/interfaces`

#### Local Dependencies
- `bytes`
- `encoding/json`

### `development\managers\dependency-manager\dependency_manager.go`

- **Package**: dependency
- **Total imports**: 6
- **Standard**: 2
- **Third-party**: 2 
- **Local**: 2

#### Standard Library
- `sync`
- `time`

#### Third-Party Dependencies  
- `github.com/google/uuid`
- `github.com/Masterminds/semver/v3`

#### Local Dependencies
- `go.uber.org/zap`
- `d:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/development/managers/interfaces`

### `development\managers\dependency-manager\modules\dependency_manager.go`

- **Package**: main
- **Total imports**: 13
- **Standard**: 6
- **Third-party**: 2 
- **Local**: 5

#### Standard Library
- `context`
- `fmt`
- `os`
- `os/exec`
- `strings`
- `time`

#### Third-Party Dependencies  
- `github.com/google/uuid`
- `golang.org/x/mod/modfile`

#### Local Dependencies
- `encoding/json`
- `flag`
- `path/filepath`
- `go.uber.org/zap`
- `./interfaces`

### `development\managers\dependency-manager\modules\import_manager.go`

- **Package**: main
- **Total imports**: 14
- **Standard**: 6
- **Third-party**: 0 
- **Local**: 8

#### Standard Library
- `context`
- `fmt`
- `os`
- `strconv`
- `strings`
- `time`

#### Third-Party Dependencies  
- Aucune dépendance externe

#### Local Dependencies
- `go/ast`
- `go/parser`
- `go/token`
- `path/filepath`
- `regexp`
- `sort`
- `./interfaces`
- `go.uber.org/zap`

### `development\managers\dependency-manager\modules\manager_integration.go`

- **Package**: main
- **Total imports**: 5
- **Standard**: 3
- **Third-party**: 0 
- **Local**: 2

#### Standard Library
- `context`
- `fmt`
- `time`

#### Third-Party Dependencies  
- Aucune dépendance externe

#### Local Dependencies
- `./interfaces`
- `go.uber.org/zap`

### `development\managers\dependency-manager\modules\manager_interfaces.go`

- **Package**: main
- **Total imports**: 3
- **Standard**: 2
- **Third-party**: 0 
- **Local**: 1

#### Standard Library
- `context`
- `time`

#### Third-Party Dependencies  
- Aucune dépendance externe

#### Local Dependencies
- `./interfaces`

### `development\managers\dependency-manager\modules\real_manager_integration.go`

- **Package**: main
- **Total imports**: 7
- **Standard**: 5
- **Third-party**: 0 
- **Local**: 2

#### Standard Library
- `context`
- `fmt`
- `log`
- `os/exec`
- `time`

#### Third-Party Dependencies  
- Aucune dépendance externe

#### Local Dependencies
- `./interfaces`
- `go.uber.org/zap`

### `development\managers\dependency-manager\version_manager.go`

- **Package**: dependency
- **Total imports**: 5
- **Standard**: 3
- **Third-party**: 2 
- **Local**: 0

#### Standard Library
- `context`
- `fmt`
- `strings`

#### Third-Party Dependencies  
- `github.com/Masterminds/semver/v3`
- `github.com/email-sender-manager/interfaces`

#### Local Dependencies
- Aucune dépendance locale

### `development\managers\deployment-manager\development\deployment_manager.go`

- **Package**: main
- **Total imports**: 11
- **Standard**: 8
- **Third-party**: 0 
- **Local**: 3

#### Standard Library
- `context`
- `fmt`
- `io/ioutil`
- `log`
- `os`
- `os/exec`
- `strings`
- `time`

#### Third-Party Dependencies  
- Aucune dépendance externe

#### Local Dependencies
- `encoding/json`
- `path/filepath`
- `go.uber.org/zap`

### `development\managers\email-manager\email_manager.go`

- **Package**: email
- **Total imports**: 11
- **Standard**: 5
- **Third-party**: 4 
- **Local**: 2

#### Standard Library
- `context`
- `fmt`
- `log`
- `sync`
- `time`

#### Third-Party Dependencies  
- `github.com/google/uuid`
- `github.com/email-sender-manager/interfaces`
- `gopkg.in/gomail.v2`
- `github.com/robfig/cron/v3`

#### Local Dependencies
- `crypto/tls`
- `go.uber.org/zap`

### `development\managers\email-manager\queue_manager.go`

- **Package**: email
- **Total imports**: 8
- **Standard**: 4
- **Third-party**: 3 
- **Local**: 1

#### Standard Library
- `context`
- `fmt`
- `sync`
- `time`

#### Third-Party Dependencies  
- `github.com/google/uuid`
- `github.com/email-sender-manager/interfaces`
- `github.com/robfig/cron/v3`

#### Local Dependencies
- `go.uber.org/zap`

### `development\managers\email-manager\template_manager.go`

- **Package**: email
- **Total imports**: 9
- **Standard**: 5
- **Third-party**: 2 
- **Local**: 2

#### Standard Library
- `context`
- `fmt`
- `strings`
- `sync`
- `time`

#### Third-Party Dependencies  
- `github.com/google/uuid`
- `github.com/email-sender-manager/interfaces`

#### Local Dependencies
- `html/template`
- `go.uber.org/zap`

### `development\managers\git-workflow-manager\git_workflow_manager.go`

- **Package**: gitworkflowmanager
- **Total imports**: 10
- **Standard**: 5
- **Third-party**: 5 
- **Local**: 0

#### Standard Library
- `context`
- `fmt`
- `log`
- `sync`
- `time`

#### Third-Party Dependencies  
- `github.com/email-sender/git-workflow-manager/internal/branch`
- `github.com/email-sender/git-workflow-manager/internal/commit`
- `github.com/email-sender/git-workflow-manager/internal/pr`
- `github.com/email-sender/git-workflow-manager/internal/webhook`
- `github.com/email-sender/managers/interfaces`

#### Local Dependencies
- Aucune dépendance locale

### `development\managers\git-workflow-manager\internal\branch\manager.go`

- **Package**: branch
- **Total imports**: 8
- **Standard**: 5
- **Third-party**: 3 
- **Local**: 0

#### Standard Library
- `context`
- `fmt`
- `log`
- `strings`
- `time`

#### Third-Party Dependencies  
- `github.com/email-sender/managers/interfaces`
- `github.com/go-git/go-git/v5`
- `github.com/go-git/go-git/v5/plumbing`

#### Local Dependencies
- Aucune dépendance locale

### `development\managers\git-workflow-manager\internal\commit\manager.go`

- **Package**: commit
- **Total imports**: 10
- **Standard**: 5
- **Third-party**: 4 
- **Local**: 1

#### Standard Library
- `context`
- `fmt`
- `log`
- `strings`
- `time`

#### Third-Party Dependencies  
- `github.com/go-git/go-git/v5`
- `github.com/go-git/go-git/v5/plumbing`
- `github.com/go-git/go-git/v5/plumbing/object`
- `github.com/email-sender/managers/interfaces`

#### Local Dependencies
- `regexp`

### `development\managers\git-workflow-manager\internal\pr\manager.go`

- **Package**: pr
- **Total imports**: 8
- **Standard**: 5
- **Third-party**: 3 
- **Local**: 0

#### Standard Library
- `context`
- `fmt`
- `log`
- `strings`
- `time`

#### Third-Party Dependencies  
- `github.com/email-sender/managers/interfaces`
- `github.com/google/go-github/v58/github`
- `golang.org/x/oauth2`

#### Local Dependencies
- Aucune dépendance locale

### `development\managers\git-workflow-manager\internal\webhook\manager.go`

- **Package**: webhook
- **Total imports**: 13
- **Standard**: 7
- **Third-party**: 1 
- **Local**: 5

#### Standard Library
- `context`
- `fmt`
- `io`
- `log`
- `net/http`
- `strings`
- `time`

#### Third-Party Dependencies  
- `github.com/email-sender/managers/interfaces`

#### Local Dependencies
- `bytes`
- `crypto/hmac`
- `crypto/sha256`
- `encoding/hex`
- `encoding/json`

### `development\managers\integrated-manager\conformity_manager.go`

- **Package**: integratedmanager
- **Total imports**: 9
- **Standard**: 5
- **Third-party**: 1 
- **Local**: 3

#### Standard Library
- `context`
- `fmt`
- `strings`
- `sync`
- `time`

#### Third-Party Dependencies  
- `github.com/google/uuid`

#### Local Dependencies
- `encoding/json`
- `math`
- `go.uber.org/zap`

### `development\managers\integrated-manager\manager_hooks.go`

- **Package**: integratedmanager
- **Total imports**: 4
- **Standard**: 4
- **Third-party**: 0 
- **Local**: 0

#### Standard Library
- `fmt`
- `log`
- `strings`
- `time`

#### Third-Party Dependencies  
- Aucune dépendance externe

#### Local Dependencies
- Aucune dépendance locale

### `development\managers\integration-manager\integration_manager.go`

- **Package**: integration_manager
- **Total imports**: 16
- **Standard**: 8
- **Third-party**: 3 
- **Local**: 5

#### Standard Library
- `context`
- `fmt`
- `io`
- `net/http`
- `net/url`
- `strings`
- `sync`
- `time`

#### Third-Party Dependencies  
- `github.com/google/uuid`
- `github.com/sirupsen/logrus`
- `github.com/your-org/email-sender/development/managers/interfaces`

#### Local Dependencies
- `crypto/rand`
- `crypto/hmac`
- `crypto/sha256`
- `encoding/hex`
- `encoding/json`

### `development\managers\interfaces\manager_common.go`

- **Package**: interfaces
- **Total imports**: 2
- **Standard**: 2
- **Third-party**: 0 
- **Local**: 0

#### Standard Library
- `context`
- `time`

#### Third-Party Dependencies  
- Aucune dépendance externe

#### Local Dependencies
- Aucune dépendance locale

### `development\managers\maintenance-manager\src\cleanup\cleanup_manager.go`

- **Package**: cleanup
- **Total imports**: 11
- **Standard**: 6
- **Third-party**: 2 
- **Local**: 3

#### Standard Library
- `context`
- `fmt`
- `io`
- `os`
- `strings`
- `time`

#### Third-Party Dependencies  
- `github.com/email-sender/maintenance-manager/src/ai`
- `github.com/email-sender/maintenance-manager/src/core`

#### Local Dependencies
- `crypto/md5`
- `path/filepath`
- `sort`

### `development\managers\maintenance-manager\src\core\maintenance_manager.go`

- **Package**: core
- **Total imports**: 7
- **Standard**: 4
- **Third-party**: 2 
- **Local**: 1

#### Standard Library
- `context`
- `fmt`
- `sync`
- `time`

#### Third-Party Dependencies  
- `github.com/sirupsen/logrus`
- `gopkg.in/yaml.v3`

#### Local Dependencies
- `path/filepath`

### `development\managers\maintenance-manager\src\integration\manager_coordinator.go`

- **Package**: integration
- **Total imports**: 6
- **Standard**: 4
- **Third-party**: 1 
- **Local**: 1

#### Standard Library
- `context`
- `fmt`
- `sync`
- `time`

#### Third-Party Dependencies  
- `github.com/sirupsen/logrus`

#### Local Dependencies
- `./interfaces`

### `development\managers\maintenance-manager\src\vector\qdrant_manager.go`

- **Package**: vector
- **Total imports**: 7
- **Standard**: 4
- **Third-party**: 2 
- **Local**: 1

#### Standard Library
- `context`
- `fmt`
- `net/http`
- `time`

#### Third-Party Dependencies  
- `github.com/qdrant/go-client/qdrant`
- `github.com/email-sender/maintenance-manager/src/core`

#### Local Dependencies
- `go.uber.org/zap`

### `development\managers\monitoring-manager\development\monitoring_manager.go`

- **Package**: main
- **Total imports**: 7
- **Standard**: 5
- **Third-party**: 0 
- **Local**: 2

#### Standard Library
- `context`
- `fmt`
- `log`
- `sync`
- `time`

#### Third-Party Dependencies  
- Aucune dépendance externe

#### Local Dependencies
- `runtime`
- `go.uber.org/zap`

### `development\managers\n8n-manager\n8n_manager.go`

- **Package**: n8nmanager
- **Total imports**: 11
- **Standard**: 7
- **Third-party**: 1 
- **Local**: 3

#### Standard Library
- `context`
- `fmt`
- `io`
- `net/http`
- `strings`
- `sync`
- `time`

#### Third-Party Dependencies  
- `github.com/google/uuid`

#### Local Dependencies
- `encoding/json`
- `go.uber.org/zap`
- `	errormanager `

### `development\managers\notification-manager\alert_manager.go`

- **Package**: notification
- **Total imports**: 7
- **Standard**: 4
- **Third-party**: 2 
- **Local**: 1

#### Standard Library
- `context`
- `fmt`
- `sync`
- `time`

#### Third-Party Dependencies  
- `github.com/google/uuid`
- `github.com/email-sender-notification-manager/interfaces`

#### Local Dependencies
- `go.uber.org/zap`

### `development\managers\notification-manager\channel_manager.go`

- **Package**: notification
- **Total imports**: 7
- **Standard**: 4
- **Third-party**: 2 
- **Local**: 1

#### Standard Library
- `context`
- `fmt`
- `sync`
- `time`

#### Third-Party Dependencies  
- `github.com/google/uuid`
- `github.com/email-sender-notification-manager/interfaces`

#### Local Dependencies
- `go.uber.org/zap`

### `development\managers\notification-manager\notification_manager.go`

- **Package**: notification
- **Total imports**: 8
- **Standard**: 4
- **Third-party**: 3 
- **Local**: 1

#### Standard Library
- `context`
- `fmt`
- `sync`
- `time`

#### Third-Party Dependencies  
- `github.com/google/uuid`
- `github.com/email-sender-notification-manager/interfaces`
- `github.com/robfig/cron/v3`

#### Local Dependencies
- `go.uber.org/zap`

### `development\managers\process-manager\process_manager.go`

- **Package**: processmanager
- **Total imports**: 10
- **Standard**: 6
- **Third-party**: 2 
- **Local**: 2

#### Standard Library
- `context`
- `fmt`
- `os`
- `os/exec`
- `sync`
- `time`

#### Third-Party Dependencies  
- `github.com/email-sender/managers/error-manager`
- `github.com/google/uuid`

#### Local Dependencies
- `syscall`
- `go.uber.org/zap`

### `development\managers\roadmap-manager\roadmap-cli\keybinds\config_manager.go`

- **Package**: keybinds
- **Total imports**: 5
- **Standard**: 3
- **Third-party**: 0 
- **Local**: 2

#### Standard Library
- `fmt`
- `os`
- `time`

#### Third-Party Dependencies  
- Aucune dépendance externe

#### Local Dependencies
- `encoding/json`
- `path/filepath`

### `development\managers\roadmap-manager\roadmap-cli\storage\manager.go`

- **Package**: storage
- **Total imports**: 5
- **Standard**: 2
- **Third-party**: 0 
- **Local**: 3

#### Standard Library
- `os`
- `time`

#### Third-Party Dependencies  
- Aucune dépendance externe

#### Local Dependencies
- `encoding/json`
- `path/filepath`
- `email_sender/cmd/roadmap-cli/types`

### `development\managers\roadmap-manager\roadmap-cli\tui\navigation\manager.go`

- **Package**: navigation
- **Total imports**: 9
- **Standard**: 5
- **Third-party**: 1 
- **Local**: 3

#### Standard Library
- `context`
- `fmt`
- `os`
- `sync`
- `time`

#### Third-Party Dependencies  
- `github.com/charmbracelet/bubbletea`

#### Local Dependencies
- `encoding/json`
- `path/filepath`
- `sort`

### `development\managers\roadmap-manager\roadmap-cli\tui\navigation\mode_manager.go`

- **Package**: navigation
- **Total imports**: 7
- **Standard**: 4
- **Third-party**: 2 
- **Local**: 1

#### Standard Library
- `context`
- `fmt`
- `sync`
- `time`

#### Third-Party Dependencies  
- `github.com/google/uuid`
- `github.com/charmbracelet/bubbletea`

#### Local Dependencies
- `go.uber.org/zap`

### `development\managers\script-manager\script_manager.go`

- **Package**: scriptmanager
- **Total imports**: 13
- **Standard**: 8
- **Third-party**: 2 
- **Local**: 3

#### Standard Library
- `context`
- `fmt`
- `io/ioutil`
- `os`
- `os/exec`
- `strings`
- `sync`
- `time`

#### Third-Party Dependencies  
- `github.com/google/uuid`
- `github.com/email-sender/managers/error-manager`

#### Local Dependencies
- `encoding/json`
- `runtime`
- `go.uber.org/zap`

### `development\managers\security-manager\development\security_manager.go`

- **Package**: main
- **Total imports**: 16
- **Standard**: 6
- **Third-party**: 0 
- **Local**: 10

#### Standard Library
- `context`
- `fmt`
- `io`
- `log`
- `strings`
- `time`

#### Third-Party Dependencies  
- Aucune dépendance externe

#### Local Dependencies
- `go.uber.org/zap`
- `crypto/aes`
- `crypto/cipher`
- `crypto/rand`
- `crypto/sha256`
- `encoding/base64`
- `encoding/hex`
- `regexp`
- `./interfaces`
- `go.uber.org/zap`

### `development\managers\security-manager\security_manager.go`

- **Package**: security
- **Total imports**: 19
- **Standard**: 7
- **Third-party**: 4 
- **Local**: 8

#### Standard Library
- `context`
- `fmt`
- `io`
- `log`
- `strings`
- `sync`
- `time`

#### Third-Party Dependencies  
- `github.com/email-sender-manager/interfaces`
- `github.com/google/uuid`
- `golang.org/x/crypto/bcrypt`
- `golang.org/x/time/rate`

#### Local Dependencies
- `crypto/aes`
- `crypto/cipher`
- `crypto/rand`
- `crypto/sha256`
- `encoding/base64`
- `encoding/hex`
- `regexp`
- `go.uber.org/zap`

### `development\managers\smart-variable-manager\interfaces\smart_variable_manager.go`

- **Package**: interfaces
- **Total imports**: 3
- **Standard**: 2
- **Third-party**: 1 
- **Local**: 0

#### Standard Library
- `context`
- `time`

#### Third-Party Dependencies  
- `github.com/chrlesur/Email_Sender/development/managers/interfaces`

#### Local Dependencies
- Aucune dépendance locale

### `development\managers\smart-variable-manager\smart_variable_manager.go`

- **Package**: smart_variable_manager
- **Total imports**: 7
- **Standard**: 5
- **Third-party**: 2 
- **Local**: 0

#### Standard Library
- `context`
- `fmt`
- `strings`
- `sync`
- `time`

#### Third-Party Dependencies  
- `github.com/chrlesur/Email_Sender/development/managers/smart-variable-manager/interfaces`
- `github.com/chrlesur/Email_Sender/development/managers/smart-variable-manager/internal/analyzer`

#### Local Dependencies
- Aucune dépendance locale

### `development\managers\storage-manager\development\storage_manager.go`

- **Package**: main
- **Total imports**: 11
- **Standard**: 5
- **Third-party**: 1 
- **Local**: 5

#### Standard Library
- `context`
- `fmt`
- `log`
- `net/http`
- `time`

#### Third-Party Dependencies  
- `github.com/lib/pq`

#### Local Dependencies
- `go.uber.org/zap`
- `database/sql`
- `encoding/json`
- `./interfaces`
- `go.uber.org/zap`

### `development\managers\storage-manager\storage_manager.go`

- **Package**: storage
- **Total imports**: 12
- **Standard**: 6
- **Third-party**: 4 
- **Local**: 2

#### Standard Library
- `context`
- `fmt`
- `log`
- `os`
- `sync`
- `time`

#### Third-Party Dependencies  
- `github.com/google/uuid`
- `github.com/lib/pq`
- `github.com/lib/pq`
- `github.com/email-sender-manager/interfaces`

#### Local Dependencies
- `database/sql`
- `encoding/json`

### `development\managers\template-performance-manager\interfaces\template_performance_manager.go`

- **Package**: interfaces
- **Total imports**: 2
- **Standard**: 2
- **Third-party**: 0 
- **Local**: 0

#### Standard Library
- `context`
- `time`

#### Third-Party Dependencies  
- Aucune dépendance externe

#### Local Dependencies
- Aucune dépendance locale

### `development\managers\template-performance-manager\manager.go`

- **Package**: template_performance_manager
- **Total imports**: 8
- **Standard**: 4
- **Third-party**: 4 
- **Local**: 0

#### Standard Library
- `context`
- `fmt`
- `sync`
- `time`

#### Third-Party Dependencies  
- `github.com/fmoua/email-sender/development/managers/template-performance-manager/interfaces`
- `github.com/fmoua/email-sender/development/managers/template-performance-manager/internal/analytics`
- `github.com/fmoua/email-sender/development/managers/template-performance-manager/internal/neural`
- `github.com/fmoua/email-sender/development/managers/template-performance-manager/internal/optimization`

#### Local Dependencies
- Aucune dépendance locale

### `development\managers\tools\cmd\manager-toolkit\manager_toolkit.go`

- **Package**: main
- **Total imports**: 15
- **Standard**: 5
- **Third-party**: 6 
- **Local**: 4

#### Standard Library
- `context`
- `fmt`
- `log`
- `os`
- `time`

#### Third-Party Dependencies  
- `github.com/email-sender/tools/core/registry`
- `github.com/email-sender/tools/core/toolkit`
- `github.com/email-sender/tools/operations/analysis`
- `github.com/email-sender/tools/operations/correction`
- `github.com/email-sender/tools/operations/migration`
- `github.com/email-sender/tools/operations/validation`

#### Local Dependencies
- `encoding/json`
- `flag`
- `go/token`
- `path/filepath`

### `development\managers\tools\manager_toolkit_lib.go`

- **Package**: tools
- **Total imports**: 6
- **Standard**: 3
- **Third-party**: 2 
- **Local**: 1

#### Standard Library
- `context`
- `fmt`
- `time`

#### Third-Party Dependencies  
- `github.com/email-sender/tools/core/toolkit`
- `github.com/email-sender/tools/operations/validation`

#### Local Dependencies
- `go/token`

### `development\managers\tools\manager_toolkit.go`

- **Package**: tools
- **Total imports**: 0
- **Standard**: 0
- **Third-party**: 0 
- **Local**: 0

#### Standard Library
- Aucun import standard

#### Third-Party Dependencies  
- Aucune dépendance externe

#### Local Dependencies
- Aucune dépendance locale

### `development\tools\qdrant\rag-go\pkg\types\collection_manager.go`

- **Package**: types
- **Total imports**: 3
- **Standard**: 2
- **Third-party**: 0 
- **Local**: 1

#### Standard Library
- `fmt`
- `sync`

#### Third-Party Dependencies  
- Aucune dépendance externe

#### Local Dependencies
- `encoding/json`

### `internal\evolution\manager.go`

- **Package**: evolution
- **Total imports**: 5
- **Standard**: 3
- **Third-party**: 2 
- **Local**: 0

#### Standard Library
- `context`
- `fmt`
- `time`

#### Third-Party Dependencies  
- `github.com/prometheus/client_golang/prometheus`
- `github.com/prometheus/client_golang/prometheus/promauto`

#### Local Dependencies
- Aucune dépendance locale

### `internal\monitoring\advanced-autonomy-manager.go`

- **Package**: monitoring
- **Total imports**: 5
- **Standard**: 4
- **Third-party**: 0 
- **Local**: 1

#### Standard Library
- `context`
- `fmt`
- `log`
- `time`

#### Third-Party Dependencies  
- Aucune dépendance externe

#### Local Dependencies
- `encoding/json`

### `pkg\cache\redis\reconnection_manager.go`

- **Package**: redis
- **Total imports**: 8
- **Standard**: 5
- **Third-party**: 1 
- **Local**: 2

#### Standard Library
- `context`
- `fmt`
- `log`
- `sync`
- `time`

#### Third-Party Dependencies  
- `github.com/redis/go-redis/v9`

#### Local Dependencies
- `math`
- `math/rand`

### `pkg\cache\ttl\invalidationmanager.go`

- **Package**: ttl
- **Total imports**: 3
- **Standard**: 2
- **Third-party**: 1 
- **Local**: 0

#### Standard Library
- `context`
- `fmt`

#### Third-Party Dependencies  
- `github.com/redis/go-redis/v9`

#### Local Dependencies
- Aucune dépendance locale

### `pkg\cache\ttl\manager.go`

- **Package**: ttl
- **Total imports**: 6
- **Standard**: 4
- **Third-party**: 1 
- **Local**: 1

#### Standard Library
- `context`
- `fmt`
- `sync`
- `time`

#### Third-Party Dependencies  
- `github.com/redis/go-redis/v9`

#### Local Dependencies
- `encoding/json`

### `planning-ecosystem-sync\tools\roadmap-connector\roadmap_manager_connector.go`

- **Package**: roadmapconnector
- **Total imports**: 9
- **Standard**: 7
- **Third-party**: 0 
- **Local**: 2

#### Standard Library
- `context`
- `fmt`
- `io`
- `log`
- `net/http`
- `net/url`
- `time`

#### Third-Party Dependencies  
- Aucune dépendance externe

#### Local Dependencies
- `bytes`
- `encoding/json`

### `projet\cred\dependency_manager.go`

- **Package**: main
- **Total imports**: 12
- **Standard**: 6
- **Third-party**: 2 
- **Local**: 4

#### Standard Library
- `context`
- `fmt`
- `os`
- `os/exec`
- `strings`
- `time`

#### Third-Party Dependencies  
- `github.com/google/uuid`
- `golang.org/x/mod/modfile`

#### Local Dependencies
- `encoding/json`
- `flag`
- `path/filepath`
- `go.uber.org/zap`

### `tools\alert-manager.go`

- **Package**: tools
- **Total imports**: 9
- **Standard**: 7
- **Third-party**: 0 
- **Local**: 2

#### Standard Library
- `context`
- `fmt`
- `log`
- `net/http`
- `net/smtp`
- `sync`
- `time`

#### Third-Party Dependencies  
- Aucune dépendance externe

#### Local Dependencies
- `bytes`
- `encoding/json`

## 📊 Statistiques Globales

### Répartition par Type d'Import

- **Standard Library**: 347 imports (56.5%)
- **Third-Party**: 112 imports (18.2%)
- **Local**: 155 imports (25.2%)

### Complexité par Fichier
- `development\managers\security-manager\security_manager.go`: 19 imports
- `development\managers\security-manager\development\security_manager.go`: 16 imports
- `development\managers\integration-manager\integration_manager.go`: 16 imports
- `development\managers\tools\cmd\manager-toolkit\manager_toolkit.go`: 15 imports
- `development\managers\dependency-manager\modules\import_manager.go`: 14 imports

### Dépendances Communes (utilisées dans >2 fichiers)
- `time`: 70 fichiers
- `context`: 69 fichiers
- `fmt`: 68 fichiers
- `sync`: 35 fichiers
- `go.uber.org/zap`: 27 fichiers
- `encoding/json`: 27 fichiers
- `log`: 27 fichiers
- `strings`: 27 fichiers
- `github.com/google/uuid`: 20 fichiers
- `os`: 15 fichiers
- `./interfaces`: 13 fichiers
- `path/filepath`: 12 fichiers
- `net/http`: 11 fichiers
- `io`: 9 fichiers
- `os/exec`: 8 fichiers
- `bytes`: 6 fichiers
- `github.com/email-sender-manager/interfaces`: 6 fichiers
- `database/sql`: 6 fichiers
- `encoding/hex`: 5 fichiers
- `github.com/email-sender/development/managers/contextual-memory-manager/interfaces`: 5 fichiers
- `github.com/email-sender/managers/interfaces`: 5 fichiers
- `crypto/sha256`: 5 fichiers
- `advanced-autonomy-manager/interfaces`: 5 fichiers
- `regexp`: 4 fichiers
- `github.com/contextual-memory-manager/pkg/interfaces`: 4 fichiers
- `go/token`: 3 fichiers
- `sort`: 3 fichiers
- `github.com/lib/pq`: 3 fichiers
- `math`: 3 fichiers
- `github.com/email-sender-notification-manager/interfaces`: 3 fichiers
- `flag`: 3 fichiers
- `github.com/robfig/cron/v3`: 3 fichiers
- `github.com/sirupsen/logrus`: 3 fichiers
- `github.com/redis/go-redis/v9`: 3 fichiers
- `crypto/rand`: 3 fichiers

---
*Généré par Tâche Atomique 004 - 2025-06-18 20:34:35*
