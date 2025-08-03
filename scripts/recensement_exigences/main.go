// scripts/recensement_exigences/main.go
//
// Script Roo-Code : Recensement des exigences d’interopérabilité documentaire multi-agents
// Lit AGENTS.md, extrait interfaces, points d’extension, dépendances, et génère exigences-interoperabilite.yaml
//
// Usage : go run scripts/recensement_exigences/main.go
//
// Prévu pour extension future (tests, CI/CD, modularité)
package main

import (
	"fmt"
	"os"
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

// Point d’entrée principal Roo-Code
func main() {
	em := &ErrorManager{}

	// Lecture du fichier AGENTS.md
	agentsContent, err := os.ReadFile("AGENTS.md")
	if err != nil {
		em.Add(fmt.Errorf("Erreur lecture AGENTS.md : %w", err))
		em.Report()
		os.Exit(1)
	}
	lines := splitLines(string(agentsContent))

	// Extraction de la liste brute des managers
	var managers []string
	inList := false
	for _, line := range lines {
		if !inList && (line == "## Liste brute des managers détectés" || line == "## Liste brute des managers") {
			inList = true
			continue
		}
		if inList {
			if len(line) == 0 || line[0] != '-' {
				break
			}
			// Nettoyage du nom
			name := line[1:]
			name = trimSpaces(name)
			managers = append(managers, name)
		}
	}

	// Pour chaque manager, extraire le rôle
	type ManagerRole struct {
		Name string
		Role string
	}
	var result []ManagerRole
	for _, manager := range managers {
		role := extractRoleForManager(lines, manager)
		result = append(result, ManagerRole{Name: manager, Role: role})
	}

	// Génération Markdown
	md := "# Besoins Pipeline — Managers et rôles\n\n"
	for _, mr := range result {
		md += fmt.Sprintf("## %s\n\n**Rôle :** %s\n\n", mr.Name, mr.Role)
	}

	// Écriture du fichier
	err = os.WriteFile("besoins-pipeline.md", []byte(md), 0644)
	if err != nil {
		em.Add(fmt.Errorf("Erreur écriture besoins-pipeline.md : %w", err))
		em.Report()
		os.Exit(1)
	}
	fmt.Println("Génération de besoins-pipeline.md terminée.")
}

// splitLines découpe une chaîne en lignes (compatible CRLF/LF)
func splitLines(s string) []string {
	var res []string
	start := 0
	for i := 0; i < len(s); i++ {
		if s[i] == '\n' {
			res = append(res, trimCR(s[start:i]))
			start = i + 1
		}
	}
	if start < len(s) {
		res = append(res, trimCR(s[start:]))
	}
	return res
}

// trimSpaces supprime les espaces en début/fin
func trimSpaces(s string) string {
	for len(s) > 0 && (s[0] == ' ' || s[0] == '\t') {
		s = s[1:]
	}
	for len(s) > 0 && (s[len(s)-1] == ' ' || s[len(s)-1] == '\t') {
		s = s[:len(s)-1]
	}
	return s
}

// trimCR supprime un éventuel \r final
func trimCR(s string) string {
	if len(s) > 0 && s[len(s)-1] == '\r' {
		return s[:len(s)-1]
	}
	return s
}

// extractRoleForManager cherche la section du manager et extrait la ligne Rôle
func extractRoleForManager(lines []string, manager string) string {
	section := "### " + manager
	for i, line := range lines {
		if line == section {
			// Cherche la ligne "**Rôle :**" après la section
			for j := i + 1; j < len(lines); j++ {
				l := lines[j]
				if len(l) == 0 {
					continue
				}
				if l[:8] == "- **Rôle" || l[:8] == "* **Rôle" || l[:8] == "**Rôle" {
					idx := indexOf(l, ":")
					if idx != -1 {
						return trimSpaces(l[idx+1:])
					}
				}
				// Fin de section si nouvelle section
				if len(l) > 0 && l[0] == '#' {
					break
				}
			}
			break
		}
	}
	return "(non trouvé)"
}

// indexOf retourne l'index du premier c dans s, ou -1
func indexOf(s string, c string) int {
	for i := 0; i+len(c) <= len(s); i++ {
		if s[i:i+len(c)] == c {
			return i
		}
	}
	return -1
}
