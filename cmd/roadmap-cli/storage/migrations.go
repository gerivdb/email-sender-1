package storage

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"

	"email_sender/cmd/roadmap-cli/types"
)

// MigrationManager handles data migrations between versions
type MigrationManager struct {
	storageDir string
}

// NewMigrationManager creates a new migration manager
func NewMigrationManager(storageDir string) *MigrationManager {
	return &MigrationManager{
		storageDir: storageDir,
	}
}

// Migration represents a data migration
type Migration struct {
	Version     string
	Description string
	Function    func() error
}

// GetAvailableMigrations returns all available migrations
func (m *MigrationManager) GetAvailableMigrations() []Migration {
	return []Migration{
		{
			Version:     "2.0.0",
			Description: "Migrate to advanced roadmap format with hierarchical support",
			Function:    m.migrateToAdvancedFormat,
		},
		{
			Version:     "2.1.0",
			Description: "Add technical specifications support",
			Function:    m.addTechnicalSpecifications,
		},
		{
			Version:     "2.2.0",
			Description: "Add complexity metrics and dependency tracking",
			Function:    m.addComplexityAndDependencies,
		},
	}
}

// RunMigrations executes all pending migrations
func (m *MigrationManager) RunMigrations() error {
	currentVersion, err := m.getCurrentVersion()
	if err != nil {
		return fmt.Errorf("failed to get current version: %v", err)
	}
	
	migrations := m.GetAvailableMigrations()
	
	for _, migration := range migrations {
		if m.shouldRunMigration(currentVersion, migration.Version) {
			fmt.Printf("Running migration %s: %s\n", migration.Version, migration.Description)
			
			err := migration.Function()
			if err != nil {
				return fmt.Errorf("migration %s failed: %v", migration.Version, err)
			}
			
			err = m.updateVersion(migration.Version)
			if err != nil {
				return fmt.Errorf("failed to update version after migration: %v", err)
			}
			
			fmt.Printf("Migration %s completed successfully\n", migration.Version)
		}
	}
	
	return nil
}

// getCurrentVersion reads the current data version
func (m *MigrationManager) getCurrentVersion() (string, error) {
	versionFile := filepath.Join(m.storageDir, "version.json")
	
	if _, err := os.Stat(versionFile); os.IsNotExist(err) {
		return "1.0.0", nil // Default version for new installations
	}
	
	data, err := os.ReadFile(versionFile)
	if err != nil {
		return "", err
	}
	
	var versionInfo struct {
		Version   string    `json:"version"`
		UpdatedAt time.Time `json:"updated_at"`
	}
	
	err = json.Unmarshal(data, &versionInfo)
	if err != nil {
		return "", err
	}
	
	return versionInfo.Version, nil
}

// updateVersion updates the stored version
func (m *MigrationManager) updateVersion(version string) error {
	versionFile := filepath.Join(m.storageDir, "version.json")
	
	versionInfo := struct {
		Version   string    `json:"version"`
		UpdatedAt time.Time `json:"updated_at"`
	}{
		Version:   version,
		UpdatedAt: time.Now(),
	}
	
	data, err := json.MarshalIndent(versionInfo, "", "  ")
	if err != nil {
		return err
	}
	
	return os.WriteFile(versionFile, data, 0644)
}

// shouldRunMigration determines if a migration should be executed
func (m *MigrationManager) shouldRunMigration(currentVersion, migrationVersion string) bool {
	// Simple version comparison - in production, use proper semver comparison
	return currentVersion < migrationVersion
}

// Migration functions

