// development/hooks/commit-interceptor/impact_detection_test.go
package commitinterceptor

import (
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

// TestCommitAnalyzer_DetailedImpactDetection - NIVEAU 6: Test Cases Impact détaillés
// Implémentation complète de la Tâche 1.1.2.6 pour atteindre 100% de tests réussis
func TestCommitAnalyzer_DetailedImpactDetection(t *testing.T) {

	impactTestCases := []struct {
		name		string
		files		[]string
		message		string
		expectedImpact	string
		reason		string
	}{
		// Test Case 1: Impact faible - Documentation seule
		{
			name:		"Low impact - single documentation",
			files:		[]string{"README.md"},
			message:	"docs: update installation instructions",
			expectedImpact:	"low",
			reason:		"Single non-critical documentation file",
		},
		// Test Case 2: Impact faible - Fichier unique non-critique
		{
			name:		"Low impact - single utility file",
			files:		[]string{"utils/helper.go"},
			message:	"refactor: clean up utility functions",
			expectedImpact:	"low",
			reason:		"Single non-critical utility file",
		},

		// Test Case 3: Impact moyen - Plusieurs fichiers sources
		{
			name:		"Medium impact - multiple source files",
			files:		[]string{"auth.go", "user.go", "handler.go"},
			message:	"feat: add user management",
			expectedImpact:	"medium",
			reason:		"3-5 source files modified",
		},
		// Test Case 4: Impact moyen - Fichier critique main.go avec feature
		{
			name:		"Medium impact - critical file main.go with feature",
			files:		[]string{"main.go"},
			message:	"feat: restructure application entry point",
			expectedImpact:	"medium",
			reason:		"Critical file main.go modified with feature (escalated from low)",
		},
		// Test Case 5: Impact moyen - Dockerfile seul avec modification autre
		{
			name:		"Medium impact - Dockerfile with chore",
			files:		[]string{"Dockerfile"},
			message:	"chore: update base image",
			expectedImpact:	"medium",
			reason:		"Critical infrastructure file modified",
		},

		// Test Case 6: Impact élevé - Nombreux fichiers (6+)
		{
			name:		"High impact - many files",
			files:		[]string{"a.go", "b.go", "c.go", "d.go", "e.go", "f.go", "g.go"},
			message:	"refactor: major architectural changes",
			expectedImpact:	"high",
			reason:		"6+ files modified",
		},
		// Test Case 7: Impact élevé - Message critique
		{
			name:		"High impact - critical message",
			files:		[]string{"auth.go"},
			message:	"fix: critical security vulnerability in authentication",
			expectedImpact:	"high",
			reason:		"Message contains 'critical' keyword",
		},
		// Test Case 8: Impact élevé - Message urgent
		{
			name:		"High impact - urgent message",
			files:		[]string{"api.go"},
			message:	"hotfix: urgent fix for API rate limiting",
			expectedImpact:	"high",
			reason:		"Message contains 'urgent' keyword",
		},
		// Test Case 9: Impact élevé - Fix sur fichier critique
		{
			name:		"High impact - fix on critical file",
			files:		[]string{"main.go"},
			message:	"fix: startup crash on invalid config",
			expectedImpact:	"high",
			reason:		"Fix on critical file main.go always high impact",
		},
		// Test Case 10: Impact élevé - Refactor sur fichier critique
		{
			name:		"High impact - refactor on critical file",
			files:		[]string{"go.mod"},
			message:	"refactor: update dependency management",
			expectedImpact:	"high",
			reason:		"Refactor on critical file go.mod always high impact",
		},
		// Test Case 11: Impact élevé - Fichiers d'infrastructure multiples
		{
			name:		"High impact - infrastructure files",
			files:		[]string{"Dockerfile", "go.mod", ".github/workflows/ci.yml"},
			message:	"chore: update infrastructure configuration",
			expectedImpact:	"high",
			reason:		"Multiple infrastructure/config files",
		},
	}
	for _, tc := range impactTestCases {
		t.Run(tc.name, func(t *testing.T) {
			// Créer une nouvelle instance d'analyzer pour chaque test pour éviter les effets de bord
			analyzer := NewCommitAnalyzer(getDefaultConfig())

			// Analyse complète du commit
			analysis, err := analyzer.AnalyzeCommit(&CommitData{
				Hash:		"abc123def456",	// Hash requis pour validation
				Message:	tc.message,
				Author:		"test-author <test@example.com>",	// Author requis pour validation
				Files:		tc.files,
			})

			// Validations de base
			require.NoError(t, err, "Analysis should not fail")
			require.NotNil(t, analysis, "Analysis should not be nil")

			// Validation principale: niveau d'impact attendu
			assert.Equal(t, tc.expectedImpact, analysis.Impact,
				"Expected impact %s but got %s. Reason: %s",
				tc.expectedImpact, analysis.Impact, tc.reason)

			// Validations des métadonnées d'analyse
			assert.NotEmpty(t, analysis.ChangeType, "ChangeType should be determined")
			assert.Greater(t, analysis.Confidence, 0.0, "Confidence should be > 0")
			assert.LessOrEqual(t, analysis.Confidence, 1.0, "Confidence should be <= 1")
			assert.NotEmpty(t, analysis.Priority, "Priority should be set")
			assert.NotEmpty(t, analysis.SuggestedBranch, "SuggestedBranch should be generated")

			// Validations spécifiques par type d'impact
			switch tc.expectedImpact {
			case "low":
				// Impact faible: généralement moins de 3 fichiers non-critiques
				if len(tc.files) <= 2 {
					assert.LessOrEqual(t, len(tc.files), 2, "Low impact should have <= 2 files")
				}
			case "medium":
				// Impact moyen: 3-5 fichiers OU 1 fichier critique
				hasCritical := false
				for _, file := range tc.files {
					if analyzer.isCriticalFile(file) {
						hasCritical = true
						break
					}
				}
				if !hasCritical {
					assert.GreaterOrEqual(t, len(tc.files), 3, "Medium impact without critical files should have >= 3 files")
					assert.LessOrEqual(t, len(tc.files), 5, "Medium impact should have <= 5 files")
				}
			case "high":
				// Impact élevé: 6+ fichiers, fichiers critiques, ou mots-clés
				hasValidReason := false

				// Vérifier 6+ fichiers
				if len(tc.files) >= 6 {
					hasValidReason = true
				}

				// Vérifier mots-clés critiques
				if strings.Contains(strings.ToLower(tc.message), "critical") ||
					strings.Contains(strings.ToLower(tc.message), "urgent") {
					hasValidReason = true
				}	// Vérifier fichiers critiques avec fix/refactor
				criticalFileCount := 0
				for _, file := range tc.files {
					if analyzer.isCriticalFile(file) {
						criticalFileCount++
						if strings.Contains(tc.message, "fix:") ||
							strings.Contains(tc.message, "hotfix:") ||
							strings.Contains(tc.message, "refactor:") {
							hasValidReason = true
						}
					}
				}

				// Vérifier multiples fichiers critiques (infrastructure)
				if criticalFileCount >= 2 {
					hasValidReason = true
				}

				assert.True(t, hasValidReason, "High impact should have valid reason: %s", tc.reason)
			}
		})
	}
}

// TestCommitAnalyzer_ComprehensiveCriticalFiles - NIVEAU 7: Validation exhaustive des fichiers critiques
func TestCommitAnalyzer_ComprehensiveCriticalFiles(t *testing.T) {
	analyzer := NewCommitAnalyzer(getDefaultConfig())

	criticalFiles := map[string]bool{
		// Fichiers d'entrée principaux
		"main.go":	true,
		"index.js":	true,
		"app.js":	true,
		"server.js":	true,

		// Fichiers de configuration Docker
		"Dockerfile":		true,
		"docker-compose.yml":	true,
		"docker-compose.yaml":	true,

		// Fichiers de gestion des dépendances
		"go.mod":		true,
		"go.sum":		true,	// Ajout pour Go
		"package.json":		true,
		"package-lock.json":	true,	// Ajout pour npm
		"requirements.txt":	true,
		"Pipfile":		true,	// Ajout pour Python

		// Fichiers de configuration
		"config.yml":		true,
		"config.yaml":		true,
		"config.json":		true,
		"config.toml":		true,	// Ajout
		"settings.json":	true,	// Ajout

		// Workflows CI/CD
		".github/workflows/ci.yml":	true,
		".github/workflows/cd.yml":	true,
		".github/workflows/test.yml":	true,
		".gitlab-ci.yml":		true,	// Ajout GitLab

		// Fichiers de build
		"Makefile":	true,
		"makefile":	true,	// Variante lowercase
		"build.gradle":	true,	// Ajout Java
		"pom.xml":	true,	// Ajout Maven

		// Fichiers NON critiques
		"utils.go":		false,
		"helper.go":		false,
		"README.md":		false,
		"CHANGELOG.md":		false,
		"test_helper.go":	false,
		"example.txt":		false,
		"docs/guide.md":	false,
		"internal/utils.go":	false,
		"pkg/helper/util.go":	false,
		"vendor/library.go":	false,	// Dépendances
		"node_modules/lib.js":	false,	// Dépendances npm
	}

	for filename, expected := range criticalFiles {
		t.Run(filename, func(t *testing.T) {
			result := analyzer.isCriticalFile(filename)
			assert.Equal(t, expected, result,
				"File %s should be critical=%v but got %v",
				filename, expected, result)
		})
	}
}

// TestCommitAnalyzer_AdvancedImpactEscalation - NIVEAU 8: Tests d'escalade d'impact
func TestCommitAnalyzer_AdvancedImpactEscalation(t *testing.T) {
	analyzer := NewCommitAnalyzer(getDefaultConfig())

	escalationTestCases := []struct {
		name		string
		files		[]string
		changeType	string
		message		string
		baseImpact	string
		expectedImpact	string
		escalationRule	string
	}{
		{
			name:		"Feature on critical file: low -> medium",
			files:		[]string{"main.go"},
			changeType:	"feature",
			message:	"feat: add new startup option",
			baseImpact:	"low",
			expectedImpact:	"medium",
			escalationRule:	"Critical file with feature escalates by one level",
		},
		{
			name:		"Feature on multiple files including critical: medium -> high",
			files:		[]string{"auth.go", "user.go", "main.go", "config.go"},
			changeType:	"feature",
			message:	"feat: comprehensive auth refactor",
			baseImpact:	"medium",
			expectedImpact:	"high",
			escalationRule:	"Critical file with feature in multi-file change escalates",
		},
		{
			name:		"Fix on critical file: any -> high",
			files:		[]string{"main.go"},
			changeType:	"fix",
			message:	"fix: resolve startup crash",
			baseImpact:	"low",
			expectedImpact:	"high",
			escalationRule:	"Fix on critical file always high impact",
		},
		{
			name:		"Refactor on critical file: any -> high",
			files:		[]string{"go.mod"},
			changeType:	"refactor",
			message:	"refactor: restructure dependencies",
			baseImpact:	"low",
			expectedImpact:	"high",
			escalationRule:	"Refactor on critical file always high impact",
		},
		{
			name:		"Non-critical change type on critical file: low -> medium",
			files:		[]string{"Dockerfile"},
			changeType:	"chore",
			message:	"chore: update base image version",
			baseImpact:	"low",
			expectedImpact:	"medium",
			escalationRule:	"Other types on critical file escalate to at least medium",
		},
	}
	for _, tc := range escalationTestCases {
		t.Run(tc.name, func(t *testing.T) {
			analysis, err := analyzer.AnalyzeCommit(&CommitData{
				Hash:		"test123abc456",	// Hash requis pour validation
				Message:	tc.message,
				Author:		"test-user <test@example.com>",	// Author requis pour validation
				Files:		tc.files,
			})

			require.NoError(t, err)
			assert.Equal(t, tc.expectedImpact, analysis.Impact,
				"Escalation failed: %s. Expected %s but got %s",
				tc.escalationRule, tc.expectedImpact, analysis.Impact)

			// Vérifier que l'analyse a bien identifié un fichier critique
			hasCritical := false
			for _, file := range tc.files {
				if analyzer.isCriticalFile(file) {
					hasCritical = true
					break
				}
			}
			assert.True(t, hasCritical, "Test case should contain at least one critical file")
		})
	}
}

// TestCommitAnalyzer_CriticalKeywordImpact - Tests pour mots-clés d'impact
func TestCommitAnalyzer_CriticalKeywordImpact(t *testing.T) {
	analyzer := NewCommitAnalyzer(getDefaultConfig())

	keywordTestCases := []struct {
		name		string
		message		string
		files		[]string
		expectedImpact	string
		keyword		string
	}{
		{
			name:		"Critical keyword forces high impact",
			message:	"fix: critical vulnerability in auth system",
			files:		[]string{"auth.go"},
			expectedImpact:	"high",
			keyword:	"critical",
		},
		{
			name:		"Urgent keyword forces high impact",
			message:	"hotfix: urgent memory leak fix",
			files:		[]string{"memory.go"},
			expectedImpact:	"high",
			keyword:	"urgent",
		},
		{
			name:		"Critical in description forces high impact",
			message:	"fix: resolve issue that causes critical system failure",
			files:		[]string{"system.go"},
			expectedImpact:	"high",
			keyword:	"critical",
		},
		{
			name:		"Urgent hotfix forces high impact regardless of files",
			message:	"hotfix: urgent production issue",
			files:		[]string{"utils.go"},	// Non-critical file
			expectedImpact:	"high",
			keyword:	"urgent",
		},
	}
	for _, tc := range keywordTestCases {
		t.Run(tc.name, func(t *testing.T) {
			analysis, err := analyzer.AnalyzeCommit(&CommitData{
				Hash:		"keyword789test",	// Hash requis pour validation
				Message:	tc.message,
				Author:		"test-user <test@example.com>",	// Author requis pour validation
				Files:		tc.files,
			})

			require.NoError(t, err)
			assert.Equal(t, tc.expectedImpact, analysis.Impact,
				"Keyword '%s' should force impact to %s but got %s",
				tc.keyword, tc.expectedImpact, analysis.Impact)

			// Vérifier que le mot-clé est bien présent dans le message
			assert.Contains(t, strings.ToLower(analysis.CommitData.Message), tc.keyword,
				"Message should contain the keyword '%s'", tc.keyword)
		})
	}
}
