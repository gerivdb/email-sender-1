package errormanager

import (
	"database/sql"
	"time"
)

// PatternMetrics représente les métriques d'un pattern d'erreur
type PatternMetrics struct {
	ErrorCode     string                 `json:"error_code"`
	Module        string                 `json:"module"`
	Frequency     int                    `json:"frequency"`
	LastOccurred  time.Time              `json:"last_occurred"`
	FirstOccurred time.Time              `json:"first_occurred"`
	Severity      string                 `json:"severity"`
	Context       map[string]interface{} `json:"context"`
}

// TemporalCorrelation représente les corrélations temporelles entre erreurs
type TemporalCorrelation struct {
	ErrorCode1    string        `json:"error_code_1"`
	ErrorCode2    string        `json:"error_code_2"`
	Module1       string        `json:"module_1"`
	Module2       string        `json:"module_2"`
	Correlation   float64       `json:"correlation"`
	TimeWindow    time.Duration `json:"time_window"`
	OccurrenceGap time.Duration `json:"occurrence_gap"`
}

// PatternAnalyzer gère l'analyse des patterns d'erreurs
type PatternAnalyzer struct {
	db *sql.DB
}

// NewPatternAnalyzer crée une nouvelle instance de PatternAnalyzer
func NewPatternAnalyzer(db *sql.DB) *PatternAnalyzer {
	return &PatternAnalyzer{db: db}
}

// PatternReport représente un rapport d'analyse des patterns
type PatternReport struct {
	GeneratedAt          time.Time                 `json:"generated_at"`
	TotalErrors          int                       `json:"total_errors"`
	UniquePatterns       int                       `json:"unique_patterns"`
	TopPatterns          []PatternMetrics          `json:"top_patterns"`
	FrequencyMetrics     map[string]map[string]int `json:"frequency_metrics"`
	TemporalCorrelations []TemporalCorrelation     `json:"temporal_correlations"`
	Recommendations      []string                  `json:"recommendations"`
	CriticalFindings     []string                  `json:"critical_findings"`
}

// ReportGenerator gère la génération des rapports d'analyse
type ReportGenerator struct {
	analyzer *PatternAnalyzer
}

// NewReportGenerator crée une nouvelle instance de ReportGenerator
func NewReportGenerator(analyzer *PatternAnalyzer) *ReportGenerator {
	return &ReportGenerator{analyzer: analyzer}
}
