package extractionparser

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"time"

	"github.com/gerivdb/email-sender-1/core/extraction"
	"github.com/gerivdb/email-sender-1/core/gapanalyzer"
	"github.com/gerivdb/email-sender-1/core/ports"
)

func main() {
	fmt.Println("Starting Orchestration of Phase 4: Extraction and Parsing.")

	// Define output paths
	outputDir := "../../output/phase4"  // A directory for the outputs
	os.MkdirAll(outputDir, os.ModePerm) // Create the directory if it doesn't exist

	extractionScanPath := filepath.Join(outputDir, "extraction-parsing-scan.json")
	gapAnalysisPath := filepath.Join(outputDir, "EXTRACTION_PARSING_GAP_ANALYSIS.md")
	phase4ReportPath := filepath.Join(outputDir, "EXTRACTION_PARSING_PHASE4_REPORT.md")

	// --- Step 1: Extraction and Parsing ---
	fmt.Println("\nExecuting Extraction and Parsing...")
	// Simulate a source path for extraction. In reality, this would be a path to real data.
	// For this test, we will create a temporary file.
	tempSourceFile := filepath.Join(outputDir, "simulated_source_data.txt")
	err := os.WriteFile(tempSourceFile, []byte("This is simulated data content for extraction."), 0o644)
	if err != nil {
		log.Fatalf("Error creating simulated source file: %v", err)
	}

	extractedData, err := extraction.ExtractAndParseData(tempSourceFile)
	if err != nil {
		log.Printf("Error during extraction and parsing: %v", err)
		// Continue if possible for gap analysis even if extraction fails
		extractedData = map[string]interface{}{"status": "failed", "error": err.Error()}
	} else {
		fmt.Println("Extraction and parsing completed successfully.")
	}

	// Generate the extraction scan file
	err = extraction.GenerateExtractionParsingScan(extractionScanPath, extractedData)
	if err != nil {
		log.Fatalf("Error generating extraction scan: %v", err)
	}
	fmt.Printf("Extraction scan file generated: %s\n", extractionScanPath)

	// --- Step 2: Gap Analysis ---
	fmt.Println("\nExecuting Gap Analysis...")
	var analyzer ports.GapAnalyzer = gapanalyzer.NewAnalyzer()
	analysisResult, err := analyzer.AnalyzeExtractionParsingGap(extractedData)
	if err != nil {
		log.Fatalf("Error during gap analysis: %v", err)
	}
	fmt.Println("Gap analysis completed.")

	// Generate the gap analysis report
	err = analyzer.GenerateExtractionParsingGapAnalysis(gapAnalysisPath, analysisResult)
	if err != nil {
		log.Fatalf("Error generating gap analysis report: %v", err)
	}
	fmt.Printf("Gap analysis report generated: %s\n", gapAnalysisPath)

	// --- Step 3: Generate Phase 4 Report ---
	fmt.Println("\nGenerating Phase 4 Report...")
	reportContent := fmt.Sprintf(`
# Phase 4 Report: Extraction and Parsing

## Summary
This phase covered data extraction and parsing, followed by a gap analysis.

## Extraction/Parsing Results
- See file: [%s](%s)

## Gap Analysis Results
- See file: [%s](%s)

## Overall Status
Phase 4 completed on %s.
Detected gaps: %v
`,
		filepath.Base(extractionScanPath), extractionScanPath,
		filepath.Base(gapAnalysisPath), gapAnalysisPath,
		time.Now().Format(time.RFC3339), analysisResult["gap_found"])

	err = os.WriteFile(phase4ReportPath, []byte(reportContent), 0o644)
	if err != nil {
		log.Fatalf("Error generating Phase 4 report: %v", err)
	}
	fmt.Printf("Phase 4 report generated: %s\n", phase4ReportPath)

	fmt.Println("\nPhase 4 Orchestration finished.")
}
