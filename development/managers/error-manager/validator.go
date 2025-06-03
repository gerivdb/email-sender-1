package errormanager

import (
	"errors"
)

// ValidateErrorEntry validates the fields of an ErrorEntry
func ValidateErrorEntry(entry ErrorEntry) error {
	if entry.ID == "" {
		return errors.New("ID cannot be empty")
	}
	if entry.Timestamp.IsZero() {
		return errors.New("Timestamp cannot be zero")
	}
	if entry.Message == "" {
		return errors.New("Message cannot be empty")
	}
	if entry.Module == "" {
		return errors.New("Module cannot be empty")
	}
	if entry.ErrorCode == "" {
		return errors.New("ErrorCode cannot be empty")
	}
	if !isValidSeverity(entry.Severity) {
		return errors.New("Invalid severity level")
	}
	return nil
}

// isValidSeverity checks if the severity level is valid
func isValidSeverity(severity string) bool {
	validSeverities := []string{"low", "medium", "high", "critical"}
	for _, s := range validSeverities {
		if severity == s {
			return true
		}
	}
	return false
}
