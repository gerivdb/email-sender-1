// core/docmanager/validation/benchmark_test.go
// Benchmarks validation et conflits DocManager v66

package validation

import (
	"context"
	"testing"
)

func BenchmarkValidateDocument(b *testing.B) {
	for i := 0; i < b.N; i++ {
		_ = ValidateDocument(context.Background(), &Document{})
	}
}

func BenchmarkDetectConflicts(b *testing.B) {
	for i := 0; i < b.N; i++ {
		_, _ = DetectConflicts(&Document{})
	}
}
