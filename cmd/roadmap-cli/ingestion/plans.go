// Package ingestion provides functionality to ingest and process roadmap plans
// from the EMAIL_SENDER_1 ecosystem consolidated plans directory
package ingestion

import (
	"bufio"
	"context"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"time"

	"email_sender/cmd/roadmap-cli/storage"
	"email_sender/cmd/roadmap-cli/types"

	"github.com/google/uuid"
)

// PlanIngester handles the ingestion of consolidated roadmap plans
type PlanIngester struct {
	plansDir  string
	ragClient RAGClient
	chunks    []PlanChunk
}

// RAGClient interface for vector storage operations
type RAGClient interface {
	IndexRoadmapItem(ctx context.Context, itemID, title, description string, metadata map[string]interface{}) error
	HealthCheck(ctx context.Context) error
}

// PlanChunk represents a processed chunk of a plan file
type PlanChunk struct {
	ID           string                 `json:"id"`
	PlanFile     string                 `json:"plan_file"`
	Title        string                 `json:"title"`
	Content      string                 `json:"content"`
	Type         string                 `json:"type"`  // "header", "task", "section", "list_item"
	Level        int                    `json:"level"` // For headers: 1, 2, 3, etc.
	Metadata     map[string]interface{} `json:"metadata"`
	Dependencies []string               `json:"dependencies"`
	CreatedAt    time.Time              `json:"created_at"`
}

// EnrichedPlanItem represents a parsed plan item with enriched metadata
type EnrichedPlanItem struct {
	Title         string
	Description   string
	Priority      types.Priority
	Status        types.Status
	Complexity    types.BasicComplexity
	RiskLevel     types.RiskLevel
	Inputs        []types.TaskInput
	Outputs       []types.TaskOutput
	Scripts       []types.TaskScript
	Prerequisites []string
	Methods       []string
	URIs          []string
	Tools         []string
	Frameworks    []string
	Effort        int
	BusinessValue int
	TechnicalDebt int
	Tags          []string
	TargetDate    time.Time
	SourceFile    string
	LineNumber    int
}

// EnrichedIngestionResult extends the basic result with enriched item counts
type EnrichedIngestionResult struct {
	*IngestionResult
	EnrichedItemsCreated int                `json:"enriched_items_created"`
	EnrichedItems        []EnrichedPlanItem `json:"enriched_items"`
}

// IngestionResult contains statistics about the ingestion process
type IngestionResult struct {
	FilesProcessed    int           `json:"files_processed"`
	ChunksCreated     int           `json:"chunks_created"`
	DependenciesFound int           `json:"dependencies_found"`
	Errors            []string      `json:"errors"`
	ProcessingTime    time.Duration `json:"processing_time"`
}

// NewPlanIngester creates a new plan ingester for the EMAIL_SENDER_1 ecosystem
func NewPlanIngester(plansDir string, ragClient RAGClient) *PlanIngester {
	return &PlanIngester{
		plansDir:  plansDir,
		ragClient: ragClient,
		chunks:    make([]PlanChunk, 0),
	}
}

