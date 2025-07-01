package sync_core

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"
)

// PlanSynchronizer handles synchronization from dynamic system to Markdown
type PlanSynchronizer struct {
	qdrantClient	*QDrantClient
	sqlStorage	*SQLStorage
	config		*MarkdownSyncConfig
	logger		*log.Logger
	stats		*SyncStats
}

// MarkdownSyncConfig contains configuration for synchronization
type MarkdownSyncConfig struct {
	OutputDirectory		string	`json:"output_directory"`
	PreserveFormatting	bool	`json:"preserve_formatting"`
	BackupOriginal		bool	`json:"backup_original"`
	OverwriteExisting	bool	`json:"overwrite_existing"`
}

// SyncStats tracks synchronization statistics
type SyncStats struct {
	FilesSynced	int		`json:"files_synced"`
	ErrorsEncounter	int		`json:"errors_encountered"`
	TotalSyncTime	time.Duration	`json:"total_sync_time"`
	LastSyncTime	time.Time	`json:"last_sync_time"`
}

// PhaseGroup represents a group of tasks organized by phase
type PhaseGroup struct {
	Name		string	`json:"name"`
	Tasks		[]Task	`json:"tasks"`
	Progression	float64	`json:"progression"`
	Order		int	`json:"order"`
}

// NewPlanSynchronizer creates a new instance of PlanSynchronizer
func NewPlanSynchronizer(sqlStorage *SQLStorage, qdrantClient *QDrantClient, config *MarkdownSyncConfig) *PlanSynchronizer {
	logger := log.New(os.Stdout, "[PLAN-SYNC] ", log.LstdFlags|log.Lshortfile)

	if config == nil {
		config = &MarkdownSyncConfig{
			OutputDirectory:	"./exported-plans",
			PreserveFormatting:	true,
			BackupOriginal:		true,
			OverwriteExisting:	false,
		}
	}

	return &PlanSynchronizer{
		qdrantClient:	qdrantClient,
		sqlStorage:	sqlStorage,
		config:		config,
		logger:		logger,
		stats:		&SyncStats{},
	}
}

// SyncToMarkdown synchronizes a plan from dynamic system to Markdown format
func (ps *PlanSynchronizer) SyncToMarkdown(planID string) error {
	ps.logger.Printf("🔄 Starting sync to Markdown for plan: %s", planID)
	startTime := time.Now()

	// Récupérer plan depuis système dynamique
	dynamicPlan, err := ps.fetchPlanFromDynamic(planID)
	if err != nil {
		ps.logger.Printf("❌ Failed to fetch plan from dynamic system: %v", err)
		ps.stats.ErrorsEncounter++
		return fmt.Errorf("failed to fetch plan from dynamic system: %w", err)
	}

	// Créer le répertoire de sortie si nécessaire
	if err := ps.ensureOutputDirectory(); err != nil {
		ps.logger.Printf("❌ Failed to create output directory: %v", err)
		return fmt.Errorf("failed to create output directory: %w", err)
	}

	// Déterminer le chemin du fichier de sortie
	outputPath := ps.getOutputPath(dynamicPlan)

	// Backup du fichier existant si demandé
	if ps.config.BackupOriginal && ps.fileExists(outputPath) {
		if err := ps.backupExistingFile(outputPath); err != nil {
			ps.logger.Printf("⚠️ Warning: Failed to backup existing file: %v", err)
		}
	}

	// Convertir vers format Markdown
	markdownContent := ps.convertToMarkdown(dynamicPlan)

	// Écrire fichier avec préservation de l'historique
	if err := ps.writeMarkdownFile(outputPath, markdownContent); err != nil {
		ps.logger.Printf("❌ Failed to write Markdown file: %v", err)
		ps.stats.ErrorsEncounter++
		return fmt.Errorf("failed to write markdown file: %w", err)
	}

	// Mettre à jour les statistiques
	ps.stats.FilesSynced++
	ps.stats.TotalSyncTime += time.Since(startTime)
	ps.stats.LastSyncTime = time.Now()

	ps.logger.Printf("✅ Successfully synced plan to Markdown: %s", outputPath)
	return nil
}

