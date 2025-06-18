go test ./pkg/fmoua/... -v -coverprofile=coverage.out
go tool cover -func coverage.out