// IngestAllPlans processes all markdown files in the consolidated plans directory
func (p *PlanIngester) IngestAllPlans(ctx context.Context) (*IngestionResult, error) {
	fmt.Printf("DEBUG: Starting IngestAllPlans for directory: %s\n", p.plansDir)
	startTime := time.Now()
	result := &IngestionResult{
		Errors: make([]string, 0),
	}

	// Check if plans directory exists
	if _, err := os.Stat(p.plansDir); os.IsNotExist(err) {
		fmt.Printf("DEBUG: Plans directory does not exist: %s\n", p.plansDir)
		return nil, fmt.Errorf("plans directory does not exist: %s", p.plansDir)
	}
	fmt.Printf("DEBUG: Plans directory exists, starting file walk\n")

	// Walk through all markdown files
	err := filepath.Walk(p.plansDir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			fmt.Printf("DEBUG: Error accessing %s: %v\n", path, err)
			result.Errors = append(result.Errors, fmt.Sprintf("Error accessing %s: %v", path, err))
			return nil // Continue processing other files
		}

		// Process only markdown files
		if !info.IsDir() && strings.HasSuffix(strings.ToLower(info.Name()), ".md") {
			fmt.Printf("DEBUG: Processing markdown file: %s\n", path)
			if err := p.processPlanFile(ctx, path); err != nil {
				fmt.Printf("DEBUG: Error processing %s: %v\n", path, err)
				result.Errors = append(result.Errors, fmt.Sprintf("Error processing %s: %v", path, err))
			} else {
				result.FilesProcessed++
				fmt.Printf("DEBUG: Successfully processed %s (chunks so far: %d)\n", path, len(p.chunks))
			}
		}

		return nil
	})

	if err != nil {
		fmt.Printf("DEBUG: Error during file walk: %v\n", err)
		return nil, fmt.Errorf("error walking plans directory: %w", err)
	}

	fmt.Printf("DEBUG: File processing complete. Total chunks: %d\n", len(p.chunks))

	// Process chunks and extract dependencies
	result.ChunksCreated = len(p.chunks)
	fmt.Printf("DEBUG: Extracting dependencies...\n")
	result.DependenciesFound = p.extractDependencies()
	fmt.Printf("DEBUG: Dependencies extracted: %d\n", result.DependenciesFound)
	result.ProcessingTime = time.Since(startTime)

	// Index chunks in RAG system if available
	if p.ragClient != nil {
		fmt.Printf("DEBUG: Indexing chunks in RAG system...\n")
		if err := p.indexChunksInRAG(ctx); err != nil {
			fmt.Printf("DEBUG: RAG indexing error: %v\n", err)
			result.Errors = append(result.Errors, fmt.Sprintf("RAG indexing error: %v", err))
		}
	} else {
		fmt.Printf("DEBUG: No RAG client available, skipping indexing\n")
	}

	fmt.Printf("DEBUG: IngestAllPlans completed successfully\n")
	return result, nil
}

