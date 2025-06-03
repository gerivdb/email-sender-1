// Plan Dev v41 - Phase 1.1.1.2 - Simulation Engine
// Moteur de simulation pour les opérations de fichiers
// Version: 1.0
// Date: 2025-06-03

package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// ISimulatable - Interface pour les opérations simulables
type ISimulatable interface {
	SimulateAction() (*SimulationResult, error)
	GetActionType() string
	GetTargetPath() string
	GetDestinationPath() string
}

// SimulationResult - Résultat d'une simulation
type SimulationResult struct {
	ActionType        string                 `json:"action_type"`
	SourcePath        string                 `json:"source_path"`
	DestinationPath   string                 `json:"destination_path"`
	Success           bool                   `json:"success"`
	EstimatedDuration time.Duration          `json:"estimated_duration"`
	RiskLevel         string                 `json:"risk_level"`
	Impact            *ImpactAnalysis        `json:"impact"`
	Conflicts         []ConflictInfo         `json:"conflicts"`
	Warnings          []string               `json:"warnings"`
	Recommendations   []string               `json:"recommendations"`
	Metadata          map[string]interface{} `json:"metadata"`
}

// ImpactAnalysis - Analyse d'impact d'une opération
type ImpactAnalysis struct {
	FileCount          int      `json:"file_count"`
	DirectoryCount     int      `json:"directory_count"`
	TotalSize          int64    `json:"total_size"`
	CriticalFiles      []string `json:"critical_files"`
	AffectedSubmodules []string `json:"affected_submodules"`
	GitImpact          bool     `json:"git_impact"`
	ConfigImpact       bool     `json:"config_impact"`
}

// ConflictInfo - Information sur un conflit détecté
type ConflictInfo struct {
	Type        string `json:"type"`
	Source      string `json:"source"`
	Target      string `json:"target"`
	Severity    string `json:"severity"`
	Description string `json:"description"`
	Resolution  string `json:"resolution"`
}

// FileOperationSimulator - Simulateur d'opérations de fichiers
type FileOperationSimulator struct {
	SourcePath      string
	DestinationPath string
	ActionType      string
	CriticalFiles   []string
	ProtectedDirs   []string
}

// NewFileOperationSimulator - Constructeur pour FileOperationSimulator
func NewFileOperationSimulator(source, destination, actionType string) *FileOperationSimulator {
	return &FileOperationSimulator{
		SourcePath:      source,
		DestinationPath: destination,
		ActionType:      actionType,
		CriticalFiles: []string{
			".gitmodules", ".gitignore", ".env", "package.json", "go.mod", "go.sum",
			"Makefile", "docker-compose.yml", "Dockerfile", "*.key", "*.pem", "*.cert",
		},
		ProtectedDirs: []string{
			".git", ".github", ".vscode", "node_modules", ".env*",
		},
	}
}

// SimulateAction - Simule une opération de fichier sans l'exécuter
func (f *FileOperationSimulator) SimulateAction() (*SimulationResult, error) {
	result := &SimulationResult{
		ActionType:      f.ActionType,
		SourcePath:      f.SourcePath,
		DestinationPath: f.DestinationPath,
		Success:         true,
		Impact:          &ImpactAnalysis{},
		Conflicts:       []ConflictInfo{},
		Warnings:        []string{},
		Recommendations: []string{},
		Metadata:        make(map[string]interface{}),
	}

	// Vérifier l'existence du fichier source
	sourceInfo, err := os.Stat(f.SourcePath)
	if err != nil {
		result.Success = false
		result.Warnings = append(result.Warnings, fmt.Sprintf("Source path not found: %s", f.SourcePath))
		return result, nil
	}

	// Analyser l'impact
	if err := f.analyzeImpact(result); err != nil {
		return nil, err
	}

	// Détecter les conflits
	if err := f.detectConflicts(result); err != nil {
		return nil, err
	}

	// Évaluer les risques
	f.evaluateRisks(result)

	// Estimer la durée
	f.estimateDuration(result, sourceInfo)

	// Générer des recommandations
	f.generateRecommendations(result)

	return result, nil
}

