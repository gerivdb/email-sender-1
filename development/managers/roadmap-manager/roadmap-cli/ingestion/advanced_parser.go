package ingestion

import (
	"fmt"
	"regexp"
	"strconv"
	"strings"
	"time"

	"email_sender/cmd/roadmap-cli/types"

	"github.com/google/uuid"
)

// AdvancedPlanParser handles sophisticated parsing of technical roadmap plans
type AdvancedPlanParser struct {
	config *AdvancedParserConfig
}

// AdvancedParserConfig provides configuration for advanced parsing
type AdvancedParserConfig struct {
	MaxDepth              int
	IncludeTechnicalSpecs bool
	AnalyzeDependencies   bool
	ExtractComplexity     bool
	ParseCodeReferences   bool
	ParseDatabaseSchemas  bool
	ParseAPIEndpoints     bool
}

// NewAdvancedPlanParser creates a new advanced parser with configuration
func NewAdvancedPlanParser(config *AdvancedParserConfig) *AdvancedPlanParser {
	if config == nil {
		config = &AdvancedParserConfig{
			MaxDepth:              12, // Updated to support 12 levels of hierarchy
			IncludeTechnicalSpecs: true,
			AnalyzeDependencies:   true,
			ExtractComplexity:     true,
			ParseCodeReferences:   true,
			ParseDatabaseSchemas:  true,
			ParseAPIEndpoints:     true,
		}
	}
	return &AdvancedPlanParser{config: config}
}

// ParseAdvancedRoadmap parses a markdown file into an advanced roadmap structure
func (p *AdvancedPlanParser) ParseAdvancedRoadmap(content string, filename string) (*types.AdvancedRoadmap, error) {
	lines := strings.Split(content, "\n")

	roadmap := &types.AdvancedRoadmap{
		Version:     "2.0",
		Name:        extractRoadmapName(filename),
		Description: extractRoadmapDescription(lines),
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
		Items:       []types.AdvancedRoadmapItem{},
		Hierarchy:   make(map[string][]string),
		MaxDepth:    p.config.MaxDepth,
		LevelNames:  initializeLevelNames(p.config.MaxDepth),
		ParameterStats: &types.ParameterExtractionStats{
			TotalTasksWithParams:   0,
			InputsExtracted:        0,
			OutputsExtracted:       0,
			ScriptsExtracted:       0,
			URIsExtracted:          0,
			MethodsExtracted:       0,
			PrerequisitesExtracted: 0,
			ToolsExtracted:         0,
			FrameworksExtracted:    0,
		},
	}

	items, err := p.parseHierarchicalItems(lines, filename, roadmap)
	if err != nil {
		return nil, err
	}

	roadmap.Items = items
	roadmap.TotalItems = len(items)

	// Build hierarchy map
	p.buildHierarchyMap(roadmap)

	// Calculate analytics
	p.calculateAnalytics(roadmap)

	return roadmap, nil
}

