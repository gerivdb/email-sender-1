module github.com/email-sender/tools

go 1.23.9

require (
	github.com/email-sender/tools/core/platform v0.0.0 // Add platform as a requirement
	github.com/stretchr/testify v1.10.0
)

require (
	github.com/davecgh/go-spew v1.1.1 // indirect
	github.com/kr/pretty v0.3.1 // indirect
	github.com/pmezard/go-difflib v1.0.0 // indirect
	gopkg.in/check.v1 v1.0.0-20180628173108-788fd7840127 // indirect
	gopkg.in/yaml.v3 v3.0.1 // indirect
)

replace github.com/email-sender/tools/core/platform => ./core/platform // Add replace directive