// analyzeImpact - Analyse l'impact de l'opération
func (f *FileOperationSimulator) analyzeImpact(result *SimulationResult) error {
	impact := result.Impact

	// Compter les fichiers et dossiers affectés
	if info, err := os.Stat(f.SourcePath); err == nil {
		if info.IsDir() {
			if err := f.analyzeDirectoryImpact(f.SourcePath, impact); err != nil {
				return err
			}
		} else {
			impact.FileCount = 1
			impact.TotalSize = info.Size()

			// Vérifier si c'est un fichier critique
			if f.isCriticalFile(f.SourcePath) {
				impact.CriticalFiles = append(impact.CriticalFiles, f.SourcePath)
			}
		}
	}

	// Analyser l'impact Git
	impact.GitImpact = f.hasGitImpact()
	impact.ConfigImpact = f.hasConfigImpact()

	return nil
}

// analyzeDirectoryImpact - Analyse l'impact sur un dossier
func (f *FileOperationSimulator) analyzeDirectoryImpact(dir string, impact *ImpactAnalysis) error {
	return filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return nil // Ignorer les erreurs de lecture
		}

		if info.IsDir() {
			impact.DirectoryCount++
		} else {
			impact.FileCount++
			impact.TotalSize += info.Size()

			if f.isCriticalFile(path) {
				impact.CriticalFiles = append(impact.CriticalFiles, path)
			}
		}

		return nil
	})
}

// detectConflicts - Détecte les conflits potentiels
func (f *FileOperationSimulator) detectConflicts(result *SimulationResult) error {
	conflicts := &result.Conflicts

	// Vérifier si la destination existe déjà
	if _, err := os.Stat(f.DestinationPath); err == nil {
		*conflicts = append(*conflicts, ConflictInfo{
			Type:        "destination_exists",
			Source:      f.SourcePath,
			Target:      f.DestinationPath,
			Severity:    "WARNING",
			Description: "Destination already exists",
			Resolution:  "Consider renaming or backing up existing file",
		})
	}

	// Vérifier les permissions
	if err := f.checkPermissions(); err != nil {
		*conflicts = append(*conflicts, ConflictInfo{
			Type:        "permission_denied",
			Source:      f.SourcePath,
			Target:      f.DestinationPath,
			Severity:    "CRITICAL",
			Description: fmt.Sprintf("Permission denied: %v", err),
			Resolution:  "Check file permissions and user access rights",
		})
	}

	// Vérifier l'auto-suppression
	if f.wouldCauseSelfDeletion() {
		*conflicts = append(*conflicts, ConflictInfo{
			Type:        "self_deletion",
			Source:      f.SourcePath,
			Target:      f.DestinationPath,
			Severity:    "CRITICAL",
			Description: "Operation would move the script itself",
			Resolution:  "Exclude the script from the operation",
		})
	}

	return nil
}

// evaluateRisks - Évalue le niveau de risque
func (f *FileOperationSimulator) evaluateRisks(result *SimulationResult) {
	riskScore := 0

	// Fichiers critiques
	if len(result.Impact.CriticalFiles) > 0 {
		riskScore += 30
	}

	// Impact Git
	if result.Impact.GitImpact {
		riskScore += 25
	}

	// Impact configuration
	if result.Impact.ConfigImpact {
		riskScore += 20
	}

	// Conflits critiques
	for _, conflict := range result.Conflicts {
		if conflict.Severity == "CRITICAL" {
			riskScore += 15
		}
	}

	switch {
	case riskScore >= 50:
		result.RiskLevel = "CRITICAL"
	case riskScore >= 30:
		result.RiskLevel = "HIGH"
	case riskScore >= 15:
		result.RiskLevel = "MEDIUM"
	default:
		result.RiskLevel = "LOW"
	}
}