// parseHierarchicalItems extracts items with full hierarchy support
func (p *AdvancedPlanParser) parseHierarchicalItems(lines []string, filename string, roadmap *types.AdvancedRoadmap) ([]types.AdvancedRoadmapItem, error) {
	var items []types.AdvancedRoadmapItem
	var currentItem *types.AdvancedRoadmapItem
	var hierarchyStack []string // Track current hierarchy path
	var parentStack []string    // Track parent IDs
	var currentHeaderLevel int  // Track current header level for bullet context

	// Regex patterns for different content types
	headerRegex := regexp.MustCompile(`^(#{1,12})\s+(.+)$`) // Updated to support up to 12 header levels

	// Enhanced patterns for various markdown formats
	// Order matters: more specific patterns first, then general ones
	checkboxNumberedBoldRegex := regexp.MustCompile(`^(\s*)-\s*\[\s*(.?)\s*\]\s*\*\*(\d+(?:\.\d+)*\.?)\*\*\s+(.+)$`) // - [ ] **1.1.1** Title
	numberedBoldRegex := regexp.MustCompile(`^(\s*)-\s*\*\*(\d+(?:\.\d+)*\.?)\*\*\s+(.+)$`)                          // - **1.1.1** Title
	checkboxBoldRegex := regexp.MustCompile(`^(\s*)-\s*\[(.)\]\s*\*\*([^*]+)\*\*\s*(.*)$`)                           // - [x] **Title** description
	checkboxRegex := regexp.MustCompile(`^(\s*)-\s*\[(.)\]\s*(.+)$`)                                                 // - [x] Title
	boldTextRegex := regexp.MustCompile(`^(\s*)-\s*\*\*([^*]+)\*\*\s*(.*)$`)                                         // - **Title** content
	numberedListRegex := regexp.MustCompile(`^(\s*)-?\s*(\d+(?:\.\d+)*\.?)\s+(.+)$`)                                 // - 1.1.1 Title or 1.1.1 Title
	simpleListRegex := regexp.MustCompile(`^(\s*)-\s+(.+)$`)                                                         // - Simple Title (most general)

	complexityRegex := regexp.MustCompile(`(?i)complexity:\s*(\d+(?:\.\d+)?)/10|complexity:\s*(trivial|simple|moderate|complex|expert)`)
	priorityRegex := regexp.MustCompile(`(?i)priority:\s*(low|medium|high|critical)`)
	effortRegex := regexp.MustCompile(`(?i)effort:\s*(\d+(?:\.\d+)?)\s*(hours?|days?|weeks?)`)
	dependencyRegex := regexp.MustCompile(`(?i)depends?\s+on:\s*(.+)`)

	// Enhanced parameter extraction patterns
	parameterPatterns := p.getParameterExtractionPatterns()
	for i, line := range lines {
		line = strings.TrimSpace(line)

		// Skip empty lines
		if line == "" {
			continue
		}
		// Parse headers (hierarchy levels)
		if headerMatch := headerRegex.FindStringSubmatch(line); headerMatch != nil {
			level := len(headerMatch[1])
			title := strings.TrimSpace(headerMatch[2])

			// Update current header level for bullet context
			currentHeaderLevel = level

			if level <= p.config.MaxDepth {
				// Save previous item if exists
				if currentItem != nil {
					items = append(items, *currentItem)
				}

				// Create new item
				currentItem = &types.AdvancedRoadmapItem{
					ID:         generateID(),
					Title:      title,
					Status:     "pending",
					Priority:   "medium",
					CreatedAt:  time.Now(),
					UpdatedAt:  time.Now(),
					SourceFile: filename,
					SourceLine: i + 1,
					LastParsed: time.Now(),
				}

				// Set hierarchy information
				p.setHierarchyInfo(currentItem, level, title, &hierarchyStack, &parentStack)

				continue
			}
		}
		// Parse checkbox items with numbered bold format: - [ ] **1.1.1** Title
		if checkboxNumberedBoldMatch := checkboxNumberedBoldRegex.FindStringSubmatch(line); checkboxNumberedBoldMatch != nil {
			indent := len(checkboxNumberedBoldMatch[1])
			status := strings.TrimSpace(checkboxNumberedBoldMatch[2])
			numbering := strings.TrimSpace(checkboxNumberedBoldMatch[3])
			title := strings.TrimSpace(checkboxNumberedBoldMatch[4])

			// Calculate level based on numbering dots + indent + current header context
			level := strings.Count(numbering, ".") + 1
			if indent > 0 {
				level += (indent / 2)
			}
			// Adjust level based on current header context
			if currentHeaderLevel > 0 {
				level = currentHeaderLevel + (indent / 2) + 1
			}

			if level <= p.config.MaxDepth {
				// Save previous item if exists
				if currentItem != nil {
					items = append(items, *currentItem)
				}

				itemStatus := "pending"
				if status == "x" || status == "X" {
					itemStatus = "completed"
				}

				currentItem = &types.AdvancedRoadmapItem{
					ID:         generateID(),
					Title:      title,
					Status:     itemStatus,
					Priority:   "medium",
					CreatedAt:  time.Now(),
					UpdatedAt:  time.Now(),
					SourceFile: filename,
					SourceLine: i + 1,
					LastParsed: time.Now(),
				}

				p.setHierarchyInfo(currentItem, level, title, &hierarchyStack, &parentStack)
				continue
			}
		}
		// Parse numbered bold items: - **1.1.1** Title
		if numberedBoldMatch := numberedBoldRegex.FindStringSubmatch(line); numberedBoldMatch != nil {
			indent := len(numberedBoldMatch[1])
			numbering := strings.TrimSpace(numberedBoldMatch[2])
			title := strings.TrimSpace(numberedBoldMatch[3])

			// Calculate level based on numbering dots + indent + current header context
			level := strings.Count(numbering, ".") + 1
			if indent > 0 {
				level += (indent / 2)
			}
			// Adjust level based on current header context
			if currentHeaderLevel > 0 {
				level = currentHeaderLevel + (indent / 2) + 1
			}

			if level <= p.config.MaxDepth {
				// Save previous item if exists
				if currentItem != nil {
					items = append(items, *currentItem)
				}

				currentItem = &types.AdvancedRoadmapItem{
					ID:         generateID(),
					Title:      title,
					Status:     "pending",
					Priority:   "medium",
					CreatedAt:  time.Now(),
					UpdatedAt:  time.Now(),
					SourceFile: filename,
					SourceLine: i + 1,
					LastParsed: time.Now(),
				}

				p.setHierarchyInfo(currentItem, level, title, &hierarchyStack, &parentStack)
				continue
			}
		}
		// Parse checkbox with bold: - [x] **Title** description
		if checkboxBoldMatch := checkboxBoldRegex.FindStringSubmatch(line); checkboxBoldMatch != nil {
			indent := len(checkboxBoldMatch[1])
			status := strings.TrimSpace(checkboxBoldMatch[2])
			title := strings.TrimSpace(checkboxBoldMatch[3])
			description := strings.TrimSpace(checkboxBoldMatch[4])

			// Calculate level based on indent + current header context
			level := (indent / 2) + 1
			if currentHeaderLevel > 0 {
				level = currentHeaderLevel + (indent / 2) + 1
			}
			if level <= p.config.MaxDepth {
				// Save previous item if exists
				if currentItem != nil {
					items = append(items, *currentItem)
				}

				itemStatus := "pending"
				if status == "x" || status == "X" {
					itemStatus = "completed"
				}

				currentItem = &types.AdvancedRoadmapItem{
					ID:          generateID(),
					Title:       title,
					Description: description,
					Status:      itemStatus,
					Priority:    "medium",
					CreatedAt:   time.Now(),
					UpdatedAt:   time.Now(),
					SourceFile:  filename,
					SourceLine:  i + 1,
					LastParsed:  time.Now(),
				}

				p.setHierarchyInfo(currentItem, level, title, &hierarchyStack, &parentStack)
				continue
			}
		}
		// Parse regular checkbox: - [x] Title
		if checkboxMatch := checkboxRegex.FindStringSubmatch(line); checkboxMatch != nil {
			indent := len(checkboxMatch[1])
			status := strings.TrimSpace(checkboxMatch[2])
			title := strings.TrimSpace(checkboxMatch[3])

			// Calculate level based on indent + current header context
			level := (indent / 2) + 1
			if currentHeaderLevel > 0 {
				level = currentHeaderLevel + (indent / 2) + 1
			}
			if level <= p.config.MaxDepth {
				// Save previous item if exists
				if currentItem != nil {
					items = append(items, *currentItem)
				}

				itemStatus := "pending"
				if status == "x" || status == "X" {
					itemStatus = "completed"
				}

				currentItem = &types.AdvancedRoadmapItem{
					ID:         generateID(),
					Title:      title,
					Status:     itemStatus,
					Priority:   "medium",
					CreatedAt:  time.Now(),
					UpdatedAt:  time.Now(),
					SourceFile: filename,
					SourceLine: i + 1,
					LastParsed: time.Now(),
				}

				p.setHierarchyInfo(currentItem, level, title, &hierarchyStack, &parentStack)
				continue
			}
		}
		// Parse bold text items: - **Title** content
		if boldMatch := boldTextRegex.FindStringSubmatch(line); boldMatch != nil {
			indent := len(boldMatch[1])
			title := strings.TrimSpace(boldMatch[2])
			description := strings.TrimSpace(boldMatch[3])

			// Calculate level based on indent + current header context
			level := (indent / 2) + 1
			if currentHeaderLevel > 0 {
				level = currentHeaderLevel + (indent / 2) + 1
			}
			if level <= p.config.MaxDepth {
				// Save previous item if exists
				if currentItem != nil {
					items = append(items, *currentItem)
				}

				currentItem = &types.AdvancedRoadmapItem{
					ID:          generateID(),
					Title:       title,
					Description: description,
					Status:      "pending",
					Priority:    "medium",
					CreatedAt:   time.Now(),
					UpdatedAt:   time.Now(),
					SourceFile:  filename,
					SourceLine:  i + 1,
					LastParsed:  time.Now(),
				}

				p.setHierarchyInfo(currentItem, level, title, &hierarchyStack, &parentStack)
				continue
			}
		}
		// Parse numbered lists: - 1.1.1 Title or 1.1.1 Title
		if numberedMatch := numberedListRegex.FindStringSubmatch(line); numberedMatch != nil {
			indent := len(numberedMatch[1])
			numbering := strings.TrimSpace(numberedMatch[2])
			title := strings.TrimSpace(numberedMatch[3])

			// Calculate level based on numbering dots + indent + current header context
			level := strings.Count(numbering, ".") + 1
			if indent > 0 {
				level += (indent / 2)
			}
			// Adjust level based on current header context
			if currentHeaderLevel > 0 {
				level = currentHeaderLevel + (indent / 2) + 1
			}

			if level <= p.config.MaxDepth {
				// Save previous item if exists
				if currentItem != nil {
					items = append(items, *currentItem)
				}

				currentItem = &types.AdvancedRoadmapItem{
					ID:         generateID(),
					Title:      title,
					Status:     "pending",
					Priority:   "medium",
					CreatedAt:  time.Now(),
					UpdatedAt:  time.Now(),
					SourceFile: filename,
					SourceLine: i + 1,
					LastParsed: time.Now(),
				}

				p.setHierarchyInfo(currentItem, level, title, &hierarchyStack, &parentStack)
				continue
			}
		}
		// Parse simple list items: - Title (most general pattern)
		if simpleMatch := simpleListRegex.FindStringSubmatch(line); simpleMatch != nil {
			indent := len(simpleMatch[1])
			title := strings.TrimSpace(simpleMatch[2])

			// Calculate level based on indent + current header context
			level := (indent / 2) + 1
			if currentHeaderLevel > 0 {
				level = currentHeaderLevel + (indent / 2) + 1
			}
			if level <= p.config.MaxDepth {
				// Save previous item if exists
				if currentItem != nil {
					items = append(items, *currentItem)
				}

				currentItem = &types.AdvancedRoadmapItem{
					ID:         generateID(),
					Title:      title,
					Status:     "pending",
					Priority:   "medium",
					CreatedAt:  time.Now(),
					UpdatedAt:  time.Now(),
					SourceFile: filename,
					SourceLine: i + 1,
					LastParsed: time.Now(),
				}

				p.setHierarchyInfo(currentItem, level, title, &hierarchyStack, &parentStack)
				continue
			}
		}

		// If no pattern matched and we have a current item, this line might be additional content
		if currentItem == nil {
			continue
		}

		// Parse content for current item
		if line == "" {
			continue
		}

		// Extract description (non-special lines)
		if !p.isSpecialLine(line) {
			if currentItem.Description == "" {
				currentItem.Description = line
			} else {
				currentItem.Description += "\n" + line
			}
		}

		// Parse complexity information
		if complexityMatch := complexityRegex.FindStringSubmatch(line); complexityMatch != nil {
			p.parseComplexityInfo(currentItem, complexityMatch, line)
		}

		// Parse priority
		if priorityMatch := priorityRegex.FindStringSubmatch(line); priorityMatch != nil {
			currentItem.Priority = strings.ToLower(priorityMatch[1])
		}

		// Parse effort estimation
		if effortMatch := effortRegex.FindStringSubmatch(line); effortMatch != nil {
			p.parseEffortEstimation(currentItem, effortMatch)
		}

		// Parse dependencies
		if dependencyMatch := dependencyRegex.FindStringSubmatch(line); dependencyMatch != nil {
			p.parseDependencies(currentItem, dependencyMatch[1])
		}

		// Parse technical specifications
		if p.config.IncludeTechnicalSpecs {
			p.parseTechnicalSpecs(currentItem, line, lines, i)
		}

		// Parse detailed task parameters
		p.parseTaskParameters(currentItem, line, parameterPatterns, roadmap.ParameterStats)

		// Parse implementation steps
		p.parseImplementationSteps(currentItem, line, lines, i)

		// Parse detailed steps for ultra-granular tasks
		p.parseDetailedSteps(currentItem, line, lines, i)
	}

	// Add the last item
	if currentItem != nil {
		items = append(items, *currentItem)
	}

	return items, nil
}

