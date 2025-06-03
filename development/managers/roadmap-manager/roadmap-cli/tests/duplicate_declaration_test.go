package tests

import (
	"testing"
	"os/exec"
	"strings"
)

func TestDuplicateDeclarations(t *testing.T) {
	cmd := exec.Command("go", "run", "../scripts/fix_duplicate_declarations.go")
	output, err := cmd.CombinedOutput()
	if err != nil {
		t.Fatalf("Error running fix_duplicate_declarations.go: %v", err)
	}

	if strings.Contains(string(output), "Duplicate declaration found") {
		t.Errorf("Duplicate declarations were not fixed: %s", output)
	}
}