// processPlanFile processes a single markdown plan file
func (p *PlanIngester) processPlanFile(_ context.Context, filePath string) error {
	fmt.Printf("DEBUG: Starting to process file: %s\n", filePath)
	file, err := os.Open(filePath)
	if err != nil {
		fmt.Printf("DEBUG: Failed to open file %s: %v\n", filePath, err)
		return fmt.Errorf("failed to open file: %w", err)
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	lineNumber := 0
	currentSection := ""
	currentContent := strings.Builder{}
	taskCount := 0
	listCount := 0

	planName := filepath.Base(filePath)
	fmt.Printf("DEBUG: Processing file %s (planName: %s)\n", filePath, planName)

	for scanner.Scan() {
		lineNumber++
		line := scanner.Text()

		// Every 1000 lines, log progress
		if lineNumber%1000 == 0 {
			fmt.Printf("DEBUG: Processed %d lines in %s\n", lineNumber, filePath)
		}

		// Detect headers (these are always important chunks)
		if match := regexp.MustCompile(`^(#{1,6})\s+(.+)`).FindStringSubmatch(line); match != nil {
			// Save previous section if exists and has substantial content
			if currentContent.Len() > 100 { // Only create section chunks if they have substantial content
				p.createChunk(planName, currentSection, currentContent.String(), "section", len(match[1]), lineNumber)
				currentContent.Reset()
			}

			currentSection = match[2]
			level := len(match[1])
			p.createChunk(planName, currentSection, line, "header", level, lineNumber)

			// Reset counters for new section
			taskCount = 0
			listCount = 0
			continue
		}
		// Detect task items (but limit to avoid explosion)
		if match := regexp.MustCompile(`^[\s]*[-*+]\s*\[[ x]\]\s*(.+)`).FindStringSubmatch(line); match != nil {
			taskCount++
			// Only create task chunks for important tasks (longer descriptions or specific patterns)
			if len(match[1]) > 30 && (taskCount <= 10 || strings.Contains(strings.ToLower(match[1]), "implement") ||
				strings.Contains(strings.ToLower(match[1]), "create") || strings.Contains(strings.ToLower(match[1]), "configure")) {
				p.createChunk(planName, match[1], line, "task", 0, lineNumber)
			}
			continue
		}

		// Detect list items (but be very selective)
		if match := regexp.MustCompile(`^[\s]*[-*+]\s+(.+)`).FindStringSubmatch(line); match != nil {
			listCount++
			// Only create list item chunks for very significant items
			if listCount <= 2 && len(match[1]) > 50 {
				p.createChunk(planName, match[1], line, "list_item", 0, lineNumber)
			}
			continue
		}

		// Accumulate content for sections
		if strings.TrimSpace(line) != "" {
			currentContent.WriteString(line + "\n")
		}
	}

	// Save final section if exists and has substantial content
	if currentContent.Len() > 100 {
		p.createChunk(planName, currentSection, currentContent.String(), "section", 0, lineNumber)
	}

	fmt.Printf("DEBUG: Finished processing file %s (total lines: %d, chunks so far: %d)\n", filePath, lineNumber, len(p.chunks))

	if scanErr := scanner.Err(); scanErr != nil {
		fmt.Printf("DEBUG: Scanner error in %s: %v\n", filePath, scanErr)
		return scanErr
	}

	return nil
}

// createChunk creates a new plan chunk with metadata
func (p *PlanIngester) createChunk(planFile, title, content, chunkType string, level, lineNumber int) {
	// Safety limit to prevent memory issues
	if len(p.chunks) >= 50000 {
		return // Skip creating more chunks if we already have too many
	}

	chunk := PlanChunk{
		ID:       uuid.New().String(),
		PlanFile: planFile,
		Title:    title,
		Content:  content,
		Type:     chunkType,
		Level:    level,
		Metadata: map[string]interface{}{
			"line_number": lineNumber,
			"word_count":  len(strings.Fields(content)),
			"plan_file":   planFile,
		},
		Dependencies: make([]string, 0),
		CreatedAt:    time.Now(),
	}

	p.chunks = append(p.chunks, chunk)
}

// extractDependencies analyzes chunks to identify cross-plan dependencies
func (p *PlanIngester) extractDependencies() int {
	dependencyPatterns := []string{
		`(?i)depends?\s+on`,
		`(?i)requires?`,
		`(?i)prerequisite`,
		`(?i)after\s+completion\s+of`,
		`(?i)following\s+completion\s+of`,
		`(?i)once\s+.+\s+is\s+complete`,
	}

	dependenciesFound := 0

	for i := range p.chunks {
		chunk := &p.chunks[i]

		for _, pattern := range dependencyPatterns {
			if matched, _ := regexp.MatchString(pattern, chunk.Content); matched {
				// Extract potential dependency references
				deps := p.extractDependencyReferences(chunk.Content)
				chunk.Dependencies = append(chunk.Dependencies, deps...)
				dependenciesFound += len(deps)
			}
		}
	}

	return dependenciesFound
}

// extractDependencyReferences extracts specific dependency references from text
func (p *PlanIngester) extractDependencyReferences(content string) []string {
	deps := make([]string, 0)

	// Look for plan file references (plan-dev-vXX)
	planRefs := regexp.MustCompile(`plan-dev-v\d+[a-zA-Z0-9-]*`).FindAllString(content, -1)
	deps = append(deps, planRefs...)

	// Look for section references
	sectionRefs := regexp.MustCompile(`section\s+\d+\.\d+`).FindAllString(content, -1)
	deps = append(deps, sectionRefs...)

	// Look for quoted dependencies
	quotedRefs := regexp.MustCompile(`"([^"]+)"`).FindAllStringSubmatch(content, -1)
	for _, match := range quotedRefs {
		if len(match) > 1 && len(match[1]) > 3 { // Ignore very short quotes
			deps = append(deps, match[1])
		}
	}

	return deps
}

// indexChunksInRAG indexes all chunks in the RAG vector database
func (p *PlanIngester) indexChunksInRAG(ctx context.Context) error {
	if p.ragClient == nil {
		return fmt.Errorf("RAG client not available")
	}

	// Check RAG health first
	if err := p.ragClient.HealthCheck(ctx); err != nil {
		return fmt.Errorf("RAG system not available: %w", err)
	}

	successCount := 0
	for _, chunk := range p.chunks {
		// Create a search-optimized title and description
		title := fmt.Sprintf("[%s] %s", chunk.PlanFile, chunk.Title)
		description := chunk.Content

		// Add chunk metadata
		metadata := chunk.Metadata
		metadata["chunk_type"] = chunk.Type
		metadata["chunk_level"] = chunk.Level
		metadata["dependencies"] = chunk.Dependencies
		metadata["source"] = "plan_ingestion"

		if err := p.ragClient.IndexRoadmapItem(ctx, chunk.ID, title, description, metadata); err != nil {
			// Log error but continue with other chunks
			continue
		}
		successCount++
	}

	if successCount == 0 {
		return fmt.Errorf("failed to index any chunks")
	}

	return nil
}

// GetIngestionSummary returns a summary of the last ingestion
func (p *PlanIngester) GetIngestionSummary() map[string]interface{} {
	summary := map[string]interface{}{
		"total_chunks": len(p.chunks),
		"chunk_types":  make(map[string]int),
		"plan_files":   make(map[string]int),
	}

	chunkTypes := summary["chunk_types"].(map[string]int)
	planFiles := summary["plan_files"].(map[string]int)

	for _, chunk := range p.chunks {
		chunkTypes[chunk.Type]++
		planFiles[chunk.PlanFile]++
	}

	return summary
}

// SearchChunks finds chunks matching a query (simple text search)
func (p *PlanIngester) SearchChunks(query string) []PlanChunk {
	results := make([]PlanChunk, 0)
	queryLower := strings.ToLower(query)

	for _, chunk := range p.chunks {
		if strings.Contains(strings.ToLower(chunk.Title), queryLower) ||
			strings.Contains(strings.ToLower(chunk.Content), queryLower) {
			results = append(results, chunk)
		}
	}

	return results
}

// IngestEnrichedPlans processes markdown files and extracts enriched metadata
func (p *PlanIngester) IngestEnrichedPlans(ctx context.Context) (*EnrichedIngestionResult, error) {
	startTime := time.Now()
	basicResult, err := p.IngestAllPlans(ctx)
	if err != nil {
		return nil, err
	}

	enrichedResult := &EnrichedIngestionResult{
		IngestionResult: basicResult,
		EnrichedItems:   make([]EnrichedPlanItem, 0),
	}

	// Parse enriched metadata from chunks
	for _, chunk := range p.chunks {
		if enrichedItem := p.parseEnrichedItem(chunk); enrichedItem != nil {
			enrichedResult.EnrichedItems = append(enrichedResult.EnrichedItems, *enrichedItem)
			enrichedResult.EnrichedItemsCreated++
		}
	}

	enrichedResult.ProcessingTime = time.Since(startTime)
	return enrichedResult, nil
}

// parseEnrichedItem extracts enriched metadata from a plan chunk
func (p *PlanIngester) parseEnrichedItem(chunk PlanChunk) *EnrichedPlanItem {
	// Only process task chunks or sections with task-like content
	if chunk.Type != "task" && chunk.Type != "section" {
		return nil
	}

	item := &EnrichedPlanItem{
		Title:       chunk.Title,
		Description: p.extractDescription(chunk.Content),
		Priority:    p.extractPriority(chunk.Content),
		Status:      p.extractStatus(chunk.Content),
		Complexity:  p.extractComplexity(chunk.Content),
		RiskLevel:   p.extractRiskLevel(chunk.Content),
		SourceFile:  chunk.PlanFile,
		LineNumber:  chunk.Metadata["line_number"].(int),
		TargetDate:  p.extractTargetDate(chunk.Content),
	}

	// Extract structured fields
	item.Inputs = p.extractInputs(chunk.Content)
	item.Outputs = p.extractOutputs(chunk.Content)
	item.Scripts = p.extractScripts(chunk.Content)
	item.Prerequisites = p.extractPrerequisites(chunk.Content)
	item.Methods = p.extractMethods(chunk.Content)
	item.URIs = p.extractURIs(chunk.Content)
	item.Tools = p.extractTools(chunk.Content)
	item.Frameworks = p.extractFrameworks(chunk.Content)
	item.Tags = p.extractTags(chunk.Content)

	// Extract assessment metrics
	item.Effort = p.extractEffort(chunk.Content)
	item.BusinessValue = p.extractBusinessValue(chunk.Content)
	item.TechnicalDebt = p.extractTechnicalDebt(chunk.Content)

	// Only return if we found significant enriched data
	if len(item.Inputs) > 0 || len(item.Outputs) > 0 || len(item.Scripts) > 0 ||
		len(item.Prerequisites) > 0 || item.Effort > 0 || item.BusinessValue > 0 {
		return item
	}

	return nil
}

// extractDescription extracts description from content
func (p *PlanIngester) extractDescription(content string) string {
	lines := strings.Split(content, "\n")
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if line != "" && !strings.HasPrefix(line, "-") && !strings.HasPrefix(line, "*") {
			return line
		}
	}
	return ""
}