// setHierarchyInfo sets hierarchy information for an item
func (p *AdvancedPlanParser) setHierarchyInfo(
	item *types.AdvancedRoadmapItem,
	level int,
	title string,
	hierarchyStack *[]string,
	parentStack *[]string,
) {
	// Adjust stacks to current level
	if len(*hierarchyStack) >= level {
		*hierarchyStack = (*hierarchyStack)[:level-1]
		*parentStack = (*parentStack)[:level-1]
	}

	// Add current item to hierarchy
	*hierarchyStack = append(*hierarchyStack, title)
	*parentStack = append(*parentStack, item.ID)

	// Set hierarchy information with level name
	levelNames := initializeLevelNames(12)
	levelName := levelNames[level]
	if levelName == "" {
		levelName = fmt.Sprintf("Level-%d", level)
	}

	item.Hierarchy = types.HierarchyLevel{
		Level:     level,
		LevelName: levelName,
		Path:      make([]string, len(*hierarchyStack)),
		Position:  0, // Will be calculated later
		MaxDepth:  p.config.MaxDepth,
	}
	copy(item.Hierarchy.Path, *hierarchyStack)
	item.HierarchyPath = make([]string, len(*hierarchyStack))
	copy(item.HierarchyPath, *hierarchyStack)
	// Set parent relationship
	if level > 1 && len(*parentStack) > 1 {
		item.ParentItemID = (*parentStack)[len(*parentStack)-2]
		item.Hierarchy.Parent = (*parentStack)[len(*parentStack)-2]
	}
}

