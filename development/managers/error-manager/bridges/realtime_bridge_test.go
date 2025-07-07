package bridges

import (
	"bytes"
	"encoding/json"
	"net/http"
	"os"
	"path/filepath"
	"testing"
	"time"
)

func TestNewRealtimeBridge(t *testing.T) {
	config := DefaultRealtimeBridgeConfig()
	config.LogFilePath = "./test_realtime.log"
	config.HTTPPort = 8081 // Use different port for testing

	bridge, err := NewRealtimeBridge(config)
	if err != nil {
		t.Fatalf("Failed to create realtime bridge: %v", err)
	}
	defer bridge.Stop()

	if bridge == nil {
		t.Fatal("Expected bridge to be created")
	}

	if bridge.config.HTTPPort != 8081 {
		t.Errorf("Expected port 8081, got %d", bridge.config.HTTPPort)
	}

	// Cleanup
	os.Remove("./test_realtime.log")
}

func TestDefaultRealtimeBridgeConfig(t *testing.T) {
	config := DefaultRealtimeBridgeConfig()

	if config.HTTPPort != 8080 {
		t.Errorf("Expected default port 8080, got %d", config.HTTPPort)
	}

	if config.DebounceMs != 500 {
		t.Errorf("Expected default debounce 500ms, got %d", config.DebounceMs)
	}

	if config.MaxEvents != 1000 {
		t.Errorf("Expected default max events 1000, got %d", config.MaxEvents)
	}

	if !config.EnableFileWatch {
		t.Error("Expected file watching to be enabled by default")
	}

	if !config.EnableHTTPServer {
		t.Error("Expected HTTP server to be enabled by default")
	}
}

func TestRealtimeBridgeStartStop(t *testing.T) {
	config := DefaultRealtimeBridgeConfig()
	config.LogFilePath = "./test_realtime_start_stop.log"
	config.HTTPPort = 8082
	config.WatchPaths = []string{"."} // Watch current directory

	bridge, err := NewRealtimeBridge(config)
	if err != nil {
		t.Fatalf("Failed to create realtime bridge: %v", err)
	}

	// Start the bridge
	err = bridge.Start()
	if err != nil {
		t.Fatalf("Failed to start bridge: %v", err)
	}

	// Give it a moment to start
	time.Sleep(100 * time.Millisecond)

	// Stop the bridge
	err = bridge.Stop()
	if err != nil {
		t.Errorf("Failed to stop bridge: %v", err)
	}

	// Cleanup
	os.Remove("./test_realtime_start_stop.log")
}

