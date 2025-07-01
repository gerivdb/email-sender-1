package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// DocumentFile represents a documentation file with metadata
type DocumentFile struct {
	Path         string            `json:"path"`
	Name         string            `json:"name"`
	Extension    string            `json:"extension"`
	Size         int64             `json:"size"`
	LastModified time.Time         `json:"last_modified"`
	Type         string            `json:"type"`
	Category     string            `json:"category"`
	Tags         []string          `json:"tags"`
	Metadata     map[string]string `json:"metadata"`
}

// InventoryReport represents the complete inventory
type InventoryReport struct {
	GeneratedAt    time.Time       `json:"generated_at"`
	TotalFiles     int             `json:"total_files"`
	TotalSize      int64           `json:"total_size"`
	Categories     map[string]int  `json:"categories"`
	Extensions     map[string]int  `json:"extensions"`
	Files          []DocumentFile  `json:"files"`
	Summary        string          `json:"summary"`
}

func main() {
	projectRoot := "."
	if len(os.Args) > 1 {
		projectRoot = os.Args[1]
	}

	report, err := generateInventory(projectRoot)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error generating inventory: %v\n", err)
		os.Exit(1)
	}

	// Output JSON to stdout
	encoder := json.NewEncoder(os.Stdout)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(report); err != nil {
		fmt.Fprintf(os.Stderr, "Error encoding JSON: %v\n", err)
		os.Exit(1)
	}
}

func generateInventory(root string) (*InventoryReport, error) {
	var files []DocumentFile
	categories := make(map[string]int)
	extensions := make(map[string]int)
	var totalSize int64

	// Documentation patterns to look for (for reference)
	// We use filepath.Walk instead of pattern matching for better control

	err := filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if info.IsDir() {
			return nil
		}

		// Get relative path for consistent processing
		relPath, err := filepath.Rel(root, path)
		if err != nil {
			relPath = path // fallback to absolute path
		}

		// Check if file matches documentation patterns
		if !isDocumentationFile(relPath, info.Name()) {
			return nil
		}

		// Skip certain directories
		if shouldSkipPath(relPath) {
			return nil
		}

		ext := strings.ToLower(filepath.Ext(path))
		category := categorizeFile(relPath, info.Name())
		tags := extractTags(relPath, info.Name())

		doc := DocumentFile{
			Path:         relPath, // Use relative path in output
			Name:         info.Name(),
			Extension:    ext,
			Size:         info.Size(),
			LastModified: info.ModTime(),
			Type:         getFileType(ext),
			Category:     category,
			Tags:         tags,
			Metadata:     extractMetadata(relPath),
		}

		files = append(files, doc)
		categories[category]++
		extensions[ext]++
		totalSize += info.Size()

		return nil
	})

	if err != nil {
		return nil, err
	}

	report := &InventoryReport{
		GeneratedAt: time.Now(),
		TotalFiles:  len(files),
		TotalSize:   totalSize,
		Categories:  categories,
		Extensions:  extensions,
		Files:       files,
		Summary:     generateSummary(len(files), categories, extensions),
	}

	return report, nil
}

func isDocumentationFile(path, name string) bool {
	ext := strings.ToLower(filepath.Ext(name))
	docExts := []string{".md", ".txt", ".rst", ".adoc", ".org"}
	
	// Check extension
	for _, docExt := range docExts {
		if ext == docExt {
			return true
		}
	}

	// Check special files without extension
	baseName := strings.ToUpper(name)
	specialFiles := []string{"README", "CHANGELOG", "LICENSE", "AUTHORS", "CONTRIBUTORS"}
	for _, special := range specialFiles {
		if strings.HasPrefix(baseName, special) {
			return true
		}
	}

	// Check if in docs directory
	pathLower := strings.ToLower(path)
	if strings.HasPrefix(pathLower, "docs/") || strings.Contains(pathLower, "/docs/") ||
		strings.HasPrefix(pathLower, ".github/") || strings.Contains(pathLower, "/.github/") {
		return ext == ".md" || ext == ".txt"
	}

	return false
}

func shouldSkipPath(path string) bool {
	skipPaths := []string{
		"node_modules", ".git", "vendor", "build", "dist",
		"coverage", "backup", ".avg-exclude", "bin", "tmp",
	}

	pathLower := strings.ToLower(path)
	for _, skip := range skipPaths {
		// Check if path starts with skip directory
		if strings.HasPrefix(pathLower, skip+"/") ||
			// Check if path contains skip directory  
			strings.Contains(pathLower, "/"+skip+"/") ||
			// Check if path ends with skip directory
			strings.HasSuffix(pathLower, "/"+skip) ||
			// Check if path is exactly the skip directory
			pathLower == skip {
			return true
		}
	}
	return false
}

