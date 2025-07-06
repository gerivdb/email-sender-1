package ports

// GapAnalyzer defines the interface for gap analysis.
type GapAnalyzer interface {
	AnalyzeExtractionParsingGap(extractedData map[string]interface{}) (map[string]interface{}, error)
	GenerateExtractionParsingGapAnalysis(filePath string, analysisResult map[string]interface{}) error
}
