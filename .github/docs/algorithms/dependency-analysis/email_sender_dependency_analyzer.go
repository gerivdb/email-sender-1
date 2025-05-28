// email_sender_dependency_analyzer.go
// Algorithm 3: Dependency Graph Analysis for EMAIL_SENDER_1
// Analyzes circular dependencies and component interactions across the multi-stack system

package main

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
	"time"
)

// DependencyNode represents a component in the dependency graph
type DependencyNode struct {
	Name         string            `json:"name"`
	Type         string            `json:"type"`
	Path         string            `json:"path"`
	Dependencies []string          `json:"dependencies"`
	Dependents   []string          `json:"dependents"`
	Circular     []string          `json:"circular"`
	Depth        int               `json:"depth"`
	Metadata     map[string]string `json:"metadata"`
}

// DependencyGraph represents the complete dependency structure
type DependencyGraph struct {
	Nodes       map[string]*DependencyNode `json:"nodes"`
	Edges       []DependencyEdge           `json:"edges"`
	Circular    []CircularDependency       `json:"circular"`
	Stats       DependencyStats            `json:"stats"`
	Timestamp   time.Time                  `json:"timestamp"`
	ProjectPath string                     `json:"project_path"`
}

// DependencyEdge represents a dependency relationship
type DependencyEdge struct {
	From   string `json:"from"`
	To     string `json:"to"`
	Type   string `json:"type"`
	Weight int    `json:"weight"`
}

// CircularDependency represents a circular dependency cycle
type CircularDependency struct {
	Cycle    []string `json:"cycle"`
	Length   int      `json:"length"`
	Severity string   `json:"severity"`
	Impact   string   `json:"impact"`
}

// DependencyStats provides analysis statistics
type DependencyStats struct {
	TotalNodes     int `json:"total_nodes"`
	TotalEdges     int `json:"total_edges"`
	CircularCycles int `json:"circular_cycles"`
	MaxDepth       int `json:"max_depth"`
	IsolatedNodes  int `json:"isolated_nodes"`
	CriticalNodes  int `json:"critical_nodes"`
}

// EMAIL_SENDER_1 Component Types
var componentTypes = map[string]string{
	".md":    "documentation",
	".ps1":   "powershell_script",
	".py":    "python_script",
	".js":    "javascript",
	".json":  "configuration",
	".yml":   "configuration",
	".yaml":  "configuration",
	".go":    "go_module",
	".ts":    "typescript",
	".env":   "environment",
	"n8n":    "n8n_workflow",
	"notion": "notion_integration",
	"gmail":  "gmail_processor",
	"rag":    "rag_engine",
}

// EMAIL_SENDER_1 Dependency Patterns
var dependencyPatterns = map[string]*regexp.Regexp{
	"powershell_import":   regexp.MustCompile(`(?i)^\s*\.\s+(.+\.ps1)`),
	"powershell_module":   regexp.MustCompile(`(?i)Import-Module\s+(.+)`),
	"python_import":       regexp.MustCompile(`(?i)^(?:from\s+(.+)\s+)?import\s+(.+)`),
	"javascript_require":  regexp.MustCompile(`(?i)require\(['"](.+)['"]\)`),
	"javascript_import":   regexp.MustCompile(`(?i)import\s+.+\s+from\s+['"](.+)['"]`),
	"json_reference":      regexp.MustCompile(`(?i)["'](.+\.json)["']`),
	"config_reference":    regexp.MustCompile(`(?i)["'](.+\.(?:yml|yaml|env))["']`),
	"file_path_reference": regexp.MustCompile(`(?i)["']([./\\].+\.(?:ps1|py|js|json|yml|yaml))["']`),
	"n8n_workflow_ref":    regexp.MustCompile(`(?i)workflow[_-]?(?:id|name)["']\s*:\s*["'](.+)["']`),
	"notion_database_ref": regexp.MustCompile(`(?i)database[_-]?(?:id|name)["']\s*:\s*["'](.+)["']`),
}

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: go run email_sender_dependency_analyzer.go <project_path> [output_file]")
		os.Exit(1)
	}

	projectPath := os.Args[1]
	outputFile := "dependency_analysis.json"
	if len(os.Args) > 2 {
		outputFile = os.Args[2]
	}

	fmt.Printf("🔗 EMAIL_SENDER_1 Dependency Analysis Starting...\n")
	fmt.Printf("📁 Project Path: %s\n", projectPath)
	fmt.Printf("📄 Output File: %s\n", outputFile)

	analyzer := NewDependencyAnalyzer(projectPath)

	// Step 1: Scan and build dependency graph
	fmt.Printf("\n🔍 Step 1: Scanning project structure...\n")
	err := analyzer.ScanProject()
	if err != nil {
		log.Fatalf("Error scanning project: %v", err)
	}

	// Step 2: Analyze dependencies
	fmt.Printf("\n🔗 Step 2: Analyzing dependencies...\n")
	analyzer.AnalyzeDependencies()

	// Step 3: Detect circular dependencies
	fmt.Printf("\n🔄 Step 3: Detecting circular dependencies...\n")
	analyzer.DetectCircularDependencies()

	// Step 4: Calculate statistics
	fmt.Printf("\n📊 Step 4: Calculating statistics...\n")
	analyzer.CalculateStats()

	// Step 5: Generate report
	fmt.Printf("\n📋 Step 5: Generating dependency report...\n")
	err = analyzer.GenerateReport(outputFile)
	if err != nil {
		log.Fatalf("Error generating report: %v", err)
	}

	// Display summary
	analyzer.DisplaySummary()

	fmt.Printf("\n✅ Dependency analysis complete! Report saved to: %s\n", outputFile)
}