// estimateDuration - Estime la durée de l'opération
func (f *FileOperationSimulator) estimateDuration(result *SimulationResult, sourceInfo os.FileInfo) {
	baseTime := 100 * time.Millisecond

	if sourceInfo.IsDir() {
		// 10ms par fichier estimé
		baseTime += time.Duration(result.Impact.FileCount) * 10 * time.Millisecond
	} else {
		// Basé sur la taille du fichier (1MB = 100ms)
		sizeInMB := float64(sourceInfo.Size()) / (1024 * 1024)
		baseTime += time.Duration(sizeInMB*100) * time.Millisecond
	}

	result.EstimatedDuration = baseTime
}

// generateRecommendations - Génère des recommandations
func (f *FileOperationSimulator) generateRecommendations(result *SimulationResult) {
	recommendations := &result.Recommendations

	if result.RiskLevel == "CRITICAL" {
		*recommendations = append(*recommendations, "⚠️ CRITICAL: Review operation carefully before execution")
	}

	if len(result.Impact.CriticalFiles) > 0 {
		*recommendations = append(*recommendations, "🔒 Critical files detected - consider backup before operation")
	}

	if result.Impact.GitImpact {
		*recommendations = append(*recommendations, "📁 Git repository will be affected - ensure working directory is clean")
	}

	for _, conflict := range result.Conflicts {
		if conflict.Severity == "CRITICAL" {
			*recommendations = append(*recommendations, fmt.Sprintf("🚫 Resolve conflict: %s", conflict.Description))
		}
	}

	if len(result.Conflicts) == 0 && result.RiskLevel == "LOW" {
		*recommendations = append(*recommendations, "✅ Operation appears safe to execute")
	}
}

// Helper methods
func (f *FileOperationSimulator) isCriticalFile(path string) bool {
	basename := filepath.Base(path)
	for _, pattern := range f.CriticalFiles {
		if matched, _ := filepath.Match(pattern, basename); matched {
			return true
		}
		if strings.Contains(basename, strings.TrimSuffix(pattern, "*")) {
			return true
		}
	}
	return false
}

func (f *FileOperationSimulator) hasGitImpact() bool {
	path := strings.ToLower(f.SourcePath)
	return strings.Contains(path, ".git") || strings.Contains(path, ".github")
}

func (f *FileOperationSimulator) hasConfigImpact() bool {
	basename := strings.ToLower(filepath.Base(f.SourcePath))
	configFiles := []string{"package.json", "go.mod", "makefile", "dockerfile", "docker-compose"}

	for _, config := range configFiles {
		if strings.Contains(basename, config) {
			return true
		}
	}
	return false
}

func (f *FileOperationSimulator) checkPermissions() error {
	// Vérifier les permissions de lecture sur la source
	if _, err := os.Open(f.SourcePath); err != nil {
		return fmt.Errorf("cannot read source: %w", err)
	}

	// Vérifier les permissions d'écriture sur la destination
	destDir := filepath.Dir(f.DestinationPath)
	if _, err := os.Stat(destDir); os.IsNotExist(err) {
		return fmt.Errorf("destination directory does not exist: %s", destDir)
	}

	return nil
}

func (f *FileOperationSimulator) wouldCauseSelfDeletion() bool {
	currentExe, err := os.Executable()
	if err != nil {
		return false
	}

	currentExeAbs, _ := filepath.Abs(currentExe)
	sourceAbs, _ := filepath.Abs(f.SourcePath)

	return currentExeAbs == sourceAbs
}

// Interface methods
func (f *FileOperationSimulator) GetActionType() string {
	return f.ActionType
}

func (f *FileOperationSimulator) GetTargetPath() string {
	return f.SourcePath
}

func (f *FileOperationSimulator) GetDestinationPath() string {
	return f.DestinationPath
}

// SimulationEngine - Moteur principal de simulation
type SimulationEngine struct {
	Operations []ISimulatable
	Results    []*SimulationResult
}

