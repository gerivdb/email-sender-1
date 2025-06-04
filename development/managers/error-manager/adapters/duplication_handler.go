package adapters

import (
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"time"

	"github.com/pkg/errors"
)

// DuplicationErrorHandler gère les erreurs liées à la détection de duplications
// Micro-étape 8.2.1 : Adapter Find-CodeDuplication.ps1 pour signaler les erreurs via ErrorManager
type DuplicationErrorHandler struct {
	reportsPath     string
	watchInterval   time.Duration
	onErrorCallback func(DuplicationError)
}

// DuplicationError représente une erreur de duplication détectée
type DuplicationError struct {
	ID                 string                 `json:"id"`
	Timestamp          time.Time              `json:"timestamp"`
	SourceFile         string                 `json:"source_file"`
	DuplicateFile      string                 `json:"duplicate_file"`
	SimilarityScore    float64                `json:"similarity_score"`
	DuplicationContext map[string]interface{} `json:"duplication_context"`
	ErrorCode          string                 `json:"error_code"`
	Severity           string                 `json:"severity"`
	RecommendedAction  string                 `json:"recommended_action"`
}

// DuplicationReport rapport de détection de duplications
type DuplicationReport struct {
	GeneratedAt    time.Time              `json:"generated_at"`
	TotalFiles     int                    `json:"total_files"`
	Duplications   []DuplicationError     `json:"duplications"`
	Summary        map[string]int         `json:"summary"`
	ReportMetadata map[string]interface{} `json:"report_metadata"`
}

// NewDuplicationErrorHandler crée un nouveau gestionnaire d'erreurs de duplication
func NewDuplicationErrorHandler(reportsPath string, watchInterval time.Duration) *DuplicationErrorHandler {
	return &DuplicationErrorHandler{
		reportsPath:   reportsPath,
		watchInterval: watchInterval,
	}
}

// SetErrorCallback définit le callback pour traiter les erreurs détectées
// Micro-étape 8.2.2 : Créer DuplicationErrorHandler() pour traiter les erreurs de détection
func (d *DuplicationErrorHandler) SetErrorCallback(callback func(DuplicationError)) {
	d.onErrorCallback = callback
}

// ProcessDuplicationReport traite un rapport de duplication
// Micro-étape 8.2.3 : Implémenter la surveillance des rapports de duplication (duplication_report.json)
func (d *DuplicationErrorHandler) ProcessDuplicationReport(reportPath string) error {
	data, err := os.ReadFile(reportPath)
	if err != nil {
		return errors.Wrap(err, "échec de lecture du rapport de duplication")
	}

	var report DuplicationReport
	if err := json.Unmarshal(data, &report); err != nil {
		return errors.Wrap(err, "échec du parsing du rapport JSON")
	}

	// Traiter chaque duplication trouvée
	for _, dup := range report.Duplications {
		if d.onErrorCallback != nil {
			d.onErrorCallback(dup)
		}
	}

	return nil
}

// WatchDuplicationReports surveille les nouveaux rapports de duplication
func (d *DuplicationErrorHandler) WatchDuplicationReports() error {
	ticker := time.NewTicker(d.watchInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ticker.C:
			if err := d.scanForNewReports(); err != nil {
				return errors.Wrap(err, "erreur lors du scan des rapports")
			}
		}
	}
}

// scanForNewReports scanne le répertoire à la recherche de nouveaux rapports
func (d *DuplicationErrorHandler) scanForNewReports() error {
	pattern := filepath.Join(d.reportsPath, "duplication_report_*.json")
	matches, err := filepath.Glob(pattern)
	if err != nil {
		return errors.Wrap(err, "échec du scan des fichiers de rapport")
	}

	for _, reportPath := range matches {
		if err := d.ProcessDuplicationReport(reportPath); err != nil {
			fmt.Printf("Erreur lors du traitement du rapport %s: %v\n", reportPath, err)
		}
	}

	return nil
}

// GenerateDuplicationError crée une erreur de duplication standardisée
func (d *DuplicationErrorHandler) GenerateDuplicationError(sourceFile, duplicateFile string, similarityScore float64) DuplicationError {
	severity := "WARNING"
	if similarityScore > 0.9 {
		severity = "ERROR"
	} else if similarityScore > 0.7 {
		severity = "WARNING"
	} else {
		severity = "INFO"
	}

	return DuplicationError{
		ID:              fmt.Sprintf("DUP_%d", time.Now().Unix()),
		Timestamp:       time.Now(),
		SourceFile:      sourceFile,
		DuplicateFile:   duplicateFile,
		SimilarityScore: similarityScore,
		DuplicationContext: map[string]interface{}{
			"detection_method":    "script_analysis",
			"file_size_source":    d.getFileSize(sourceFile),
			"file_size_duplicate": d.getFileSize(duplicateFile),
		},
		ErrorCode:         "SCRIPT_DUPLICATION",
		Severity:          severity,
		RecommendedAction: d.getRecommendedAction(similarityScore),
	}
}

// getFileSize récupère la taille d'un fichier
func (d *DuplicationErrorHandler) getFileSize(filePath string) int64 {
	if info, err := os.Stat(filePath); err == nil {
		return info.Size()
	}
	return 0
}

// getRecommendedAction génère une action recommandée basée sur le score de similarité
func (d *DuplicationErrorHandler) getRecommendedAction(score float64) string {
	if score > 0.95 {
		return "Supprimer le fichier dupliqué ou fusionner les fonctionnalités"
	} else if score > 0.8 {
		return "Examiner et refactoriser le code dupliqué"
	} else if score > 0.6 {
		return "Vérifier s'il existe des opportunités de refactorisation"
	}
	return "Aucune action immédiate requise"
}

// IntegrateWithFindCodeDuplication interface avec le script PowerShell Find-CodeDuplication.ps1
func (d *DuplicationErrorHandler) IntegrateWithFindCodeDuplication(scriptPath, targetDirectory string) error {
	reportPath := filepath.Join(d.reportsPath, "duplication_report.json")
	cmd := fmt.Sprintf(`
		& '%s' -Path '%s' -OutputFormat JSON -ReportPath '%s'
	`, scriptPath, targetDirectory, reportPath)

	// Exécuter le script PowerShell via os/exec
	psCmd := exec.Command("powershell", "-Command", cmd)
	output, err := psCmd.CombinedOutput()
	if err != nil {
		return fmt.Errorf("failed to execute Find-CodeDuplication script: %v, output: %s", err, string(output))
	}

	// Log de confirmation
	fmt.Printf("Successfully executed duplication detection script. Output: %s\n", string(output))
	return nil
}
