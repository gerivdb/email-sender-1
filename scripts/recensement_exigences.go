// scripts/recensement_exigences.go
//
// Script Roo-Code : Recensement des exigences d’interopérabilité documentaire multi-agents
// Lit AGENTS.md, extrait interfaces, points d’extension, dépendances, et génère exigences-interoperabilite.yaml
//
// Usage : go run scripts/recensement_exigences.go
//
// Prévu pour extension future (tests, CI/CD, modularité)
package main

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"regexp"
	"strings"

	"gopkg.in/yaml.v3"
)

/*
Exigence représente une exigence d’interopérabilité extraite pour un agent.
Fusion des deux définitions précédentes.
*/
type Exigence struct {
	Dependencies []string `yaml:"dependencies,omitempty"`
	Agent        string   `yaml:"agent"`
	Description  string   `yaml:"description"`
	Interfaces   []string `yaml:"interfaces,omitempty"`
	Extensions   []string `yaml:"extensions,omitempty"`
	DependsOn    []string `yaml:"depends_on,omitempty"`
}

// ErrorManager centralise la gestion des erreurs du script.
type ErrorManager struct {
	errors []error
}

func (em *ErrorManager) Add(err error) {
	if err != nil {
		em.errors = append(em.errors, err)
	}
}

func (em *ErrorManager) HasErrors() bool {
	return len(em.errors) > 0
}

func (em *ErrorManager) Report() {
	for _, err := range em.errors {
		fmt.Fprintf(os.Stderr, "Erreur: %v\n", err)
	}
}

// Recensement regroupe toutes les exigences extraites.
type Recensement struct {
	Exigences []Exigence `yaml:"exigences"`
}

// parseAgentsMD lit AGENTS.md et extrait les exigences d’interopérabilité.
func parseAgentsMD(r io.Reader, em *ErrorManager) ([]Exigence, error) {
	scanner := bufio.NewScanner(r)
	var exigences []Exigence
	var current Exigence
	var inSection bool
	var sectionLines []string

	agentHeader := regexp.MustCompile(`^###\s+([A-Za-z0-9_]+)`)
	// keyValue := regexp.MustCompile(`^\s*-\s+\*\*(.+?)\*\*\s*:\s*(.+)$`)
	// listItem := regexp.MustCompile(`^\s*-\s+(.+)$`)

	for scanner.Scan() {
		line := scanner.Text()
		if matches := agentHeader.FindStringSubmatch(line); matches != nil {
			// Nouvelle section agent
			if inSection {
				parsed, err := parseAgentSection(sectionLines, current.Agent)
				if err != nil {
					em.Add(fmt.Errorf("Erreur parsing agent %s: %w", current.Agent, err))
				} else {
					exigences = append(exigences, parsed)
				}
			}
			current = Exigence{Agent: matches[1]}
			sectionLines = nil
			inSection = true
			continue
		}
		if inSection {
			sectionLines = append(sectionLines, line)
		}
	}
	// Dernière section
	if inSection {
		parsed, err := parseAgentSection(sectionLines, current.Agent)
		if err != nil {
			em.Add(fmt.Errorf("Erreur parsing agent %s: %w", current.Agent, err))
		} else {
			exigences = append(exigences, parsed)
		}
	}
	if err := scanner.Err(); err != nil {
		return exigences, err
	}
	return exigences, nil
}

// parseAgentSection extrait les exigences d’une section agent.
func parseAgentSection(lines []string, agentName string) (Exigence, error) {
	var ex Exigence
	ex.Agent = agentName
	var currentField string
	for _, line := range lines {
		line = strings.TrimSpace(line)
		if strings.HasPrefix(line, "- **Interfaces") || strings.HasPrefix(line, "- **Interfaces") {
			currentField = "interfaces"
			continue
		}
		if strings.HasPrefix(line, "- **Utilisation") {
			currentField = "description"
			continue
		}
		if strings.HasPrefix(line, "- **Entrée/Sortie") {
			currentField = "dependencies"
			continue
		}
		if strings.HasPrefix(line, "- **Points d’extension") || strings.HasPrefix(line, "- **Points d'extension") {
			currentField = "extensions"
			continue
		}
		if strings.HasPrefix(line, "- **Rôle") {
			currentField = "description"
			continue
		}
		if strings.HasPrefix(line, "- **") {
			currentField = ""
			continue
		}
		if strings.HasPrefix(line, "- ") && currentField != "" {
			val := strings.TrimPrefix(line, "- ")
			switch currentField {
			case "interfaces":
				ex.Interfaces = append(ex.Interfaces, val)
			case "extensions":
				ex.Extensions = append(ex.Extensions, val)
			case "dependencies":
				ex.Dependencies = append(ex.Dependencies, val)
			case "description":
				if ex.Description != "" {
					ex.Description += " "
				}
				ex.Description += val
			}
		}
	}
	return ex, nil
}

// writeYAML écrit les exigences extraites dans un fichier YAML.
func writeYAML(filename string, exigences []Exigence, em *ErrorManager) error {
	rec := Recensement{Exigences: exigences}
	f, err := os.Create(filename)
	if err != nil {
		return err
	}
	defer f.Close()
	encoder := yaml.NewEncoder(f)
	encoder.SetIndent(2)
	if err := encoder.Encode(&rec); err != nil {
		return err
	}
	return nil
}

func main() {
	em := &ErrorManager{}
	agentsFile := "AGENTS.md"
	outputFile := "exigences-interoperabilite.yaml"

	f, err := os.Open(agentsFile)
	if err != nil {
		em.Add(fmt.Errorf("Impossible d’ouvrir %s: %w", agentsFile, err))
		em.Report()
		os.Exit(1)
	}
	defer f.Close()

	exigences, err := parseAgentsMD(f, em)
	if err != nil {
		em.Add(fmt.Errorf("Erreur parsing AGENTS.md: %w", err))
	}

	if err := writeYAML(outputFile, exigences, em); err != nil {
		em.Add(fmt.Errorf("Erreur écriture YAML: %w", err))
	}

	if em.HasErrors() {
		em.Report()
		os.Exit(1)
	}

	fmt.Printf("Recensement terminé. %d exigences extraites.\nFichier généré : %s\n", len(exigences), outputFile)
}