// extractPriority extracts priority from content
func (p *PlanIngester) extractPriority(content string) types.Priority {
	content = strings.ToLower(content)
	if strings.Contains(content, "critique") || strings.Contains(content, "critical") || strings.Contains(content, "urgent") {
		return types.PriorityCritical
	}
	if strings.Contains(content, "high") || strings.Contains(content, "haute") || strings.Contains(content, "important") {
		return types.PriorityHigh
	}
	if strings.Contains(content, "low") || strings.Contains(content, "basse") || strings.Contains(content, "faible") {
		return types.PriorityLow
	}
	return types.PriorityMedium
}

// extractStatus extracts status from task markers
func (p *PlanIngester) extractStatus(content string) types.Status {
	if strings.Contains(content, "[x]") || strings.Contains(content, "[X]") {
		return types.StatusCompleted
	}
	if strings.Contains(content, "[ ]") {
		return types.StatusPlanned
	}
	if strings.Contains(content, "in progress") || strings.Contains(content, "en cours") {
		return types.StatusInProgress
	}
	if strings.Contains(content, "review") || strings.Contains(content, "révision") {
		return types.StatusInReview
	}
	if strings.Contains(content, "blocked") || strings.Contains(content, "bloqué") {
		return types.StatusBlocked
	}
	return types.StatusPlanned
}

