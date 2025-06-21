package conflict

import (
	"encoding/json"
	"net/http"
)

// DashboardMetrics exposes metrics via HTTP endpoints.
func DashboardMetricsHandler(w http.ResponseWriter, r *http.Request) {
	metrics := map[string]interface{}{
		"conflicts": 42,
		"alerts":    3,
	}
	w.Header().Set("Content-Type", "application/json")
	_ = json.NewEncoder(w).Encode(metrics)
}