// parseComplexityInfo extracts complexity information
func (p *AdvancedPlanParser) parseComplexityInfo(item *types.AdvancedRoadmapItem, match []string, line string) {
	if !p.config.ExtractComplexity {
		return
	}

	var score int
	var level string

	if match[1] != "" {
		// Numeric score
		if s, err := strconv.ParseFloat(match[1], 64); err == nil {
			score = int(s)
			level = scoreToLevel(score)
		}
	} else if match[2] != "" {
		// Text level
		level = strings.ToLower(match[2])
		score = levelToScore(level)
	}

	complexityLevel := types.ComplexityLevel{
		Score:         score,
		Level:         level,
		Justification: extractJustification(line),
	}

	// Determine complexity type from context
	lowerLine := strings.ToLower(line)
	if strings.Contains(lowerLine, "database") || strings.Contains(lowerLine, "schema") {
		item.ComplexityMetrics.Database = complexityLevel
	} else if strings.Contains(lowerLine, "integration") || strings.Contains(lowerLine, "api") {
		item.ComplexityMetrics.Integration = complexityLevel
	} else if strings.Contains(lowerLine, "testing") {
		item.ComplexityMetrics.Testing = complexityLevel
	} else if strings.Contains(lowerLine, "deployment") {
		item.ComplexityMetrics.Deployment = complexityLevel
	} else {
		item.ComplexityMetrics.Technical = complexityLevel
	}

	// Calculate overall complexity
	p.calculateOverallComplexity(item)
}

// parseEffortEstimation extracts effort estimation
func (p *AdvancedPlanParser) parseEffortEstimation(item *types.AdvancedRoadmapItem, match []string) {
	value, err := strconv.ParseFloat(match[1], 64)
	if err != nil {
		return
	}

	unit := strings.ToLower(match[2])
	var duration time.Duration

	switch {
	case strings.Contains(unit, "hour"):
		duration = time.Duration(value) * time.Hour
	case strings.Contains(unit, "day"):
		duration = time.Duration(value) * 24 * time.Hour
	case strings.Contains(unit, "week"):
		duration = time.Duration(value) * 7 * 24 * time.Hour
	}

	item.EstimatedEffort = duration
}

// parseDependencies extracts dependency information
func (p *AdvancedPlanParser) parseDependencies(item *types.AdvancedRoadmapItem, depStr string) {
	if !p.config.AnalyzeDependencies {
		return
	}

	dependencies := strings.Split(depStr, ",")
	for _, dep := range dependencies {
		dep = strings.TrimSpace(dep)
		if dep != "" {
			techDep := types.TechnicalDependency{
				Type:         "technical",
				TargetID:     generateDependencyID(dep),
				Relationship: "requires",
				Strength:     3,
				Description:  dep,
				Critical:     false,
			}
			item.TechnicalDependencies = append(item.TechnicalDependencies, techDep)
		}
	}
}

// parseTechnicalSpecs extracts technical specifications
func (p *AdvancedPlanParser) parseTechnicalSpecs(item *types.AdvancedRoadmapItem, line string, lines []string, index int) {
	lowerLine := strings.ToLower(line)

	// Parse database schemas
	if p.config.ParseDatabaseSchemas && strings.Contains(lowerLine, "table:") {
		schema := p.parseDatabaseSchema(line, lines, index)
		if schema != nil {
			item.TechnicalSpec.DatabaseSchemas = append(item.TechnicalSpec.DatabaseSchemas, *schema)
		}
	}

	// Parse API endpoints
	if p.config.ParseAPIEndpoints && (strings.Contains(lowerLine, "endpoint:") || strings.Contains(lowerLine, "api:")) {
		endpoint := p.parseAPIEndpoint(line, lines, index)
		if endpoint != nil {
			item.TechnicalSpec.APIEndpoints = append(item.TechnicalSpec.APIEndpoints, *endpoint)
		}
	}

	// Parse code references
	if p.config.ParseCodeReferences && strings.Contains(lowerLine, "file:") {
		codeRef := p.parseCodeReference(line)
		if codeRef != nil {
			item.TechnicalSpec.CodeReferences = append(item.TechnicalSpec.CodeReferences, *codeRef)
		}
	}
}

