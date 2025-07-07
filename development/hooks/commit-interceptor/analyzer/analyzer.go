package analyzer

import (
	"fmt"
	"regexp"
	"strings"

	commitinterceptor "github.com/gerivdb/email-sender-1/development/hooks/commit-interceptor" // Corrected import for parent package
)

// AnalysisResult holds the outcome of a commit analysis by this package.
type AnalysisResult struct {
	ChangeType string
	Confidence float64
	Impact     string
	// Note: SuggestedBranch is NOT part of this analyzer's direct result.
}

// CommitAnalyzer - Analyseur de commits pour la classification traditionnelle

type CommitAnalyzer struct {
	config *commitinterceptor.Config // Corrected type
}

// NewCommitAnalyzer - Crée un nouvel analyseur de commits

func NewCommitAnalyzer(config *commitinterceptor.Config) *CommitAnalyzer { // Corrected type
	return &CommitAnalyzer{config: config}
}

// AnalyzeCommit - Analyse un commit et retourne une classification

func (a *CommitAnalyzer) AnalyzeCommit(commitData *commitinterceptor.CommitData) (*AnalysisResult, error) { // Corrected type
	if commitData == nil {
		return nil, fmt.Errorf("commit data is nil")
	}

	changeType, confidence := a.classifyByMessage(commitData.Message)
	impact := a.assessImpact(commitData.Files)

	return &AnalysisResult{
		ChangeType: changeType,
		Confidence: confidence,
		Impact:     impact,
	}, nil
}

// classifyByMessage - Classifie le commit en fonction du message

func (a *CommitAnalyzer) classifyByMessage(message string) (string, float64) {
	lowerMessage := strings.ToLower(message)

	// Regex pour les types de commits conventionnels
	patterns := map[string]string{
		"feature": `^(feat|feature)(\(.+\))?:`,
		"fix":     `^(fix|bugfix)(\(.+\))?:`,
		"docs":    `^docs(\(.+\))?:`,
		"refactor": `^refactor(\(.+\))?:`,
		"test":    `^test(\(.+\))?:`,
		"chore":   `^chore(\(.+\))?:`,
		"style":   `^style(\(.+\))?:`,
	}

	for typeName, pattern := range patterns {
		if matched, _ := regexp.MatchString(pattern, lowerMessage); matched {
			return typeName, 0.9 // Confiance élevée pour les messages conventionnels
		}
	}

	// Classification par mots-clés si aucun format conventionnel n'est trouvé
	keywords := map[string][]string{
		"feature": {"add", "implement", "introduce"},
		"fix":     {"fix", "resolve", "correct", "bug"},
		"docs":    {"docs", "documentation", "readme"},
		"refactor": {"refactor", "restructure", "cleanup"},
	}

	for typeName, keys := range keywords {
		for _, key := range keys {
			if strings.Contains(lowerMessage, key) {
				return typeName, 0.6 // Confiance modérée pour les mots-clés
			}
		}
	}

	return "chore", 0.3 // Type par défaut pour les messages non classifiables
}

// assessImpact - Évalue l'impact des changements en fonction des fichiers modifiés

func (a *CommitAnalyzer) assessImpact(files []string) string {
	if len(files) > 10 {
		return "high"
	}

	for _, file := range files {
		if a.isCriticalFile(file) {
			return "high"
		}
	}

	if len(files) > 3 {
		return "medium"
	}

	return "low"
}

// isCriticalFile - Vérifie si un fichier est critique

func (a *CommitAnalyzer) isCriticalFile(filename string) bool {
	criticalPatterns := a.config.Routing.CriticalFilePatterns
	lowerFile := strings.ToLower(filename)

	for _, pattern := range criticalPatterns {
		if strings.Contains(lowerFile, pattern) {
			return true
		}
	}

	return false
}