// fetchPlanFromDynamic retrieves a plan from the dynamic storage system
func (ps *PlanSynchronizer) fetchPlanFromDynamic(planID string) (*DynamicPlan, error) {
	ps.logger.Printf("📖 Fetching plan from dynamic system: %s", planID)

	// Récupérer depuis SQL storage
	plan, err := ps.sqlStorage.GetPlan(planID)
	if err != nil {
		return nil, fmt.Errorf("failed to retrieve plan from SQL storage: %w", err)
	}

	ps.logger.Printf("✅ Successfully fetched plan: %s (%d tasks)", plan.ID, len(plan.Tasks))
	return plan, nil
}

// convertToMarkdown converts a DynamicPlan to Markdown format
func (ps *PlanSynchronizer) convertToMarkdown(plan *DynamicPlan) string {
	var builder strings.Builder

	ps.logger.Printf("🔄 Converting plan to Markdown format: %s", plan.Metadata.Title)

	// En-tête avec métadonnées
	builder.WriteString(fmt.Sprintf("# %s\n\n", plan.Metadata.Title))

	// Ligne de version et progression
	if plan.Metadata.Version != "" || plan.Metadata.Progression > 0 {
		versionInfo := ""
		if plan.Metadata.Version != "" {
			versionInfo = fmt.Sprintf("**Version %s", plan.Metadata.Version)
		} else {
			versionInfo = "**Version 1.0"
		}

		if plan.UpdatedAt.IsZero() {
			versionInfo += fmt.Sprintf(" - %s", time.Now().Format("2006-01-02"))
		} else {
			versionInfo += fmt.Sprintf(" - %s", plan.UpdatedAt.Format("2006-01-02"))
		}

		versionInfo += fmt.Sprintf(" - Progression globale : %.0f%%**\n\n", plan.Metadata.Progression)
		builder.WriteString(versionInfo)
	}

	// Description si disponible
	if plan.Metadata.Description != "" {
		builder.WriteString(fmt.Sprintf("%s\n\n", plan.Metadata.Description))
	}

	// Organiser tâches par phases
	phaseGroups := ps.groupTasksByPhase(plan.Tasks)

	// Trier les phases par ordre
	sort.Slice(phaseGroups, func(i, j int) bool {
		return phaseGroups[i].Order < phaseGroups[j].Order
	})

	// Générer le contenu pour chaque phase
	for _, phaseGroup := range phaseGroups {
		builder.WriteString(fmt.Sprintf("## %s\n\n", phaseGroup.Name))

		// Ajouter progression de la phase si calculée
		if phaseGroup.Progression >= 0 {
			builder.WriteString(fmt.Sprintf("*Progression: %.0f%%*\n\n", phaseGroup.Progression))
		}

		// Ajouter les tâches de la phase
		for _, task := range phaseGroup.Tasks {
			checkbox := "[ ]"
			if task.Completed {
				checkbox = "[x]"
			}	// Indentation selon le niveau de la tâche (minimum level 1)
			level := task.Level
			if level < 1 {
				level = 1
			}
			indent := strings.Repeat("  ", level-1)
			builder.WriteString(fmt.Sprintf("%s- %s %s", indent, checkbox, task.Title))

			// Ajouter la description si disponible
			if task.Description != "" && task.Description != task.Title {
				builder.WriteString(fmt.Sprintf(" : %s", task.Description))
			}

			builder.WriteString("\n")
		}

		builder.WriteString("\n")
	}

	// Footer avec informations de synchronisation
	builder.WriteString("---\n\n")
	builder.WriteString(fmt.Sprintf("*Synchronisé depuis le système dynamique le %s*\n", time.Now().Format("2006-01-02 15:04:05")))
	builder.WriteString(fmt.Sprintf("*Plan ID: %s*\n", plan.ID))

	ps.logger.Printf("✅ Markdown conversion completed (%d characters)", builder.Len())
	return builder.String()
}

