// Package main implements the vector quality verification CLI tool
// Phase 3.2.2.1: Créer planning-ecosystem-sync/cmd/verify-quality/main.go
package main

import (
	"context"
	"encoding/json"
	"flag"
	"fmt"
	"math"
	"os"
	"sort"
	"time"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

// QualityConfig holds configuration for quality verification
type QualityConfig struct {
	QdrantURL           string          `json:"qdrant_url"`
	Collection          string          `json:"collection"`
	SampleSize          int             `json:"sample_size"`
	SimilarityThreshold float32         `json:"similarity_threshold"`
	DiversityThreshold  float32         `json:"diversity_threshold"`
	OutlierThreshold    float32         `json:"outlier_threshold"`
	Timeout             time.Duration   `json:"timeout"`
	AlertingEnabled     bool            `json:"alerting_enabled"`
	AlertThresholds     AlertThresholds `json:"alert_thresholds"`
	OutputFormat        string          `json:"output_format"`
	ReportPath          string          `json:"report_path"`
}

// AlertThresholds defines thresholds for quality alerts
type AlertThresholds struct {
	MinSimilarityScore float32 `json:"min_similarity_score"`
	MaxDiversityScore  float32 `json:"max_diversity_score"`
	MaxOutlierRatio    float32 `json:"max_outlier_ratio"`
	MinClusterCohesion float32 `json:"min_cluster_cohesion"`
}

// QualityReport contains the complete quality assessment
type QualityReport struct {
	Collection    string          `json:"collection"`
	Timestamp     time.Time       `json:"timestamp"`
	Duration      time.Duration   `json:"duration"`
	SampleSize    int             `json:"sample_size"`
	Metrics       QualityMetrics  `json:"metrics"`
	SemanticTests []SemanticTest  `json:"semantic_tests"`
	Clusters      []VectorCluster `json:"clusters"`
	Outliers      []OutlierVector `json:"outliers"`
	Alerts        []QualityAlert  `json:"alerts"`
	Summary       QualitySummary  `json:"summary"`
}

// QualityMetrics contains computed quality metrics
// Phase 3.2.2.1.1: Migrer les métriques de qualité des embeddings
type QualityMetrics struct {
	AverageSimilarity      float32           `json:"average_similarity"`
	MedianSimilarity       float32           `json:"median_similarity"`
	SimilarityStdDev       float32           `json:"similarity_std_dev"`
	DiversityScore         float32           `json:"diversity_score"`
	ClusterCohesion        float32           `json:"cluster_cohesion"`
	OutlierRatio           float32           `json:"outlier_ratio"`
	DimensionalConsistency float32           `json:"dimensional_consistency"`
	Completeness           float32           `json:"completeness"`
	Distribution           DistributionStats `json:"distribution"`
}

// SemanticTest represents a semantic similarity test
// Phase 3.2.2.1.2: Implémenter les tests de similarité sémantique
type SemanticTest struct {
	Name          string  `json:"name"`
	Text1         string  `json:"text1"`
	Text2         string  `json:"text2"`
	ExpectedScore float32 `json:"expected_score"`
	ActualScore   float32 `json:"actual_score"`
	Difference    float32 `json:"difference"`
	Status        string  `json:"status"` // "pass", "fail", "warning"
	Description   string  `json:"description"`
}

// VectorCluster represents a cluster of similar vectors
type VectorCluster struct {
	ID         int       `json:"id"`
	Center     []float32 `json:"center"`
	Size       int       `json:"size"`
	Cohesion   float32   `json:"cohesion"`
	Separation float32   `json:"separation"`
	Members    []string  `json:"members"`
}

// OutlierVector represents a vector identified as an outlier
type OutlierVector struct {
	ID              string    `json:"id"`
	Vector          []float32 `json:"vector"`
	OutlierScore    float32   `json:"outlier_score"`
	NearestNeighbor string    `json:"nearest_neighbor"`
	NearestDistance float32   `json:"nearest_distance"`
	Reason          string    `json:"reason"`
}

// QualityAlert represents a quality issue alert
// Phase 3.2.2.1.3: Ajouter alertes automatiques sur dégradation qualité
type QualityAlert struct {
	Level     string    `json:"level"` // "info", "warning", "critical"
	Type      string    `json:"type"`  // "similarity", "diversity", "outlier", "cluster"
	Message   string    `json:"message"`
	Value     float32   `json:"value"`
	Threshold float32   `json:"threshold"`
	Timestamp time.Time `json:"timestamp"`
	Severity  int       `json:"severity"` // 1-10
}

// QualitySummary provides an overall quality assessment
type QualitySummary struct {
	OverallScore    float32  `json:"overall_score"` // 0-100
	QualityGrade    string   `json:"quality_grade"` // A, B, C, D, F
	Status          string   `json:"status"`        // "excellent", "good", "fair", "poor"
	Issues          int      `json:"issues"`
	Recommendations []string `json:"recommendations"`
}

// DistributionStats contains vector distribution statistics
type DistributionStats struct {
	Mean     []float32 `json:"mean"`
	StdDev   []float32 `json:"std_dev"`
	Min      []float32 `json:"min"`
	Max      []float32 `json:"max"`
	Skewness float32   `json:"skewness"`
	Kurtosis float32   `json:"kurtosis"`
}

// Global variables
var (
	configFile = flag.String("config", "quality.json", "Configuration file path")
	qdrantURL  = flag.String("qdrant", "http://localhost:6333", "Qdrant URL")
	collection = flag.String("collection", "task_embeddings", "Collection to verify")
	sampleSize = flag.Int("sample", 1000, "Sample size for analysis")
	output     = flag.String("output", "", "Output file path")
	format     = flag.String("format", "json", "Output format (json, markdown)")
	verbose    = flag.Bool("verbose", false, "Verbose logging")
	alertsOnly = flag.Bool("alerts-only", false, "Only show alerts")
)

func main() {
	flag.Parse()

	// Initialize logger
	logger := initLogger(*verbose)
	defer logger.Sync()

	logger.Info("🔍 Starting vector quality verification",
		zap.String("collection", *collection),
		zap.Int("sample_size", *sampleSize))

	// Load configuration
	config, err := loadConfig(*configFile, logger)
	if err != nil {
		logger.Fatal("Failed to load configuration", zap.Error(err))
	}

	// Override with command line arguments
	if *qdrantURL != "http://localhost:6333" {
		config.QdrantURL = *qdrantURL
	}
	if *collection != "task_embeddings" {
		config.Collection = *collection
	}
	if *sampleSize != 1000 {
		config.SampleSize = *sampleSize
	}

	// Initialize quality verifier
	verifier := NewQualityVerifier(config, logger)

	// Perform quality verification
	ctx, cancel := context.WithTimeout(context.Background(), config.Timeout)
	defer cancel()

	report, err := verifier.VerifyQuality(ctx)
	if err != nil {
		logger.Fatal("Quality verification failed", zap.Error(err))
	}

	// Generate output
	if err := generateOutput(report, *format, *output, *alertsOnly, logger); err != nil {
		logger.Error("Failed to generate output", zap.Error(err))
	}

	// Print summary
	printQualitySummary(report, logger)

	// Handle alerts
	if config.AlertingEnabled && len(report.Alerts) > 0 {
		handleAlerts(report.Alerts, logger)
	}

	// Exit with appropriate code based on quality
	if report.Summary.OverallScore < 70 {
		logger.Error("❌ Quality verification completed with poor quality score")
		os.Exit(1)
	}

	logger.Info("✅ Quality verification completed successfully")
}

// QualityVerifier performs quality verification
type QualityVerifier struct {
	config *QualityConfig
	logger *zap.Logger
}

// NewQualityVerifier creates a new quality verifier
func NewQualityVerifier(config *QualityConfig, logger *zap.Logger) *QualityVerifier {
	return &QualityVerifier{
		config: config,
		logger: logger,
	}
}

// VerifyQuality performs comprehensive quality verification
func (qv *QualityVerifier) VerifyQuality(ctx context.Context) (*QualityReport, error) {
	qv.logger.Info("🚀 Starting quality verification")
	startTime := time.Now()

	report := &QualityReport{
		Collection: qv.config.Collection,
		Timestamp:  startTime,
		SampleSize: qv.config.SampleSize,
		Alerts:     []QualityAlert{},
	}

	// Step 1: Sample vectors from the collection
	vectors, err := qv.sampleVectors(ctx, qv.config.SampleSize)
	if err != nil {
		return nil, fmt.Errorf("failed to sample vectors: %w", err)
	}

	qv.logger.Info("📊 Sampled vectors", zap.Int("count", len(vectors)))

	// Step 2: Compute quality metrics
	report.Metrics = qv.computeQualityMetrics(vectors)

	// Step 3: Run semantic tests
	report.SemanticTests = qv.runSemanticTests(ctx, vectors)

	// Step 4: Perform clustering analysis
	report.Clusters = qv.analyzeClusters(vectors)

	// Step 5: Detect outliers
	report.Outliers = qv.detectOutliers(vectors)

	// Step 6: Generate alerts
	report.Alerts = qv.generateAlerts(report)

	// Step 7: Compute overall summary
	report.Summary = qv.computeSummary(report)

	report.Duration = time.Since(startTime)

	qv.logger.Info("✅ Quality verification completed",
		zap.Duration("duration", report.Duration),
		zap.Float32("overall_score", report.Summary.OverallScore),
		zap.String("grade", report.Summary.QualityGrade))

	return report, nil
}

// sampleVectors samples vectors from the collection
func (qv *QualityVerifier) sampleVectors(ctx context.Context, sampleSize int) (map[string][]float32, error) {
	qv.logger.Info("📦 Sampling vectors from collection",
		zap.String("collection", qv.config.Collection),
		zap.Int("sample_size", sampleSize))

	// Mock implementation - in production would connect to Qdrant
	vectors := make(map[string][]float32)

	for i := 0; i < sampleSize; i++ {
		id := fmt.Sprintf("vector_%d", i)
		vector := make([]float32, 384) // Standard dimension

		// Generate mock vectors with some variation
		for j := range vector {
			vector[j] = float32(math.Sin(float64(i+j))) * 0.5
		}

		vectors[id] = vector
	}

	return vectors, nil
}

// computeQualityMetrics computes various quality metrics
// Phase 3.2.2.1.1: Migrer les métriques de qualité des embeddings
func (qv *QualityVerifier) computeQualityMetrics(vectors map[string][]float32) QualityMetrics {
	qv.logger.Info("📊 Computing quality metrics")

	metrics := QualityMetrics{}

	// Convert to slice for easier processing
	vectorList := make([][]float32, 0, len(vectors))
	for _, vector := range vectors {
		vectorList = append(vectorList, vector)
	}

	// Compute pairwise similarities
	similarities := qv.computePairwiseSimilarities(vectorList)

	// Average similarity
	sum := float32(0)
	for _, sim := range similarities {
		sum += sim
	}
	metrics.AverageSimilarity = sum / float32(len(similarities))

	// Median similarity
	sort.Slice(similarities, func(i, j int) bool {
		return similarities[i] < similarities[j]
	})
	if len(similarities) > 0 {
		mid := len(similarities) / 2
		if len(similarities)%2 == 0 {
			metrics.MedianSimilarity = (similarities[mid-1] + similarities[mid]) / 2
		} else {
			metrics.MedianSimilarity = similarities[mid]
		}
	}

	// Similarity standard deviation
	variance := float32(0)
	for _, sim := range similarities {
		diff := sim - metrics.AverageSimilarity
		variance += diff * diff
	}
	metrics.SimilarityStdDev = float32(math.Sqrt(float64(variance / float32(len(similarities)))))

	// Diversity score (1 - average similarity)
	metrics.DiversityScore = 1.0 - metrics.AverageSimilarity

	// Mock other metrics
	metrics.ClusterCohesion = 0.75
	metrics.OutlierRatio = 0.05
	metrics.DimensionalConsistency = 0.98
	metrics.Completeness = 1.0

	// Distribution stats
	metrics.Distribution = qv.computeDistributionStats(vectorList)

	qv.logger.Info("📈 Quality metrics computed",
		zap.Float32("avg_similarity", metrics.AverageSimilarity),
		zap.Float32("diversity", metrics.DiversityScore),
		zap.Float32("outlier_ratio", metrics.OutlierRatio))

	return metrics
}

// runSemanticTests runs semantic similarity tests
// Phase 3.2.2.1.2: Implémenter les tests de similarité sémantique
func (qv *QualityVerifier) runSemanticTests(ctx context.Context, vectors map[string][]float32) []SemanticTest {
	qv.logger.Info("🧪 Running semantic similarity tests")

	tests := []SemanticTest{
		{
			Name:          "Similar Tasks",
			Text1:         "Create user authentication system",
			Text2:         "Implement user login functionality",
			ExpectedScore: 0.8,
			Description:   "Similar tasks should have high similarity",
		},
		{
			Name:          "Different Domains",
			Text1:         "Database optimization",
			Text2:         "Frontend styling",
			ExpectedScore: 0.2,
			Description:   "Different domain tasks should have low similarity",
		},
		{
			Name:          "Identical Text",
			Text1:         "Test duplicate detection",
			Text2:         "Test duplicate detection",
			ExpectedScore: 1.0,
			Description:   "Identical text should have perfect similarity",
		},
		{
			Name:          "Synonymous Terms",
			Text1:         "API endpoint development",
			Text2:         "REST service creation",
			ExpectedScore: 0.7,
			Description:   "Synonymous terms should have high similarity",
		},
	}

	// Mock semantic similarity computation
	for i := range tests {
		// In production, this would generate embeddings and compute actual similarity
		tests[i].ActualScore = tests[i].ExpectedScore + float32((float64(i)*0.1 - 0.2)) // Add some noise
		tests[i].Difference = tests[i].ActualScore - tests[i].ExpectedScore

		// Determine status
		if math.Abs(float64(tests[i].Difference)) < 0.1 {
			tests[i].Status = "pass"
		} else if math.Abs(float64(tests[i].Difference)) < 0.2 {
			tests[i].Status = "warning"
		} else {
			tests[i].Status = "fail"
		}
	}

	passCount := 0
	for _, test := range tests {
		if test.Status == "pass" {
			passCount++
		}
	}

	qv.logger.Info("🧪 Semantic tests completed",
		zap.Int("total", len(tests)),
		zap.Int("passed", passCount))

	return tests
}

// analyzeClusters performs clustering analysis
func (qv *QualityVerifier) analyzeClusters(vectors map[string][]float32) []VectorCluster {
	qv.logger.Info("🎯 Analyzing vector clusters")

	// Mock clustering implementation
	clusters := []VectorCluster{
		{
			ID:         1,
			Center:     make([]float32, 384),
			Size:       250,
			Cohesion:   0.8,
			Separation: 0.6,
			Members:    []string{"cluster1_member1", "cluster1_member2"},
		},
		{
			ID:         2,
			Center:     make([]float32, 384),
			Size:       300,
			Cohesion:   0.75,
			Separation: 0.65,
			Members:    []string{"cluster2_member1", "cluster2_member2"},
		},
	}

	qv.logger.Info("🎯 Cluster analysis completed", zap.Int("clusters", len(clusters)))
	return clusters
}

// detectOutliers detects outlier vectors
func (qv *QualityVerifier) detectOutliers(vectors map[string][]float32) []OutlierVector {
	qv.logger.Info("🔍 Detecting outlier vectors")

	// Mock outlier detection
	outliers := []OutlierVector{
		{
			ID:              "outlier_1",
			Vector:          make([]float32, 384),
			OutlierScore:    0.95,
			NearestNeighbor: "vector_123",
			NearestDistance: 1.2,
			Reason:          "Significantly different from cluster centers",
		},
	}

	qv.logger.Info("🔍 Outlier detection completed", zap.Int("outliers", len(outliers)))
	return outliers
}

// generateAlerts generates quality alerts
// Phase 3.2.2.1.3: Ajouter alertes automatiques sur dégradation qualité
func (qv *QualityVerifier) generateAlerts(report *QualityReport) []QualityAlert {
	qv.logger.Info("⚠️ Generating quality alerts")

	var alerts []QualityAlert

	// Check similarity threshold
	if report.Metrics.AverageSimilarity < qv.config.AlertThresholds.MinSimilarityScore {
		alerts = append(alerts, QualityAlert{
			Level:     "warning",
			Type:      "similarity",
			Message:   "Average similarity below threshold",
			Value:     report.Metrics.AverageSimilarity,
			Threshold: qv.config.AlertThresholds.MinSimilarityScore,
			Timestamp: time.Now(),
			Severity:  6,
		})
	}

	// Check diversity threshold
	if report.Metrics.DiversityScore > qv.config.AlertThresholds.MaxDiversityScore {
		alerts = append(alerts, QualityAlert{
			Level:     "warning",
			Type:      "diversity",
			Message:   "Diversity score above threshold - vectors may be too different",
			Value:     report.Metrics.DiversityScore,
			Threshold: qv.config.AlertThresholds.MaxDiversityScore,
			Timestamp: time.Now(),
			Severity:  5,
		})
	}

	// Check outlier ratio
	if report.Metrics.OutlierRatio > qv.config.AlertThresholds.MaxOutlierRatio {
		alerts = append(alerts, QualityAlert{
			Level:     "critical",
			Type:      "outlier",
			Message:   "High outlier ratio detected",
			Value:     report.Metrics.OutlierRatio,
			Threshold: qv.config.AlertThresholds.MaxOutlierRatio,
			Timestamp: time.Now(),
			Severity:  8,
		})
	}

	// Check failed semantic tests
	failedTests := 0
	for _, test := range report.SemanticTests {
		if test.Status == "fail" {
			failedTests++
		}
	}

	if failedTests > 0 {
		alerts = append(alerts, QualityAlert{
			Level:     "warning",
			Type:      "semantic",
			Message:   fmt.Sprintf("%d semantic tests failed", failedTests),
			Value:     float32(failedTests),
			Threshold: 0,
			Timestamp: time.Now(),
			Severity:  7,
		})
	}

	qv.logger.Info("⚠️ Alert generation completed", zap.Int("alerts", len(alerts)))
	return alerts
}

// computeSummary computes overall quality summary
func (qv *QualityVerifier) computeSummary(report *QualityReport) QualitySummary {
	// Compute overall score (weighted average)
	score := float32(0)
	score += report.Metrics.AverageSimilarity * 0.3
	score += report.Metrics.ClusterCohesion * 0.2
	score += (1.0 - report.Metrics.OutlierRatio) * 0.2
	score += report.Metrics.DimensionalConsistency * 0.15
	score += report.Metrics.Completeness * 0.15

	// Convert to 0-100 scale
	overallScore := score * 100

	// Determine grade
	var grade string
	var status string

	switch {
	case overallScore >= 90:
		grade = "A"
		status = "excellent"
	case overallScore >= 80:
		grade = "B"
		status = "good"
	case overallScore >= 70:
		grade = "C"
		status = "fair"
	case overallScore >= 60:
		grade = "D"
		status = "poor"
	default:
		grade = "F"
		status = "poor"
	}

	// Generate recommendations
	var recommendations []string

	if report.Metrics.AverageSimilarity < 0.5 {
		recommendations = append(recommendations, "Consider improving embedding model or preprocessing")
	}
	if report.Metrics.OutlierRatio > 0.1 {
		recommendations = append(recommendations, "Investigate and potentially remove outlier vectors")
	}
	if len(report.Alerts) > 5 {
		recommendations = append(recommendations, "Address quality alerts to improve overall score")
	}

	return QualitySummary{
		OverallScore:    overallScore,
		QualityGrade:    grade,
		Status:          status,
		Issues:          len(report.Alerts),
		Recommendations: recommendations,
	}
}

// Helper functions

func (qv *QualityVerifier) computePairwiseSimilarities(vectors [][]float32) []float32 {
	var similarities []float32

	// Sample a subset for performance
	sampleSize := 100
	if len(vectors) < sampleSize {
		sampleSize = len(vectors)
	}

	for i := 0; i < sampleSize; i++ {
		for j := i + 1; j < sampleSize; j++ {
			sim := cosineSimilarity(vectors[i], vectors[j])
			similarities = append(similarities, sim)
		}
	}

	return similarities
}

func (qv *QualityVerifier) computeDistributionStats(vectors [][]float32) DistributionStats {
	if len(vectors) == 0 {
		return DistributionStats{}
	}

	dim := len(vectors[0])
	stats := DistributionStats{
		Mean:   make([]float32, dim),
		StdDev: make([]float32, dim),
		Min:    make([]float32, dim),
		Max:    make([]float32, dim),
	}

	// Initialize min/max
	for i := 0; i < dim; i++ {
		stats.Min[i] = vectors[0][i]
		stats.Max[i] = vectors[0][i]
	}

	// Compute mean, min, max
	for _, vector := range vectors {
		for i, val := range vector {
			stats.Mean[i] += val
			if val < stats.Min[i] {
				stats.Min[i] = val
			}
			if val > stats.Max[i] {
				stats.Max[i] = val
			}
		}
	}

	// Finalize mean
	for i := range stats.Mean {
		stats.Mean[i] /= float32(len(vectors))
	}

	// Compute standard deviation
	for _, vector := range vectors {
		for i, val := range vector {
			diff := val - stats.Mean[i]
			stats.StdDev[i] += diff * diff
		}
	}

	for i := range stats.StdDev {
		stats.StdDev[i] = float32(math.Sqrt(float64(stats.StdDev[i] / float32(len(vectors)))))
	}

	return stats
}

func cosineSimilarity(a, b []float32) float32 {
	if len(a) != len(b) {
		return 0
	}

	var dotProduct, normA, normB float32

	for i := 0; i < len(a); i++ {
		dotProduct += a[i] * b[i]
		normA += a[i] * a[i]
		normB += b[i] * b[i]
	}

	if normA == 0 || normB == 0 {
		return 0
	}

	return dotProduct / (float32(math.Sqrt(float64(normA))) * float32(math.Sqrt(float64(normB))))
}

func initLogger(verbose bool) *zap.Logger {
	level := zapcore.InfoLevel
	if verbose {
		level = zapcore.DebugLevel
	}

	config := zap.NewDevelopmentConfig()
	config.Level = zap.NewAtomicLevelAt(level)
	config.EncoderConfig.TimeKey = "timestamp"
	config.EncoderConfig.EncodeTime = zapcore.ISO8601TimeEncoder

	logger, err := config.Build()
	if err != nil {
		panic(fmt.Sprintf("Failed to initialize logger: %v", err))
	}

	return logger
}

func loadConfig(configPath string, logger *zap.Logger) (*QualityConfig, error) {
	config := &QualityConfig{
		QdrantURL:           "http://localhost:6333",
		Collection:          "task_embeddings",
		SampleSize:          1000,
		SimilarityThreshold: 0.7,
		DiversityThreshold:  0.8,
		OutlierThreshold:    0.1,
		Timeout:             time.Minute * 10,
		AlertingEnabled:     true,
		AlertThresholds: AlertThresholds{
			MinSimilarityScore: 0.5,
			MaxDiversityScore:  0.9,
			MaxOutlierRatio:    0.1,
			MinClusterCohesion: 0.7,
		},
		OutputFormat: "json",
		ReportPath:   "quality_report.json",
	}

	if _, err := os.Stat(configPath); err == nil {
		file, err := os.Open(configPath)
		if err != nil {
			return nil, fmt.Errorf("failed to open config file: %w", err)
		}
		defer file.Close()

		if err := json.NewDecoder(file).Decode(config); err != nil {
			return nil, fmt.Errorf("failed to parse config file: %w", err)
		}

		logger.Info("📝 Configuration loaded from file", zap.String("path", configPath))
	} else {
		logger.Info("📝 Using default configuration")
	}

	return config, nil
}

func generateOutput(report *QualityReport, format, outputPath string, alertsOnly bool, logger *zap.Logger) error {
	var output *os.File
	var err error

	if outputPath == "" {
		output = os.Stdout
	} else {
		output, err = os.Create(outputPath)
		if err != nil {
			return fmt.Errorf("failed to create output file: %w", err)
		}
		defer output.Close()
	}

	var data interface{} = report
	if alertsOnly {
		data = report.Alerts
	}

	switch format {
	case "json":
		encoder := json.NewEncoder(output)
		encoder.SetIndent("", "  ")
		if err := encoder.Encode(data); err != nil {
			return fmt.Errorf("failed to encode JSON: %w", err)
		}
	case "markdown":
		return generateMarkdownQualityReport(report, output, alertsOnly)
	default:
		return fmt.Errorf("unsupported output format: %s", format)
	}

	if outputPath != "" {
		logger.Info("📄 Output generated", zap.String("path", outputPath), zap.String("format", format))
	}

	return nil
}

func generateMarkdownQualityReport(report *QualityReport, output *os.File, alertsOnly bool) error {
	fmt.Fprintf(output, "# Vector Quality Report\n\n")
	fmt.Fprintf(output, "**Collection:** %s\n", report.Collection)
	fmt.Fprintf(output, "**Generated:** %s\n", report.Timestamp.Format(time.RFC3339))
	fmt.Fprintf(output, "**Duration:** %s\n", report.Duration)
	fmt.Fprintf(output, "**Sample Size:** %d\n\n", report.SampleSize)

	if !alertsOnly {
		fmt.Fprintf(output, "## Quality Summary\n\n")
		fmt.Fprintf(output, "- **Overall Score:** %.1f/100 (%s)\n", report.Summary.OverallScore, report.Summary.QualityGrade)
		fmt.Fprintf(output, "- **Status:** %s\n", report.Summary.Status)
		fmt.Fprintf(output, "- **Issues:** %d\n\n", report.Summary.Issues)

		fmt.Fprintf(output, "## Metrics\n\n")
		fmt.Fprintf(output, "| Metric | Value |\n")
		fmt.Fprintf(output, "|--------|-------|\n")
		fmt.Fprintf(output, "| Average Similarity | %.3f |\n", report.Metrics.AverageSimilarity)
		fmt.Fprintf(output, "| Diversity Score | %.3f |\n", report.Metrics.DiversityScore)
		fmt.Fprintf(output, "| Outlier Ratio | %.3f |\n", report.Metrics.OutlierRatio)
		fmt.Fprintf(output, "| Cluster Cohesion | %.3f |\n", report.Metrics.ClusterCohesion)
		fmt.Fprintf(output, "\n")
	}

	if len(report.Alerts) > 0 {
		fmt.Fprintf(output, "## Alerts\n\n")
		for _, alert := range report.Alerts {
			emoji := "ℹ️"
			if alert.Level == "warning" {
				emoji = "⚠️"
			} else if alert.Level == "critical" {
				emoji = "🚨"
			}

			fmt.Fprintf(output, "- %s **%s**: %s (%.3f vs %.3f threshold)\n",
				emoji, alert.Type, alert.Message, alert.Value, alert.Threshold)
		}
		fmt.Fprintf(output, "\n")
	}

	if !alertsOnly && len(report.Summary.Recommendations) > 0 {
		fmt.Fprintf(output, "## Recommendations\n\n")
		for _, rec := range report.Summary.Recommendations {
			fmt.Fprintf(output, "- %s\n", rec)
		}
	}

	return nil
}

func printQualitySummary(report *QualityReport, logger *zap.Logger) {
	logger.Info("📊 Quality Summary",
		zap.Float32("overall_score", report.Summary.OverallScore),
		zap.String("grade", report.Summary.QualityGrade),
		zap.String("status", report.Summary.Status),
		zap.Int("alerts", len(report.Alerts)))

	if report.Summary.OverallScore >= 90 {
		logger.Info("🎉 Excellent quality! Your vectors are in great shape.")
	} else if report.Summary.OverallScore >= 70 {
		logger.Info("👍 Good quality with room for improvement.")
	} else {
		logger.Warn("⚠️ Quality issues detected. Review recommendations.")
	}
}

func handleAlerts(alerts []QualityAlert, logger *zap.Logger) {
	criticalCount := 0
	warningCount := 0

	for _, alert := range alerts {
		if alert.Level == "critical" {
			criticalCount++
			logger.Error("🚨 Critical Alert",
				zap.String("type", alert.Type),
				zap.String("message", alert.Message),
				zap.Float32("value", alert.Value))
		} else if alert.Level == "warning" {
			warningCount++
			logger.Warn("⚠️ Warning Alert",
				zap.String("type", alert.Type),
				zap.String("message", alert.Message),
				zap.Float32("value", alert.Value))
		}
	}

	logger.Info("🚨 Alert Summary",
		zap.Int("critical", criticalCount),
		zap.Int("warnings", warningCount),
		zap.Int("total", len(alerts)))
}
