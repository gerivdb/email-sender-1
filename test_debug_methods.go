package main

import (
	"fmt"
	"runtime"
	"time"
)

// TestDebugMethods provides debugging methods for test scenarios
type TestDebugMethods struct {
	testName  string
	startTime time.Time
}

// NewTestDebugMethods creates a new test debug methods instance
func NewTestDebugMethods(testName string) *TestDebugMethods {
	return &TestDebugMethods{
		testName:  testName,
		startTime: time.Now(),
	}
}

// LogTestStart logs the start of a test
func (t *TestDebugMethods) LogTestStart() {
	fmt.Printf("=== TEST START: %s ===\n", t.testName)
	fmt.Printf("Start time: %s\n", t.startTime.Format(time.RFC3339))
}

// LogTestEnd logs the end of a test
func (t *TestDebugMethods) LogTestEnd() {
	duration := time.Since(t.startTime)
	fmt.Printf("=== TEST END: %s ===\n", t.testName)
	fmt.Printf("Duration: %v\n", duration)
}

// LogMemoryUsage logs current memory usage
func (t *TestDebugMethods) LogMemoryUsage() {
	var m runtime.MemStats
	runtime.ReadMemStats(&m)

	fmt.Printf("Memory Usage for %s:\n", t.testName)
	fmt.Printf("  Alloc: %d KB\n", m.Alloc/1024)
	fmt.Printf("  TotalAlloc: %d KB\n", m.TotalAlloc/1024)
	fmt.Printf("  Sys: %d KB\n", m.Sys/1024)
	fmt.Printf("  NumGC: %d\n", m.NumGC)
}

// LogGoroutineCount logs the current number of goroutines
func (t *TestDebugMethods) LogGoroutineCount() {
	count := runtime.NumGoroutine()
	fmt.Printf("Goroutines for %s: %d\n", t.testName, count)
}

// DebugPanic captures and logs panic information
func (t *TestDebugMethods) DebugPanic() {
	if r := recover(); r != nil {
		fmt.Printf("PANIC in %s: %v\n", t.testName, r)
		// Log stack trace
		buf := make([]byte, 4096)
		n := runtime.Stack(buf, false)
		fmt.Printf("Stack trace:\n%s\n", buf[:n])
	}
}
