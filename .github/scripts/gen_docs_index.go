package scripts

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"
)

// DocumentationIndex represents the complete documentation index
type DocumentationIndex struct {
	GeneratedAt	time.Time		`json:"generated_at"`
	ProjectName	string			`json:"project_name"`
	TotalFiles	int			`json:"total_files"`
	Categories	[]CategoryIndex		`json:"categories"`
	GlobalIndex	[]IndexEntry		`json:"global_index"`
	CrossReferences	[]CrossReference	`json:"cross_references"`
	Metadata	IndexMetadata		`json:"metadata"`
	Navigation	NavigationIndex		`json:"navigation"`
}

// CategoryIndex represents documentation grouped by category
type CategoryIndex struct {
	Name		string		`json:"name"`
	Description	string		`json:"description"`
	Files		[]IndexEntry	`json:"files"`
	Subcategories	[]CategoryIndex	`json:"subcategories,omitempty"`
}

// IndexEntry represents a single documentation file entry
type IndexEntry struct {
	Title		string			`json:"title"`
	Path		string			`json:"path"`
	Description	string			`json:"description"`
	Tags		[]string		`json:"tags"`
	LastModified	time.Time		`json:"last_modified"`
	Size		int64			`json:"size"`
	Type		string			`json:"type"`
	Category	string			`json:"category"`
	Level		int			`json:"level"`
	Metadata	map[string]string	`json:"metadata"`
}

// CrossReference represents links between documents
type CrossReference struct {
	From	string	`json:"from"`
	To	string	`json:"to"`
	Type	string	`json:"type"`
	Context	string	`json:"context"`
	Line	int	`json:"line,omitempty"`
}

// IndexMetadata represents metadata about the index
type IndexMetadata struct {
	Version		string			`json:"version"`
	Generator	string			`json:"generator"`
	LastUpdate	time.Time		`json:"last_update"`
	Statistics	IndexStatistics		`json:"statistics"`
	Configuration	map[string]string	`json:"configuration"`
}

// IndexStatistics represents statistics about the documentation
type IndexStatistics struct {
	TotalFiles	int		`json:"total_files"`
	TotalSize	int64		`json:"total_size"`
	CategoryCounts	map[string]int	`json:"category_counts"`
	TypeCounts	map[string]int	`json:"type_counts"`
	TagCounts	map[string]int	`json:"tag_counts"`
	RecentChanges	int		`json:"recent_changes"`
}

// NavigationIndex represents navigation structure
type NavigationIndex struct {
	MainSections	[]NavigationSection	`json:"main_sections"`
	QuickStart	[]string		`json:"quick_start"`
	ImportantPages	[]string		`json:"important_pages"`
	SearchIndex	[]SearchIndexEntry	`json:"search_index"`
}

// NavigationSection represents a navigation section
type NavigationSection struct {
	Name		string		`json:"name"`
	Path		string		`json:"path"`
	Children	[]string	`json:"children"`
	Order		int		`json:"order"`
}

// SearchIndexEntry represents a search index entry
type SearchIndexEntry struct {
	Path		string		`json:"path"`
	Title		string		`json:"title"`
	Keywords	[]string	`json:"keywords"`
	Content		string		`json:"content"`
}

func main() {
	projectRoot := "."
	if len(os.Args) > 1 {
		projectRoot = os.Args[1]
	}

	outputPath := ".github/DOCS_INDEX.md"
	if len(os.Args) > 2 {
		outputPath = os.Args[2]
	}

	index, err := generateDocumentationIndex(projectRoot)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error generating documentation index: %v\n", err)
		os.Exit(1)
	}

	// Generate markdown output
	markdownContent, err := generateMarkdownIndex(index)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error generating markdown: %v\n", err)
		os.Exit(1)
	}

	// Write markdown file
	if err := writeMarkdownFile(outputPath, markdownContent); err != nil {
		fmt.Fprintf(os.Stderr, "Error writing markdown file: %v\n", err)
		os.Exit(1)
	}

	// Output JSON to stdout
	encoder := json.NewEncoder(os.Stdout)
	encoder.SetIndent("", "  ")
	if err := encoder.Encode(index); err != nil {
		fmt.Fprintf(os.Stderr, "Error encoding JSON: %v\n", err)
		os.Exit(1)
	}
}