func categorizeFile(path, name string) string {
	pathLower := strings.ToLower(path)
	nameLower := strings.ToLower(name)

	// Project root files - check if no directory separators
	if !strings.Contains(path, "/") && !strings.Contains(path, "\\") {
		return "root"
	}

	// GitHub specific - check for .github directory
	if strings.HasPrefix(pathLower, ".github/") || strings.Contains(pathLower, "/.github/") {
		return "github"
	}

	// Documentation directories - check for docs directory
	if strings.HasPrefix(pathLower, "docs/") || strings.Contains(pathLower, "/docs/") {
		return "documentation"
	}

	// Development files - check for development directory
	if strings.HasPrefix(pathLower, "development/") || strings.Contains(pathLower, "/development/") {
		return "development"
	}

	// Project management - check for projet directory
	if strings.HasPrefix(pathLower, "projet/") || strings.Contains(pathLower, "/projet/") || 
		strings.HasPrefix(pathLower, "planning/") || strings.Contains(pathLower, "/planning/") {
		return "project-management"
	}

	// API documentation - check filename and path more specifically
	if strings.Contains(nameLower, "api") || strings.Contains(pathLower, "/api/") || strings.HasPrefix(pathLower, "api/") {
		// If it's also in docs, prioritize documentation category
		if strings.Contains(pathLower, "/docs/") || strings.HasPrefix(pathLower, "docs/") {
			return "documentation"
		}
		return "api"
	}

	// Tests - check for test directory
	if strings.Contains(pathLower, "/test") || strings.Contains(nameLower, "test") ||
		strings.HasPrefix(pathLower, "test") {
		return "testing"
	}

	// Configuration
	if strings.Contains(nameLower, "config") || strings.Contains(nameLower, "setup") {
		return "configuration"
	}

	return "general"
}

func extractTags(path, name string) []string {
	var tags []string
	
	pathLower := strings.ToLower(path)
	nameLower := strings.ToLower(name)

	// Add tags based on path
	if strings.Contains(pathLower, "roadmap") {
		tags = append(tags, "roadmap")
	}
	if strings.Contains(pathLower, "plan") {
		tags = append(tags, "plan")
	}
	if strings.Contains(pathLower, "spec") {
		tags = append(tags, "specification")
	}
	if strings.Contains(pathLower, "guide") {
		tags = append(tags, "guide")
	}
	if strings.Contains(pathLower, "tutorial") {
		tags = append(tags, "tutorial")
	}

	// Add tags based on filename
	if strings.Contains(nameLower, "readme") {
		tags = append(tags, "readme")
	}
	if strings.Contains(nameLower, "changelog") {
		tags = append(tags, "changelog")
	}
	if strings.Contains(nameLower, "license") {
		tags = append(tags, "license")
	}
	if strings.Contains(nameLower, "install") {
		tags = append(tags, "installation")
	}

	return tags
}

func extractMetadata(path string) map[string]string {
	metadata := make(map[string]string)
	
	// Add directory depth
	depth := strings.Count(path, "/")
	metadata["depth"] = fmt.Sprintf("%d", depth)
	
	// Add parent directory
	if dir := filepath.Dir(path); dir != "." {
		metadata["parent_dir"] = filepath.Base(dir)
	}

	return metadata
}

func getFileType(ext string) string {
	switch ext {
	case ".md":
		return "markdown"
	case ".txt":
		return "text"
	case ".rst":
		return "restructuredtext"
	case ".adoc":
		return "asciidoc"
	case ".org":
		return "org-mode"
	default:
		return "other"
	}
}

func generateSummary(totalFiles int, categories, extensions map[string]int) string {
	summary := fmt.Sprintf("Found %d documentation files across %d categories and %d file types.\n",
		totalFiles, len(categories), len(extensions))
	
	summary += "\nTop categories:\n"
	for cat, count := range categories {
		summary += fmt.Sprintf("- %s: %d files\n", cat, count)
	}
	
	summary += "\nFile types:\n"
	for ext, count := range extensions {
		summary += fmt.Sprintf("- %s: %d files\n", ext, count)
	}

	return summary
}