// NewDependencyAnalyzer creates a new dependency analyzer
func NewDependencyAnalyzer(projectPath string) *DependencyGraph {
	return &DependencyGraph{
		Nodes:       make(map[string]*DependencyNode),
		Edges:       []DependencyEdge{},
		Circular:    []CircularDependency{},
		Timestamp:   time.Now(),
		ProjectPath: projectPath,
	}
}

// ScanProject scans the project directory for components
func (dg *DependencyGraph) ScanProject() error {
	return filepath.Walk(dg.ProjectPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil // Skip errors, continue scanning
		}

		if info.IsDir() {
			return nil // Skip directories
		}

		// Skip hidden files and directories
		if strings.HasPrefix(info.Name(), ".") && info.Name() != ".env" {
			return nil
		}

		// Skip binary and large files
		if info.Size() > 10*1024*1024 { // 10MB limit
			return nil
		}

		ext := strings.ToLower(filepath.Ext(path))
		relativePath, _ := filepath.Rel(dg.ProjectPath, path)
		nodeKey := strings.ReplaceAll(relativePath, "\\", "/")

		// Determine component type
		componentType := "unknown"
		if ct, exists := componentTypes[ext]; exists {
			componentType = ct
		}

		// Special cases for EMAIL_SENDER_1 components
		if strings.Contains(strings.ToLower(path), "n8n") {
			componentType = "n8n_workflow"
		} else if strings.Contains(strings.ToLower(path), "notion") {
			componentType = "notion_integration"
		} else if strings.Contains(strings.ToLower(path), "gmail") {
			componentType = "gmail_processor"
		} else if strings.Contains(strings.ToLower(path), "rag") {
			componentType = "rag_engine"
		}

		// Create dependency node
		node := &DependencyNode{
			Name:         nodeKey,
			Type:         componentType,
			Path:         path,
			Dependencies: []string{},
			Dependents:   []string{},
			Circular:     []string{},
			Depth:        0,
			Metadata:     make(map[string]string),
		}

		node.Metadata["size"] = fmt.Sprintf("%d", info.Size())
		node.Metadata["modified"] = info.ModTime().Format(time.RFC3339)

		dg.Nodes[nodeKey] = node
		return nil
	})
}

// AnalyzeDependencies analyzes dependencies between components
func (dg *DependencyGraph) AnalyzeDependencies() {
	for nodeKey, node := range dg.Nodes {
		dependencies := dg.extractDependencies(node.Path)

		for _, dep := range dependencies {
			// Normalize dependency path
			depPath := dg.normalizePath(dep, filepath.Dir(node.Path))
			relDepPath, _ := filepath.Rel(dg.ProjectPath, depPath)
			depKey := strings.ReplaceAll(relDepPath, "\\", "/")

			// Check if dependency exists in our graph
			if _, exists := dg.Nodes[depKey]; exists {
				node.Dependencies = append(node.Dependencies, depKey)

				// Add edge
				edge := DependencyEdge{
					From:   nodeKey,
					To:     depKey,
					Type:   "direct",
					Weight: 1,
				}
				dg.Edges = append(dg.Edges, edge)

				// Add to dependents
				if dg.Nodes[depKey] != nil {
					dg.Nodes[depKey].Dependents = append(dg.Nodes[depKey].Dependents, nodeKey)
				}
			}
		}
	}
}

