module email_sender

go 1.24.4

toolchain go1.24.4

require (
	github.com/gerivdb/email-sender-1/managers/error-manager v0.0.0-00010101000000-000000000000
	github.com/gin-gonic/gin v1.10.1
	github.com/gorilla/mux v1.8.1
	github.com/pkg/errors v0.9.1
	github.com/redis/go-redis/v9 v9.11.0
	github.com/sirupsen/logrus v1.9.3
	github.com/spf13/cobra v1.9.1
	github.com/stretchr/testify v1.10.0
	go.uber.org/zap v1.27.0
	gopkg.in/yaml.v3 v3.0.1
)

replace github.com/gerivdb/email-sender-1/managers/error-manager => ./development/managers/error-manager

replace github.com/gerivdb/email-sender-1/interfaces => ./development/managers/interfaces

replace email_sender/core/gapanalyzer => ./core/gapanalyzer

replace email_sender/pkg/common => ./pkg/common

replace email_sender/pkg/email => ./pkg/email

replace email_sender/pkg/vectorization => ./pkg/vectorization

replace email_sender/pkg/cache/redis => ./pkg/cache/redis

replace email_sender/pkg/cache/ttl => ./pkg/cache/ttl

replace email_sender/tools/operations/validation => ./tools/operations/validation

replace email_sender/tools/pkg/manager => ./tools/pkg/manager

replace email_sender/internal/monitoring => ./internal/monitoring

replace email_sender/development/managers/interfaces => ./development/managers/interfaces

replace email_sender/development/managers/dependency-manager => ./development/managers/dependency-manager

replace email_sender/development/managers/security-manager => ./development/managers/security-manager

replace email_sender/development/managers/storage-manager => ./development/managers/storage-manager

replace email_sender/development/managers/advanced-autonomy-manager/interfaces => ./development/managers/advanced-autonomy-manager/interfaces

replace email_sender/development/managers/advanced-autonomy-manager/internal/config => ./development/managers/advanced-autonomy-manager/internal/config

replace email_sender/development/managers/advanced-autonomy-manager/internal/logging => ./development/managers/advanced-autonomy-manager/internal/logging

replace email_sender/development/managers/ai-template-manager/interfaces => ./development/managers/ai-template-manager/interfaces

replace email_sender/development/managers/ai-template-manager/internal/ai => ./development/managers/ai-template-manager/internal/ai

replace email_sender/development/managers/branching-manager/interfaces => ./development/managers/branching-manager/interfaces

replace email_sender/development/managers/branching-manager/development => ./development/managers/branching-manager/development

replace email_sender/development/managers/branching-manager/ai => ./development/managers/branching-manager/ai

replace email_sender/development/managers/branching-manager/database => ./development/managers/branching-manager/database

replace email_sender/development/managers/branching-manager/git => ./development/managers/branching-manager/git

replace email_sender/development/managers/branching-manager/integrations => ./development/managers/branching-manager/integrations

replace email_sender/development/managers/contextual-memory-manager/interfaces => ./development/managers/contextual-memory-manager/interfaces

replace email_sender/development/managers/contextual-memory-manager/internal/ast => ./development/managers/contextual-memory-manager/internal/ast

replace email_sender/development/managers/contextual-memory-manager/internal/monitoring => ./development/managers/contextual-memory-manager/internal/monitoring

replace email_sender/development/managers/contextual-memory-manager/pkg/manager => ./development/managers/contextual-memory-manager/pkg/manager

replace email_sender/development/managers/contextual-memory-manager/internal/hybrid => ./development/managers/contextual-memory-manager/internal/hybrid

replace email_sender/development/managers/contextual-memory-manager/internal/indexing => ./development/managers/contextual-memory-manager/internal/indexing

replace email_sender/development/managers/contextual-memory-manager/internal/integration => ./development/managers/contextual-memory-manager/internal/integration

replace email_sender/development/managers/contextual-memory-manager/internal/retrieval => ./development/managers/contextual-memory-manager/internal/retrieval

replace email_sender/development/managers/contextual-memory-manager/pkg/interfaces => ./development/managers/contextual-memory-manager/pkg/interfaces

replace email_sender/development/managers/dependencymanager => ./development/managers/dependencymanager

replace email_sender/development/managers/error-manager => ./development/managers/error-manager

replace email_sender/development/managers/smart-variable-manager/interfaces => ./development/managers/smart-variable-manager/interfaces

