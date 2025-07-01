package scripts

import (
	"encoding/json"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func TestGenerateNeedsSurvey(t *testing.T) {
	// Create temporary test directory
	tmpDir, err := ioutil.TempDir("", "needs_survey_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	// Create test project structure
	testFiles := []string{
		"main.go",
		"api/handler.go",
		"docs/README.md",
		".github/workflows/ci.yml",
		"docker-compose.yml",
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

	// Generate needs survey
	report, err := generateNeedsSurvey(tmpDir)
	if err != nil {
		t.Fatalf("Failed to generate needs survey: %v", err)
	}

	// Validate basic structure
	if report.ProjectName == "" {
		t.Error("Expected project name to be set")
	}

	if len(report.UserRoles) == 0 {
		t.Error("Expected user roles to be defined")
	}

	if len(report.DocumentationNeeds) == 0 {
		t.Error("Expected documentation needs to be identified")
	}

	if len(report.PriorityMatrix) == 0 {
		t.Error("Expected priority matrix to be generated")
	}

	if len(report.Recommendations) == 0 {
		t.Error("Expected recommendations to be generated")
	}

	// Check for expected user roles
	foundDeveloper := false
	foundUser := false
	foundAPIConsumer := false

	for _, role := range report.UserRoles {
		switch role.Name {
		case "developer":
			foundDeveloper = true
		case "user":
			foundUser = true
		case "api_consumer":
			foundAPIConsumer = true
		}
	}

	if !foundDeveloper {
		t.Error("Expected to find 'developer' role")
	}
	if !foundUser {
		t.Error("Expected to find 'user' role")
	}
	if !foundAPIConsumer {
		t.Error("Expected to find 'api_consumer' role for API project")
	}

	// Validate timestamp
	if time.Since(report.GeneratedAt) > time.Minute {
		t.Error("Report timestamp seems incorrect")
	}
}

func TestAnalyzeProjectType(t *testing.T) {
	// Create temporary test directory
	tmpDir, err := ioutil.TempDir("", "project_type_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	// Create API project structure
	apiFiles := []string{
		"api/handler.go",
		"main.go",
		"docker-compose.yml",
		".github/workflows/deploy.yml",
	}

	for _, file := range apiFiles {
		fullPath := filepath.Join(tmpDir, file)
		dir := filepath.Dir(fullPath)
		if err := os.MkdirAll(dir, 0755); err != nil {
			t.Fatalf("Failed to create dir %s: %v", dir, err)
		}
		if err := ioutil.WriteFile(fullPath, []byte("test content"), 0644); err != nil {
			t.Fatalf("Failed to create file %s: %v", fullPath, err)
		}
	}

	features := analyzeProjectType(tmpDir)

	// Should detect API project
	if !features["api"] {
		t.Error("Expected to detect API project")
	}

	// Should detect CLI project (main.go)
	if !features["cli"] {
		t.Error("Expected to detect CLI project")
	}

	// Should detect Docker
	if !features["docker"] {
		t.Error("Expected to detect Docker usage")
	}

	// Should detect CI/CD
	if !features["cicd"] {
		t.Error("Expected to detect CI/CD usage")
	}
}

func TestDefineUserRoles(t *testing.T) {
	// Test with API project
	apiProject := map[string]bool{
		"api":		true,
		"cicd":		true,
		"docker":	true,
	}

	roles := defineUserRoles(apiProject)

	// Should have basic roles
	roleNames := make(map[string]bool)
	for _, role := range roles {
		roleNames[role.Name] = true
	}

	expectedRoles := []string{"developer", "user", "contributor", "api_consumer", "devops", "project_manager"}
	for _, expected := range expectedRoles {
		if !roleNames[expected] {
			t.Errorf("Expected role '%s' not found", expected)
		}
	}

	// Test with simple project
	simpleProject := map[string]bool{}
	simpleRoles := defineUserRoles(simpleProject)

	// Should still have basic roles
	if len(simpleRoles) < 3 {
		t.Error("Expected at least basic roles for simple project")
	}
}

func TestGenerateDocumentationNeeds(t *testing.T) {
	// Test with API project
	apiProject := map[string]bool{
		"api":		true,
		"testing":	true,
		"cicd":		true,
	}

	needs := generateDocumentationNeeds(apiProject)

	if len(needs) == 0 {
		t.Error("Expected documentation needs to be generated")
	}

	// Check for API-specific needs
	foundAPIReference := false
	foundAPIAuth := false

	for _, need := range needs {
		if need.Category == "api" && need.Type == "reference" {
			foundAPIReference = true
		}
		if need.Category == "api" && need.Type == "authentication" {
			foundAPIAuth = true
		}
	}

	if !foundAPIReference {
		t.Error("Expected API reference documentation need for API project")
	}
	if !foundAPIAuth {
		t.Error("Expected API authentication documentation need for API project")
	}

	// Check priority levels
	foundCritical := false
	for _, need := range needs {
		if need.Priority == "critical" {
			foundCritical = true
			break
		}
	}

	if !foundCritical {
		t.Error("Expected at least one critical priority need")
	}
}

func TestCreatePriorityMatrix(t *testing.T) {
	testNeeds := []DocumentationNeed{
		{
			Category:	"getting_started",
			Type:		"installation",
			Priority:	"critical",
			UserRoles:	[]string{"developer", "user", "contributor"},
		},
		{
			Category:	"api",
			Type:		"reference",
			Priority:	"high",
			UserRoles:	[]string{"developer", "api_consumer"},
		},
	}

	matrix := createPriorityMatrix(testNeeds)

	if len(matrix) != len(testNeeds) {
		t.Errorf("Expected %d items in priority matrix, got %d", len(testNeeds), len(matrix))
	}

	// Check specific items
	installKey := "getting_started_installation"
	if item, exists := matrix[installKey]; exists {
		if item.Impact != "high" {
			t.Errorf("Expected high impact for critical item with 3+ user roles")
		}
	} else {
		t.Errorf("Expected priority matrix item for %s", installKey)
	}
}

func TestGenerateRecommendations(t *testing.T) {
	testRoles := []UserRole{
		{Name: "developer", Priority: "high"},
		{Name: "api_consumer", Priority: "high"},
		{Name: "devops", Priority: "medium"},
	}

	testNeeds := []DocumentationNeed{
		{Priority: "critical"},
		{Priority: "critical"},
		{Priority: "high"},
		{Priority: "high"},
		{Priority: "high"},
		{Priority: "high"},
	}

	recommendations := generateRecommendations(testRoles, testNeeds)

	if len(recommendations) == 0 {
		t.Error("Expected recommendations to be generated")
	}

	// Should mention critical needs
	foundCriticalMention := false
	for _, rec := range recommendations {
		if strings.Contains(strings.ToLower(rec), "critical") {
			foundCriticalMention = true
			break
		}
	}

	if !foundCriticalMention {
		t.Error("Expected recommendation to mention critical needs")
	}

	// Should have API-specific recommendation
	foundAPIMention := false
	for _, rec := range recommendations {
		if strings.Contains(strings.ToLower(rec), "api") {
			foundAPIMention = true
			break
		}
	}

	if !foundAPIMention {
		t.Error("Expected API-specific recommendation for project with API consumer role")
	}
}

func TestShouldSkipPathNeedsVerision(t *testing.T) {
	tests := []struct {
		path		string
		expected	bool
	}{
		{"docs/api.md", false},
		{"node_modules/package.json", true},
		{".git/config", true},
		{"vendor/deps", true},
		{"build/output", true},
		{"README.md", false},
	}

	for _, test := range tests {
		result := shouldSkipPath(test.path)
		if result != test.expected {
			t.Errorf("shouldSkipPath(%s) = %v, expected %v",
				test.path, result, test.expected)
		}
	}
}

func TestJSONOutput(t *testing.T) {
	// Create a minimal test report
	report := &NeedsSurveyReport{
		GeneratedAt:		time.Now(),
		ProjectName:		"test-project",
		UserRoles:		[]UserRole{{Name: "test", Description: "test role"}},
		DocumentationNeeds:	[]DocumentationNeed{{Category: "test", Type: "test", Priority: "medium"}},
		PriorityMatrix:		map[string]PriorityItem{"test": {Description: "test item"}},
		Recommendations:	[]string{"test recommendation"},
		Summary:		"test summary",
	}

	// Test JSON encoding
	data, err := json.Marshal(report)
	if err != nil {
		t.Fatalf("Failed to marshal JSON: %v", err)
	}

	// Test JSON decoding
	var decoded NeedsSurveyReport
	if err := json.Unmarshal(data, &decoded); err != nil {
		t.Fatalf("Failed to unmarshal JSON: %v", err)
	}

	// Validate key fields
	if decoded.ProjectName != report.ProjectName {
		t.Errorf("ProjectName mismatch: got %s, expected %s",
			decoded.ProjectName, report.ProjectName)
	}
	if len(decoded.UserRoles) != len(report.UserRoles) {
		t.Errorf("UserRoles length mismatch: got %d, expected %d",
			len(decoded.UserRoles), len(report.UserRoles))
	}
	if decoded.Summary != report.Summary {
		t.Errorf("Summary mismatch: got %s, expected %s",
			decoded.Summary, report.Summary)
	}
}

func TestCompleteNeedsSurveyWorkflow(t *testing.T) {
	// Create temporary test directory
	tmpDir, err := ioutil.TempDir("", "complete_needs_test")
	if err != nil {
		t.Fatalf("Failed to create temp dir: %v", err)
	}
	defer os.RemoveAll(tmpDir)

	// Create complex project structure
	testFiles := []string{
		"main.go",
		"api/v1/handler.go",
		"api/v1/auth.go",
		"cmd/cli/main.go",
		"internal/service/user.go",
		"tests/integration_test.go",
		"docker-compose.yml",
		"Dockerfile",
		".github/workflows/ci.yml",
		"config/app.yaml",
		"docs/README.md",
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

	// Run complete workflow
	report, err := generateNeedsSurvey(tmpDir)
	if err != nil {
		t.Fatalf("Failed to generate needs survey: %v", err)
	}

	// Should detect multiple project features
	if len(report.UserRoles) < 5 {
		t.Errorf("Expected multiple user roles for complex project, got %d", len(report.UserRoles))
	}

	if len(report.DocumentationNeeds) < 8 {
		t.Errorf("Expected multiple documentation needs, got %d", len(report.DocumentationNeeds))
	}

	// Test JSON output
	data, err := json.Marshal(report)
	if err != nil {
		t.Fatalf("Failed to marshal JSON: %v", err)
	}

	// Validate JSON structure
	var decoded NeedsSurveyReport
	if err := json.Unmarshal(data, &decoded); err != nil {
		t.Fatalf("Failed to unmarshal JSON: %v", err)
	}

	// Basic validation
	if time.Since(decoded.GeneratedAt) > time.Minute {
		t.Error("Report timestamp seems incorrect")
	}
}
