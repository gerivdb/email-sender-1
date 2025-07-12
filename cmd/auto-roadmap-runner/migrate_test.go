// cmd/auto-roadmap-runner/migrate_test.go
package main

import (
	"testing"
)

func TestExtractTitle(t *testing.T) {
	content := "# Titre\n\nObjectifs..."
	title := extractTitle(content)
	if title != "" {
		t.Logf("Titre extrait: %s", title)
	} else {
		t.Errorf("Titre non extrait")
	}
}

func TestExtractObjectives(t *testing.T) {
	content := "# Titre\n\n## Objectifs\nMigration, Synchronisation"
	objectives := extractObjectives(content)
	if objectives != "" {
		t.Logf("Objectifs extraits: %s", objectives)
	} else {
		t.Errorf("Objectifs non extraits")
	}
}

func TestExtractSections(t *testing.T) {
	content := "# Titre\n\n## Section 1\nTexte\n## Section 2\nTexte"
	sections := extractSections(content)
	if len(sections) > 0 {
		t.Logf("Sections extraites: %v", sections)
	} else {
		t.Errorf("Sections non extraites")
	}
}