// extractComplexity extracts complexity level from content
func (p *PlanIngester) extractComplexity(content string) types.BasicComplexity {	content = strings.ToLower(content)
	if strings.Contains(content, "complexe") || strings.Contains(content, "complex") || strings.Contains(content, "difficile") {
		return types.BasicComplexityHigh
	}
	if strings.Contains(content, "simple") || strings.Contains(content, "facile") || strings.Contains(content, "easy") {
		return types.BasicComplexityLow
	}
	return types.BasicComplexityMedium
}

// extractRiskLevel extracts risk level from content
func (p *PlanIngester) extractRiskLevel(content string) types.RiskLevel {
	content = strings.ToLower(content)
	if strings.Contains(content, "risque élevé") || strings.Contains(content, "high risk") || strings.Contains(content, "risky") {
		return types.RiskHigh
	}
	if strings.Contains(content, "risque faible") || strings.Contains(content, "low risk") || strings.Contains(content, "safe") {
		return types.RiskLow
	}
	return types.RiskMedium
}

// extractInputs extracts inputs from French "Entrées" sections
func (p *PlanIngester) extractInputs(content string) []types.TaskInput {
	var inputs []types.TaskInput
	pattern := regexp.MustCompile(`(?i)(?:entrées|inputs?)\s*[:：]\s*(.+?)(?:\n|$)`)
	matches := pattern.FindAllStringSubmatch(content, -1)

	for _, match := range matches {
		if len(match) > 1 {
			inputStr := strings.TrimSpace(match[1])
			inputItems := strings.Split(inputStr, ",")
			for _, item := range inputItems {
				item = strings.TrimSpace(item)
				if item != "" {
					inputs = append(inputs, types.TaskInput{
						Name:        item,
						Description: item,
						Type:        "requirement",
						Source:      "plan_extraction",
					})
				}
			}
		}
	}

	return inputs
}