// groupTasksByPhase organizes tasks by their phase
func (ps *PlanSynchronizer) groupTasksByPhase(tasks []Task) []PhaseGroup {
	ps.logger.Printf("📊 Grouping %d tasks by phase", len(tasks))

	phaseMap := make(map[string]*PhaseGroup)
	phaseOrder := make(map[string]int)

	// Regrouper les tâches par phase
	for _, task := range tasks {
		phaseName := task.Phase
		if phaseName == "" {
			phaseName = "Général"
		}

		if _, exists := phaseMap[phaseName]; !exists {
			// Déterminer l'ordre de la phase depuis le nom
			order := ps.extractPhaseOrder(phaseName)
			phaseMap[phaseName] = &PhaseGroup{
				Name:		phaseName,
				Tasks:		[]Task{},
				Progression:	-1,	// Will be calculated later
				Order:		order,
			}
			phaseOrder[phaseName] = order
		}

		phaseMap[phaseName].Tasks = append(phaseMap[phaseName].Tasks, task)
	}

	// Calculer la progression pour chaque phase
	for _, phase := range phaseMap {
		phase.Progression = ps.calculatePhaseProgression(phase.Tasks)

		// Trier les tâches dans la phase par niveau puis par ordre de création
		sort.Slice(phase.Tasks, func(i, j int) bool {
			if phase.Tasks[i].Level != phase.Tasks[j].Level {
				return phase.Tasks[i].Level < phase.Tasks[j].Level
			}
			return phase.Tasks[i].CreatedAt.Before(phase.Tasks[j].CreatedAt)
		})
	}

	// Convertir map en slice
	var phaseGroups []PhaseGroup
	for _, phase := range phaseMap {
		phaseGroups = append(phaseGroups, *phase)
	}

	ps.logger.Printf("✅ Organized into %d phases", len(phaseGroups))
	return phaseGroups
}

// extractPhaseOrder extracts order number from phase name
func (ps *PlanSynchronizer) extractPhaseOrder(phaseName string) int {
	// Essayer d'extraire un numéro depuis le nom de la phase
	lowerName := strings.ToLower(phaseName)

	if strings.Contains(lowerName, "phase 1") || strings.Contains(lowerName, "1.") {
		return 1
	} else if strings.Contains(lowerName, "phase 2") || strings.Contains(lowerName, "2.") {
		return 2
	} else if strings.Contains(lowerName, "phase 3") || strings.Contains(lowerName, "3.") {
		return 3
	} else if strings.Contains(lowerName, "phase 4") || strings.Contains(lowerName, "4.") {
		return 4
	} else if strings.Contains(lowerName, "phase 5") || strings.Contains(lowerName, "5.") {
		return 5
	} else if strings.Contains(lowerName, "phase 6") || strings.Contains(lowerName, "6.") {
		return 6
	} else if strings.Contains(lowerName, "phase 7") || strings.Contains(lowerName, "7.") {
		return 7
	} else if strings.Contains(lowerName, "phase 8") || strings.Contains(lowerName, "8.") {
		return 8
	}

	// Par défaut, retourner un ordre élevé pour les phases non reconnues
	return 999
}

// calculatePhaseProgression calculates progression percentage for a phase
func (ps *PlanSynchronizer) calculatePhaseProgression(tasks []Task) float64 {
	if len(tasks) == 0 {
		return 0
	}

	completedTasks := 0
	for _, task := range tasks {
		if task.Completed {
			completedTasks++
		}
	}

	return float64(completedTasks) / float64(len(tasks)) * 100
}

// ensureOutputDirectory creates the output directory if it doesn't exist
func (ps *PlanSynchronizer) ensureOutputDirectory() error {
	if err := os.MkdirAll(ps.config.OutputDirectory, 0755); err != nil {
		return fmt.Errorf("failed to create output directory: %w", err)
	}
	return nil
}

// getOutputPath determines the output file path for a plan
func (ps *PlanSynchronizer) getOutputPath(plan *DynamicPlan) string {
	// Nettoyer le titre pour créer un nom de fichier valide
	cleanTitle := ps.sanitizeFilename(plan.Metadata.Title)

	// Ajouter version si disponible
	if plan.Metadata.Version != "" {
		cleanTitle += fmt.Sprintf("-%s", plan.Metadata.Version)
	}

	filename := fmt.Sprintf("%s.md", cleanTitle)
	return filepath.Join(ps.config.OutputDirectory, filename)
}

