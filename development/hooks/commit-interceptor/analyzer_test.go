// development/hooks/commit-interceptor/analyzer_test.go
package main

import (
    "strings"
    "testing"
    "time"
)

func TestCommitAnalyzer_AnalyzeCommit(t *testing.T) {
    config := getDefaultConfig()
    analyzer := NewCommitAnalyzer(config)

    tests := []struct {
        name           string
        commitData     *CommitData
        expectedType   string
        expectedImpact string
    }{
        {
            name: "Feature commit",
            commitData: &CommitData{
                Hash:      "abc123",
                Message:   "feat: add user authentication system",
                Author:    "Test User",
                Timestamp: time.Now(),
                Files:     []string{"auth.go", "user.go", "main.go"},
                Branch:    "main",
            },
            expectedType:   "feature",
            expectedImpact: "medium",
        },
        {
            name: "Bug fix commit",
            commitData: &CommitData{
                Hash:      "def456",
                Message:   "fix: resolve critical authentication bug",
                Author:    "Test User",
                Timestamp: time.Now(),
                Files:     []string{"auth.go"},
                Branch:    "main",
            },
            expectedType:   "fix",
            expectedImpact: "medium",
        },
        {
            name: "Documentation commit",
            commitData: &CommitData{
                Hash:      "ghi789",
                Message:   "docs: update README with installation instructions",
                Author:    "Test User",
                Timestamp: time.Now(),
                Files:     []string{"README.md"},
                Branch:    "main",
            },
            expectedType:   "docs",
            expectedImpact: "low",
        },
        {
            name: "Large refactor",
            commitData: &CommitData{
                Hash:      "jkl012",
                Message:   "refactor: restructure authentication module",
                Author:    "Test User",
                Timestamp: time.Now(),
                Files:     []string{"auth.go", "user.go", "token.go", "middleware.go", "handler.go", "service.go", "repository.go", "model.go", "config.go", "utils.go", "test.go"},
                Branch:    "main",
            },
            expectedType:   "refactor",
            expectedImpact: "high",
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            analysis, err := analyzer.AnalyzeCommit(tt.commitData)
            if err != nil {
                t.Errorf("AnalyzeCommit() error = %v", err)
                return
            }

            if analysis.ChangeType != tt.expectedType {
                t.Errorf("Expected change type %s, got %s", tt.expectedType, analysis.ChangeType)
            }

            if analysis.Impact != tt.expectedImpact {
                t.Errorf("Expected impact %s, got %s", tt.expectedImpact, analysis.Impact)
            }

            // Check that confidence is within reasonable range
            if analysis.Confidence < 0.0 || analysis.Confidence > 1.0 {
                t.Errorf("Confidence should be between 0 and 1, got %f", analysis.Confidence)
            }

            // Check that suggested branch is not empty
            if analysis.SuggestedBranch == "" {
                t.Error("Suggested branch should not be empty")
            }
        })
    }
}

func TestCommitAnalyzer_analyzeMessage(t *testing.T) {
    config := getDefaultConfig()
    analyzer := NewCommitAnalyzer(config)

    tests := []struct {
        message      string
        expectedType string
    }{
        {"feat: add new feature", "feature"},
        {"fix: resolve bug", "fix"},
        {"docs: update documentation", "docs"},
        {"refactor: clean up code", "refactor"},
        {"style: fix formatting", "style"},
        {"test: add unit tests", "test"},
        {"chore: update dependencies", "chore"},
        {"implement new authentication", "feature"},
        {"fix critical bug in auth", "fix"},
        {"random commit message", "chore"}, // default
    }

    for _, tt := range tests {
        t.Run(tt.message, func(t *testing.T) {
            analysis := &CommitAnalysis{
                CommitData: &CommitData{
                    Message: tt.message,
                },
            }

            analyzer.analyzeMessage(analysis)

            if analysis.ChangeType != tt.expectedType {
                t.Errorf("Expected change type %s for message '%s', got %s", 
                    tt.expectedType, tt.message, analysis.ChangeType)
            }
        })
    }
}

func TestCommitAnalyzer_analyzeFiles(t *testing.T) {
    config := getDefaultConfig()
    analyzer := NewCommitAnalyzer(config)

    tests := []struct {
        name         string
        files        []string
        expectedTypes []string
    }{
        {
            name:          "Go files",
            files:         []string{"main.go", "auth.go", "user.go"},
            expectedTypes: []string{".go"},
        },
        {
            name:          "Documentation files",
            files:         []string{"README.md", "docs.md"},
            expectedTypes: []string{".md"},
        },
        {
            name:          "Mixed files",
            files:         []string{"main.go", "README.md", "config.json"},
            expectedTypes: []string{".go", ".md", ".json"},
        },
        {
            name:          "Config files",
            files:         []string{"Dockerfile", "Makefile"},
            expectedTypes: []string{"no-ext"},
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            analysis := &CommitAnalysis{
                CommitData: &CommitData{
                    Files: tt.files,
                },
            }

            analyzer.analyzeFiles(analysis)

            // Check that all expected types are present
            for _, expectedType := range tt.expectedTypes {
                found := false
                for _, actualType := range analysis.FileTypes {
                    if actualType == expectedType {
                        found = true
                        break
                    }
                }
                if !found {
                    t.Errorf("Expected file type %s not found in %v", expectedType, analysis.FileTypes)
                }
            }
        })
    }
}