// extractOutputs extracts outputs from French "Sorties" sections
func (p *PlanIngester) extractOutputs(content string) []types.TaskOutput {
	var outputs []types.TaskOutput
	pattern := regexp.MustCompile(`(?i)(?:sorties|outputs?)\s*[:：]\s*(.+?)(?:\n|$)`)
	matches := pattern.FindAllStringSubmatch(content, -1)

	for _, match := range matches {
		if len(match) > 1 {
			outputStr := strings.TrimSpace(match[1])
			outputItems := strings.Split(outputStr, ",")
			for _, item := range outputItems {
				item = strings.TrimSpace(item)
				if item != "" {
					outputs = append(outputs, types.TaskOutput{
						Name:        item,
						Description: item,
						Type:        "deliverable",
						Format:      "file",
					})
				}
			}
		}
	}

	return outputs
}

// extractScripts extracts scripts from "Scripts" sections
func (p *PlanIngester) extractScripts(content string) []types.TaskScript {
	var scripts []types.TaskScript
	pattern := regexp.MustCompile(`(?i)scripts?\s*[:：]\s*(.+?)(?:\n|$)`)
	matches := pattern.FindAllStringSubmatch(content, -1)

	for _, match := range matches {
		if len(match) > 1 {
			scriptStr := strings.TrimSpace(match[1])
			scriptItems := strings.Split(scriptStr, ",")
			for _, item := range scriptItems {
				item = strings.TrimSpace(item)
				if item != "" {
					// Extract language from file extension or path
					language := "bash"
					if strings.Contains(item, ".go") {
						language = "go"
					} else if strings.Contains(item, ".js") {
						language = "javascript"
					} else if strings.Contains(item, ".py") {
						language = "python"
					}

					scripts = append(scripts, types.TaskScript{
						Name:        item,
						Description: item,
						Language:    language,
						Path:        item,
					})
				}
			}
		}
	}

	return scripts
}

// extractPrerequisites extracts prerequisites from French "Conditions préalables" sections
func (p *PlanIngester) extractPrerequisites(content string) []string {
	var prerequisites []string
	pattern := regexp.MustCompile(`(?i)(?:conditions préalables|prérequis|prerequisites?)\s*[:：]\s*(.+?)(?:\n|$)`)
	matches := pattern.FindAllStringSubmatch(content, -1)

	for _, match := range matches {
		if len(match) > 1 {
			prereqStr := strings.TrimSpace(match[1])
			prereqItems := strings.Split(prereqStr, ",")
			for _, item := range prereqItems {
				item = strings.TrimSpace(item)
				if item != "" {
					prerequisites = append(prerequisites, item)
				}
			}
		}
	}

	return prerequisites
}