func generateDocumentationIndex(root string) (*DocumentationIndex, error) {
	projectName := filepath.Base(root)
	if projectName == "." || projectName == "/" {
		projectName = "project"
	}

	// Collect all documentation files
	entries, err := collectDocumentationFiles(root)
	if err != nil {
		return nil, err
	}

	// Generate categories
	categories := generateCategories(entries)

	// Generate cross-references
	crossRefs := generateCrossReferences(entries, root)

	// Generate navigation
	navigation := generateNavigation(entries, categories)

	// Generate statistics
	stats := generateStatistics(entries)

	index := &DocumentationIndex{
		GeneratedAt:		time.Now(),
		ProjectName:		projectName,
		TotalFiles:		len(entries),
		Categories:		categories,
		GlobalIndex:		entries,
		CrossReferences:	crossRefs,
		Navigation:		navigation,
		Metadata: IndexMetadata{
			Version:	"1.0",
			Generator:	"gen_docs_index.go",
			LastUpdate:	time.Now(),
			Statistics:	stats,
			Configuration: map[string]string{
				"root_path":	root,
				"format":	"markdown",
			},
		},
	}

	return index, nil
}

func collectDocumentationFiles(root string) ([]IndexEntry, error) {
	var entries []IndexEntry

	err := filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if info.IsDir() {
			return nil
		}

		// Get relative path
		relPath, err := filepath.Rel(root, path)
		if err != nil {
			relPath = path
		}

		// Check if it's a documentation file
		if !isDocumentationFile(relPath, info.Name()) {
			return nil
		}

		// Skip certain paths
		if shouldSkipPath(relPath) {
			return nil
		}

		// Extract title and description
		title, description := extractTitleAndDescription(path)
		if title == "" {
			title = strings.TrimSuffix(info.Name(), filepath.Ext(info.Name()))
		}

		// Extract tags and metadata
		tags := extractTags(relPath, info.Name())
		metadata := extractMetadata(relPath)

		entry := IndexEntry{
			Title:		title,
			Path:		relPath,
			Description:	description,
			Tags:		tags,
			LastModified:	info.ModTime(),
			Size:		info.Size(),
			Type:		getFileType(filepath.Ext(info.Name())),
			Category:	categorizeFile(relPath, info.Name()),
			Level:		calculateDocumentLevel(relPath),
			Metadata:	metadata,
		}

		entries = append(entries, entry)
		return nil
	})

	return entries, err
}

func extractTitleAndDescription(filePath string) (string, string) {
	file, err := os.Open(filePath)
	if err != nil {
		return "", ""
	}
	defer file.Close()

	// Read first few lines to extract title and description
	buffer := make([]byte, 1024)
	n, err := file.Read(buffer)
	if err != nil {
		return "", ""
	}

	content := string(buffer[:n])
	lines := strings.Split(content, "\n")

	var title, description string

	for i, line := range lines {
		line = strings.TrimSpace(line)

		// Look for markdown title
		if strings.HasPrefix(line, "# ") {
			title = strings.TrimPrefix(line, "# ")
			title = strings.TrimSpace(title)
			break
		}

		// Look for HTML title
		if strings.Contains(line, "<title>") {
			start := strings.Index(line, "<title>") + 7
			end := strings.Index(line, "</title>")
			if end > start {
				title = line[start:end]
				break
			}
		}

		// If no title found and this is a substantial line, use it
		if title == "" && len(line) > 5 && !strings.HasPrefix(line, "<!--") &&
			!strings.HasPrefix(line, "---") && i < 10 {
			title = line
			if len(title) > 60 {
				title = title[:60] + "..."
			}
			break
		}
	}

	// Look for description (usually second substantial line)
	for i, line := range lines {
		line = strings.TrimSpace(line)
		if line != "" && line != title && !strings.HasPrefix(line, "#") &&
			!strings.HasPrefix(line, "<!--") && !strings.HasPrefix(line, "---") &&
			len(line) > 10 && i < 15 {
			description = line
			if len(description) > 120 {
				description = description[:120] + "..."
			}
			break
		}
	}

	return title, description
}

