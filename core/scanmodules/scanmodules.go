package scanmodules

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

// ModuleInfo represents a module's information
type ModuleInfo struct {
	Name         string    `json:"name"`
	Path         string    `json:"path"`
	Description  string    `json:"description"`
	LastModified time.Time `json:"last_modified"`
}

// RepositoryStructure represents the complete repository structure
type RepositoryStructure struct {
	TreeOutput   string       `json:"tree_output"`
	Modules      []ModuleInfo `json:"modules"`
	TotalModules int          `json:"total_modules"`
	GeneratedAt  time.Time    `json:"generated_at"`
	RootPath     string       `json:"root_path"`
}

// ScanDir scans a directory for Go modules.
func ScanDir(rootDir string) (*RepositoryStructure, error) {
	fmt.Println("=== Scanning modules and repository structure ===")

	// Get the current working directory
	pwd, err := os.Getwd()
	if err != nil {
		return nil, fmt.Errorf("error getting working directory: %w", err)
	}

	// Execute tree to get the structure
	fmt.Println("Generating tree structure...")
	treeCmd := exec.Command("tree", "-L", "3")
	treeOutput, err := treeCmd.Output()
	if err != nil {
		log.Printf("Warning: could not execute tree: %v", err)
		// Fallback for Windows or if tree is not available
		treeOutput = []byte("Tree structure not available (tree not installed)")
	}

	// Execute go list to get modules
	fmt.Println("Scanning Go modules...")
	goListCmd := exec.Command("go", "list", "./...")
	goListCmd.Dir = rootDir
	goListOutput, err := goListCmd.Output()
	if err != nil {
		return nil, fmt.Errorf("error executing go list: %w", err)
	}

	// Parse modules and collect information
	moduleLines := strings.Split(strings.TrimSpace(string(goListOutput)), "\n")
	var modules []ModuleInfo

	for _, moduleLine := range moduleLines {
		if strings.TrimSpace(moduleLine) == "" {
			continue
		}

		// Convert module name to file path
		modulePath := strings.ReplaceAll(moduleLine, "/", string(filepath.Separator))

		// Find the main file of the module
		var actualPath string
		possiblePaths := []string{
			modulePath,
			filepath.Join(modulePath, "main.go"),
			filepath.Join(modulePath, "*.go"),
		}

		for _, path := range possiblePaths {
			if _, err := os.Stat(path); err == nil {
				actualPath = path
				break
			}
		}

		// Get modification info
		var lastModified time.Time
		if actualPath != "" {
			if info, err := os.Stat(actualPath); err == nil {
				lastModified = info.ModTime()
			}
		}

		module := ModuleInfo{
			Name:         moduleLine,
			Path:         actualPath,
			Description:  fmt.Sprintf("Go module: %s", moduleLine),
			LastModified: lastModified,
		}
		modules = append(modules, module)
	}

	// Create the complete repository structure
	repoStructure := &RepositoryStructure{
		TreeOutput:   string(treeOutput),
		Modules:      modules,
		TotalModules: len(modules),
		GeneratedAt:  time.Now(),
		RootPath:     pwd,
	}

	return repoStructure, nil
}

// ExportModules exports the repository structure to a JSON file.
func ExportModules(repoStructure *RepositoryStructure, outputFile string) error {
	// Save to JSON
	jsonData, err := json.MarshalIndent(repoStructure, "", "  ")
	if err != nil {
		return fmt.Errorf("error marshalling JSON: %w", err)
	}

	err = ioutil.WriteFile(outputFile, jsonData, 0644)
	if err != nil {
		return fmt.Errorf("error writing to %s: %w", outputFile, err)
	}

	return nil
}