replace email_sender/development/managers/smart-variable-manager/internal/analyzer => ./development/managers/smart-variable-manager/internal/analyzer

replace email_sender/development/managers/template-performance-manager/interfaces => ./development/managers/template-performance-manager/interfaces

replace email_sender/development/managers/template-performance-manager/internal/analytics => ./development/managers/template-performance-manager/internal/analytics

replace email_sender/development/managers/template-performance-manager/internal/neural => ./development/managers/template-performance-manager/internal/neural

replace email_sender/development/managers/template-performance-manager/internal/optimization => ./development/managers/template-performance-manager/internal/optimization

replace email_sender/development/managers/template-performance-manager => ./development/managers/template-performance-manager

replace email_sender/tools/operations/analysis => ./development/managers/tools/operations/analysis

replace email_sender/tools/core/registry => ./development/managers/tools/core/registry

replace email_sender/maintenance-manager/src/ai => ./development/managers/maintenance-manager/src/ai

replace email_sender/maintenance-manager/src/cleanup => ./development/managers/maintenance-manager/src/cleanup

replace email_sender/maintenance-manager/src/core => ./development/managers/maintenance-manager/src/core

replace email_sender/maintenance-manager/src/generator => ./development/managers/maintenance-manager/src/generator

replace email_sender/maintenance-manager/src/integration => ./development/managers/maintenance-manager/src/integration

replace email_sender/maintenance-manager/src/templates => ./development/managers/maintenance-manager/src/templates

replace email_sender/maintenance-manager/src/vector => ./development/managers/maintenance-manager/src/vector

replace email_sender/maintenance-manager/src/vector/qdrant => ./development/managers/maintenance-manager/src/vector/qdrant

replace email_sender/cmd/roadmap-cli/commands => ./development/managers/roadmap-manager/roadmap-cli/commands

replace email_sender/cmd/roadmap-cli/tui/panels => ./development/managers/roadmap-manager/roadmap-cli/tui/panels

replace email_sender/cmd/roadmap-cli/priority => ./development/managers/roadmap-manager/roadmap-cli/priority

replace email_sender/cmd/roadmap-cli/types => ./development/managers/roadmap-manager/roadmap-cli/types

replace email_sender/cmd/roadmap-cli/ingestion => ./development/managers/roadmap-manager/roadmap-cli/ingestion

replace email_sender/cmd/roadmap-cli/rag => ./development/managers/roadmap-manager/roadmap-cli/rag

replace email_sender/cmd/roadmap-cli/storage => ./development/managers/roadmap-manager/roadmap-cli/storage

replace email_sender/cmd/roadmap-cli/tui => ./development/managers/roadmap-manager/roadmap-cli/tui

replace email_sender/cmd/roadmap-cli/keybinds => ./development/managers/roadmap-manager/roadmap-cli/keybinds

replace email_sender/cmd/roadmap-cli/tui/models => ./development/managers/roadmap-manager/roadmap-cli/tui/models

replace github.com/gerivdb/email-sender-1/managers/integrated-manager => ./development/managers/integrated-manager

replace github.com/gerivdb/email-sender-1/git-workflow-manager/internal/branch => ./development/managers/git-workflow-manager/internal/branch

replace github.com/gerivdb/email-sender-1/git-workflow-manager/internal/commit => ./development/managers/git-workflow-manager/internal/commit

replace github.com/gerivdb/email-sender-1/git-workflow-manager/internal/pr => ./development/managers/git-workflow-manager/internal/pr

replace github.com/gerivdb/email-sender-1/git-workflow-manager/internal/webhook => ./development/managers/git-workflow-manager/internal/webhook

replace github.com/gerivdb/email-sender-1/managers/interfaces => ./development/managers/interfaces

replace github.com/your-org/email-sender/development/managers/interfaces => ./development/managers/interfaces

replace rag-go-system/pkg/client => ./tools/qdrant/rag-go/pkg/client

replace plan-generator/pkg/generator => ./development/tools/plan-generator/pkg/generator

replace plan-generator/pkg/interactive => ./development/tools/plan-generator/pkg/interactive

replace plan-generator/pkg/io => ./development/tools/plan-generator/pkg/io

replace plan-generator/pkg/models => ./development/tools/plan-generator/pkg/models

replace plan-generator/pkg/utils => ./development/tools/plan-generator/pkg/utils