func generateCategories(entries []IndexEntry) []CategoryIndex {
	categoryMap := make(map[string][]IndexEntry)

	// Group entries by category
	for _, entry := range entries {
		categoryMap[entry.Category] = append(categoryMap[entry.Category], entry)
	}

	var categories []CategoryIndex
	categoryDescriptions := map[string]string{
		"root":			"Project root documentation (README, LICENSE, etc.)",
		"documentation":	"Main documentation directory",
		"github":		"GitHub-specific documentation and templates",
		"development":		"Development and contribution guides",
		"project-management":	"Project planning and management documents",
		"api":			"API documentation and specifications",
		"testing":		"Testing guides and documentation",
		"configuration":	"Configuration and setup documentation",
		"general":		"General documentation files",
	}

	// Create categories with sorted entries
	for categoryName, categoryEntries := range categoryMap {
		sort.Slice(categoryEntries, func(i, j int) bool {
			// Sort by level (depth), then by name
			if categoryEntries[i].Level != categoryEntries[j].Level {
				return categoryEntries[i].Level < categoryEntries[j].Level
			}
			return categoryEntries[i].Title < categoryEntries[j].Title
		})

		description := categoryDescriptions[categoryName]
		if description == "" {
			description = fmt.Sprintf("Documentation files categorized as %s", categoryName)
		}

		category := CategoryIndex{
			Name:		categoryName,
			Description:	description,
			Files:		categoryEntries,
		}

		categories = append(categories, category)
	}

	// Sort categories by importance
	sort.Slice(categories, func(i, j int) bool {
		order := map[string]int{
			"root":	1, "documentation": 2, "github": 3, "development": 4,
			"api":	5, "testing": 6, "project-management": 7, "configuration": 8, "general": 9,
		}
		return order[categories[i].Name] < order[categories[j].Name]
	})

	return categories
}

func generateCrossReferences(entries []IndexEntry, root string) []CrossReference {
	var crossRefs []CrossReference

	for _, entry := range entries {
		// Find references in this file
		refs := findReferencesInFile(filepath.Join(root, entry.Path), entries)
		crossRefs = append(crossRefs, refs...)
	}

	return crossRefs
}

func findReferencesInFile(filePath string, allEntries []IndexEntry) []CrossReference {
	var refs []CrossReference

	file, err := os.Open(filePath)
	if err != nil {
		return refs
	}
	defer file.Close()

	// Read file content
	buffer := make([]byte, 4096)
	n, err := file.Read(buffer)
	if err != nil {
		return refs
	}

	content := string(buffer[:n])
	lines := strings.Split(content, "\n")

	// Get relative path for the current file
	for _, entry := range allEntries {
		if strings.HasSuffix(filePath, entry.Path) {
			currentPath := entry.Path

			// Look for references to other files
			for lineNum, line := range lines {
				for _, targetEntry := range allEntries {
					if targetEntry.Path == currentPath {
						continue
					}

					// Look for markdown links
					if strings.Contains(line, targetEntry.Path) ||
						strings.Contains(line, targetEntry.Title) {
						refs = append(refs, CrossReference{
							From:		currentPath,
							To:		targetEntry.Path,
							Type:		"link",
							Context:	strings.TrimSpace(line),
							Line:		lineNum + 1,
						})
					}
				}
			}
			break
		}
	}

	return refs
}

