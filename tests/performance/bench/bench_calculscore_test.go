package bench

import (
	"testing"
)

func BenchmarkCalculScore(b *testing.B) {
	for i := 0; i < b.N; i++ {
		_ = i * 42
	}
}
