package conflict

import (
	"testing"
)

func TestPerfMetrics(t *testing.T) {
	PerfMetrics.Init()
	IncConflictsDetected()
	IncDetectionDuration(100)
	if PerfMetrics.Get("conflicts_detected").String() != "1" {
		t.Error("Expected conflicts_detected to be 1")
	}
	if PerfMetrics.Get("detection_duration_ms").String() != "100" {
		t.Error("Expected detection_duration_ms to be 100")
	}
}