// migrateToAdvancedFormat converts basic roadmap to advanced format
func (m *MigrationManager) migrateToAdvancedFormat() error {
	roadmapFile := filepath.Join(m.storageDir, "roadmap.json")
	
	// Check if file exists
	if _, err := os.Stat(roadmapFile); os.IsNotExist(err) {
		// No existing roadmap to migrate
		return nil
	}
	
	// Read existing roadmap
	data, err := os.ReadFile(roadmapFile)
	if err != nil {
		return err
	}
	
	var basicRoadmap types.Roadmap
	err = json.Unmarshal(data, &basicRoadmap)
	if err != nil {
		return err
	}
	
	// Convert to advanced format
	advancedRoadmap := convertBasicToAdvanced(&basicRoadmap)
	
	// Backup original file
	backupFile := filepath.Join(m.storageDir, "roadmap_backup_v1.json")
	err = os.Rename(roadmapFile, backupFile)
	if err != nil {
		return err
	}
	
	// Save advanced roadmap
	advancedData, err := json.MarshalIndent(advancedRoadmap, "", "  ")
	if err != nil {
		return err
	}
	
	err = os.WriteFile(roadmapFile, advancedData, 0644)
	if err != nil {
		// Restore backup if save fails
		os.Rename(backupFile, roadmapFile)
		return err
	}
	
	return nil
}

// addTechnicalSpecifications adds technical specifications to existing items
func (m *MigrationManager) addTechnicalSpecifications() error {
	// Load current roadmap
	roadmapFile := filepath.Join(m.storageDir, "roadmap.json")
	
	data, err := os.ReadFile(roadmapFile)
	if err != nil {
		return err
	}
	
	var roadmap types.AdvancedRoadmap
	err = json.Unmarshal(data, &roadmap)
	if err != nil {
		return err
	}
	
	// Add empty technical specifications to items that don't have them
	for i := range roadmap.Items {
		if len(roadmap.Items[i].TechnicalSpec.DatabaseSchemas) == 0 &&
		   len(roadmap.Items[i].TechnicalSpec.APIEndpoints) == 0 &&
		   len(roadmap.Items[i].TechnicalSpec.CodeReferences) == 0 {
			
			roadmap.Items[i].TechnicalSpec = types.TechnicalSpec{
				DatabaseSchemas:    []types.DatabaseSchema{},
				APIEndpoints:      []types.APIEndpoint{},
				CodeReferences:    []types.CodeReference{},
				SystemRequirements: []types.SystemRequirement{},
				PerformanceTargets: []types.PerformanceTarget{},
			}
		}
	}
	
	// Save updated roadmap
	updatedData, err := json.MarshalIndent(roadmap, "", "  ")
	if err != nil {
		return err
	}
	
	return os.WriteFile(roadmapFile, updatedData, 0644)
}

// addComplexityAndDependencies adds complexity metrics and dependency tracking
func (m *MigrationManager) addComplexityAndDependencies() error {
	// Load current roadmap
	roadmapFile := filepath.Join(m.storageDir, "roadmap.json")
	
	data, err := os.ReadFile(roadmapFile)
	if err != nil {
		return err
	}
	
	var roadmap types.AdvancedRoadmap
	err = json.Unmarshal(data, &roadmap)
	if err != nil {
		return err
	}
	
	// Add complexity metrics and dependencies to items
	for i := range roadmap.Items {
		item := &roadmap.Items[i]
		
		// Initialize complexity metrics if not present
		if item.ComplexityMetrics.Overall.Score == 0 {
			// Estimate complexity based on description length and keywords
			complexity := estimateComplexity(item.Description, item.Title)
			item.ComplexityMetrics = complexity
		}
		
		// Initialize empty dependencies if not present
		if item.TechnicalDependencies == nil {
			item.TechnicalDependencies = []types.TechnicalDependency{}
		}
		
		// Initialize implementation steps if not present
		if item.ImplementationSteps == nil {
			item.ImplementationSteps = []types.ImplementationStep{}
		}
	}
	
	// Save updated roadmap
	updatedData, err := json.MarshalIndent(roadmap, "", "  ")
	if err != nil {
		return err
	}
	
	return os.WriteFile(roadmapFile, updatedData, 0644)
}

// Helper functions