// NewSimulationEngine - Constructeur pour SimulationEngine
func NewSimulationEngine() *SimulationEngine {
	return &SimulationEngine{
		Operations: make([]ISimulatable, 0),
		Results:    make([]*SimulationResult, 0),
	}
}

// AddOperation - Ajoute une opération à simuler
func (e *SimulationEngine) AddOperation(op ISimulatable) {
	e.Operations = append(e.Operations, op)
}

// RunSimulation - Exécute toutes les simulations
func (e *SimulationEngine) RunSimulation() error {
	e.Results = make([]*SimulationResult, 0, len(e.Operations))

	for _, op := range e.Operations {
		result, err := op.SimulateAction()
		if err != nil {
			return fmt.Errorf("simulation failed for %s: %w", op.GetTargetPath(), err)
		}
		e.Results = append(e.Results, result)
	}

	return nil
}

// GetResults - Retourne les résultats de simulation
func (e *SimulationEngine) GetResults() []*SimulationResult {
	return e.Results
}

// GenerateReport - Génère un rapport de simulation
func (e *SimulationEngine) GenerateReport() (string, error) {
	report := map[string]interface{}{
		"simulation_timestamp": time.Now().Format("2006-01-02 15:04:05"),
		"total_operations":     len(e.Operations),
		"results":              e.Results,
		"summary": map[string]interface{}{
			"critical_operations":    e.countByRiskLevel("CRITICAL"),
			"high_risk_operations":   e.countByRiskLevel("HIGH"),
			"medium_risk_operations": e.countByRiskLevel("MEDIUM"),
			"low_risk_operations":    e.countByRiskLevel("LOW"),
		},
	}

	jsonData, err := json.MarshalIndent(report, "", "  ")
	if err != nil {
		return "", fmt.Errorf("failed to generate report: %w", err)
	}

	return string(jsonData), nil
}

func (e *SimulationEngine) countByRiskLevel(level string) int {
	count := 0
	for _, result := range e.Results {
		if result.RiskLevel == level {
			count++
		}
	}
	return count
}

// Fonction principale pour tests
func main() {
	if len(os.Args) < 4 {
		fmt.Println("Usage: simulation-engine <source> <destination> <action_type>")
		fmt.Println("Example: simulation-engine ./file.txt ./misc/file.txt move")
		os.Exit(1)
	}

	source := os.Args[1]
	destination := os.Args[2]
	actionType := os.Args[3]

	// Créer le simulateur
	simulator := NewFileOperationSimulator(source, destination, actionType)

	// Créer le moteur de simulation
	engine := NewSimulationEngine()
	engine.AddOperation(simulator)

	// Exécuter la simulation
	if err := engine.RunSimulation(); err != nil {
		fmt.Printf("Error during simulation: %v\n", err)
		os.Exit(1)
	}

	// Générer le rapport
	report, err := engine.GenerateReport()
	if err != nil {
		fmt.Printf("Error generating report: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("=== SIMULATION REPORT ===")
	fmt.Println(report)

	// Afficher un résumé
	results := engine.GetResults()
	if len(results) > 0 {
		result := results[0]
		fmt.Printf("\n=== SUMMARY ===\n")
		fmt.Printf("Operation: %s %s -> %s\n", result.ActionType, result.SourcePath, result.DestinationPath)
		fmt.Printf("Risk Level: %s\n", result.RiskLevel)
		fmt.Printf("Estimated Duration: %v\n", result.EstimatedDuration)
		fmt.Printf("Critical Files: %d\n", len(result.Impact.CriticalFiles))
		fmt.Printf("Conflicts: %d\n", len(result.Conflicts))

		if len(result.Recommendations) > 0 {
			fmt.Println("\nRecommendations:")
			for _, rec := range result.Recommendations {
				fmt.Printf("  - %s\n", rec)
			}
		}
	}
}