// parseDatabaseSchema extracts database schema information
func (p *AdvancedPlanParser) parseDatabaseSchema(line string, lines []string, startIndex int) *types.DatabaseSchema {
	tableRegex := regexp.MustCompile(`(?i)table:\s*(\w+)`)
	match := tableRegex.FindStringSubmatch(line)
	if match == nil {
		return nil
	}

	schema := &types.DatabaseSchema{
		TableName: match[1],
		Fields:    []types.DatabaseField{},
	}

	// Look for field definitions in following lines
	fieldRegex := regexp.MustCompile(`^\s*-\s*(\w+)\s*\(([^)]+)\)(?:\s*(.*))?`)
	for i := startIndex + 1; i < len(lines) && i < startIndex+20; i++ {
		line := strings.TrimSpace(lines[i])
		if line == "" || strings.HasPrefix(line, "#") {
			break
		}

		if fieldMatch := fieldRegex.FindStringSubmatch(line); fieldMatch != nil {
			field := types.DatabaseField{
				Name: fieldMatch[1],
				Type: fieldMatch[2],
			}

			if len(fieldMatch) > 3 {
				desc := strings.TrimSpace(fieldMatch[3])
				field.Description = desc
				field.Nullable = !strings.Contains(strings.ToLower(desc), "not null")
				field.PrimaryKey = strings.Contains(strings.ToLower(desc), "primary")
			}

			schema.Fields = append(schema.Fields, field)
		}
	}

	return schema
}

// parseAPIEndpoint extracts API endpoint information
func (p *AdvancedPlanParser) parseAPIEndpoint(line string, lines []string, startIndex int) *types.APIEndpoint {
	endpointRegex := regexp.MustCompile(`(?i)(?:endpoint|api):\s*(GET|POST|PUT|DELETE|PATCH)\s+([^\s]+)(?:\s*-\s*(.*))?`)
	match := endpointRegex.FindStringSubmatch(line)
	if match == nil {
		return nil
	}

	endpoint := &types.APIEndpoint{
		Method: strings.ToUpper(match[1]),
		Path:   match[2],
	}

	if len(match) > 3 {
		endpoint.Description = strings.TrimSpace(match[3])
	}

	// Look for parameters in following lines
	paramRegex := regexp.MustCompile(`^\s*-\s*(\w+)\s*\(([^)]+)\)(?:\s*(.*))?`)
	for i := startIndex + 1; i < len(lines) && i < startIndex+10; i++ {
		line := strings.TrimSpace(lines[i])
		if line == "" || strings.HasPrefix(line, "#") {
			break
		}

		if paramMatch := paramRegex.FindStringSubmatch(line); paramMatch != nil {
			param := types.APIParameter{
				Name:     paramMatch[1],
				Type:     paramMatch[2],
				Required: !strings.Contains(strings.ToLower(line), "optional"),
				Location: "query", // Default
			}

			if len(paramMatch) > 3 {
				param.Description = strings.TrimSpace(paramMatch[3])
			}

			endpoint.Parameters = append(endpoint.Parameters, param)
		}
	}

	return endpoint
}

// parseCodeReference extracts code reference information
func (p *AdvancedPlanParser) parseCodeReference(line string) *types.CodeReference {
	fileRegex := regexp.MustCompile(`(?i)file:\s*([^\s]+)(?:\s*-\s*(.*))?`)
	match := fileRegex.FindStringSubmatch(line)
	if match == nil {
		return nil
	}

	codeRef := &types.CodeReference{
		FilePath: match[1],
		Language: detectLanguage(match[1]),
	}

	if len(match) > 2 {
		codeRef.Description = strings.TrimSpace(match[2])
	}

	return codeRef
}

// parseImplementationSteps extracts implementation steps
func (p *AdvancedPlanParser) parseImplementationSteps(item *types.AdvancedRoadmapItem, line string, lines []string, index int) {
	stepRegex := regexp.MustCompile(`^\s*\d+\.\s+(.+)$`)
	if match := stepRegex.FindStringSubmatch(line); match != nil {
		step := types.ImplementationStep{
			ID:            generateID(),
			Order:         len(item.ImplementationSteps) + 1,
			Title:         match[1],
			Type:          detectStepType(match[1]),
			Status:        "pending",
			Prerequisites: []string{},
			Validation:    []types.ValidationStep{},
		}

		// Look for commands and validation in following lines
		for i := index + 1; i < len(lines) && i < index+10; i++ {
			nextLine := strings.TrimSpace(lines[i])
			if nextLine == "" {
				break
			}

			if strings.HasPrefix(nextLine, "```") || strings.HasPrefix(nextLine, "`") {
				// Command block
				cmd := extractCommand(nextLine)
				if cmd != "" {
					step.Commands = append(step.Commands, cmd)
				}
			}
		}

		item.ImplementationSteps = append(item.ImplementationSteps, step)
	}
}

// Helper functions

func (p *AdvancedPlanParser) isSpecialLine(line string) bool {
	lowerLine := strings.ToLower(line)
	specialKeywords := []string{
		"complexity:", "priority:", "effort:", "depends on:", "dependency:",
		"table:", "endpoint:", "api:", "file:", "validation:", "command:",
		"entrées:", "sorties:", "scripts:", "uri:", "méthodes:", "conditions préalables:",
		"inputs:", "outputs:", "methods:", "prerequisites:", "tools:", "frameworks:",
	}

	for _, keyword := range specialKeywords {
		if strings.Contains(lowerLine, keyword) {
			return true
		}
	}

	return false
}

func (p *AdvancedPlanParser) buildHierarchyMap(roadmap *types.AdvancedRoadmap) {
	for _, item := range roadmap.Items {
		levelKey := fmt.Sprintf("level_%d", item.Hierarchy.Level)
		roadmap.Hierarchy[levelKey] = append(roadmap.Hierarchy[levelKey], item.ID)
	}
}

