package tests

import (
	"os/exec"
	"strings"
	"testing"
)

func TestKeybindsIntegration(t *testing.T) {
	cmd := exec.Command("go", "run", "../scripts/fix_keybind_conflicts.go")
	output, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("Error running fix_keybind_conflicts.go: %v\nOutput: %s", err, output)
	}

	if strings.Contains(string(output), "Error") {
		t.Errorf("Fixing keybind conflicts produced errors: %s", output)
	}

	cmd = exec.Command("go", "run", "../scripts/clean_unused_code.go")
	output, err = cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("Error running clean_unused_code.go: %v\nOutput: %s", err, output)
	}

	if strings.Contains(string(output), "Error") {
		t.Errorf("Cleaning unused code produced errors: %s", output)
	}
}
