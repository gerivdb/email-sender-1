// load_bench_test.go
package main

import (
	"testing"
)

func BenchmarkOrchestrationLoad(b *testing.B) {
	for i := 0; i < b.N; i++ {
		Orchestrate()
	}
}

// Fonction fictive pour l'exemple
func Orchestrate() {
	// Simulation d'une orchestration
}