// convertBasicToAdvanced converts a basic roadmap to advanced format
func convertBasicToAdvanced(basic *types.Roadmap) *types.AdvancedRoadmap {
	advanced := &types.AdvancedRoadmap{
		Version:     "2.0",
		Name:        "Migrated Roadmap",
		Description: "Migrated from basic format",
		CreatedAt:   basic.CreatedAt,
		UpdatedAt:   time.Now(),
		Items:       []types.AdvancedRoadmapItem{},
		Hierarchy:   make(map[string][]string),
		MaxDepth:    5,
	}
	
	// Convert items
	for i, basicItem := range basic.Items {		advancedItem := types.AdvancedRoadmapItem{
			ID:          basicItem.ID,
			Title:       basicItem.Title,
			Description: basicItem.Description,
			Status:      string(basicItem.Status),
			Priority:    string(basicItem.Priority),
			CreatedAt:   basicItem.CreatedAt,
			UpdatedAt:   basicItem.UpdatedAt,
			
			// Set basic hierarchy
			Hierarchy: types.HierarchyLevel{
				Level:    1,
				Path:     []string{basicItem.Title},
				Position: i,
				MaxDepth: 5,
			},
			HierarchyPath: []string{basicItem.Title},
			
			// Initialize advanced fields
			TechnicalSpec: types.TechnicalSpec{
				DatabaseSchemas:    []types.DatabaseSchema{},
				APIEndpoints:      []types.APIEndpoint{},
				CodeReferences:    []types.CodeReference{},
				SystemRequirements: []types.SystemRequirement{},
				PerformanceTargets: []types.PerformanceTarget{},
			},
			ImplementationSteps:   []types.ImplementationStep{},
			TechnicalDependencies: []types.TechnicalDependency{},
			ComplexityMetrics:     estimateComplexity(basicItem.Description, basicItem.Title),
		}
		
		advanced.Items = append(advanced.Items, advancedItem)
	}
	
	advanced.TotalItems = len(advanced.Items)
	
	// Build hierarchy map
	advanced.Hierarchy["level_1"] = make([]string, len(advanced.Items))
	for i, item := range advanced.Items {
		advanced.Hierarchy["level_1"][i] = item.ID
	}
	
	return advanced
}

// estimateComplexity estimates complexity metrics based on text analysis
func estimateComplexity(description, title string) types.ComplexityMetrics {
	text := description + " " + title
	lowerText := strings.ToLower(text)
	
	// Complexity indicators
	simpleKeywords := []string{"simple", "basic", "easy", "quick", "straightforward"}
	complexKeywords := []string{"complex", "advanced", "intricate", "challenging", "sophisticated"}
	expertKeywords := []string{"critical", "expert", "deep", "comprehensive", "enterprise"}
	
	score := 5 // Default moderate complexity
	
	// Adjust based on keywords
	for _, keyword := range simpleKeywords {
		if strings.Contains(lowerText, keyword) {
			score -= 2
			break
		}
	}
	
	for _, keyword := range complexKeywords {
		if strings.Contains(lowerText, keyword) {
			score += 2
			break
		}
	}
	
	for _, keyword := range expertKeywords {
		if strings.Contains(lowerText, keyword) {
			score += 3
			break
		}
	}
	
	// Technical indicators
	if strings.Contains(lowerText, "database") || strings.Contains(lowerText, "schema") {
		score += 1
	}
	
	if strings.Contains(lowerText, "api") || strings.Contains(lowerText, "integration") {
		score += 1
	}
	
	if strings.Contains(lowerText, "security") || strings.Contains(lowerText, "authentication") {
		score += 2
	}
	
	// Clamp score
	if score < 1 {
		score = 1
	}
	if score > 10 {
		score = 10
	}
	
	level := scoreToComplexityLevel(score)
	
	complexityLevel := types.ComplexityLevel{
		Score: score,
		Level: level,
	}
	
	return types.ComplexityMetrics{
		Technical:   complexityLevel,
		Overall:     complexityLevel,
		RiskLevel:   scoreToRiskLevel(score),
	}
}

// scoreToComplexityLevel converts score to complexity level
func scoreToComplexityLevel(score int) string {
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

// scoreToRiskLevel converts score to risk level
func scoreToRiskLevel(score int) string {
	switch {
	case score <= 3:
		return "low"
	case score <= 6:
		return "medium"
	case score <= 8:
		return "high"
	default:
		return "critical"
	}
}