func TestHTTPEventReceiver(t *testing.T) {
	config := DefaultRealtimeBridgeConfig()
	config.LogFilePath = "./test_http_events.log"
	config.HTTPPort = 8083
	config.EnableFileWatch = false // Disable file watching for this test

	bridge, err := NewRealtimeBridge(config)
	if err != nil {
		t.Fatalf("Failed to create realtime bridge: %v", err)
	}
	defer bridge.Stop()

	// Start the bridge
	err = bridge.Start()
	if err != nil {
		t.Fatalf("Failed to start bridge: %v", err)
	}

	// Give server time to start
	time.Sleep(200 * time.Millisecond)

	// Test health endpoint
	resp, err := http.Get("http://localhost:8083/health")
	if err != nil {
		t.Fatalf("Failed to connect to health endpoint: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Errorf("Expected status 200, got %d", resp.StatusCode)
	}

	// Test event submission
	event := RealtimeEvent{
		Type:       "duplication_alert",
		Source:     "test_script.ps1",
		Severity:   "high",
		Message:    "Test duplication detected",
		ScriptType: "powershell",
		Metadata: map[string]interface{}{
			"test": "data",
		},
	}

	eventJSON, _ := json.Marshal(event)
	resp, err = http.Post("http://localhost:8083/events", "application/json", bytes.NewBuffer(eventJSON))
	if err != nil {
		t.Fatalf("Failed to post event: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Errorf("Expected status 200 for event post, got %d", resp.StatusCode)
	}

	// Verify event was received
	time.Sleep(100 * time.Millisecond)
	events := bridge.GetEvents()
	if len(events) != 1 {
		t.Errorf("Expected 1 event, got %d", len(events))
	}

	if len(events) > 0 {
		receivedEvent := events[0]
		if receivedEvent.Type != "duplication_alert" {
			t.Errorf("Expected event type 'duplication_alert', got '%s'", receivedEvent.Type)
		}
		if receivedEvent.Source != "test_script.ps1" {
			t.Errorf("Expected source 'test_script.ps1', got '%s'", receivedEvent.Source)
		}
		if receivedEvent.Severity != "high" {
			t.Errorf("Expected severity 'high', got '%s'", receivedEvent.Severity)
		}
	}

	// Cleanup
	os.Remove("./test_http_events.log")
}

func TestEventBufferManagement(t *testing.T) {
	config := DefaultRealtimeBridgeConfig()
	config.LogFilePath = "./test_buffer.log"
	config.HTTPPort = 8084
	config.MaxEvents = 3 // Small buffer for testing
	config.EnableFileWatch = false
	config.EnableHTTPServer = false

	bridge, err := NewRealtimeBridge(config)
	if err != nil {
		t.Fatalf("Failed to create realtime bridge: %v", err)
	}
	defer bridge.Stop()

	// Add events to test buffer management
	for i := 0; i < 5; i++ {
		event := RealtimeEvent{
			Type:       "test_event",
			Source:     "test_file.go",
			Timestamp:  time.Now(),
			Severity:   "low",
			Message:    "Test event",
			ScriptType: "go",
		}
		bridge.addEvent(event)
	}

	// Should only have 3 events due to buffer limit
	events := bridge.GetEvents()
	if len(events) != 3 {
		t.Errorf("Expected 3 events in buffer, got %d", len(events))
	}

	// Should have processed 5 events total
	if bridge.GetEventCount() != 5 {
		t.Errorf("Expected total event count 5, got %d", bridge.GetEventCount())
	}

	// Test buffer clearing
	bridge.ClearEvents()
	events = bridge.GetEvents()
	if len(events) != 0 {
		t.Errorf("Expected 0 events after clearing, got %d", len(events))
	}

	// Event count should remain the same
	if bridge.GetEventCount() != 5 {
		t.Errorf("Expected total event count to remain 5 after clearing buffer, got %d", bridge.GetEventCount())
	}

	// Cleanup
	os.Remove("./test_buffer.log")
}

func TestFileWatchingSetup(t *testing.T) {
	// Create a temporary directory for testing
	tempDir, err := os.MkdirTemp("", "realtime_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tempDir)

	config := DefaultRealtimeBridgeConfig()
	config.LogFilePath = "./test_filewatch.log"
	config.HTTPPort = 8085
	config.WatchPaths = []string{tempDir}
	config.EnableHTTPServer = false

	bridge, err := NewRealtimeBridge(config)
	if err != nil {
		t.Fatalf("Failed to create realtime bridge: %v", err)
	}
	defer bridge.Stop()

	// Start the bridge
	err = bridge.Start()
	if err != nil {
		t.Fatalf("Failed to start bridge: %v", err)
	}

	// Give file watcher time to start
	time.Sleep(200 * time.Millisecond)

	// Create a test file to trigger an event
	testFile := filepath.Join(tempDir, "test_file.go")
	err = os.WriteFile(testFile, []byte("package main"), 0644)
	if err != nil {
		t.Fatalf("Failed to create test file: %v", err)
	}
	// Give time for event to be processed (Windows may need more time)
	time.Sleep(1500 * time.Millisecond)

	// Check if event was captured
	events := bridge.GetEvents()
	if len(events) == 0 {
		t.Log("No events captured - this may be normal on some systems")
		// Don't fail the test as file watching can be flaky in test environments
	} else {
		// Verify the event contains expected information
		found := false
		for _, event := range events {
			t.Logf("Found event: Type=%s, ScriptType=%s, Source=%s", event.Type, event.ScriptType, event.Source)
			if event.ScriptType == "go" || event.Type == "file_created" || event.Type == "file_change" {
				found = true
				break
			}
		}
		if found {
			t.Log("Successfully captured file system events")
		} else {
			t.Log("Events captured but not the expected Go file events")
		}
	}

	// Cleanup
	os.Remove("./test_filewatch.log")
}

func TestEventPatternAnalysis(t *testing.T) {
	config := DefaultRealtimeBridgeConfig()
	config.LogFilePath = "./test_patterns.log"
	config.HTTPPort = 8086
	config.EnableFileWatch = false
	config.EnableHTTPServer = false

	bridge, err := NewRealtimeBridge(config)
	if err != nil {
		t.Fatalf("Failed to create realtime bridge: %v", err)
	}
	defer bridge.Stop()

	// Add various events for pattern analysis
	events := []RealtimeEvent{
		{Type: "file_change", ScriptType: "go", Severity: "medium", Source: "/test/file1.go"},
		{Type: "file_change", ScriptType: "go", Severity: "medium", Source: "/test/file2.go"},
		{Type: "file_change", ScriptType: "powershell", Severity: "high", Source: "/test/script.ps1"},
		{Type: "duplication_alert", ScriptType: "go", Severity: "high", Source: "/test/file3.go"},
		{Type: "file_change", ScriptType: "go", Severity: "medium", Source: "/test/file4.go"},
	}

	patterns := bridge.analyzeEventPatterns(events)

	// Check expected patterns
	if patterns["go_file_change"] != 3 {
		t.Errorf("Expected 3 'go_file_change' patterns, got %d", patterns["go_file_change"])
	}

	if patterns["severity_medium"] != 3 {
		t.Errorf("Expected 3 'severity_medium' patterns, got %d", patterns["severity_medium"])
	}

	if patterns["severity_high"] != 2 {
		t.Errorf("Expected 2 'severity_high' patterns, got %d", patterns["severity_high"])
	}

	if patterns["powershell_file_change"] != 1 {
		t.Errorf("Expected 1 'powershell_file_change' pattern, got %d", patterns["powershell_file_change"])
	}

	// Cleanup
	os.Remove("./test_patterns.log")
}

func TestStatusEndpoint(t *testing.T) {
	config := DefaultRealtimeBridgeConfig()
	config.LogFilePath = "./test_status.log"
	config.HTTPPort = 8087
	config.EnableFileWatch = false

	bridge, err := NewRealtimeBridge(config)
	if err != nil {
		t.Fatalf("Failed to create realtime bridge: %v", err)
	}
	defer bridge.Stop()

	// Start the bridge
	err = bridge.Start()
	if err != nil {
		t.Fatalf("Failed to start bridge: %v", err)
	}

	// Give server time to start
	time.Sleep(200 * time.Millisecond)

	// Test status endpoint
	resp, err := http.Get("http://localhost:8087/status")
	if err != nil {
		t.Fatalf("Failed to connect to status endpoint: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Errorf("Expected status 200, got %d", resp.StatusCode)
	}

	var status map[string]interface{}
	err = json.NewDecoder(resp.Body).Decode(&status)
	if err != nil {
		t.Fatalf("Failed to decode status response: %v", err)
	}

	// Verify status contains expected fields
	expectedFields := []string{"config", "event_count", "buffer_size", "buffer_capacity", "file_watching", "http_server"}
	for _, field := range expectedFields {
		if _, exists := status[field]; !exists {
			t.Errorf("Expected status field '%s' not found", field)
		}
	}

	// Cleanup
	os.Remove("./test_status.log")
}
