package reporting

import (
	"encoding/json"
	"fmt"
	"os"
)

// Specification représente une structure de spécification.
type Specification struct {
	ID           string `json:"id"`
	Description  string `json:"description"`
	Status       string `json:"status"`
	Completeness string `json:"completeness"` // e.g., "Complete", "Partial", "Missing"
}

// ValidateSpecifications simule la validation de la complétude des spécifications à partir d'un fichier JSON de besoins.
func ValidateSpecifications(needsFilePath string) ([]Specification, error) {
	fmt.Printf("Validation des spécifications à partir de %s...\n", needsFilePath)

	// Pour l'exemple, nous allons simuler la lecture d'un fichier de besoins.
	// Si le fichier n'existe pas, nous retournons des spécifications par défaut pour les tests.
	if _, err := os.Stat(needsFilePath); os.IsNotExist(err) {
		fmt.Printf("Fichier de besoins non trouvé: %s. Génération de spécifications par défaut.\n", needsFilePath)
		return []Specification{
			{ID: "SPEC-001", Description: "Spécification du module de scan", Status: "Approuvée", Completeness: "Complete"},
			{ID: "SPEC-002", Description: "Spécification du rapport d'analyse d'écart", Status: "En révision", Completeness: "Partial"},
			{ID: "SPEC-003", Description: "Spécification de l'orchestrateur", Status: "Non démarrée", Completeness: "Missing"},
		}, nil
	}

	needsBytes, err := os.ReadFile(needsFilePath)
	if err != nil {
		return nil, fmt.Errorf("erreur lors de la lecture du fichier de besoins: %w", err)
	}

	var needs []Need // Assuming Need struct is defined in this package or imported
	err = json.Unmarshal(needsBytes, &needs)
	if err != nil {
		return nil, fmt.Errorf("erreur lors du décode du JSON des besoins: %w", err)
	}

	var specifications []Specification
	for _, need := range needs {
		completeness := "Missing"
		status := "Non démarrée" // Default status

		// Simulate completeness and status based on need description or other logic
		if need.Status == "Ouvert" || need.Status == "En cours" {
			completeness = "Partial"
			status = "En révision"
		}
		if need.ID == "REQ-001" { // Specific example for full completeness
			completeness = "Complete"
			status = "Approuvée"
		}

		spec := Specification{
			ID:           fmt.Sprintf("SPEC-%s", need.ID[len(need.ID)-3:]), // Derive spec ID from need ID
			Description:  fmt.Sprintf("Spécification de %s", need.Description),
			Status:       status,
			Completeness: completeness,
		}
		specifications = append(specifications, spec)
	}

	return specifications, nil
}

// GenerateSpecReport génère le rapport des spécifications au format JSON et Markdown.
func GenerateSpecReport(outputPathJSON, outputPathMD string, specs []Specification) error {
	fmt.Printf("Génération du rapport des spécifications...\n")

	// Générer le rapport JSON
	jsonBytes, err := json.MarshalIndent(specs, "", "  ")
	if err != nil {
		return fmt.Errorf("erreur lors de la sérialisation du rapport JSON des spécifications: %w", err)
	}
	err = os.WriteFile(outputPathJSON, jsonBytes, 0o644)
	if err != nil {
		return fmt.Errorf("erreur lors de l'écriture du fichier JSON des spécifications: %w", err)
	}
	fmt.Printf("Rapport JSON des spécifications généré : %s\n", outputPathJSON)

	// Générer le rapport Markdown
	markdownContent := "# Rapport des Spécifications\n\n"
	markdownContent += "## Liste des Spécifications :\n"
	for _, spec := range specs {
		markdownContent += fmt.Sprintf("- **ID**: %s\n", spec.ID)
		markdownContent += fmt.Sprintf("  **Description**: %s\n", spec.Description)
		markdownContent += fmt.Sprintf("  **Statut**: %s\n", spec.Status)
		markdownContent += fmt.Sprintf("  **Complétude**: %s\n", spec.Completeness)
		markdownContent += "\n"
	}

	err = os.WriteFile(outputPathMD, []byte(markdownContent), 0o644)
	if err != nil {
		return fmt.Errorf("erreur lors de l'écriture du fichier Markdown des spécifications: %w", err)
	}
	fmt.Printf("Rapport Markdown des spécifications généré : %s\n", outputPathMD)

	return nil
}
