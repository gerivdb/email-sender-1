package conflict

import (
	"expvar"
)

// PerfMetrics exposes performance metrics for conflict detection.
var PerfMetrics = expvar.NewMap("conflict_detection_metrics")

func IncConflictsDetected() {
	PerfMetrics.Add("conflicts_detected", 1)
}

func IncDetectionDuration(ms int64) {
	PerfMetrics.Add("detection_duration_ms", ms)
}
