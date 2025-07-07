package commands

import (
	"fmt"
	"os"
	"strings"
	"time"

	"email_sender/cmd/roadmap-cli/ingestion"
	"email_sender/cmd/roadmap-cli/storage"
	"email_sender/cmd/roadmap-cli/types"

	"github.com/spf13/cobra"
)

// AdvancedIngestCmd represents the advanced ingest command
var AdvancedIngestCmd = &cobra.Command{
	Use:   "ingest-advanced [file_or_directory]",
	Short: "Advanced ingestion with deep technical analysis", Long: `Advanced ingestion command that supports:
- Deep hierarchical parsing up to 12 levels of hierarchy
- Technical specification extraction (database schemas, APIs, code references)
- Complex dependency analysis
- Implementation step extraction
- Complexity metrics calculation
- Performance target analysis`,
	Args: cobra.ExactArgs(1),
	RunE: runAdvancedIngest,
}

// Advanced ingest flags
var (
	maxDepth              int
	includeTechnicalSpecs bool
	analyzeDependencies   bool
	extractComplexity     bool
	parseCodeReferences   bool
	parseDatabaseSchemas  bool
	parseAPIEndpoints     bool
	outputFormat          string
	showAnalytics         bool
	exportTechnicalSpecs  bool
	dryRunAdvanced        bool
)

func init() {
	AdvancedIngestCmd.Flags().IntVar(&maxDepth, "max-depth", 12, "Maximum hierarchy depth to parse (up to 12 levels)")
	AdvancedIngestCmd.Flags().BoolVar(&includeTechnicalSpecs, "include-technical-specs", true, "Include technical specifications parsing")
	AdvancedIngestCmd.Flags().BoolVar(&analyzeDependencies, "analyze-dependencies", true, "Analyze and extract dependencies")
	AdvancedIngestCmd.Flags().BoolVar(&extractComplexity, "extract-complexity", true, "Extract complexity metrics")
	AdvancedIngestCmd.Flags().BoolVar(&parseCodeReferences, "parse-code-references", true, "Parse code file references")
	AdvancedIngestCmd.Flags().BoolVar(&parseDatabaseSchemas, "parse-database-schemas", true, "Parse database schema definitions")
	AdvancedIngestCmd.Flags().BoolVar(&parseAPIEndpoints, "parse-api-endpoints", true, "Parse API endpoint definitions")
	AdvancedIngestCmd.Flags().StringVar(&outputFormat, "output", "json", "Output format: json, yaml, summary")
	AdvancedIngestCmd.Flags().BoolVar(&showAnalytics, "show-analytics", true, "Show analytics and metrics")
	AdvancedIngestCmd.Flags().BoolVar(&exportTechnicalSpecs, "export-tech-specs", false, "Export technical specifications separately")
	AdvancedIngestCmd.Flags().BoolVar(&dryRunAdvanced, "dry-run", false, "Parse and analyze without saving")
}

func runAdvancedIngest(cmd *cobra.Command, args []string) error {
	inputPath := args[0]

	// Create advanced parser configuration
	config := &ingestion.AdvancedParserConfig{
		MaxDepth:              maxDepth,
		IncludeTechnicalSpecs: includeTechnicalSpecs,
		AnalyzeDependencies:   analyzeDependencies,
		ExtractComplexity:     extractComplexity,
		ParseCodeReferences:   parseCodeReferences,
		ParseDatabaseSchemas:  parseDatabaseSchemas,
		ParseAPIEndpoints:     parseAPIEndpoints,
	}

	parser := ingestion.NewAdvancedPlanParser(config)

	// Check if input is file or directory
	fileInfo, err := os.Stat(inputPath)
	if err != nil {
		return fmt.Errorf("error accessing path %s: %v", inputPath, err)
	}

	var roadmaps []*types.AdvancedRoadmap

	if fileInfo.IsDir() {
		roadmaps, err = processAdvancedDirectory(parser, inputPath)
	} else {
		roadmap, err := processAdvancedFile(parser, inputPath)
		if err == nil {
			roadmaps = []*types.AdvancedRoadmap{roadmap}
		}
	}

	if err != nil {
		return err
	}

	// Display results
	for _, roadmap := range roadmaps {
		displayAdvancedRoadmap(roadmap)

		if !dryRunAdvanced {
			err = saveAdvancedRoadmap(roadmap)
			if err != nil {
				fmt.Printf("Error saving roadmap %s: %v\n", roadmap.Name, err)
			}
		}
	}

	fmt.Printf("\nProcessed %d roadmap(s) successfully\n", len(roadmaps))
	return nil
}

func processAdvancedFile(parser *ingestion.AdvancedPlanParser, filepath string) (*types.AdvancedRoadmap, error) {
	content, err := os.ReadFile(filepath)
	if err != nil {
		return nil, fmt.Errorf("error reading file %s: %v", filepath, err)
	}

	fmt.Printf("Parsing advanced roadmap: %s\n", filepath)
	roadmap, err := parser.ParseAdvancedRoadmap(string(content), filepath)
	if err != nil {
		return nil, fmt.Errorf("error parsing roadmap: %v", err)
	}

	return roadmap, nil
}