func generateNavigation(entries []IndexEntry, categories []CategoryIndex) NavigationIndex {
	// Generate main sections based on categories
	var mainSections []NavigationSection
	for i, category := range categories {
		if len(category.Files) > 0 {
			// Use first file as the section entry point
			mainPath := category.Files[0].Path

			var children []string
			for _, file := range category.Files {
				if file.Path != mainPath {
					children = append(children, file.Path)
				}
			}

			section := NavigationSection{
				Name:		category.Name,
				Path:		mainPath,
				Children:	children,
				Order:		i,
			}
			mainSections = append(mainSections, section)
		}
	}

	// Generate quick start recommendations
	quickStart := []string{}
	for _, entry := range entries {
		name := strings.ToLower(entry.Title)
		if strings.Contains(name, "readme") || strings.Contains(name, "quick") ||
			strings.Contains(name, "start") || strings.Contains(name, "install") {
			quickStart = append(quickStart, entry.Path)
		}
	}

	// Limit to 5 quick start items
	if len(quickStart) > 5 {
		quickStart = quickStart[:5]
	}

	// Generate important pages
	importantPages := []string{}
	for _, entry := range entries {
		if entry.Category == "root" || strings.Contains(strings.ToLower(entry.Title), "important") {
			importantPages = append(importantPages, entry.Path)
		}
	}

	// Generate search index
	var searchIndex []SearchIndexEntry
	for _, entry := range entries {
		keywords := append(entry.Tags, strings.Fields(entry.Title)...)
		keywords = append(keywords, entry.Category)

		searchEntry := SearchIndexEntry{
			Path:		entry.Path,
			Title:		entry.Title,
			Keywords:	keywords,
			Content:	entry.Description,
		}
		searchIndex = append(searchIndex, searchEntry)
	}

	return NavigationIndex{
		MainSections:	mainSections,
		QuickStart:	quickStart,
		ImportantPages:	importantPages,
		SearchIndex:	searchIndex,
	}
}

func generateStatistics(entries []IndexEntry) IndexStatistics {
	stats := IndexStatistics{
		TotalFiles:	len(entries),
		CategoryCounts:	make(map[string]int),
		TypeCounts:	make(map[string]int),
		TagCounts:	make(map[string]int),
	}

	recentThreshold := time.Now().AddDate(0, 0, -7)	// Last 7 days

	for _, entry := range entries {
		stats.TotalSize += entry.Size
		stats.CategoryCounts[entry.Category]++
		stats.TypeCounts[entry.Type]++

		if entry.LastModified.After(recentThreshold) {
			stats.RecentChanges++
		}

		for _, tag := range entry.Tags {
			stats.TagCounts[tag]++
		}
	}

	return stats
}

func generateMarkdownIndex(index *DocumentationIndex) (string, error) {
	var md strings.Builder

	// Header
	md.WriteString(fmt.Sprintf("# %s Documentation Index\n\n", index.ProjectName))
	md.WriteString(fmt.Sprintf("*Generated on %s*\n\n", index.GeneratedAt.Format("2006-01-02 15:04:05")))

	// Summary
	md.WriteString("## Summary\n\n")
	md.WriteString(fmt.Sprintf("- **Total Files**: %d\n", index.TotalFiles))
	md.WriteString(fmt.Sprintf("- **Categories**: %d\n", len(index.Categories)))
	md.WriteString(fmt.Sprintf("- **Recent Changes**: %d files (last 7 days)\n", index.Metadata.Statistics.RecentChanges))
	md.WriteString(fmt.Sprintf("- **Total Size**: %.2f KB\n\n", float64(index.Metadata.Statistics.TotalSize)/1024))

	// Quick Start
	if len(index.Navigation.QuickStart) > 0 {
		md.WriteString("## Quick Start\n\n")
		for _, path := range index.Navigation.QuickStart {
			for _, entry := range index.GlobalIndex {
				if entry.Path == path {
					md.WriteString(fmt.Sprintf("- [%s](%s) - %s\n", entry.Title, entry.Path, entry.Description))
					break
				}
			}
		}
		md.WriteString("\n")
	}

	// Categories
	md.WriteString("## Documentation by Category\n\n")
	for _, category := range index.Categories {
		md.WriteString(fmt.Sprintf("### %s\n\n", strings.Title(strings.ReplaceAll(category.Name, "-", " "))))
		md.WriteString(fmt.Sprintf("*%s*\n\n", category.Description))

		for _, file := range category.Files {
			md.WriteString(fmt.Sprintf("- [%s](%s)", file.Title, file.Path))
			if file.Description != "" {
				md.WriteString(fmt.Sprintf(" - %s", file.Description))
			}
			if len(file.Tags) > 0 {
				md.WriteString(fmt.Sprintf(" `%s`", strings.Join(file.Tags, "` `")))
			}
			md.WriteString("\n")
		}
		md.WriteString("\n")
	}

	// Statistics
	md.WriteString("## Statistics\n\n")
	md.WriteString("### By Category\n\n")
	for category, count := range index.Metadata.Statistics.CategoryCounts {
		md.WriteString(fmt.Sprintf("- %s: %d files\n", strings.Title(category), count))
	}

	md.WriteString("\n### By Type\n\n")
	for fileType, count := range index.Metadata.Statistics.TypeCounts {
		md.WriteString(fmt.Sprintf("- %s: %d files\n", strings.Title(fileType), count))
	}

	// Footer
	md.WriteString(fmt.Sprintf("\n---\n*Index generated by %s v%s*\n",
		index.Metadata.Generator, index.Metadata.Version))

	return md.String(), nil
}

