// Package io implements file I/O operations for the plan generator
package io

import (
	"bufio"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"strings"
	"text/template"
	"time"

	"plan-generator/pkg/generator"
	"plan-generator/pkg/models"
	"plan-generator/pkg/utils"
)

// GenerateMarkdown génère le contenu Markdown du plan de développement
func GenerateMarkdown(plan *models.Plan) string {
	templateText := `# Plan de développement {{ .Version }} - {{ .Title }}
*Version 1.0 - {{ .Date }} - Progression globale : {{ .Progress }}%*

{{ .Description }}

## Table des matières
{{ GenerateTOC .PhaseCount }}

{{ range .GeneratedPhases }}
## {{ .Number }}. Phase {{ .Number }} (Phase {{ .Number }})
{{- range .Tasks }}
{{ RenderTasksHierarchy . 1 }}
{{- end }}
  - Entrées : commandes utilisateur, configurations système.
  - Sorties : états des serveurs, fichiers de logs.
  - Conditions préalables : serveurs MCP configurés, accès réseau disponible.
{{ end }}`
	// Créer un template avec fonctions personnalisées
	tmpl, err := template.New("plan").Funcs(template.FuncMap{
		"GenerateTOC":          utils.GenerateTOC,
		"RenderTasksHierarchy": generator.RenderTasksHierarchy,
	}).Parse(templateText)
	if err != nil {
		fmt.Printf("Erreur lors de la création du template: %v\n", err)
		return ""
	}

	// Exécuter le template avec les données du plan
	var result strings.Builder
	err = tmpl.Execute(&result, plan)
	if err != nil {
		fmt.Printf("Erreur lors de l'exécution du template: %v\n", err)
		return ""
	}

	return result.String()
}

// SavePlanToFile sauvegarde le plan généré dans un fichier Markdown
func SavePlanToFile(content, outputDir, version, title string) (string, error) {
	// Créer le nom de fichier
	sanitizedTitle := utils.SanitizeTitle(title)
	filename := fmt.Sprintf("plan-dev-%s-%s.md", version, sanitizedTitle)
	outputPath := filepath.Join(outputDir, filename)

	// Créer le répertoire de sortie s'il n'existe pas
	err := os.MkdirAll(outputDir, 0755)
	if err != nil {
		return "", fmt.Errorf("erreur lors de la création du répertoire: %v", err)
	}

	// Écrire dans le fichier
	err = os.WriteFile(outputPath, []byte(content), 0644)
	if err != nil {
		return "", fmt.Errorf("erreur lors de l'écriture du fichier: %v", err)
	}

	return outputPath, nil
}

// ExportPlanToJSON exporte un plan au format JSON
func ExportPlanToJSON(plan *models.Plan, outputDir, version, title string) (string, error) {
	// Copier le plan et y ajouter les phases générées pour l'export
	exportPlan := *plan
	exportPlan.GeneratedPhases = plan.GeneratedPhases

	// Créer le nom de fichier
	sanitizedTitle := utils.SanitizeTitle(title)
	filename := fmt.Sprintf("plan-dev-%s-%s.json", version, sanitizedTitle)
	outputPath := filepath.Join(outputDir, filename)

	// Convertir le plan en JSON avec indentation pour lisibilité
	jsonData, err := json.MarshalIndent(exportPlan, "", "  ")
	if err != nil {
		return "", fmt.Errorf("erreur lors de la conversion en JSON: %v", err)
	}

	// Créer le répertoire de sortie s'il n'existe pas
	err = os.MkdirAll(outputDir, 0755)
	if err != nil {
		return "", fmt.Errorf("erreur lors de la création du répertoire: %v", err)
	}

	// Écrire dans le fichier
	err = os.WriteFile(outputPath, jsonData, 0644)
	if err != nil {
		return "", fmt.Errorf("erreur lors de l'écriture du fichier JSON: %v", err)
	}

	return outputPath, nil
}

// ImportPlanFromJSON importe un plan depuis un fichier JSON
func ImportPlanFromJSON(filePath string) (*models.Plan, error) {
	// Lire le fichier
	data, err := os.ReadFile(filePath)
	if err != nil {
		return nil, fmt.Errorf("erreur lors de la lecture du fichier JSON: %v", err)
	}

	// Désérialiser le JSON
	var plan models.Plan
	err = json.Unmarshal(data, &plan)
	if err != nil {
		return nil, fmt.Errorf("erreur lors du parsing du JSON: %v", err)
	}
	// Regénérer les phases si nécessaire
	if len(plan.GeneratedPhases) == 0 {
		plan.GeneratedPhases = generator.GeneratePhases(plan.PhaseCount, 4) // Profondeur par défaut: 4
	}

	return &plan, nil
}

// ReadExistingPlanMD lit un plan existant au format Markdown pour en extraire les métadonnées
// Cette fonction est utilisée pour mettre à jour un plan existant
func ReadExistingPlanMD(filePath string) (*models.Plan, error) {
	// Ouvrir le fichier
	file, err := os.Open(filePath)
	if err != nil {
		return nil, fmt.Errorf("erreur lors de l'ouverture du fichier: %v", err)
	}
	defer file.Close()

	// Scanner pour lire ligne par ligne
	scanner := bufio.NewScanner(file)

	// Plan par défaut
	plan := &models.Plan{
		Version:     "v1",
		Title:       "Plan inconnu",
		Description: "",
		PhaseCount:  0,
		Date:        time.Now().Format("2006-01-02"),
		Progress:    0,
	}

	// Extraction du titre et version
	if scanner.Scan() {
		title := scanner.Text()
		if strings.HasPrefix(title, "# Plan de développement ") {
			parts := strings.SplitN(title[22:], " - ", 2)
			if len(parts) >= 2 {
				plan.Version = parts[0]
				plan.Title = parts[1]
			}
		}
	}

	// Extraction de la date et progression
	if scanner.Scan() {
		metadata := scanner.Text()
		// Exemple: *Version 1.0 - 2023-05-12 - Progression globale : 25%*
		dateRegex := regexp.MustCompile(`(\d{4}-\d{2}-\d{2})`)
		dateMatches := dateRegex.FindStringSubmatch(metadata)
		if len(dateMatches) > 0 {
			plan.Date = dateMatches[0]
		}

		progressRegex := regexp.MustCompile(`Progression globale : (\d+)%`)
		progressMatches := progressRegex.FindStringSubmatch(metadata)
		if len(progressMatches) > 1 {
			fmt.Sscanf(progressMatches[1], "%d", &plan.Progress)
		}
	}

	// Extraction de la description
	if scanner.Scan() {
		description := scanner.Text()
		if len(description) > 0 {
			plan.Description = description
		}
	}

	// Compter les phases
	phaseRegex := regexp.MustCompile(`^## \d+\. Phase \d+`)
	for scanner.Scan() {
		if phaseRegex.MatchString(scanner.Text()) {
			plan.PhaseCount++
		}
	}
	// Si des phases ont été trouvées, générées-les
	if plan.PhaseCount > 0 {
		plan.GeneratedPhases = generator.GeneratePhases(plan.PhaseCount, 4) // Valeur par défaut de profondeur: 4
	}

	return plan, nil
}