func processAdvancedDirectory(parser *ingestion.AdvancedPlanParser, dirPath string) ([]*types.AdvancedRoadmap, error) {
	var roadmaps []*types.AdvancedRoadmap

	entries, err := os.ReadDir(dirPath)
	if err != nil {
		return nil, fmt.Errorf("error reading directory %s: %v", dirPath, err)
	}

	for _, entry := range entries {
		if entry.IsDir() {
			continue
		}

		if filepath := entry.Name(); isMarkdownFile(filepath) {
			fullPath := fmt.Sprintf("%s/%s", dirPath, filepath)
			roadmap, err := processAdvancedFile(parser, fullPath)
			if err != nil {
				fmt.Printf("Warning: failed to process %s: %v\n", fullPath, err)
				continue
			}
			roadmaps = append(roadmaps, roadmap)
		}
	}

	return roadmaps, nil
}

func displayAdvancedRoadmap(roadmap *types.AdvancedRoadmap) {
	fmt.Printf("\n=== Advanced Roadmap: %s ===\n", roadmap.Name)
	fmt.Printf("Description: %s\n", roadmap.Description)
	fmt.Printf("Total Items: %d\n", roadmap.TotalItems)
	fmt.Printf("Max Depth: %d\n", roadmap.MaxDepth)
	fmt.Printf("Progress: %.1f%%\n", roadmap.OverallProgress)

	if roadmap.EffortEstimation > 0 {
		fmt.Printf("Estimated Effort: %s\n", formatDuration(roadmap.EffortEstimation))
	}

	if showAnalytics {
		displayAnalytics(roadmap)
	}

	if outputFormat == "summary" {
		displayHierarchySummary(roadmap)
	} else {
		displayDetailedItems(roadmap)
	}

	if exportTechnicalSpecs {
		displayTechnicalSpecs(roadmap)
	}
}

func displayAnalytics(roadmap *types.AdvancedRoadmap) {
	fmt.Printf("\n--- Analytics ---\n")

	if len(roadmap.ComplexityDistribution) > 0 {
		fmt.Printf("Complexity Distribution:\n")
		for level, count := range roadmap.ComplexityDistribution {
			fmt.Printf("  %s: %d items\n", level, count)
		}
	}

	if len(roadmap.TechStack) > 0 {
		fmt.Printf("Tech Stack: %v\n", roadmap.TechStack)
	}

	if len(roadmap.DatabaseTypes) > 0 {
		fmt.Printf("Database Types: %v\n", roadmap.DatabaseTypes)
	}

	if roadmap.RiskAssessment != "" {
		fmt.Printf("Risk Assessment: %s\n", roadmap.RiskAssessment)
	}
}

func displayHierarchySummary(roadmap *types.AdvancedRoadmap) {
	fmt.Printf("\n--- Hierarchy Summary ---\n")

	for level := 1; level <= roadmap.MaxDepth; level++ {
		levelKey := fmt.Sprintf("level_%d", level)
		if items, exists := roadmap.Hierarchy[levelKey]; exists && len(items) > 0 {
			fmt.Printf("Level %d: %d items\n", level, len(items))
		}
	}
}

func displayDetailedItems(roadmap *types.AdvancedRoadmap) {
	fmt.Printf("\n--- Items ---\n")

	for _, item := range roadmap.Items {
		displayAdvancedItem(&item)
	}
}

func displayAdvancedItem(item *types.AdvancedRoadmapItem) {
	indent := strings.Repeat("  ", item.Hierarchy.Level-1)
	fmt.Printf("%s[L%d] %s\n", indent, item.Hierarchy.Level, item.Title)

	if item.Description != "" && len(item.Description) < 100 {
		fmt.Printf("%s    %s\n", indent, item.Description)
	}

	// Display key metrics
	if item.Priority != "medium" {
		fmt.Printf("%s    Priority: %s\n", indent, item.Priority)
	}

	if item.ComplexityMetrics.Overall.Score > 0 {
		fmt.Printf("%s    Complexity: %s (%d/10)\n", indent,
			item.ComplexityMetrics.Overall.Level,
			item.ComplexityMetrics.Overall.Score)
	}

	if item.EstimatedEffort > 0 {
		fmt.Printf("%s    Effort: %s\n", indent, formatDuration(item.EstimatedEffort))
	}

	if len(item.TechnicalDependencies) > 0 {
		fmt.Printf("%s    Dependencies: %d\n", indent, len(item.TechnicalDependencies))
	}

	if len(item.ImplementationSteps) > 0 {
		fmt.Printf("%s    Steps: %d\n", indent, len(item.ImplementationSteps))
	}

	// Display technical specs summary
	if hasNonEmptyTechnicalSpecs(&item.TechnicalSpec) {
		fmt.Printf("%s    Technical Specs: ", indent)
		specs := []string{}
		if len(item.TechnicalSpec.DatabaseSchemas) > 0 {
			specs = append(specs, fmt.Sprintf("%d DB schemas", len(item.TechnicalSpec.DatabaseSchemas)))
		}
		if len(item.TechnicalSpec.APIEndpoints) > 0 {
			specs = append(specs, fmt.Sprintf("%d API endpoints", len(item.TechnicalSpec.APIEndpoints)))
		}
		if len(item.TechnicalSpec.CodeReferences) > 0 {
			specs = append(specs, fmt.Sprintf("%d code refs", len(item.TechnicalSpec.CodeReferences)))
		}
		fmt.Printf("%s\n", strings.Join(specs, ", "))
	}
}

