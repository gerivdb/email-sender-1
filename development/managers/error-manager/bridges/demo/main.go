// Demo program for Section 8.2 Real-time Bridge Implementation
package main

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"time"

	"bridges"
)

func main() {
	fmt.Println("=== Section 8.2 Real-time Bridge Demonstration ===")
	fmt.Println("Optimisation Surveillance Temps Réel - plan-dev-v42")

	// Create demo configuration
	config := bridges.DefaultRealtimeBridgeConfig()
	config.HTTPPort = 8088
	config.LogFilePath = "./demo_realtime.log"
	config.DebounceMs = 300 // Faster response for demo
	config.MaxEvents = 50

	// Create temporary demo directory for file watching
	demoDir := "./demo_watch"
	if err := os.MkdirAll(demoDir, 0755); err != nil {
		log.Fatalf("Failed to create demo directory: %v", err)
	}
	defer os.RemoveAll(demoDir)

	config.WatchPaths = []string{demoDir}

	fmt.Printf("📁 Created demo directory: %s\n", demoDir)
	fmt.Printf("🌐 HTTP Server will run on port: %d\n", config.HTTPPort)

	// Create and start the real-time bridge
	bridge, err := bridges.NewRealtimeBridge(config)
	if err != nil {
		log.Fatalf("Failed to create real-time bridge: %v", err)
	}
	defer bridge.Stop()

	fmt.Println("🚀 Starting Real-time Bridge...")
	if err := bridge.Start(); err != nil {
		log.Fatalf("Failed to start bridge: %v", err)
	}

	// Give the bridge time to start
	time.Sleep(500 * time.Millisecond)

	// Demonstrate different aspects of the real-time bridge
	demonstrateHTTPEvents(config.HTTPPort)
	demonstrateFileWatching(demoDir)
	demonstrateStatusMonitoring(config.HTTPPort)

	// Show final statistics
	showFinalStatistics(bridge, config.HTTPPort)

	fmt.Println("✅ Real-time Bridge Demonstration Complete!")
	fmt.Println("📋 Check demo_realtime.log for detailed logs")
}

// demonstrateHTTPEvents shows HTTP event reception from PowerShell scripts
func demonstrateHTTPEvents(port int) {
	fmt.Println("\n--- Demonstration 1: HTTP Event Reception ---")
	fmt.Println("📡 Simulating PowerShell script events via HTTP...")

	baseURL := fmt.Sprintf("http://localhost:%d", port)

	// Test events simulating different scenarios
	testEvents := []bridges.RealtimeEvent{
		{
			Type:       "duplication_alert",
			Source:     "Manage-Duplications.ps1",
			Severity:   "high",
			Message:    "Duplicate function detected in PowerShell script",
			ScriptType: "powershell",
			Metadata: map[string]interface{}{
				"function_name":     "Find-CodeDuplication",
				"duplication_score": 0.95,
				"file_count":        4,
			},
		},
		{
			Type:       "error_detected",
			Source:     "development/managers/error-manager/analyzer.go",
			Severity:   "medium",
			Message:    "Potential memory leak detected in error analyzer",
			ScriptType: "go",
			Metadata: map[string]interface{}{
				"memory_usage": "250MB",
				"goroutines":   15,
				"line_number":  142,
			},
		},
		{
			Type:       "file_change",
			Source:     "development/scripts/test-script.py",
			Severity:   "low",
			Message:    "Python script modified - checking for syntax errors",
			ScriptType: "python",
			Metadata: map[string]interface{}{
				"lines_changed": 23,
				"file_size":     "15KB",
				"last_test":     "passed",
			},
		},
		{
			Type:       "duplication_alert",
			Source:     "development/managers/error-manager/types.go",
			Severity:   "critical",
			Message:    "Critical duplication found - immediate attention required",
			ScriptType: "go",
			Metadata: map[string]interface{}{
				"duplicate_lines":  150,
				"similarity_score": 0.98,
				"impact_level":     "high",
				"suggested_action": "refactor",
			},
		},
	}

	for i, event := range testEvents {
		fmt.Printf("  📤 Sending event %d: %s (%s severity)\n",
			i+1, event.Type, event.Severity)

		eventJSON, _ := json.Marshal(event)
		resp, err := http.Post(baseURL+"/events", "application/json", bytes.NewBuffer(eventJSON))
		if err != nil {
			fmt.Printf("    ❌ Failed to send event: %v\n", err)
			continue
		}
		resp.Body.Close()

		if resp.StatusCode == http.StatusOK {
			fmt.Printf("    ✅ Event accepted by bridge\n")
		} else {
			fmt.Printf("    ⚠️  Event rejected with status: %d\n", resp.StatusCode)
		}

		time.Sleep(200 * time.Millisecond)
	}

	fmt.Printf("📊 Sent %d test events to demonstrate HTTP reception\n", len(testEvents))
}