// extractMethods extracts methods from "Méthodes" sections
func (p *PlanIngester) extractMethods(content string) []string {
	var methods []string
	pattern := regexp.MustCompile(`(?i)(?:méthodes|methods?)\s*[:：]\s*(.+?)(?:\n|$)`)
	matches := pattern.FindAllStringSubmatch(content, -1)

	for _, match := range matches {
		if len(match) > 1 {
			methodStr := strings.TrimSpace(match[1])
			methodItems := strings.Split(methodStr, ",")
			for _, item := range methodItems {
				item = strings.TrimSpace(item)
				if item != "" {
					methods = append(methods, item)
				}
			}
		}
	}

	return methods
}

// extractURIs extracts URIs from content
func (p *PlanIngester) extractURIs(content string) []string {
	var uris []string
	// Extract URLs and file paths
	urlPattern := regexp.MustCompile(`https?://[^\s]+`)
	pathPattern := regexp.MustCompile(`[/\\][\w/\\.-]+\.\w+`)

	urls := urlPattern.FindAllString(content, -1)
	paths := pathPattern.FindAllString(content, -1)

	uris = append(uris, urls...)
	uris = append(uris, paths...)

	return uris
}

// extractTools extracts tools from content
func (p *PlanIngester) extractTools(content string) []string {
	var tools []string

	// Common tools patterns
	toolPatterns := []string{
		"Go", "JavaScript", "Python", "Docker", "Kubernetes", "Redis", "PostgreSQL",
		"React", "Vue", "Angular", "Node.js", "npm", "yarn", "git", "GitHub",
		"VS Code", "IntelliJ", "Notion", "Gmail", "Calendar", "n8n",
	}

	content = strings.ToLower(content)
	for _, tool := range toolPatterns {
		if strings.Contains(content, strings.ToLower(tool)) {
			tools = append(tools, tool)
		}
	}

	return tools
}

// extractFrameworks extracts frameworks from content
func (p *PlanIngester) extractFrameworks(content string) []string {
	var frameworks []string

	// Common frameworks
	frameworkPatterns := []string{
		"Next.js", "Express", "Gin", "Echo", "Fiber", "Django", "Flask",
		"Spring", "Laravel", "Symfony", "Vue.js", "React", "Angular",
	}

	content = strings.ToLower(content)
	for _, framework := range frameworkPatterns {
		if strings.Contains(content, strings.ToLower(framework)) {
			frameworks = append(frameworks, framework)
		}
	}

	return frameworks
}

// extractTags extracts tags from content
func (p *PlanIngester) extractTags(content string) []string {
	var tags []string

	// Extract common development tags
	tagPatterns := []string{
		"frontend", "backend", "api", "database", "cache", "storage",
		"security", "performance", "testing", "deployment", "infrastructure",
		"ui", "ux", "mobile", "web", "desktop", "cloud", "microservice",
	}

	content = strings.ToLower(content)
	for _, tag := range tagPatterns {
		if strings.Contains(content, tag) {
			tags = append(tags, tag)
		}
	}

	return tags
}

// extractEffort extracts effort estimate from content
func (p *PlanIngester) extractEffort(content string) int {
	// Look for hour estimates (1h, 2 hours, 8h, etc.)
	pattern := regexp.MustCompile(`(\d+)\s*(?:h|hour|heure)s?`)
	matches := pattern.FindAllStringSubmatch(content, -1)

	totalHours := 0
	for _, match := range matches {
		if len(match) > 1 {
			if hours, err := strconv.Atoi(match[1]); err == nil {
				totalHours += hours
			}
		}
	}

	return totalHours
}