func (p *AdvancedPlanParser) calculateAnalytics(roadmap *types.AdvancedRoadmap) {
	completedCount := 0
	var totalEffort time.Duration
	complexityDist := make(map[string]int)

	for _, item := range roadmap.Items {
		if item.Status == "completed" {
			completedCount++
		}

		totalEffort += item.EstimatedEffort

		if item.ComplexityMetrics.Overall.Level != "" {
			complexityDist[item.ComplexityMetrics.Overall.Level]++
		}
	}

	roadmap.CompletedItems = completedCount
	roadmap.OverallProgress = float64(completedCount) / float64(roadmap.TotalItems) * 100
	roadmap.EffortEstimation = totalEffort
	roadmap.ComplexityDistribution = complexityDist
}

func (p *AdvancedPlanParser) calculateOverallComplexity(item *types.AdvancedRoadmapItem) {
	metrics := []types.ComplexityLevel{
		item.ComplexityMetrics.Technical,
		item.ComplexityMetrics.Database,
		item.ComplexityMetrics.Integration,
		item.ComplexityMetrics.Testing,
		item.ComplexityMetrics.Deployment,
	}

	var totalScore float64
	var count float64

	for _, metric := range metrics {
		if metric.Score > 0 {
			totalScore += float64(metric.Score)
			count++
		}
	}

	if count > 0 {
		avgScore := int(totalScore / count)
		item.ComplexityMetrics.Overall = types.ComplexityLevel{
			Score: avgScore,
			Level: scoreToLevel(avgScore),
		}

		// Determine risk level
		if avgScore <= 3 {
			item.ComplexityMetrics.RiskLevel = "low"
		} else if avgScore <= 6 {
			item.ComplexityMetrics.RiskLevel = "medium"
		} else if avgScore <= 8 {
			item.ComplexityMetrics.RiskLevel = "high"
		} else {
			item.ComplexityMetrics.RiskLevel = "critical"
		}
	}
}

// initializeLevelNames creates a mapping of level names for up to 12 hierarchy levels
func initializeLevelNames(maxDepth int) map[int]string {
	levelNames := map[int]string{
		1:  "Phase",
		2:  "Section",
		3:  "Subsection",
		4:  "Category",
		5:  "Task",
		6:  "Subtask",
		7:  "Action",
		8:  "Step",
		9:  "Substep",
		10: "Detail",
		11: "Micro-detail",
		12: "Ultra-detailed",
	}

	// Only return levels up to maxDepth
	result := make(map[int]string)
	for i := 1; i <= maxDepth && i <= 12; i++ {
		result[i] = levelNames[i]
	}

	return result
}

// getParameterExtractionPatterns creates regex patterns for extracting task parameters
func (p *AdvancedPlanParser) getParameterExtractionPatterns() map[string]*regexp.Regexp {
	return map[string]*regexp.Regexp{
		"inputs":        regexp.MustCompile(`(?i)(?:entrées?|inputs?|input data|données d'entrée):\s*(.+)`),
		"outputs":       regexp.MustCompile(`(?i)(?:sorties?|outputs?|output data|données de sortie):\s*(.+)`),
		"scripts":       regexp.MustCompile(`(?i)(?:scripts?|fichiers? de script):\s*(.+)`),
		"uris":          regexp.MustCompile(`(?i)(?:uris?|urls?|liens?):\s*(.+)`),
		"methods":       regexp.MustCompile(`(?i)(?:méthodes?|methods?):\s*(.+)`),
		"prerequisites": regexp.MustCompile(`(?i)(?:conditions? préalables?|prerequisites?|prérequis):\s*(.+)`),
		"tools":         regexp.MustCompile(`(?i)(?:outils?|tools?):\s*(.+)`),
		"frameworks":    regexp.MustCompile(`(?i)(?:frameworks?|cadres? de travail):\s*(.+)`),
		"commands":      regexp.MustCompile(`(?i)(?:commandes?|commands?):\s*(.+)`),
		"configFiles":   regexp.MustCompile(`(?i)(?:fichiers? de config|config files?|configuration):\s*(.+)`),
		"dependencies":  regexp.MustCompile(`(?i)(?:dépendances?|dependencies?):\s*(.+)`),
		"environment":   regexp.MustCompile(`(?i)(?:environnement|environment|env vars?):\s*(.+)`),
		"validation":    regexp.MustCompile(`(?i)(?:validation|tests?):\s*(.+)`),
	}
}