// extractDependencies extracts dependencies from a file
func (dg *DependencyGraph) extractDependencies(filePath string) []string {
	dependencies := []string{}

	content, err := ioutil.ReadFile(filePath)
	if err != nil {
		return dependencies
	}

	contentStr := string(content)
	lines := strings.Split(contentStr, "\n")

	for _, line := range lines {
		line = strings.TrimSpace(line)

		// Skip comments and empty lines
		if strings.HasPrefix(line, "#") || strings.HasPrefix(line, "//") || line == "" {
			continue
		}
		// Apply dependency patterns
		for _, pattern := range dependencyPatterns {
			matches := pattern.FindAllStringSubmatch(line, -1)
			for _, match := range matches {
				if len(match) > 1 {
					dep := strings.TrimSpace(match[1])
					if dep != "" {
						dependencies = append(dependencies, dep)
					}
				}
			}
		}
	}

	return dg.uniqueStrings(dependencies)
}

// normalizePath normalizes a dependency path
func (dg *DependencyGraph) normalizePath(depPath, baseDir string) string {
	if filepath.IsAbs(depPath) {
		return depPath
	}

	// Handle relative paths
	if strings.HasPrefix(depPath, "./") || strings.HasPrefix(depPath, "../") {
		return filepath.Join(baseDir, depPath)
	}

	// Handle module names (try to find in project)
	possiblePaths := []string{
		filepath.Join(dg.ProjectPath, depPath),
		filepath.Join(baseDir, depPath),
		filepath.Join(dg.ProjectPath, "scripts", depPath),
		filepath.Join(dg.ProjectPath, "src", depPath),
		filepath.Join(dg.ProjectPath, "lib", depPath),
	}

	for _, path := range possiblePaths {
		if _, err := os.Stat(path); err == nil {
			return path
		}
		// Try with common extensions
		for ext := range componentTypes {
			if ext != "" {
				extPath := path + ext
				if _, err := os.Stat(extPath); err == nil {
					return extPath
				}
			}
		}
	}

	return filepath.Join(baseDir, depPath)
}

// DetectCircularDependencies detects circular dependency cycles
func (dg *DependencyGraph) DetectCircularDependencies() {
	visited := make(map[string]bool)
	recursionStack := make(map[string]bool)

	for nodeKey := range dg.Nodes {
		if !visited[nodeKey] {
			dg.dfsCircular(nodeKey, visited, recursionStack, []string{})
		}
	}
}

// dfsCircular performs DFS to detect circular dependencies
func (dg *DependencyGraph) dfsCircular(nodeKey string, visited, recursionStack map[string]bool, path []string) {
	visited[nodeKey] = true
	recursionStack[nodeKey] = true
	path = append(path, nodeKey)

	node := dg.Nodes[nodeKey]
	if node == nil {
		return
	}

	for _, dep := range node.Dependencies {
		if !visited[dep] {
			dg.dfsCircular(dep, visited, recursionStack, path)
		} else if recursionStack[dep] {
			// Found circular dependency
			cycleStart := -1
			for i, p := range path {
				if p == dep {
					cycleStart = i
					break
				}
			}

			if cycleStart >= 0 {
				cycle := append(path[cycleStart:], dep)

				// Determine severity
				severity := "medium"
				impact := "Moderate coupling between components"

				if len(cycle) <= 3 {
					severity = "high"
					impact = "Direct circular dependency - high risk"
				} else if len(cycle) > 5 {
					severity = "low"
					impact = "Complex cycle - may indicate architectural issues"
				}

				circular := CircularDependency{
					Cycle:    cycle,
					Length:   len(cycle) - 1,
					Severity: severity,
					Impact:   impact,
				}

				dg.Circular = append(dg.Circular, circular)

				// Mark nodes as circular
				for _, cycleNode := range cycle {
					if n := dg.Nodes[cycleNode]; n != nil {
						n.Circular = append(n.Circular, strings.Join(cycle, " -> "))
					}
				}
			}
		}
	}

	recursionStack[nodeKey] = false
}

// CalculateStats calculates dependency statistics
func (dg *DependencyGraph) CalculateStats() {
	stats := DependencyStats{
		TotalNodes:     len(dg.Nodes),
		TotalEdges:     len(dg.Edges),
		CircularCycles: len(dg.Circular),
	}

	maxDepth := 0
	isolatedNodes := 0
	criticalNodes := 0

	for _, node := range dg.Nodes {
		// Calculate depth
		depth := dg.calculateDepth(node.Name, make(map[string]bool))
		node.Depth = depth
		if depth > maxDepth {
			maxDepth = depth
		}

		// Check isolated nodes
		if len(node.Dependencies) == 0 && len(node.Dependents) == 0 {
			isolatedNodes++
		}

		// Check critical nodes (high dependency count)
		if len(node.Dependents) > 5 || len(node.Dependencies) > 10 {
			criticalNodes++
		}
	}

	stats.MaxDepth = maxDepth
	stats.IsolatedNodes = isolatedNodes
	stats.CriticalNodes = criticalNodes

	dg.Stats = stats
}