func TestCommitAnalyzer_analyzeImpact(t *testing.T) {
    config := getDefaultConfig()
    analyzer := NewCommitAnalyzer(config)

    tests := []struct {
        name           string
        files          []string
        changeType     string
        message        string
        expectedImpact string
    }{
        {
            name:           "Low impact - single file docs",
            files:          []string{"README.md"},
            changeType:     "docs",
            message:        "docs: update readme",
            expectedImpact: "low",
        },
        {
            name:           "Medium impact - multiple files",
            files:          []string{"auth.go", "user.go", "main.go", "config.go"},
            changeType:     "feature",
            message:        "feat: add authentication",
            expectedImpact: "medium",
        },
        {
            name:           "High impact - many files",
            files:          []string{"a.go", "b.go", "c.go", "d.go", "e.go", "f.go", "g.go", "h.go", "i.go", "j.go", "k.go"},
            changeType:     "refactor",
            message:        "refactor: major restructure",
            expectedImpact: "high",
        },
        {
            name:           "High impact - critical bug",
            files:          []string{"auth.go"},
            changeType:     "fix",
            message:        "fix: critical security vulnerability",
            expectedImpact: "high",
        },
        {
            name:           "Medium impact - critical file",
            files:          []string{"main.go"},
            changeType:     "feature",
            message:        "feat: update main entry point",
            expectedImpact: "medium",
        },
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            analysis := &CommitAnalysis{
                CommitData: &CommitData{
                    Files:   tt.files,
                    Message: tt.message,
                },
                ChangeType: tt.changeType,
            }

            analyzer.analyzeImpact(analysis)

            if analysis.Impact != tt.expectedImpact {
                t.Errorf("Expected impact %s, got %s", tt.expectedImpact, analysis.Impact)
            }
        })
    }
}

func TestCommitAnalyzer_isCriticalFile(t *testing.T) {
    config := getDefaultConfig()
    analyzer := NewCommitAnalyzer(config)

    tests := []struct {
        filename   string
        isCritical bool
    }{
        {"main.go", true},
        {"index.js", true},
        {"Dockerfile", true},
        {"go.mod", true},
        {"package.json", true},
        {"config.yml", true},
        {".github/workflows/ci.yml", true},
        {"Makefile", true},
        {"utils.go", false},
        {"README.md", false},
        {"test.go", false},
    }

    for _, tt := range tests {
        t.Run(tt.filename, func(t *testing.T) {
            result := analyzer.isCriticalFile(tt.filename)
            if result != tt.isCritical {
                t.Errorf("isCriticalFile(%s) = %v, expected %v", tt.filename, result, tt.isCritical)
            }
        })
    }
}

func TestCommitAnalyzer_suggestBranch(t *testing.T) {
    config := getDefaultConfig()
    analyzer := NewCommitAnalyzer(config)

    tests := []struct {
        changeType     string
        priority       string
        expectedPrefix string
    }{
        {"feature", "medium", "feature/"},
        {"fix", "critical", "hotfix/"},
        {"fix", "medium", "bugfix/"},
        {"refactor", "medium", "refactor/"},
        {"docs", "low", "develop"},
        {"style", "low", "develop"},
        {"chore", "low", "develop"},
    }

    for _, tt := range tests {
        t.Run(tt.changeType+"_"+tt.priority, func(t *testing.T) {
            analysis := &CommitAnalysis{
                CommitData: &CommitData{
                    Message:   "test commit message",
                    Timestamp: time.Now(),
                },
                ChangeType: tt.changeType,
                Priority:   tt.priority,
            }

            analyzer.suggestBranch(analysis)

            if tt.expectedPrefix == "develop" {
                if analysis.SuggestedBranch != "develop" {
                    t.Errorf("Expected branch 'develop', got '%s'", analysis.SuggestedBranch)
                }
            } else {
                if !strings.HasPrefix(analysis.SuggestedBranch, tt.expectedPrefix) {
                    t.Errorf("Expected branch to start with '%s', got '%s'", tt.expectedPrefix, analysis.SuggestedBranch)
                }
            }
        })
    }
}