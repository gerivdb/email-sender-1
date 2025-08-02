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