// parseTaskParameters extracts detailed task parameters from the current line
func (p *AdvancedPlanParser) parseTaskParameters(item *types.AdvancedRoadmapItem, line string, patterns map[string]*regexp.Regexp, stats *types.ParameterExtractionStats) {
	if item.TaskParameters == nil {
		item.TaskParameters = &types.TaskParameters{
			Inputs:        []string{},
			Outputs:       []string{},
			Scripts:       []string{},
			URIs:          []string{},
			Methods:       []string{},
			Prerequisites: []string{},
			Tools:         []string{},
			Frameworks:    []string{},
			Commands:      []string{},
			ConfigFiles:   []string{},
			Dependencies:  []string{},
			Environment:   map[string]string{},
			Validation:    []string{},
		}
	}

	hasParameters := false

	// Extract inputs
	if match := patterns["inputs"].FindStringSubmatch(line); match != nil {
		values := p.parseParameterValues(match[1])
		item.TaskParameters.Inputs = append(item.TaskParameters.Inputs, values...)
		stats.InputsExtracted += len(values)
		hasParameters = true
	}

	// Extract outputs
	if match := patterns["outputs"].FindStringSubmatch(line); match != nil {
		values := p.parseParameterValues(match[1])
		item.TaskParameters.Outputs = append(item.TaskParameters.Outputs, values...)
		stats.OutputsExtracted += len(values)
		hasParameters = true
	}

	// Extract scripts
	if match := patterns["scripts"].FindStringSubmatch(line); match != nil {
		values := p.parseParameterValues(match[1])
		item.TaskParameters.Scripts = append(item.TaskParameters.Scripts, values...)
		stats.ScriptsExtracted += len(values)
		hasParameters = true
	}

	// Extract URIs
	if match := patterns["uris"].FindStringSubmatch(line); match != nil {
		values := p.parseParameterValues(match[1])
		item.TaskParameters.URIs = append(item.TaskParameters.URIs, values...)
		stats.URIsExtracted += len(values)
		hasParameters = true
	}

	// Extract methods
	if match := patterns["methods"].FindStringSubmatch(line); match != nil {
		values := p.parseParameterValues(match[1])
		item.TaskParameters.Methods = append(item.TaskParameters.Methods, values...)
		stats.MethodsExtracted += len(values)
		hasParameters = true
	}

	// Extract prerequisites
	if match := patterns["prerequisites"].FindStringSubmatch(line); match != nil {
		values := p.parseParameterValues(match[1])
		item.TaskParameters.Prerequisites = append(item.TaskParameters.Prerequisites, values...)
		stats.PrerequisitesExtracted += len(values)
		hasParameters = true
	}

	// Extract tools
	if match := patterns["tools"].FindStringSubmatch(line); match != nil {
		values := p.parseParameterValues(match[1])
		item.TaskParameters.Tools = append(item.TaskParameters.Tools, values...)
		stats.ToolsExtracted += len(values)
		hasParameters = true
	}

	// Extract frameworks
	if match := patterns["frameworks"].FindStringSubmatch(line); match != nil {
		values := p.parseParameterValues(match[1])
		item.TaskParameters.Frameworks = append(item.TaskParameters.Frameworks, values...)
		stats.FrameworksExtracted += len(values)
		hasParameters = true
	}

	// Extract commands
	if match := patterns["commands"].FindStringSubmatch(line); match != nil {
		values := p.parseParameterValues(match[1])
		item.TaskParameters.Commands = append(item.TaskParameters.Commands, values...)
		hasParameters = true
	}

	// Extract config files
	if match := patterns["configFiles"].FindStringSubmatch(line); match != nil {
		values := p.parseParameterValues(match[1])
		item.TaskParameters.ConfigFiles = append(item.TaskParameters.ConfigFiles, values...)
		hasParameters = true
	}

	// Extract dependencies
	if match := patterns["dependencies"].FindStringSubmatch(line); match != nil {
		values := p.parseParameterValues(match[1])
		item.TaskParameters.Dependencies = append(item.TaskParameters.Dependencies, values...)
		hasParameters = true
	}

	// Extract environment variables
	if match := patterns["environment"].FindStringSubmatch(line); match != nil {
		envPairs := p.parseEnvironmentPairs(match[1])
		for key, value := range envPairs {
			item.TaskParameters.Environment[key] = value
		}
		hasParameters = true
	}

	// Extract validation steps
	if match := patterns["validation"].FindStringSubmatch(line); match != nil {
		values := p.parseParameterValues(match[1])
		item.TaskParameters.Validation = append(item.TaskParameters.Validation, values...)
		hasParameters = true
	}

	// Update stats if any parameters were found
	if hasParameters {
		stats.TotalTasksWithParams++
	}
}

// parseParameterValues parses a parameter string into individual values
func (p *AdvancedPlanParser) parseParameterValues(valueString string) []string {
	// Split by common delimiters
	valueString = strings.TrimSpace(valueString)

	// Handle different separators
	var values []string
	if strings.Contains(valueString, ",") {
		values = strings.Split(valueString, ",")
	} else if strings.Contains(valueString, ";") {
		values = strings.Split(valueString, ";")
	} else if strings.Contains(valueString, "|") {
		values = strings.Split(valueString, "|")
	} else {
		// Single value or space-separated
		values = strings.Fields(valueString)
	}

	// Clean up each value
	var cleanValues []string
	for _, value := range values {
		clean := strings.TrimSpace(value)
		if clean != "" {
			cleanValues = append(cleanValues, clean)
		}
	}

	return cleanValues
}

// parseEnvironmentPairs parses environment variable definitions
func (p *AdvancedPlanParser) parseEnvironmentPairs(envString string) map[string]string {
	result := make(map[string]string)
	envString = strings.TrimSpace(envString)

	// Split by common delimiters
	pairs := strings.Split(envString, ",")
	if len(pairs) == 1 {
		pairs = strings.Split(envString, ";")
	}

	for _, pair := range pairs {
		pair = strings.TrimSpace(pair)
		if strings.Contains(pair, "=") {
			parts := strings.SplitN(pair, "=", 2)
			if len(parts) == 2 {
				key := strings.TrimSpace(parts[0])
				value := strings.TrimSpace(parts[1])
				result[key] = value
			}
		} else if strings.Contains(pair, ":") {
			parts := strings.SplitN(pair, ":", 2)
			if len(parts) == 2 {
				key := strings.TrimSpace(parts[0])
				value := strings.TrimSpace(parts[1])
				result[key] = value
			}
		}
	}

	return result
}