func writeMarkdownFile(outputPath, content string) error {
	// Create directory if it doesn't exist
	dir := filepath.Dir(outputPath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return err
	}

	// Write file
	return os.WriteFile(outputPath, []byte(content), 0644)
}

// Helper functions (reused from previous scripts)
func isDocumentationFile(path, name string) bool {
	ext := strings.ToLower(filepath.Ext(name))
	docExts := []string{".md", ".txt", ".rst", ".adoc", ".org"}

	for _, docExt := range docExts {
		if ext == docExt {
			return true
		}
	}

	baseName := strings.ToUpper(name)
	specialFiles := []string{"README", "CHANGELOG", "LICENSE", "AUTHORS", "CONTRIBUTORS"}
	for _, special := range specialFiles {
		if strings.HasPrefix(baseName, special) {
			return true
		}
	}

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
		if strings.HasPrefix(pathLower, skip+"/") ||
			strings.Contains(pathLower, "/"+skip+"/") ||
			strings.HasSuffix(pathLower, "/"+skip) ||
			pathLower == skip {
			return true
		}
	}
	return false
}

func categorizeFile(path, name string) string {
	pathLower := strings.ToLower(path)
	nameLower := strings.ToLower(name)

	if !strings.Contains(path, "/") && !strings.Contains(path, "\\") {
		return "root"
	}

	if strings.HasPrefix(pathLower, ".github/") || strings.Contains(pathLower, "/.github/") {
		return "github"
	}

	if strings.HasPrefix(pathLower, "docs/") || strings.Contains(pathLower, "/docs/") {
		return "documentation"
	}

	if strings.HasPrefix(pathLower, "development/") || strings.Contains(pathLower, "/development/") {
		return "development"
	}

	if strings.HasPrefix(pathLower, "projet/") || strings.Contains(pathLower, "/projet/") ||
		strings.HasPrefix(pathLower, "planning/") || strings.Contains(pathLower, "/planning/") {
		return "project-management"
	}

	if strings.Contains(nameLower, "api") || strings.Contains(pathLower, "/api/") || strings.HasPrefix(pathLower, "api/") {
		if strings.Contains(pathLower, "/docs/") || strings.HasPrefix(pathLower, "docs/") {
			return "documentation"
		}
		return "api"
	}

	if strings.Contains(pathLower, "/test") || strings.Contains(nameLower, "test") ||
		strings.HasPrefix(pathLower, "test") {
		return "testing"
	}

	if strings.Contains(nameLower, "config") || strings.Contains(nameLower, "setup") {
		return "configuration"
	}

	return "general"
}

func extractTags(path, name string) []string {
	var tags []string

	pathLower := strings.ToLower(path)
	nameLower := strings.ToLower(name)

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

	depth := strings.Count(path, "/")
	metadata["depth"] = fmt.Sprintf("%d", depth)

	if dir := filepath.Dir(path); dir != "." {
		metadata["parent_dir"] = filepath.Base(dir)
	}

	return metadata
}

func getFileType(ext string) string {
	switch strings.ToLower(ext) {
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

func calculateDocumentLevel(path string) int {
	// Level based on directory depth and file importance
	depth := strings.Count(path, "/")

	// Root files are level 0
	if depth == 0 {
		return 0
	}

	// Important files in subdirectories are lower level
	filename := strings.ToLower(filepath.Base(path))
	if strings.Contains(filename, "readme") || strings.Contains(filename, "index") {
		return depth - 1
	}

	return depth
}
