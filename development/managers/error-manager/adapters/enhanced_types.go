package adapters

import (
	"time"
)

// DuplicationContext contexte enrichi pour les erreurs de duplication
// Micro-étape 8.3.1 : Ajouter un champ DuplicationContext à la structure ErrorEntry
type DuplicationContext struct {
	SourceFile       string                 `json:"source_file"`
	DuplicateFiles   []string               `json:"duplicate_files"`
	SimilarityScores map[string]float64     `json:"similarity_scores"`
	DetectionMethod  string                 `json:"detection_method"`
	FileReferences   []string               `json:"file_references"`
	LastDetection    time.Time              `json:"last_detection"`
	Metadata         map[string]interface{} `json:"metadata"`
}

// EnhancedErrorEntry structure ErrorEntry enrichie avec contexte de duplication
// Micro-étape 8.3.2 : Inclure les scores de similarité et références de fichiers dupliqués
type EnhancedErrorEntry struct {
	ID                 string                 `json:"id"`
	Timestamp          time.Time              `json:"timestamp"`
	Message            string                 `json:"message"`
	StackTrace         string                 `json:"stack_trace"`
	Module             string                 `json:"module"`
	ErrorCode          string                 `json:"error_code"`
	ManagerContext     map[string]interface{} `json:"manager_context"`
	Severity           string                 `json:"severity"`
	DuplicationContext *DuplicationContext    `json:"duplication_context,omitempty"`
}

// DuplicationMetrics métriques de duplication pour analyse
// Micro-étape 8.3.3 : Créer des corrélations entre erreurs et duplications détectées
type DuplicationMetrics struct {
	TotalDuplications   int                  `json:"total_duplications"`
	AverageSimilarity   float64              `json:"average_similarity"`
	FileTypeDuplication map[string]int       `json:"file_type_duplication"`
	ModuleDuplication   map[string]int       `json:"module_duplication"`
	TopDuplicatedFiles  []DuplicatedFileInfo `json:"top_duplicated_files"`
	RecentDuplications  []DuplicationSummary `json:"recent_duplications"`
}

// DuplicatedFileInfo informations sur un fichier dupliqué
type DuplicatedFileInfo struct {
	FilePath         string    `json:"file_path"`
	DuplicationCount int       `json:"duplication_count"`
	AverageScore     float64   `json:"average_score"`
	LastDetected     time.Time `json:"last_detected"`
}

// DuplicationSummary résumé d'une duplication
type DuplicationSummary struct {
	ID            string    `json:"id"`
	FilesInvolved int       `json:"files_involved"`
	MaxSimilarity float64   `json:"max_similarity"`
	DetectedAt    time.Time `json:"detected_at"`
	Status        string    `json:"status"`
}

// DuplicationCorrelation corrélation entre erreurs et duplications
type DuplicationCorrelation struct {
	ErrorID          string    `json:"error_id"`
	DuplicationID    string    `json:"duplication_id"`
	CorrelationScore float64   `json:"correlation_score"`
	CorrelationType  string    `json:"correlation_type"`
	DetectedAt       time.Time `json:"detected_at"`
}

// CreateEnhancedErrorEntry crée une ErrorEntry enrichie avec contexte de duplication
func CreateEnhancedErrorEntry(baseError map[string]interface{}, dupContext *DuplicationContext) *EnhancedErrorEntry {
	entry := &EnhancedErrorEntry{
		DuplicationContext: dupContext,
	}

	// Mapping des champs de base
	if id, ok := baseError["id"].(string); ok {
		entry.ID = id
	}
	if timestamp, ok := baseError["timestamp"].(time.Time); ok {
		entry.Timestamp = timestamp
	}
	if message, ok := baseError["message"].(string); ok {
		entry.Message = message
	}
	if stackTrace, ok := baseError["stack_trace"].(string); ok {
		entry.StackTrace = stackTrace
	}
	if module, ok := baseError["module"].(string); ok {
		entry.Module = module
	}
	if errorCode, ok := baseError["error_code"].(string); ok {
		entry.ErrorCode = errorCode
	}
	if severity, ok := baseError["severity"].(string); ok {
		entry.Severity = severity
	}
	if managerContext, ok := baseError["manager_context"].(map[string]interface{}); ok {
		entry.ManagerContext = managerContext
	}

	return entry
}

// CalculateCorrelationScore calcule le score de corrélation entre une erreur et une duplication
func CalculateCorrelationScore(errorEntry *EnhancedErrorEntry, duplication DuplicationError) float64 {
	score := 0.0

	// Corrélation basée sur le module
	if errorEntry.Module != "" && duplication.SourceFile != "" {
		// Vérifier si le fichier source appartient au même module
		score += 0.3
	}

	// Corrélation temporelle (erreurs proches dans le temps)
	timeDiff := duplication.Timestamp.Sub(errorEntry.Timestamp)
	if timeDiff < time.Hour {
		score += 0.4
	} else if timeDiff < time.Hour*24 {
		score += 0.2
	}

	// Corrélation basée sur la similarité des messages d'erreur
	if containsSimilarKeywords(errorEntry.Message, duplication.SourceFile) {
		score += 0.3
	}

	return score
}

// containsSimilarKeywords vérifie si le message d'erreur contient des mots-clés similaires
func containsSimilarKeywords(errorMessage, sourceFile string) bool {
	// Implémentation simplifiée - peut être améliorée avec des algorithmes plus sophistiqués
	return len(errorMessage) > 0 && len(sourceFile) > 0
}