// calculateDepth calculates the dependency depth of a node
func (dg *DependencyGraph) calculateDepth(nodeKey string, visited map[string]bool) int {
	if visited[nodeKey] {
		return 0 // Avoid infinite recursion
	}

	visited[nodeKey] = true
	node := dg.Nodes[nodeKey]
	if node == nil || len(node.Dependencies) == 0 {
		return 0
	}

	maxDepth := 0
	for _, dep := range node.Dependencies {
		depth := dg.calculateDepth(dep, visited)
		if depth > maxDepth {
			maxDepth = depth
		}
	}

	return maxDepth + 1
}

// GenerateReport generates a JSON report of the dependency analysis
func (dg *DependencyGraph) GenerateReport(outputFile string) error {
	jsonData, err := json.MarshalIndent(dg, "", "  ")
	if err != nil {
		return err
	}

	return ioutil.WriteFile(outputFile, jsonData, 0644)
}

// DisplaySummary displays a summary of the dependency analysis
func (dg *DependencyGraph) DisplaySummary() {
	fmt.Printf("\n" + strings.Repeat("=", 60) + "\n")
	fmt.Printf("📊 EMAIL_SENDER_1 DEPENDENCY ANALYSIS SUMMARY\n")
	fmt.Printf(strings.Repeat("=", 60) + "\n")

	fmt.Printf("📁 Project: %s\n", dg.ProjectPath)
	fmt.Printf("🕐 Analysis Time: %s\n\n", dg.Timestamp.Format("2006-01-02 15:04:05"))

	fmt.Printf("📈 STATISTICS:\n")
	fmt.Printf("  • Total Components: %d\n", dg.Stats.TotalNodes)
	fmt.Printf("  • Total Dependencies: %d\n", dg.Stats.TotalEdges)
	fmt.Printf("  • Maximum Depth: %d\n", dg.Stats.MaxDepth)
	fmt.Printf("  • Isolated Components: %d\n", dg.Stats.IsolatedNodes)
	fmt.Printf("  • Critical Components: %d\n", dg.Stats.CriticalNodes)

	fmt.Printf("\n🔄 CIRCULAR DEPENDENCIES:\n")
	fmt.Printf("  • Total Cycles: %d\n", dg.Stats.CircularCycles)

	if len(dg.Circular) > 0 {
		fmt.Printf("\n⚠️  CIRCULAR DEPENDENCY DETAILS:\n")

		// Sort by severity
		sort.Slice(dg.Circular, func(i, j int) bool {
			severity := map[string]int{"high": 3, "medium": 2, "low": 1}
			return severity[dg.Circular[i].Severity] > severity[dg.Circular[j].Severity]
		})

		for i, circular := range dg.Circular {
			if i >= 5 { // Limit display to top 5
				fmt.Printf("  ... and %d more cycles\n", len(dg.Circular)-5)
				break
			}

			fmt.Printf("  %d. [%s] Length: %d\n", i+1, strings.ToUpper(circular.Severity), circular.Length)
			fmt.Printf("     Cycle: %s\n", strings.Join(circular.Cycle, " → "))
			fmt.Printf("     Impact: %s\n\n", circular.Impact)
		}
	} else {
		fmt.Printf("  ✅ No circular dependencies detected!\n")
	}

	// Component type breakdown
	typeCount := make(map[string]int)
	for _, node := range dg.Nodes {
		typeCount[node.Type]++
	}

	fmt.Printf("\n📋 COMPONENT BREAKDOWN:\n")
	for componentType, count := range typeCount {
		fmt.Printf("  • %s: %d\n", strings.Title(strings.ReplaceAll(componentType, "_", " ")), count)
	}

	fmt.Printf("\n" + strings.Repeat("=", 60) + "\n")
}

// uniqueStrings removes duplicates from a string slice
func (dg *DependencyGraph) uniqueStrings(slice []string) []string {
	keys := make(map[string]bool)
	result := []string{}

	for _, item := range slice {
		if !keys[item] {
			keys[item] = true
			result = append(result, item)
		}
	}

	return result
}