// demonstrateFileWatching shows real-time file system monitoring
func demonstrateFileWatching(watchDir string) {
	fmt.Println("\n--- Demonstration 2: File System Watching ---")
	fmt.Println("👁️  Monitoring file system changes in real-time...")

	// Create various file types to demonstrate different script monitoring
	testFiles := []struct {
		name    string
		content string
		action  string
	}{
		{"test-script.ps1", "# PowerShell test script\nGet-Process | Where-Object { $_.CPU -gt 100 }", "create"},
		{"analyzer.go", "package main\n\nfunc main() {\n\tfmt.Println(\"Hello Go\")\n}", "create"},
		{"utilities.py", "# Python utilities\ndef calculate_metrics():\n    pass", "create"},
		{"config.json", "{\"debug\": true, \"port\": 8080}", "create"},
	}

	for i, file := range testFiles {
		filePath := filepath.Join(watchDir, file.name)
		fmt.Printf("  📝 Creating file %d: %s\n", i+1, file.name)

		if err := os.WriteFile(filePath, []byte(file.content), 0644); err != nil {
			fmt.Printf("    ❌ Failed to create file: %v\n", err)
			continue
		}

		fmt.Printf("    ✅ File created successfully\n")
		time.Sleep(400 * time.Millisecond) // Allow debounce time
	}

	// Modify some files to show update detection
	fmt.Println("  🔄 Modifying files to test change detection...")

	modifyFile := filepath.Join(watchDir, "analyzer.go")
	newContent := "package main\n\nimport \"fmt\"\n\nfunc main() {\n\tfmt.Println(\"Updated Go code\")\n}"
	if err := os.WriteFile(modifyFile, []byte(newContent), 0644); err != nil {
		fmt.Printf("    ❌ Failed to modify file: %v\n", err)
	} else {
		fmt.Printf("    ✅ Modified analyzer.go\n")
	}

	time.Sleep(400 * time.Millisecond)

	// Delete a file to show deletion detection
	deleteFile := filepath.Join(watchDir, "config.json")
	if err := os.Remove(deleteFile); err != nil {
		fmt.Printf("    ❌ Failed to delete file: %v\n", err)
	} else {
		fmt.Printf("    ✅ Deleted config.json\n")
	}

	time.Sleep(400 * time.Millisecond)

	fmt.Println("📁 File system monitoring demonstration complete")
}