// parseDetailedSteps parses ultra-detailed task steps for granular hierarchy
func (p *AdvancedPlanParser) parseDetailedSteps(item *types.AdvancedRoadmapItem, line string, lines []string, index int) {
	// Look for detailed step patterns with high granularity
	stepPatterns := []*regexp.Regexp{
		regexp.MustCompile(`^\s*-\s+(.+)$`),        // Bullet points
		regexp.MustCompile(`^\s*\*\s+(.+)$`),       // Asterisk bullets
		regexp.MustCompile(`^\s*\d+\)\s+(.+)$`),    // Numbered with parenthesis
		regexp.MustCompile(`^\s*[a-z]\)\s+(.+)$`),  // Letter enumeration
		regexp.MustCompile(`^\s*[ivx]+\.\s+(.+)$`), // Roman numerals
		regexp.MustCompile(`^\s*→\s+(.+)$`),        // Arrow steps
		regexp.MustCompile(`^\s*▸\s+(.+)$`),        // Triangle bullets
	}

	for _, pattern := range stepPatterns {
		if match := pattern.FindStringSubmatch(line); match != nil {
			stepTitle := strings.TrimSpace(match[1])

			detailedStep := types.DetailedTaskStep{
				ID:            generateID(),
				Title:         stepTitle,
				Level:         item.Hierarchy.Level + 1, // One level deeper than parent
				Type:          detectStepType(stepTitle),
				Status:        "pending",
				Prerequisites: []string{},
				SubSteps:      []types.DetailedTaskStep{},
			}

			// Look for sub-steps in following lines
			p.parseSubSteps(&detailedStep, lines, index+1, item.Hierarchy.Level+2)

			// Initialize DetailedSteps if needed
			if item.DetailedSteps == nil {
				item.DetailedSteps = []types.DetailedTaskStep{}
			}

			item.DetailedSteps = append(item.DetailedSteps, detailedStep)
			break
		}
	}
}

// parseSubSteps recursively parses sub-steps up to 12 levels deep
func (p *AdvancedPlanParser) parseSubSteps(parentStep *types.DetailedTaskStep, lines []string, startIndex, currentLevel int) {
	if currentLevel > 12 || startIndex >= len(lines) {
		return
	}

	subStepPatterns := []*regexp.Regexp{
		regexp.MustCompile(`^\s{2,}-\s+(.+)$`),       // Indented bullets
		regexp.MustCompile(`^\s{2,}\*\s+(.+)$`),      // Indented asterisks
		regexp.MustCompile(`^\s{2,}\d+\)\s+(.+)$`),   // Indented numbers
		regexp.MustCompile(`^\s{4,}[a-z]\)\s+(.+)$`), // Deeply indented letters
	}

	for i := startIndex; i < len(lines) && i < startIndex+20; i++ {
		line := lines[i]

		// Stop if we hit a new section or empty line sequence
		if strings.TrimSpace(line) == "" || strings.HasPrefix(strings.TrimSpace(line), "#") {
			break
		}

		for _, pattern := range subStepPatterns {
			if match := pattern.FindStringSubmatch(line); match != nil {
				stepTitle := strings.TrimSpace(match[1])

				subStep := types.DetailedTaskStep{
					ID:            generateID(),
					Title:         stepTitle,
					Level:         currentLevel,
					Type:          detectStepType(stepTitle),
					Status:        "pending",
					Prerequisites: []string{},
					SubSteps:      []types.DetailedTaskStep{},
				}

				// Recursively parse deeper sub-steps
				p.parseSubSteps(&subStep, lines, i+1, currentLevel+1)

				parentStep.SubSteps = append(parentStep.SubSteps, subStep)
				break
			}
		}
	}
}

// Utility functions

func generateID() string {
	return uuid.New().String()
}

func generateDependencyID(dep string) string {
	// Simple hash-based ID generation for dependencies
	return fmt.Sprintf("dep_%x", strings.ToLower(strings.ReplaceAll(dep, " ", "_")))
}

func scoreToLevel(score int) string {
	switch {
	case score <= 2:
		return "trivial"
	case score <= 4:
		return "simple"
	case score <= 6:
		return "moderate"
	case score <= 8:
		return "complex"
	default:
		return "expert"
	}
}

func levelToScore(level string) int {
	switch strings.ToLower(level) {
	case "trivial":
		return 2
	case "simple":
		return 3
	case "moderate":
		return 5
	case "complex":
		return 7
	case "expert":
		return 9
	default:
		return 5
	}
}

func extractJustification(line string) string {
	// Extract text after complexity declaration
	parts := strings.Split(line, "-")
	if len(parts) > 1 {
		return strings.TrimSpace(parts[1])
	}
	return ""
}

func detectLanguage(filepath string) string {
	ext := strings.ToLower(filepath[strings.LastIndex(filepath, ".")+1:])
	langMap := map[string]string{
		"go":   "go",
		"js":   "javascript",
		"ts":   "typescript",
		"py":   "python",
		"java": "java",
		"cpp":  "cpp",
		"c":    "c",
		"cs":   "csharp",
		"rb":   "ruby",
		"php":  "php",
	}

	if lang, exists := langMap[ext]; exists {
		return lang
	}
	return "unknown"
}

func detectStepType(title string) string {
	lowerTitle := strings.ToLower(title)

	if strings.Contains(lowerTitle, "setup") || strings.Contains(lowerTitle, "install") || strings.Contains(lowerTitle, "configure") {
		return "setup"
	}
	if strings.Contains(lowerTitle, "test") || strings.Contains(lowerTitle, "validate") {
		return "testing"
	}
	if strings.Contains(lowerTitle, "deploy") || strings.Contains(lowerTitle, "release") {
		return "deployment"
	}
	if strings.Contains(lowerTitle, "implement") || strings.Contains(lowerTitle, "develop") || strings.Contains(lowerTitle, "code") {
		return "implementation"
	}

	return "implementation"
}

func extractCommand(line string) string {
	// Remove markdown code formatting
	line = strings.Trim(line, "`")
	line = strings.TrimSpace(line)

	if line != "" && !strings.HasPrefix(line, "```") {
		return line
	}

	return ""
}

func extractRoadmapName(filename string) string {
	// Extract name from filename
	base := strings.TrimSuffix(filename, ".md")
	return strings.ReplaceAll(base, "_", " ")
}

func extractRoadmapDescription(lines []string) string {
	// Look for description in first few lines
	for _, line := range lines[:min(10, len(lines))] {
		line = strings.TrimSpace(line)
		if line != "" && !strings.HasPrefix(line, "#") {
			return line
		}
	}
	return ""
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
