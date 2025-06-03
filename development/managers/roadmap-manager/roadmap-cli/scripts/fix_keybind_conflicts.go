package main

import (
	"fmt"
	"os"
	"strings"
)

func main() {
	files := []string{
		"development/managers/roadmap-manager/roadmap-cli/keybinds/types.go",
		"development/managers/roadmap-manager/roadmap-cli/keybinds/validator.go",
	}

	for _, file := range files {
		content, err := os.ReadFile(file)
		if err != nil {
			fmt.Printf("Error reading file %s: %v\n", file, err)
			continue
		}

		updatedContent := resolveKeyConflicts(string(content))
		err = os.WriteFile(file, []byte(updatedContent), 0644)
		if err != nil {
			fmt.Printf("Error writing file %s: %v\n", file, err)
		}
	}
}

func resolveKeyConflicts(content string) string {
	conflictKeys := []string{"KeyConflict"}
	for _, key := range conflictKeys {
		content = strings.ReplaceAll(content, key, key+"_resolved")
	}
	return content
}