// Package utils provides utility functions for the plan generator
package utils

import (
	"fmt"
	"regexp"
	"strings"
)

// PhaseDescription renvoie une description par défaut pour une phase en fonction de son numéro
func PhaseDescription(number int) string {
	descriptions := map[int]string{
		1: "Phase d'analyse et de conception.",
		2: "Phase de développement des fonctionnalités principales.",
		3: "Phase de tests pour valider les modules.",
		4: "Phase de déploiement en production.",
		5: "Phase d'amélioration continue.",
		6: "Phase d'évaluation et de documentation.",
	}

	if desc, exists := descriptions[number]; exists {
		return desc
	}
	return fmt.Sprintf("Phase %d", number)
}

// SanitizeTitle nettoie un titre pour l'utiliser dans un nom de fichier
func SanitizeTitle(title string) string {
	// Convertir en minuscules
	sanitized := strings.ToLower(title)

	// Remplacer les espaces par des tirets
	sanitized = strings.ReplaceAll(sanitized, " ", "-")

	// Supprimer les caractères non alphanumériques (à part les tirets)
	reg := regexp.MustCompile(`[^a-z0-9\-]`)
	sanitized = reg.ReplaceAllString(sanitized, "")

	// Limiter à 50 caractères max
	if len(sanitized) > 50 {
		sanitized = sanitized[:50]
	}

	return sanitized
}

// GenerateTOC génère la table des matières
func GenerateTOC(count int) string {
	toc := ""
	for i := 1; i <= count; i++ {
		toc += fmt.Sprintf("- [%d] Phase %d\n", i, i)
	}
	return toc
}
