package refactor_project

import (
	"bytes"
	"fmt"
	"go/format"
	"go/parser"
	"go/token"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"regexp"
	"strings"
)

const moduleName = "EMAIL_SENDER_1" // Your Go module name

func main() {
	log.Println("Starting project refactoring...")

	// 1. Rename package main outside cmd/ directories
	log.Println("Step 1: Refactoring 'package main' outside 'cmd/' directories...")
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
		if strings.Contains(path, string(filepath.Separator)+"cmd"+string(filepath.Separator)) {
			return nil // Skip files in cmd directories
		}

		fset := token.NewFileSet()
		node, err := parser.ParseFile(fset, path, nil, parser.ParseComments)
		if err != nil {
			// Skip unparseable files, might be incomplete or malformed
			return nil
		}

		if node.Name.Name == "main" {
			dir := filepath.Dir(path)
			newPackageName := sanitizePackageName(filepath.Base(dir))
			if newPackageName == "" || newPackageName == "main" {
				// Fallback to parent directory name if current is not suitable
				parentDir := filepath.Dir(dir)
				newPackageName = sanitizePackageName(filepath.Base(parentDir))
			}

			if newPackageName == "" || newPackageName == "main" {
				log.Printf("Warning: Could not determine suitable package name for %s. Skipping package rename.", path)
				return nil
			}

			log.Printf("Renaming package in %s from 'main' to '%s'", path, newPackageName)
			node.Name.Name = newPackageName

			var buf bytes.Buffer
			if err := format.Node(&buf, fset, node); err != nil {
				return fmt.Errorf("error formatting file %s: %w", path, err)
			}
			if err := ioutil.WriteFile(path, buf.Bytes(), 0o644); err != nil {
				return fmt.Errorf("error writing file %s: %w", path, err)
			}
		}
		return nil
	})
	if err != nil {
		log.Fatalf("Error during package main refactoring: %v", err)
	}

	// 2. Rewrite import paths
	log.Println("Step 2: Rewriting import paths...")
	err = filepath.Walk(".", func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if info.IsDir() || !strings.HasSuffix(info.Name(), ".go") {
			return nil
		}

		fset := token.NewFileSet()
		node, err := parser.ParseFile(fset, path, nil, parser.ParseComments)
		if err != nil {
			log.Printf("Warning: Could not parse file %s for import rewriting: %v", path, err)
			return nil // Skip unparseable files
		}

		hasChanges := false
		for _, imp := range node.Imports {
			oldPath := strings.Trim(imp.Path.Value, `"`)
			var newPath string

			// Case 1: Problematic GitHub imports (e.g., gerivdb, your-org, fmoua)
			reProblematicGithub := regexp.MustCompile(`^github\.com/(gerivdb|your-org|fmoua)/email-sender(-1)?/?(.*)$`)
			if matches := reProblematicGithub.FindStringSubmatch(oldPath); len(matches) > 0 {
				newPath = moduleName + "/" + matches[3] // Use the part after 'email-sender-1'
				imp.Path.Value = fmt.Sprintf(`"%s"`, newPath)
				hasChanges = true
				log.Printf("Rewriting import in %s: '%s' -> '%s'", path, oldPath, newPath)
			} else if strings.HasPrefix(oldPath, "../") || strings.HasPrefix(oldPath, "./") {
				// Case 2: Relative imports
				// Calculate the absolute path relative to the module root
				absPath, err := filepath.Abs(filepath.Join(filepath.Dir(path), oldPath))
				if err != nil {
					log.Printf("Warning: Could not resolve absolute path for relative import '%s' in %s: %v", oldPath, path, err)
					continue
				}

				// Find path relative to module root (assuming current working directory is module root)
				relPath, err := filepath.Rel(".", absPath)
				if err != nil {
					log.Printf("Warning: Could not get relative path to module root for '%s' in %s: %v", absPath, path, err)
					continue
				}
				newPath = moduleName + "/" + relPath
				imp.Path.Value = fmt.Sprintf(`"%s"`, newPath)
				hasChanges = true
				log.Printf("Rewriting relative import in %s: '%s' -> '%s'", path, oldPath, newPath)
			}
		}

		if hasChanges {
			var buf bytes.Buffer
			if err := format.Node(&buf, fset, node); err != nil {
				return fmt.Errorf("error formatting file %s after import rewrite: %w", path, err)
			}
			if err := ioutil.WriteFile(path, buf.Bytes(), 0o644); err != nil {
				return fmt.Errorf("error writing file %s: %w", path, err)
			}
		}
		return nil
	})
	if err != nil {
		log.Fatalf("Error during import path rewriting: %v", err)
	}

	log.Println("Project refactoring complete. Please run 'go mod tidy' and 'go build ./...' to finalize changes.")
}

func sanitizePackageName(name string) string {
	name = strings.ReplaceAll(name, "-", "_")
	name = strings.ReplaceAll(name, ".", "_")
	name = strings.ToLower(name)
	// Remove any non-alphanumeric characters except underscore
	reg := regexp.MustCompile("[^a-zA-Z0-9_]+")
	name = reg.ReplaceAllString(name, "")
	return name
}

// Note: rewriteImports function is now defined above main.
