package errormanager

import (
	"encoding/json"
	"fmt"
	"log"
	"time"
)

// ErrorEntry represents a structured error for cataloging
type ErrorEntry struct {
	ID             string    `json:"id"`
	Timestamp      time.Time `json:"timestamp"`
	Message        string    `json:"message"`
	StackTrace     string    `json:"stack_trace"`
	Module         string    `json:"module"`
	ErrorCode      string    `json:"error_code"`
	ManagerContext string    `json:"manager_context"`
	Severity       string    `json:"severity"`
}

// Example JSON validation for ErrorEntry
func ValidateErrorEntryExample() {
	example := ErrorEntry{
		ID:             "123e4567-e89b-12d3-a456-426614174000",
		Timestamp:      time.Now(),
		Message:        "Example error message",
		StackTrace:     "Example stack trace",
		Module:         "example-module",
		ErrorCode:      "ERR1234",
		ManagerContext: "Example context",
		Severity:       "ERROR",
	}

	// Serialize to JSON
	jsonData, err := json.MarshalIndent(example, "", "  ")
	if err != nil {
		log.Fatalf("Failed to serialize ErrorEntry: %v", err)
	}

	fmt.Println("Serialized JSON:")
	fmt.Println(string(jsonData))
}
