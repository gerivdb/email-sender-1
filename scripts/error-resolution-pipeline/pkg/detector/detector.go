// Package detector implémente le système de détection d'erreurs du pipeline
package detector

import (
	"context"
	"fmt"
	"go/ast"
	"go/parser"
	"go/token"
	"go/types"
	"log"
	"path/filepath"
	"sync"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
)

// ErrorDetector représente le moteur principal de détection d'erreurs
type ErrorDetector struct {
	config        *Config
	fileSet       *token.FileSet
	typeChecker   *types.Checker
	patterns      []ErrorPattern
	metrics       *DetectorMetrics
	mu            sync.RWMutex
}

// Config contient la configuration du détecteur
type Config struct {
	MaxFileSize         int64         `json:"max_file_size"`
	Timeout            time.Duration `json:"timeout"`
	ParallelProcessing bool          `json:"parallel_processing"`
	MaxGoroutines      int           `json:"max_goroutines"`
}

// DetectedError représente une erreur détectée
type DetectedError struct {
	ID          string            `json:"id"`
	Type        string            `json:"type"`
	Severity    Severity          `json:"severity"`
	Message     string            `json:"message"`
	File        string            `json:"file"`
	Line        int               `json:"line"`
	Column      int               `json:"column"`
	Context     map[string]string `json:"context"`
	Suggestions []string          `json:"suggestions"`
	DetectedAt  time.Time         `json:"detected_at"`
}

// Severity définit la sévérité d'une erreur
type Severity int

const (
	SeverityInfo Severity = iota
	SeverityWarning
	SeverityError
	SeverityCritical
)

// ErrorPattern définit un pattern de détection d'erreur
type ErrorPattern interface {
	Name() string
	Detect(node ast.Node, info *types.Info, fset *token.FileSet) []DetectedError
	Priority() int
}

// DetectorMetrics contient les métriques Prometheus
type DetectorMetrics struct {
	ErrorsDetected    prometheus.Counter
	FilesProcessed    prometheus.Counter
	ProcessingTime    prometheus.Histogram
	PatternExecutions prometheus.CounterVec
}

// NewErrorDetector crée une nouvelle instance du détecteur
func NewErrorDetector(config *Config) *ErrorDetector {
	metrics := &DetectorMetrics{
		ErrorsDetected: promauto.NewCounter(prometheus.CounterOpts{
			Name: "error_detector_errors_total",
			Help: "Total number of errors detected",
		}),
		FilesProcessed: promauto.NewCounter(prometheus.CounterOpts{
			Name: "error_detector_files_processed_total",
			Help: "Total number of files processed",
		}),
		ProcessingTime: promauto.NewHistogram(prometheus.HistogramOpts{
			Name: "error_detector_processing_duration_seconds",
			Help: "Duration of error detection processing",
		}),
		PatternExecutions: *promauto.NewCounterVec(prometheus.CounterOpts{
			Name: "error_detector_pattern_executions_total",
			Help: "Total number of pattern executions",
		}, []string{"pattern_name"}),
	}

	return &ErrorDetector{
		config:  config,
		fileSet: token.NewFileSet(),
		patterns: []ErrorPattern{
			&UnusedVariablePattern{},
			&CircularDependencyPattern{},
			&TypeMismatchPattern{},
			&ComplexityPattern{},
		},
		metrics: metrics,
	}
}

// DetectInFile détecte les erreurs dans un fichier spécifique
func (ed *ErrorDetector) DetectInFile(ctx context.Context, filePath string) ([]DetectedError, error) {
	start := time.Now()
	defer func() {
		ed.metrics.ProcessingTime.Observe(time.Since(start).Seconds())
		ed.metrics.FilesProcessed.Inc()
	}()

	// Parse le fichier
	src, err := parser.ParseFile(ed.fileSet, filePath, nil, parser.ParseComments)
	if err != nil {
		return nil, fmt.Errorf("failed to parse file %s: %w", filePath, err)
	}

	// Configuration du type checker
	conf := types.Config{
		Importer: types.NewStdImporter(),
	}
	
	info := &types.Info{
		Types: make(map[ast.Expr]types.TypeAndValue),
		Defs:  make(map[*ast.Ident]types.Object),
		Uses:  make(map[*ast.Ident]types.Object),
	}

	var allErrors []DetectedError

	// Exécute tous les patterns de détection
	for _, pattern := range ed.patterns {
		select {
		case <-ctx.Done():
			return nil, ctx.Err()
		default:
		}

		ed.metrics.PatternExecutions.WithLabelValues(pattern.Name()).Inc()
		
		// Visite l'AST avec le pattern
		ast.Inspect(src, func(n ast.Node) bool {
			if n == nil {
				return false
			}
			
			errors := pattern.Detect(n, info, ed.fileSet)
			allErrors = append(allErrors, errors...)
			return true
		})
	}

	ed.metrics.ErrorsDetected.Add(float64(len(allErrors)))
	return allErrors, nil
}

// DetectInDirectory détecte les erreurs dans un répertoire
func (ed *ErrorDetector) DetectInDirectory(ctx context.Context, dirPath string) ([]DetectedError, error) {
	var allErrors []DetectedError
	var mu sync.Mutex
	var wg sync.WaitGroup

	err := filepath.Walk(dirPath, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		if !strings.HasSuffix(path, ".go") {
			return nil
		}

		if ed.config.ParallelProcessing {
			wg.Add(1)
			go func(filePath string) {
				defer wg.Done()
				
				errors, err := ed.DetectInFile(ctx, filePath)
				if err != nil {
					log.Printf("Error detecting in file %s: %v", filePath, err)
					return
				}

				mu.Lock()
				allErrors = append(allErrors, errors...)
				mu.Unlock()
			}(path)
		} else {
			errors, err := ed.DetectInFile(ctx, path)
			if err != nil {
				log.Printf("Error detecting in file %s: %v", path, err)
				return nil
			}
			allErrors = append(allErrors, errors...)
		}

		return nil
	})

	if ed.config.ParallelProcessing {
		wg.Wait()
	}

	return allErrors, err
}

// String retourne la représentation string de la sévérité
func (s Severity) String() string {
	switch s {
	case SeverityInfo:
		return "info"
	case SeverityWarning:
		return "warning"
	case SeverityError:
		return "error"
	case SeverityCritical:
		return "critical"
	default:
		return "unknown"
	}
}