// sanitizeFilename cleans a title to create a valid filename
func (ps *PlanSynchronizer) sanitizeFilename(title string) string {
	// Remplacer les caractères non-valides par des tirets
	cleanTitle := strings.ToLower(title)
	cleanTitle = strings.ReplaceAll(cleanTitle, " ", "-")
	cleanTitle = strings.ReplaceAll(cleanTitle, "é", "e")
	cleanTitle = strings.ReplaceAll(cleanTitle, "è", "e")
	cleanTitle = strings.ReplaceAll(cleanTitle, "à", "a")
	cleanTitle = strings.ReplaceAll(cleanTitle, "ç", "c")
	cleanTitle = strings.ReplaceAll(cleanTitle, "ù", "u")
	cleanTitle = strings.ReplaceAll(cleanTitle, "ê", "e")
	cleanTitle = strings.ReplaceAll(cleanTitle, "â", "a")
	cleanTitle = strings.ReplaceAll(cleanTitle, "î", "i")
	cleanTitle = strings.ReplaceAll(cleanTitle, "ô", "o")
	cleanTitle = strings.ReplaceAll(cleanTitle, "û", "u")
	cleanTitle = strings.ReplaceAll(cleanTitle, ".", "-")

	// Supprimer les caractères spéciaux
	var result strings.Builder
	for _, r := range cleanTitle {
		if (r >= 'a' && r <= 'z') || (r >= '0' && r <= '9') || r == '-' || r == '_' {
			result.WriteRune(r)
		}
	}

	// Nettoyer les tirets multiples
	final := result.String()
	for strings.Contains(final, "--") {
		final = strings.ReplaceAll(final, "--", "-")
	}
	final = strings.Trim(final, "-")

	return final
}

// fileExists checks if a file exists
func (ps *PlanSynchronizer) fileExists(path string) bool {
	_, err := os.Stat(path)
	return !os.IsNotExist(err)
}

// backupExistingFile creates a backup of an existing file
func (ps *PlanSynchronizer) backupExistingFile(originalPath string) error {
	backupPath := fmt.Sprintf("%s.backup.%s", originalPath, time.Now().Format("20060102-150405"))

	// Lire le fichier original
	content, err := os.ReadFile(originalPath)
	if err != nil {
		return fmt.Errorf("failed to read original file: %w", err)
	}

	// Écrire la sauvegarde
	if err := os.WriteFile(backupPath, content, 0644); err != nil {
		return fmt.Errorf("failed to write backup file: %w", err)
	}

	ps.logger.Printf("📁 Backup created: %s", backupPath)
	return nil
}

// writeMarkdownFile writes the markdown content to a file
func (ps *PlanSynchronizer) writeMarkdownFile(path, content string) error {
	ps.logger.Printf("💾 Writing Markdown file: %s", path)

	// Vérifier si le fichier existe et que l'overwrite n'est pas autorisé
	if !ps.config.OverwriteExisting && ps.fileExists(path) {
		return fmt.Errorf("file already exists and overwrite is disabled: %s", path)
	}

	// Écrire le fichier
	if err := os.WriteFile(path, []byte(content), 0644); err != nil {
		return fmt.Errorf("failed to write file: %w", err)
	}

	ps.logger.Printf("✅ Markdown file written successfully (%d bytes)", len(content))
	return nil
}

// SyncAllPlans synchronizes all plans from the dynamic system to Markdown
func (ps *PlanSynchronizer) SyncAllPlans() error {
	ps.logger.Printf("🔄 Starting synchronization of all plans")

	// Get list of all plans from SQL storage
	plans, err := ps.getAllPlanIDs()
	if err != nil {
		return fmt.Errorf("failed to get plan list: %w", err)
	}

	ps.logger.Printf("📋 Found %d plans to synchronize", len(plans))

	successCount := 0
	errorCount := 0

	for _, planID := range plans {
		if err := ps.SyncToMarkdown(planID); err != nil {
			ps.logger.Printf("❌ Failed to sync plan %s: %v", planID, err)
			errorCount++
		} else {
			successCount++
		}
	}

	ps.logger.Printf("✅ Synchronization completed: %d successful, %d errors", successCount, errorCount)
	return nil
}

// getAllPlanIDs retrieves all plan IDs from the storage
func (ps *PlanSynchronizer) getAllPlanIDs() ([]string, error) {
	// Query to get all plan IDs
	query := "SELECT id FROM plans ORDER BY created_at DESC"

	rows, err := ps.sqlStorage.db.Query(query)
	if err != nil {
		return nil, fmt.Errorf("failed to query plan IDs: %w", err)
	}
	defer rows.Close()

	var planIDs []string
	for rows.Next() {
		var planID string
		if err := rows.Scan(&planID); err != nil {
			return nil, fmt.Errorf("failed to scan plan ID: %w", err)
		}
		planIDs = append(planIDs, planID)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("row iteration error: %w", err)
	}

	return planIDs, nil
}

// GetStats returns current synchronization statistics
func (ps *PlanSynchronizer) GetStats() *SyncStats {
	return ps.stats
}

// ResetStats resets synchronization statistics
func (ps *PlanSynchronizer) ResetStats() {
	ps.stats = &SyncStats{}
	ps.logger.Printf("📊 Statistics reset")
}
