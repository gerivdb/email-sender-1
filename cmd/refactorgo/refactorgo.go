package refactorgo

import (
	"bytes"
	"fmt"
	"go/parser"
	"go/printer"
	"go/token"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"strings"
)

func main() {
	log.Println("cmd/refactorgo/refactorgo.go: main() called")
	fmt.Println("Starting Go package refactoring...")

	err := filepath.Walk(".", func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if info.IsDir() {
			return nil
		}

		if !strings.HasSuffix(info.Name(), ".go") {
			return nil
		}

		// Skip files in cmd directories as they are expected to be 'package main'
		if strings.Contains(path, string(filepath.Separator)+"cmd"+string(filepath.Separator)) {
			return nil
		}

		fset := token.NewFileSet()
		node, err := parser.ParseFile(fset, path, nil, parser.ParseComments)
		if err != nil {
			// Skip files that cannot be parsed (e.g., incomplete code)
			// fmt.Printf("Skipping unparseable file %s: %v\n", path, err)
			return nil
		}

		if node.Name.Name == "main" {
			// Determine new package name based on directory name
			dir := filepath.Dir(path)
			newPackageName := filepath.Base(dir)
			if newPackageName == "." || newPackageName == "" {
				// Handle root directory case, or if base is empty
				fmt.Printf("Warning: Could not determine new package name for %s. Skipping.\n", path)
				return nil
			}

			// Ensure package name is a valid Go identifier (e.g., no hyphens)
			newPackageName = strings.ReplaceAll(newPackageName, "-", "_")
			newPackageName = strings.ReplaceAll(newPackageName, ".", "_")
			newPackageName = strings.ToLower(newPackageName) // Conventionally, package names are lowercase

			if newPackageName == "scripts" && strings.HasSuffix(path, "scan_missing_files_lib.go") {
				// Special case for scan_missing_files_lib.go which is already scripts
				// But we need to ensure the package name is correct if it was 'main'
				node.Name.Name = newPackageName
			} else if newPackageName == "main" {
				// If directory name is 'main', use parent directory name
				parentDir := filepath.Dir(dir)
				newPackageName = filepath.Base(parentDir)
				newPackageName = strings.ReplaceAll(newPackageName, "-", "_")
				newPackageName = strings.ReplaceAll(newPackageName, ".", "_")
				newPackageName = strings.ToLower(newPackageName)
				if newPackageName == "main" || newPackageName == "." || newPackageName == "" {
					fmt.Printf("Warning: Could not determine a unique package name for %s. Skipping.\n", path)
					return nil
				}
				node.Name.Name = newPackageName
			} else {
				node.Name.Name = newPackageName
			}

			fmt.Printf("Refactoring %s: Changing package from 'main' to '%s'\n", path, node.Name.Name)

			// Rewrite the file with the new package name
			var buf bytes.Buffer
			if err := printer.Fprint(&buf, fset, node); err != nil {
				fmt.Printf("Error printing AST for %s: %v\n", path, err)
				return nil
			}

			if err := ioutil.WriteFile(path, buf.Bytes(), 0o644); err != nil {
				fmt.Printf("Error writing file %s: %v\n", path, err)
				return nil
			}

			// If the file was named main.go and it's not in a cmd/ directory, rename it
			if info.Name() == "main.go" {
				newFileName := filepath.Join(dir, newPackageName+".go")
				if _, err := os.Stat(newFileName); err == nil {
					// If target file already exists, append a suffix
					base := strings.TrimSuffix(newPackageName, ".go")
					for i := 1; ; i++ {
						tempName := filepath.Join(dir, fmt.Sprintf("%s_%d.go", base, i))
						if _, err := os.Stat(tempName); os.IsNotExist(err) {
							newFileName = tempName
							break
						}
					}
				}
				fmt.Printf("Renaming %s to %s\n", path, newFileName)
				if err := os.Rename(path, newFileName); err != nil {
					fmt.Printf("Error renaming file %s to %s: %v\n", path, newFileName, err)
				}
			}
		}
		return nil
	})
	if err != nil {
		fmt.Printf("Error during refactoring walk: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("Go package refactoring complete. Please run 'go mod tidy' and 'go build ./...' to apply changes.")
}
