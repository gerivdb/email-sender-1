module github.com/email-sender/development/managers/email-manager

go 1.21

require (
	github.com/google/uuid v1.3.0
	github.com/email-sender-manager/interfaces v0.0.0
	go.uber.org/zap v1.27.0
	gopkg.in/gomail.v2 v2.0.0-20160411212932-81ebce5c23df
	github.com/robfig/cron/v3 v3.0.1
	github.com/stretchr/testify v1.10.0
)

require (
	go.uber.org/multierr v1.11.0 // indirect
	gopkg.in/alexcesaro/quotedprintable.v3 v3.0.0-20150716171945-2caba252f4dc // indirect
)

replace github.com/email-sender-manager/interfaces => ../interfaces
