package reporting

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"os"
)

// Need représente une structure de besoin.
type Need struct {
	ID          string `json:"id"`
	Description string `json:"description"`
	Status      string `json:"status"`
	Priority    string `json:"priority"`
}

// ParseNeedsFromIssues simule l'extraction des besoins à partir d'un fichier JSON d'issues/tickets.
func ParseNeedsFromIssues(issuesFilePath string) ([]Need, error) {
	fmt.Printf("Extraction des besoins à partir de %s...\n", issuesFilePath)

	// Pour l'exemple, nous allons simuler la lecture d'un fichier d'issues.
	// En production, cela lirait un vrai fichier JSON d'issues.
	// Si le fichier n'existe pas, nous retournons des besoins par défaut pour les tests.
	if _, err := os.Stat(issuesFilePath); os.IsNotExist(err) {
		fmt.Printf("Fichier d'issues non trouvé: %s. Génération de besoins par défaut.\n", issuesFilePath)
		return []Need{
			{ID: "REQ-001", Description: "Implémenter la fonctionnalité de scan des modules", Status: "Ouvert", Priority: "Haute"},
			{ID: "REQ-002", Description: "Générer un rapport d'analyse d'écart", Status: "En cours", Priority: "Haute"},
			{ID: "REQ-003", Description: "Développer l'orchestrateur global", Status: "À faire", Priority: "Moyenne"},
		}, nil
	}

	issuesBytes, err := ioutil.ReadFile(issuesFilePath)
	if err != nil {
		return nil, fmt.Errorf("erreur lors de la lecture du fichier d'issues: %w", err)
	}

	var issues []map[string]interface{}
	err = json.Unmarshal(issuesBytes, &issues)
	if err != nil {
		return nil, fmt.Errorf("erreur lors du décode du JSON d'issues: %w", err)
	}

	var needs []Need
	for _, issue := range issues {
		need := Need{
			ID:          fmt.Sprintf("%v", issue["id"]),
			Description: fmt.Sprintf("%v", issue["description"]),
			Status:      fmt.Sprintf("%v", issue["status"]),
			Priority:    fmt.Sprintf("%v", issue["priority"]),
		}
		needs = append(needs, need)
	}

	return needs, nil
}

// GenerateNeedsReport génère le rapport des besoins au format JSON et Markdown.
func GenerateNeedsReport(outputPathJSON, outputPathMD string, needs []Need) error {
	fmt.Printf("Génération du rapport des besoins...\n")

	// Générer le rapport JSON
	jsonBytes, err := json.MarshalIndent(needs, "", "  ")
	if err != nil {
		return fmt.Errorf("erreur lors de la sérialisation du rapport JSON des besoins: %w", err)
	}
	err = os.WriteFile(outputPathJSON, jsonBytes, 0o644)
	if err != nil {
		return fmt.Errorf("erreur lors de l'écriture du fichier JSON des besoins: %w", err)
	}
	fmt.Printf("Rapport JSON des besoins généré : %s\n", outputPathJSON)

	// Générer le rapport Markdown
	markdownContent := "# Rapport des Besoins\n\n"
	markdownContent += "## Liste des Besoins :\n"
	for _, need := range needs {
		markdownContent += fmt.Sprintf("- **ID**: %s\n", need.ID)
		markdownContent += fmt.Sprintf("  **Description**: %s\n", need.Description)
		markdownContent += fmt.Sprintf("  **Statut**: %s\n", need.Status)
		markdownContent += fmt.Sprintf("  **Priorité**: %s\n", need.Priority)
		markdownContent += "\n"
	}

	err = os.WriteFile(outputPathMD, []byte(markdownContent), 0o644)
	if err != nil {
		return fmt.Errorf("erreur lors de l'écriture du fichier Markdown des besoins: %w", err)
	}
	fmt.Printf("Rapport Markdown des besoins généré : %s\n", outputPathMD)

	return nil
}
