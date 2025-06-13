module github.com/email-sender/development/managers/storage-manager/development

go 1.23.9

replace github.com/email-sender/development/managers/interfaces => ../../interfaces

require (
	github.com/lib/pq v1.10.9
	go.uber.org/zap v1.27.0
)

require (
	github.com/email-sender/development/managers/interfaces v0.0.0-00010101000000-000000000000 // indirect
	go.uber.org/multierr v1.10.0 // indirect
)
