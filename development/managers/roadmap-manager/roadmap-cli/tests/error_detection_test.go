package tests

import (
	"testing"
	"os"
	"path/filepath"
	"strings"
)

func TestErrorDetection(t *testing.T) {
	rootDir := "D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/development/managers/roadmap-manager/roadmap-cli"
	errTypes := []string{"DuplicateDecl", "UnusedVar", "MissingLitField", "IncompatibleAssign", "UndeclaredImportedName"}

	for _, errType := range errTypes {
		errFiles, err := detectErrors(rootDir, errType)
		if err != nil {
			t.Fatalf("Error detecting %s: %v", errType, err)
		}
		if len(errFiles) == 0 {
			t.Errorf("Expected to find errors of type %s, but found none", errType)
		}
	}
}

func detectErrors(rootDir, errType string) ([]string, error) {
	var errFiles []string
	err := filepath.Walk(rootDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if strings.HasSuffix(path, ".go") {
			// Simulate error detection logic
			if strings.Contains(info.Name(), errType) {
				errFiles = append(errFiles, path)
			}
		}
		return nil
	})
	return errFiles, err
}