replace error-resolution-pipeline/pkg/detector => ./scripts/error-resolution-pipeline/pkg/detector

replace error-resolution-pipeline/pkg/resolver => ./scripts/error-resolution-pipeline/pkg/resolver

replace docmanager/core/scanmodules => ./cmd/scanmodules

replace vscode-diagnostic-cli/config => ./cmd/vscode-diagnostic/config

require (
	github.com/beorn7/perks v1.0.1 // indirect
	github.com/bytedance/sonic v1.11.6 // indirect
	github.com/bytedance/sonic/loader v0.1.1 // indirect
	github.com/cespare/xxhash/v2 v2.3.0 // indirect
	github.com/cloudwego/base64x v0.1.4 // indirect
	github.com/cloudwego/iasm v0.2.0 // indirect
	github.com/davecgh/go-spew v1.1.1 // indirect
	github.com/dgryski/go-rendezvous v0.0.0-20200823014737-9f7001d12a5f // indirect
	github.com/fsnotify/fsnotify v1.9.0 // indirect
	github.com/gabriel-vasile/mimetype v1.4.3 // indirect
	github.com/gin-contrib/sse v0.1.0 // indirect
	github.com/go-logr/logr v1.4.1 // indirect
	github.com/go-logr/stdr v1.2.2 // indirect
	github.com/go-playground/locales v0.14.1 // indirect
	github.com/go-playground/universal-translator v0.18.1 // indirect
	github.com/go-playground/validator/v10 v10.20.0 // indirect
	github.com/goccy/go-json v0.10.2 // indirect
	github.com/google/uuid v1.6.0 // indirect
	github.com/inconshreveable/mousetrap v1.1.0 // indirect
	github.com/json-iterator/go v1.1.12 // indirect
	github.com/klauspost/cpuid/v2 v2.2.7 // indirect
	github.com/leodido/go-urn v1.4.0 // indirect
	github.com/mattn/go-isatty v0.0.20 // indirect
	github.com/modern-go/concurrent v0.0.0-20180306012644-bacd9c7ef1dd // indirect
	github.com/modern-go/reflect2 v1.0.2 // indirect
	github.com/munnerz/goautoneg v0.0.0-20191010083416-a7dc8b61c822 // indirect
	github.com/pelletier/go-toml/v2 v2.2.2 // indirect
	github.com/pmezard/go-difflib v1.0.0 // indirect
	github.com/prometheus/client_golang v1.20.4 // indirect
	github.com/prometheus/client_model v0.6.1 // indirect
	github.com/prometheus/common v0.62.0 // indirect
	github.com/prometheus/procfs v0.15.1 // indirect
	github.com/qdrant/go-client v1.14.1 // indirect
	github.com/spf13/pflag v1.0.6 // indirect
	github.com/stretchr/objx v0.5.2 // indirect
	github.com/twitchyliquid64/golang-asm v0.15.1 // indirect
	github.com/ugorji/go/codec v1.2.12 // indirect
	github.com/xeipuuv/gojsonpointer v0.0.0-20180127040702-4e3ac2762d5f // indirect
	github.com/xeipuuv/gojsonreference v0.0.0-20180127040603-bd5ef7bd5415 // indirect
	github.com/xeipuuv/gojsonschema v1.2.0 // indirect
	go.opentelemetry.io/otel v1.24.0 // indirect
	go.opentelemetry.io/otel/metric v1.24.0 // indirect
	go.opentelemetry.io/otel/trace v1.24.0 // indirect
	go.uber.org/multierr v1.10.0 // indirect
	golang.org/x/arch v0.8.0 // indirect
	golang.org/x/crypto v0.39.0 // indirect
	golang.org/x/mod v0.25.0 // indirect
	golang.org/x/net v0.41.0 // indirect
	golang.org/x/oauth2 v0.24.0 // indirect
	golang.org/x/sync v0.15.0 // indirect
	golang.org/x/sys v0.33.0 // indirect
	golang.org/x/text v0.26.0 // indirect
	golang.org/x/time v0.3.0 // indirect
	golang.org/x/tools v0.34.0 // indirect
	google.golang.org/genproto/googleapis/rpc v0.0.0-20240827150818-7e3bb234dfed // indirect
	google.golang.org/grpc v1.66.0 // indirect
	google.golang.org/protobuf v1.36.5 // indirect
	gopkg.in/yaml.v2 v2.4.0 // indirect
)
