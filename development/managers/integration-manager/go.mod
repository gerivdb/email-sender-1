module github.com/your-org/email-sender/development/managers/integration-manager

go 1.22

toolchain go1.23.9

require (
	github.com/sirupsen/logrus v1.9.3
	github.com/stretchr/testify v1.8.4
	github.com/your-org/email-sender/development/managers/interfaces v0.0.0
)

require (
	github.com/davecgh/go-spew v1.1.1 // indirect
	github.com/pmezard/go-difflib v1.0.0 // indirect
	golang.org/x/sys v0.0.0-20220715151400-c0bba94af5f8 // indirect
	gopkg.in/yaml.v3 v3.0.1 // indirect
)

replace github.com/your-org/email-sender/development/managers/interfaces => ../interfaces
