package errormanager

import (
	"testing"
	"time"
)

func TestValidateErrorEntry(t *testing.T) {
	tests := []struct {
		name    string
		entry   ErrorEntry
		wantErr bool
	}{
		{
			name: "Valid entry",
			entry: ErrorEntry{
				ID:            "123",
				Timestamp:     time.Now(),
				Message:       "An error occurred",
				Module:        "TestModule",
				ErrorCode:     "E001",
				ManagerContext: "TestContext",
				Severity:      "high",
			},
			wantErr: false,
		},
		{
			name: "Empty ID",
			entry: ErrorEntry{
				ID:            "",
				Timestamp:     time.Now(),
				Message:       "An error occurred",
				Module:        "TestModule",
				ErrorCode:     "E001",
				ManagerContext: "TestContext",
				Severity:      "high",
			},
			wantErr: true,
		},
		{
			name: "Invalid severity",
			entry: ErrorEntry{
				ID:            "123",
				Timestamp:     time.Now(),
				Message:       "An error occurred",
				Module:        "TestModule",
				ErrorCode:     "E001",
				ManagerContext: "TestContext",
				Severity:      "invalid",
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if err := ValidateErrorEntry(tt.entry); (err != nil) != tt.wantErr {
				t.Errorf("ValidateErrorEntry() error = %v, wantErr %v", err, tt.wantErr)
			}
		})
	}
}
