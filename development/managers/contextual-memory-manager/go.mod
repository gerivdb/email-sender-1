module github.com/email-sender/development/managers/contextual-memory-manager

go 1.21

require (
    github.com/email-sender/development/managers/interfaces v0.0.0
    github.com/email-sender/development/managers/error-manager v0.0.0
    github.com/email-sender/development/managers/storage-manager v0.0.0
    github.com/email-sender/development/managers/config-manager v0.0.0
    github.com/google/uuid v1.3.0
    github.com/prometheus/client_golang v1.16.0
    github.com/stretchr/testify v1.8.4
)

replace github.com/email-sender/development/managers/interfaces => ../interfaces
replace github.com/email-sender/development/managers/error-manager => ../error-manager
replace github.com/email-sender/development/managers/storage-manager => ../storage-manager
replace github.com/email-sender/development/managers/config-manager => ../config-manager