func displayTechnicalSpecs(roadmap *types.AdvancedRoadmap) {
	fmt.Printf("\n--- Technical Specifications Export ---\n")

	for _, item := range roadmap.Items {
		if hasNonEmptyTechnicalSpecs(&item.TechnicalSpec) {
			fmt.Printf("\n## %s\n", item.Title)

			// Database schemas
			for _, schema := range item.TechnicalSpec.DatabaseSchemas {
				fmt.Printf("\n### Database Table: %s\n", schema.TableName)
				for _, field := range schema.Fields {
					fmt.Printf("- %s (%s)", field.Name, field.Type)
					if field.PrimaryKey {
						fmt.Printf(" [PK]")
					}
					if field.ForeignKey != "" {
						fmt.Printf(" [FK: %s]", field.ForeignKey)
					}
					fmt.Printf("\n")
				}
			}

			// API endpoints
			for _, endpoint := range item.TechnicalSpec.APIEndpoints {
				fmt.Printf("\n### API: %s %s\n", endpoint.Method, endpoint.Path)
				if endpoint.Description != "" {
					fmt.Printf("%s\n", endpoint.Description)
				}
				for _, param := range endpoint.Parameters {
					fmt.Printf("- %s (%s)", param.Name, param.Type)
					if param.Required {
						fmt.Printf(" [Required]")
					}
					fmt.Printf("\n")
				}
			}

			// Code references
			for _, codeRef := range item.TechnicalSpec.CodeReferences {
				fmt.Printf("\n### Code: %s (%s)\n", codeRef.FilePath, codeRef.Language)
				if codeRef.Description != "" {
					fmt.Printf("%s\n", codeRef.Description)
				}
			}
		}
	}
}

func saveAdvancedRoadmap(roadmap *types.AdvancedRoadmap) error {
	storageManager := storage.NewStorageManager()

	// Convert to basic roadmap format for storage compatibility
	basicRoadmap := convertToBasicRoadmap(roadmap)

	return storageManager.SaveRoadmap(basicRoadmap)
}

func convertToBasicRoadmap(advanced *types.AdvancedRoadmap) *types.Roadmap {
	basic := &types.Roadmap{
		Version:   advanced.Version,
		CreatedAt: advanced.CreatedAt,
		UpdatedAt: advanced.UpdatedAt,
		Items:     []types.RoadmapItem{},
	}

	for _, advItem := range advanced.Items {
		basicItem := types.RoadmapItem{
			ID:          advItem.ID,
			Title:       advItem.Title,
			Description: advItem.Description,
			Status:      types.Status(advItem.Status),
			Priority:    types.Priority(advItem.Priority),
			CreatedAt:   advItem.CreatedAt,
			UpdatedAt:   advItem.UpdatedAt,
		}

		// Add complexity and hierarchy info to description
		if advItem.ComplexityMetrics.Overall.Score > 0 {
			basicItem.Description += fmt.Sprintf("\n[Complexity: %s (%d/10)]",
				advItem.ComplexityMetrics.Overall.Level,
				advItem.ComplexityMetrics.Overall.Score)
		}

		if len(advItem.HierarchyPath) > 0 {
			basicItem.Description += fmt.Sprintf("\n[Hierarchy: %s]",
				strings.Join(advItem.HierarchyPath, " > "))
		}

		basic.Items = append(basic.Items, basicItem)
	}

	return basic
}

func hasNonEmptyTechnicalSpecs(spec *types.TechnicalSpec) bool {
	return len(spec.DatabaseSchemas) > 0 ||
		len(spec.APIEndpoints) > 0 ||
		len(spec.CodeReferences) > 0 ||
		len(spec.SystemRequirements) > 0 ||
		len(spec.PerformanceTargets) > 0
}

func formatDuration(d time.Duration) string {
	hours := d.Hours()
	if hours < 24 {
		return fmt.Sprintf("%.1f hours", hours)
	}
	days := hours / 24
	if days < 7 {
		return fmt.Sprintf("%.1f days", days)
	}
	weeks := days / 7
	return fmt.Sprintf("%.1f weeks", weeks)
}

func isMarkdownFile(filename string) bool {
	return strings.HasSuffix(strings.ToLower(filename), ".md")
}
