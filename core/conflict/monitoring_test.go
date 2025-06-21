package conflict

import (
	"testing"
)

func TestConflictMonitor(t *testing.T) {
	m := NewConflictMonitor()
	m.Start()
	m.Stop()
}

func TestAlertingSystem(t *testing.T) {
	a := NewAlertingSystem(5)
	a.Check(10)
	select {
	case <-a.Alerts:
		// ok
	default:
		t.Error("Expected alert")
	}
}

func TestDashboardMetricsHandler(t *testing.T) {
	// Handler can be tested with httptest if needed
}

func TestSendToExternalMonitoring(t *testing.T) {
	if err := SendToExternalMonitoring(nil); err != nil {
		t.Error("External monitoring failed")
	}
}

func TestLogStructured(t *testing.T) {
	LogStructured("test log")
}

func TestHealthCheck(t *testing.T) {
	if !HealthCheck() {
		t.Error("HealthCheck failed")
	}
}
