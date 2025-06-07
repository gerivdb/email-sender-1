module github.com/email-sender/development/managers/dependency-manager/modules

go 1.23.9

require (
	github.com/email-sender/development/managers/interfaces v0.0.0-00010101000000-000000000000 // Placeholder version
	github.com/google/uuid v1.6.0
	go.uber.org/zap v1.27.0
	golang.org/x/mod v0.17.0 // Or a version compatible with go 1.23.9
)

require go.uber.org/multierr v1.10.0 // indirect

replace github.com/email-sender/development/managers/interfaces => ../../interfaces
