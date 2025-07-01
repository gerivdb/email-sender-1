module github.com/email-sender/tools

go 1.23.9

require (
	github.com/stretchr/testify v1.10.0
	github.com/email-sender/tools/core/platform v0.0.0 // Add platform as a requirement
)

require (
	github.com/davecgh/go-spew v1.1.1 // indirect
	github.com/pmezard/go-difflib v1.0.0 // indirect
	gopkg.in/yaml.v3 v3.0.1 // indirect
)

replace github.com/email-sender/tools/core/platform => ./core/platform // Add replace directive
