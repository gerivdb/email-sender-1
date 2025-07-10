// auth_bench_test.go
package main

import (
	"testing"
)

func BenchmarkAuthModule(b *testing.B) {
	for i := 0; i < b.N; i++ {
		AuthModule("admin", "admin")
	}
}

// Fonction fictive pour l'exemple
func AuthModule(username, password string) bool {
	return username == "admin" && password == "admin"
}
