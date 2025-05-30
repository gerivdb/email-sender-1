package main

import (
	"encoding/json"
	"fmt"
	"time"
)

// Simple test structure to verify timestamp precision
type TestDoc struct {
	CreatedAt time.Time `json:"created_at"`
}

func main() {
	// Create a timestamp with microsecond precision
	now := time.Now()
	fmt.Printf("Original timestamp: %v\n", now)

	// Test with RFC3339 (seconds precision)
	rfc3339Formatted := now.Format(time.RFC3339)
	parsed3339, _ := time.Parse(time.RFC3339, rfc3339Formatted)
	fmt.Printf("RFC3339 formatted: %s\n", rfc3339Formatted)
	fmt.Printf("RFC3339 parsed: %v\n", parsed3339)
	fmt.Printf("RFC3339 precision lost: %v\n", !now.Equal(parsed3339))

	// Test with RFC3339Nano (nanosecond precision)
	rfc3339NanoFormatted := now.Format(time.RFC3339Nano)
	parsed3339Nano, _ := time.Parse(time.RFC3339Nano, rfc3339NanoFormatted)
	fmt.Printf("RFC3339Nano formatted: %s\n", rfc3339NanoFormatted)
	fmt.Printf("RFC3339Nano parsed: %v\n", parsed3339Nano)
	fmt.Printf("RFC3339Nano precision preserved: %v\n", now.Equal(parsed3339Nano))

	// Test JSON serialization with RFC3339Nano
	doc := TestDoc{CreatedAt: now}
	jsonData, _ := json.Marshal(doc)
	fmt.Printf("JSON serialized: %s\n", string(jsonData))

	var docParsed TestDoc
	json.Unmarshal(jsonData, &docParsed)
	fmt.Printf("JSON deserialized: %v\n", docParsed.CreatedAt)
	fmt.Printf("JSON round-trip precision preserved: %v\n", now.Equal(docParsed.CreatedAt))
}