// demonstrateStatusMonitoring shows bridge status and monitoring capabilities
func demonstrateStatusMonitoring(port int) {
	fmt.Println("\n--- Demonstration 3: Status Monitoring ---")
	fmt.Println("📊 Checking bridge status and health...")

	baseURL := fmt.Sprintf("http://localhost:%d", port)

	// Check health endpoint
	fmt.Println("  💚 Checking health status...")
	resp, err := http.Get(baseURL + "/health")
	if err != nil {
		fmt.Printf("    ❌ Health check failed: %v\n", err)
		return
	}
	defer resp.Body.Close()

	var health map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&health); err != nil {
		fmt.Printf("    ❌ Failed to decode health response: %v\n", err)
		return
	}

	fmt.Printf("    ✅ Bridge is healthy - Status: %v\n", health["status"])
	fmt.Printf("    📈 Event count: %.0f\n", health["event_count"])

	// Check detailed status
	fmt.Println("  📋 Fetching detailed status...")
	resp, err = http.Get(baseURL + "/status")
	if err != nil {
		fmt.Printf("    ❌ Status check failed: %v\n", err)
		return
	}
	defer resp.Body.Close()

	var status map[string]interface{}
	if err := json.NewDecoder(resp.Body).Decode(&status); err != nil {
		fmt.Printf("    ❌ Failed to decode status response: %v\n", err)
		return
	}

	fmt.Printf("    📊 Buffer size: %.0f/%.0f events\n",
		status["buffer_size"], status["buffer_capacity"])
	fmt.Printf("    👁️  File watching: %v\n", status["file_watching"])
	fmt.Printf("    🌐 HTTP server: %v\n", status["http_server"])

	// Show configuration details
	if config, ok := status["config"].(map[string]interface{}); ok {
		fmt.Printf("    ⚙️  HTTP Port: %.0f\n", config["http_port"])
		fmt.Printf("    ⏱️  Debounce: %.0fms\n", config["debounce_ms"])
		fmt.Printf("    📝 Log file: %s\n", config["log_file_path"])
	}
}

// showFinalStatistics displays comprehensive statistics about the demonstration
func showFinalStatistics(bridge *bridges.RealtimeBridge, port int) {
	fmt.Println("\n--- Final Statistics ---")

	// Get current event buffer
	events := bridge.GetEvents()
	totalEvents := bridge.GetEventCount()

	fmt.Printf("📊 Total events processed: %d\n", totalEvents)
	fmt.Printf("📦 Events in buffer: %d\n", len(events))

	// Analyze event types
	eventTypes := make(map[string]int)
	scriptTypes := make(map[string]int)
	severityLevels := make(map[string]int)

	for _, event := range events {
		eventTypes[event.Type]++
		scriptTypes[event.ScriptType]++
		severityLevels[event.Severity]++
	}

	fmt.Println("\n📈 Event Analysis:")
	fmt.Println("  Event Types:")
	for eventType, count := range eventTypes {
		fmt.Printf("    - %s: %d\n", eventType, count)
	}

	fmt.Println("  Script Types:")
	for scriptType, count := range scriptTypes {
		fmt.Printf("    - %s: %d\n", scriptType, count)
	}

	fmt.Println("  Severity Levels:")
	for severity, count := range severityLevels {
		fmt.Printf("    - %s: %d\n", severity, count)
	}

	// Show recent high-priority events
	fmt.Println("\n🚨 High-Priority Events:")
	highPriorityCount := 0
	for _, event := range events {
		if event.Severity == "high" || event.Severity == "critical" {
			fmt.Printf("  - %s: %s (%s)\n", event.Type, event.Message, event.Severity)
			highPriorityCount++
		}
	}

	if highPriorityCount == 0 {
		fmt.Println("  ✅ No high-priority events detected")
	} else {
		fmt.Printf("  ⚠️  %d high-priority events require attention\n", highPriorityCount)
	}

	fmt.Println("\n🔧 Integration Points Demonstrated:")
	fmt.Println("  ✅ HTTP API for PowerShell script events")
	fmt.Println("  ✅ Real-time file system monitoring")
	fmt.Println("  ✅ Event buffering and pattern analysis")
	fmt.Println("  ✅ Health and status monitoring")
	fmt.Println("  ✅ Multi-language script detection (Go, PowerShell, Python)")
	fmt.Println("  ✅ Severity-based event prioritization")
	fmt.Println("  ✅ Configurable debouncing and buffering")

	fmt.Printf("\n🌐 Bridge accessible at: http://localhost:%d/status\n", port)
}
