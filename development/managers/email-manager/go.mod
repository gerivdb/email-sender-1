module github.com/gerivdb/email-sender-1/pkg/email

go 1.21

require (
	github.com/gerivdb/email-sender-1/managers/interfaces v0.0.0
	github.com/google/uuid v1.6.0
	go.uber.org/zap v1.27.0
)

require (
	github.com/robfig/cron/v3 v3.0.1 // indirect
	github.com/stretchr/testify v1.10.0 // indirect
	go.uber.org/multierr v1.11.0 // indirect
	gopkg.in/alexcesaro/quotedprintable.v3 v3.0.0-20150716171945-2caba252f4dc // indirect
	gopkg.in/gomail.v2 v2.0.0-20160411212932-81ebce5c23df // indirect
)

replace github.com/gerivdb/email-sender-1/managers/interfaces => ../../managers/interfaces
