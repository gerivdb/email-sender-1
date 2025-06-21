package integration

import (
	"testing"
	"time"
)

func BenchmarkPerformance(b *testing.B) {
	for i := 0; i < b.N; i++ {
		time.Sleep(1 * time.Millisecond)
	}
}
