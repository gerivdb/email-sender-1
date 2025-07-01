package scripts

import (
	"encoding/json"
	"io/ioutil"
	"os"
	"path/filepath"
	"testing"
	"time"
)

func TestAnalyzeGaps(t *testing.T) {
	// Create temporary test directory
	tmpDir, err := ioutil.TempDir("", "gap_analysis_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	// Create some basic files but leave gaps
	testFiles := []string{
		"README.md",
		"docs/api.md",
		// Missing: CHANGELOG.md, LICENSE, CONTRIBUTING.md, etc.
	}

	for _, file := range testFiles {
		fullPath := filepath.Join(tmpDir, file)
		dir := filepath.Dir(fullPath)
		if err := os.MkdirAll(dir, 0755); err != nil {
			t.Fatalf("Failed to create dir %s: %v", dir, err)
		}
		if err := ioutil.WriteFile(fullPath, []byte("test content"), 0644); err != nil {
			t.Fatalf("Failed to create file %s: %v", fullPath, err)
		}
	}

	// Analyze gaps
	report, err := analyzeGaps(tmpDir)
	if err != nil {
		t.Fatalf("Failed to analyze gaps: %v", err)
	}

	// Should identify several missing files
	if len(report.IdentifiedGaps) == 0 {
		t.Error("Expected to find documentation gaps")
	}

	// Should have recommendations
	if len(report.Recommendations) == 0 {
		t.Error("Expected to find recommendations")
	}

	// Coverage score should be less than 100%
	if report.CoverageScore >= 100.0 {
		t.Error("Expected coverage score to be less than 100% due to missing files")
	}

	// Should have priority
	if report.Priority == "" {
		t.Error("Expected priority to be set")
	}

	// Should have summary
	if report.Summary == "" {
		t.Error("Expected non-empty summary")
	}

	// Check for specific missing files
	foundLicenseGap := false
	foundChangelogGap := false
	for _, gap := range report.IdentifiedGaps {
		for _, missingFile := range gap.MissingFiles {
			if missingFile == "LICENSE" {
				foundLicenseGap = true
			}
			if missingFile == "CHANGELOG.md" {
				foundChangelogGap = true
			}
		}
	}

	if !foundLicenseGap {
		t.Error("Expected to find LICENSE gap")
	}
	if !foundChangelogGap {
		t.Error("Expected to find CHANGELOG.md gap")
	}
}

func TestGetSeverity(t *testing.T) {
	tests := []struct {
		filename	string
		expected	string
	}{
		{"README.md", "critical"},
		{"LICENSE", "critical"},
		{"SECURITY.md", "critical"},
		{"CHANGELOG.md", "high"},
		{"CONTRIBUTING.md", "high"},
		{"INSTALLATION.md", "high"},
		{"docs/api.md", "medium"},
		{"docs/guide.md", "medium"},
	}

	for _, test := range tests {
		result := getSeverity(test.filename)
		if result != test.expected {
			t.Errorf("getSeverity(%s) = %s, expected %s",
				test.filename, result, test.expected)
		}
	}
}

func TestGetImpact(t *testing.T) {
	tests := []struct {
		filename	string
		expected	string
	}{
		{"README.md", "Users cannot understand the project purpose and usage"},
		{"LICENSE", "Legal implications for project usage"},
		{"SECURITY.md", "Security vulnerabilities may go unreported"},
		{"CONTRIBUTING.md", "Contributors don't know how to contribute"},
		{"unknown.md", "General documentation completeness affected"},
	}

	for _, test := range tests {
		result := getImpact(test.filename)
		if result != test.expected {
			t.Errorf("getImpact(%s) = %s, expected %s",
				test.filename, result, test.expected)
		}
	}
}

func TestGetEffort(t *testing.T) {
	tests := []struct {
		filename	string
		expected	string
	}{
		{"LICENSE", "low"},
		{"CODE_OF_CONDUCT.md", "low"},
		{"docs/api/endpoints.md", "high"},
		{"docs/architecture.md", "high"},
		{"README.md", "medium"},
		{"CHANGELOG.md", "medium"},
	}

	for _, test := range tests {
		result := getEffort(test.filename)
		if result != test.expected {
			t.Errorf("getEffort(%s) = %s, expected %s",
				test.filename, result, test.expected)
		}
	}
}

func TestCalculateCoverageScore(t *testing.T) {
	tests := []struct {
		gaps		[]DocumentGap
		totalFiles	int
		minScore	float64	// Minimum expected score
		maxScore	float64	// Maximum expected score
	}{
		{
			gaps:		[]DocumentGap{},
			totalFiles:	10,
			minScore:	95.0,
			maxScore:	100.0,
		},
		{
			gaps: []DocumentGap{
				{Severity: "critical"},
				{Severity: "high"},
			},
			totalFiles:	10,
			minScore:	70.0,
			maxScore:	90.0,
		},
		{
			gaps: []DocumentGap{
				{Severity: "critical"},
				{Severity: "critical"},
				{Severity: "high"},
				{Severity: "high"},
			},
			totalFiles:	5,
			minScore:	30.0,
			maxScore:	70.0,
		},
	}

	for i, test := range tests {
		result := calculateCoverageScore(test.gaps, test.totalFiles)

		if result < test.minScore || result > test.maxScore {
			t.Errorf("Test %d: calculateCoverageScore() = %.1f, expected between %.1f and %.1f",
				i, result, test.minScore, test.maxScore)
		}
	}
}

func TestGetPriorityLevel(t *testing.T) {
	tests := []struct {
		gaps		[]DocumentGap
		coverageScore	float64
		expected	string
	}{
		{
			gaps:		[]DocumentGap{{Severity: "critical"}},
			coverageScore:	80.0,
			expected:	"critical",
		},
		{
			gaps:		[]DocumentGap{},
			coverageScore:	20.0,
			expected:	"critical",
		},
		{
			gaps:		[]DocumentGap{{Severity: "high"}},
			coverageScore:	70.0,
			expected:	"high",
		},
		{
			gaps:		[]DocumentGap{},
			coverageScore:	50.0,
			expected:	"high",
		},
		{
			gaps:		[]DocumentGap{{Severity: "medium"}},
			coverageScore:	75.0,
			expected:	"medium",
		},
		{
			gaps:		[]DocumentGap{},
			coverageScore:	90.0,
			expected:	"low",
		},
	}

	for i, test := range tests {
		result := getPriorityLevel(test.gaps, test.coverageScore)
		if result != test.expected {
			t.Errorf("Test %d: getPriorityLevel() = %s, expected %s",
				i, result, test.expected)
		}
	}
}

func TestAnalyzeFragmentation(t *testing.T) {
	// Test with scattered files
	scatteredFiles := []string{
		"docs1/file1.md",
		"docs2/file2.md",
		"docs3/file3.md",
		"docs4/file4.md",
		"docs5/file5.md",
		"docs6/file6.md",	// 6 different directories
	}

	gaps := analyzeFragmentation(scatteredFiles)
	if len(gaps) == 0 {
		t.Error("Expected fragmentation gap for scattered files")
	}

	// Test with consolidated files
	consolidatedFiles := []string{
		"docs/file1.md",
		"docs/file2.md",
		"docs/file3.md",
	}

	gaps = analyzeFragmentation(consolidatedFiles)
	// Should not identify fragmentation issue
	fragmentationFound := false
	for _, gap := range gaps {
		if gap.Type == "fragmentation" {
			fragmentationFound = true
		}
	}
	if fragmentationFound {
		t.Error("Did not expect fragmentation gap for consolidated files")
	}
}

func TestAnalyzeAPIDocumentation(t *testing.T) {
	// Create temporary test directory with API code
	tmpDir, err := ioutil.TempDir("", "api_analysis_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	// Create API code file
	apiFile := filepath.Join(tmpDir, "api.go")
	if err := ioutil.WriteFile(apiFile, []byte("package api\n// API code"), 0644); err != nil {
		t.Fatalf("Failed to create API file: %v", err)
	}

	// Analyze API documentation (without creating API docs)
	gaps := analyzeAPIDocumentation(tmpDir)

	// Should identify missing API documentation
	foundAPIGap := false
	for _, gap := range gaps {
		if gap.Type == "missing_api_docs" {
			foundAPIGap = true
		}
	}
	if !foundAPIGap {
		t.Error("Expected to find missing API documentation gap")
	}
}

func TestCompleteWorkflow(t *testing.T) {
	// Create temporary test directory
	tmpDir, err := ioutil.TempDir("", "complete_workflow_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	// Create minimal documentation structure
	testFiles := []string{
		"README.md",
		"docs/basic.md",
	}

	for _, file := range testFiles {
		fullPath := filepath.Join(tmpDir, file)
		dir := filepath.Dir(fullPath)
		if err := os.MkdirAll(dir, 0755); err != nil {
			t.Fatalf("Failed to create dir %s: %v", dir, err)
		}
		if err := ioutil.WriteFile(fullPath, []byte("test content"), 0644); err != nil {
			t.Fatalf("Failed to create file %s: %v", fullPath, err)
		}
	}

	// Run complete analysis
	report, err := analyzeGaps(tmpDir)
	if err != nil {
		t.Fatalf("Failed to analyze gaps: %v", err)
	}

	// Test JSON output
	data, err := json.Marshal(report)
	if err != nil {
		t.Fatalf("Failed to marshal JSON: %v", err)
	}

	// Test JSON decoding
	var decoded GapAnalysisReport
	if err := json.Unmarshal(data, &decoded); err != nil {
		t.Fatalf("Failed to unmarshal JSON: %v", err)
	}

	// Basic validation
	if decoded.ProjectName == "" {
		t.Error("Expected project name to be set")
	}
	if time.Since(decoded.GeneratedAt) > time.Minute {
		t.Error("Report timestamp seems incorrect")
	}
	if decoded.TotalFilesScanned != len(testFiles) {
		t.Errorf("Expected %d files scanned, got %d",
			len(testFiles), decoded.TotalFilesScanned)
	}
}
