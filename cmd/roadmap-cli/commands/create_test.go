package commands

import (
	"os"
	"path/filepath"
	"testing"

	"github.com/spf13/cobra"
)

func TestCreateItemCommand(t *testing.T) {
	// Create temporary directory for test storage
	tmpDir := t.TempDir()
	testFile := filepath.Join(tmpDir, "test_roadmap.json")

	// Override storage path using environment variable
	originalEnv := os.Getenv("ROADMAP_STORAGE_PATH")
	os.Setenv("ROADMAP_STORAGE_PATH", testFile)
	defer func() {
		if originalEnv == "" {
			os.Unsetenv("ROADMAP_STORAGE_PATH")
		} else {
			os.Setenv("ROADMAP_STORAGE_PATH", originalEnv)
		}
	}()

	// Create command
	cmd := newCreateItemCommand()

	// Set arguments and flags
	cmd.SetArgs([]string{"Test Item from CLI"})
	cmd.Flags().Set("description", "Test description")
	cmd.Flags().Set("priority", "high")
	cmd.Flags().Set("target-date", "2025-12-31")

	// Execute command
	err := cmd.Execute()
	if err != nil {
		t.Fatalf("Command execution failed: %v", err)
	}

	// Verify storage file was created
	if _, err := os.Stat(testFile); os.IsNotExist(err) {
		t.Error("Storage file was not created")
	}
}

func TestCreateMilestoneCommand(t *testing.T) {
	tmpDir := t.TempDir()
	testFile := filepath.Join(tmpDir, "test_roadmap.json")

	// Override storage path using environment variable
	originalEnv := os.Getenv("ROADMAP_STORAGE_PATH")
	os.Setenv("ROADMAP_STORAGE_PATH", testFile)
	defer func() {
		if originalEnv == "" {
			os.Unsetenv("ROADMAP_STORAGE_PATH")
		} else {
			os.Setenv("ROADMAP_STORAGE_PATH", originalEnv)
		}
	}()

	// Create command
	cmd := newCreateMilestoneCommand()

	// Set arguments and flags
	cmd.SetArgs([]string{"Test Milestone"})
	cmd.Flags().Set("description", "Test milestone description")
	cmd.Flags().Set("target-date", "2025-12-31")

	// Execute command
	err := cmd.Execute()
	if err != nil {
		t.Fatalf("Command execution failed: %v", err)
	}

	// Verify storage file was created
	if _, err := os.Stat(testFile); os.IsNotExist(err) {
		t.Error("Storage file was not created")
	}
}

func TestCreateCommandValidation(t *testing.T) {
	cmd := newCreateItemCommand()

	// Test invalid priority
	cmd.SetArgs([]string{"Test Item"})
	cmd.Flags().Set("priority", "invalid")

	err := cmd.Execute()
	if err == nil {
		t.Error("Expected error for invalid priority, got nil")
	}
}

func TestCommandFlags(t *testing.T) {
	tests := []struct {
		name     string
		command  *cobra.Command
		flagName string
		expected bool
	}{
		{
			name:     "CreateItem has description flag",
			command:  newCreateItemCommand(),
			flagName: "description",
			expected: true,
		},
		{
			name:     "CreateItem has priority flag",
			command:  newCreateItemCommand(),
			flagName: "priority",
			expected: true,
		},
		{
			name:     "CreateMilestone has description flag",
			command:  newCreateMilestoneCommand(),
			flagName: "description",
			expected: true,
		},
		{
			name:     "CreateMilestone has target-date flag",
			command:  newCreateMilestoneCommand(),
			flagName: "target-date",
			expected: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			flag := tt.command.Flags().Lookup(tt.flagName)
			if (flag != nil) != tt.expected {
				t.Errorf("Flag %s existence: expected %v, got %v", tt.flagName, tt.expected, flag != nil)
			}
		})
	}
}
