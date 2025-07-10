package performance

import (
	"testing"
)

func BenchmarkCalculScore(b *testing.B) {
	for i := 0; i < b.N; i++ {
		// Simuler le calcul du score
		_ = i * 42
	}
}
