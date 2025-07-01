package scripts

import (
	"bytes"
	"fmt"
	"io/fs"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

// ScanMissingFiles scanne les fichiers manquants ou vidés en comparant avec un commit sain.
func ScanMissingFiles(healthyCommit string) {
	fmt.Println("Starting scan for missing and empty files...")

	// 1. Lister les fichiers vides dans le répertoire actuel
	fmt.Println("\n--- Listing currently empty files ---")
	filepath.Walk(".", func(path string, info fs.FileInfo, err error) error {
		if err != nil {
			fmt.Printf("Error accessing path %s: %v\n", path, err)
			return nil // Continue walking
		}
		if !info.IsDir() && info.Size() == 0 {
			fmt.Printf("VIDE: %s\n", path)
		}
		return nil
	})

	// 2. Comparer avec le commit sain pour les fichiers supprimés ou vidés
	if healthyCommit != "" {
		fmt.Printf("\n--- Comparing with healthy commit: %s ---\n", healthyCommit)
		cmd := exec.Command("git", "diff", "--name-status", healthyCommit, "HEAD")
		var out bytes.Buffer
		cmd.Stdout = &out
		cmd.Stderr = &out // Capture errors as well

		err := cmd.Run()
		if err != nil {
			fmt.Printf("Error running git diff: %v\nOutput:\n%s\n", err, out.String())
			return
		}

		lines := strings.Split(out.String(), "\n")
		for _, line := range lines {
			if strings.HasPrefix(line, "D\t") {
				filePath := strings.TrimPrefix(line, "D\t")
				fmt.Printf("SUPPRIMÉ: %s (par rapport à %s)\n", filePath, healthyCommit)
			} else if strings.HasPrefix(line, "M\t") {
				filePath := strings.TrimPrefix(line, "M\t")
				// Check if the modified file is now empty
				info, err := os.Stat(filePath)
				if err == nil && info.Size() == 0 {
					fmt.Printf("VIDÉ (MODIFIÉ): %s\n", filePath)
				}
			}
		}
	} else {
		fmt.Println("\nNo healthy commit provided for comprehensive comparison.")
	}

	fmt.Println("\nScan complete.")
}
