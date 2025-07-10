// tools/scripts/list_neutralized.go
package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

func main() {
	var neutralized []string
	filepath.Walk(".", func(path string, info os.FileInfo, err error) error {
		if strings.HasSuffix(path, ".go") {
			f, _ := os.ReadFile(path)
			if strings.Contains(string(f), "Fichier neutralisé temporairement") ||
				strings.Contains(string(f), "neutralisé temporairement") ||
				strings.Contains(string(f), "/*") && strings.Contains(string(f), "neutralisé") {
				neutralized = append(neutralized, path)
			}
		}
		return nil
	})
	for _, file := range neutralized {
		fmt.Println(file)
	}
}