// extractBusinessValue extracts business value from content
func (p *PlanIngester) extractBusinessValue(content string) int {
	// Look for business value indicators
	content = strings.ToLower(content)
	if strings.Contains(content, "critique") || strings.Contains(content, "critical") {
		return 10
	}
	if strings.Contains(content, "important") || strings.Contains(content, "high value") {
		return 8
	}
	if strings.Contains(content, "useful") || strings.Contains(content, "utile") {
		return 6
	}
	if strings.Contains(content, "nice to have") || strings.Contains(content, "optionnel") {
		return 3
	}

	return 5 // Default medium value
}

// extractTechnicalDebt extracts technical debt indicators
func (p *PlanIngester) extractTechnicalDebt(content string) int {
	content = strings.ToLower(content)
	if strings.Contains(content, "refactor") || strings.Contains(content, "debt") || strings.Contains(content, "legacy") {
		return 8
	}
	if strings.Contains(content, "optimize") || strings.Contains(content, "improve") {
		return 5
	}

	return 2 // Default low debt
}

// extractTargetDate extracts target date from content
func (p *PlanIngester) extractTargetDate(content string) time.Time {
	// Look for date patterns
	datePattern := regexp.MustCompile(`\d{4}-\d{2}-\d{2}`)
	match := datePattern.FindString(content)

	if match != "" {
		if date, err := time.Parse("2006-01-02", match); err == nil {
			return date
		}
	}

	// Default to 30 days from now
	return time.Now().AddDate(0, 0, 30)
}

// ToEnrichedItemOptions converts an EnrichedPlanItem to types.EnrichedItemOptions for storage
func (item *EnrichedPlanItem) ToEnrichedItemOptions() types.EnrichedItemOptions {
	return types.EnrichedItemOptions{
		Title:         item.Title,
		Description:   item.Description,
		Status:        item.Status,
		Priority:      item.Priority,
		TargetDate:    item.TargetDate,
		Inputs:        item.Inputs,
		Outputs:       item.Outputs,
		Scripts:       item.Scripts,
		Prerequisites: item.Prerequisites,
		Methods:       item.Methods,
		URIs:          item.URIs,
		Tools:         item.Tools,
		Frameworks:    item.Frameworks,
		Complexity:    item.Complexity,
		Effort:        item.Effort,
		BusinessValue: item.BusinessValue,
		TechnicalDebt: item.TechnicalDebt,
		RiskLevel:     item.RiskLevel,
		Tags:          item.Tags,
	}
}

// IngestAndStoreEnrichedPlans processes plan files and stores enriched items to storage
func (p *PlanIngester) IngestAndStoreEnrichedPlans(storageImpl Storage, planFiles []string) ([]types.RoadmapItem, error) {
	// First, ingest and parse the enriched plans
	enrichedResult, err := p.IngestEnrichedPlans(context.Background())
	if err != nil {
		return nil, fmt.Errorf("failed to ingest enriched plans: %w", err)
	}

	if len(enrichedResult.EnrichedItems) == 0 {
		return []types.RoadmapItem{}, nil
	}

	// Convert enriched items to storage options
	var enrichedOptions []types.EnrichedItemOptions
	for _, item := range enrichedResult.EnrichedItems {
		enrichedOptions = append(enrichedOptions, item.ToEnrichedItemOptions())
	}

	// Store enriched items using batch method
	// Check if storage supports batch creation (JSONStorage specific)
	if jsonStorage, ok := storageImpl.(*storage.JSONStorage); ok {
		return jsonStorage.CreateEnrichedItems(enrichedOptions)
	}
	// Fallback to individual creation for other storage types
	var createdItems []types.RoadmapItem
	for _, options := range enrichedOptions {
		item, err := storageImpl.CreateEnrichedItem(options)
		if err != nil {
			return nil, fmt.Errorf("failed to create enriched item: %w", err)
		}
		createdItems = append(createdItems, *item)
	}
	return createdItems, nil
}

// Storage interface for dependency injection
type Storage interface {
	CreateEnrichedItem(types.EnrichedItemOptions) (*types.RoadmapItem, error)
	GetAllItems() ([]types.RoadmapItem, error)
	Close() error
}
