package main

import (
	"fmt"
	"html/template"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"
)

// ReportData structure pour les données du rapport
type ReportData struct {
	Timestamp        string
	UnitTests        string
	IntegrationTests string
	OverallStatus    string
	Coverage         string
	Errors           []string
}

func main() {
	fmt.Println("Génération du rapport automatisé pour Gateway-Manager...")

	// Exécuter les tests unitaires et capturer la sortie
	unitTestCmd := exec.Command("go", "test", "-v", "-cover", "./development/managers/gateway-manager/...")
	unitTestOutput, unitTestErr := unitTestCmd.CombinedOutput()
	unitTestResult := string(unitTestOutput)

	// Extraire la couverture des tests unitaires
	unitCoverage := "N/A"
	if strings.Contains(unitTestResult, "coverage:") {
		lines := strings.Split(unitTestResult, "\n")
		for _, line := range lines {
			if strings.Contains(line, "coverage:") {
				unitCoverage = strings.TrimSpace(strings.Split(line, "coverage:")[1])
				break
			}
		}
	}

	// Exécuter les tests d'intégration et capturer la sortie
	integrationTestCmd := exec.Command("go", "test", "-v", "-cover", "./tests/integration/...")
	integrationTestOutput, integrationTestErr := integrationTestCmd.CombinedOutput()
	integrationTestResult := string(integrationTestOutput)

	// Préparer les données du rapport
	reportData := ReportData{
		Timestamp:        time.Now().Format("2006-01-02 15:04:05 MST"),
		UnitTests:        unitTestResult,
		IntegrationTests: integrationTestResult,
		OverallStatus:    "SUCCÈS",
		Coverage:         unitCoverage, // Pour l'instant, utiliser la couverture des tests unitaires
		Errors:           []string{},
	}

	if unitTestErr != nil {
		reportData.OverallStatus = "ÉCHEC"
		reportData.Errors = append(reportData.Errors, "Tests unitaires échoués: "+unitTestErr.Error())
	}
	if integrationTestErr != nil {
		reportData.OverallStatus = "ÉCHEC"
		reportData.Errors = append(reportData.Errors, "Tests d'intégration échoués: "+integrationTestErr.Error())
	}

	// Créer le répertoire de migration si nécessaire
	reportDir := "migration/gateway-manager-v77"
	if err := os.MkdirAll(reportDir, 0o755); err != nil {
		fmt.Printf("Erreur lors de la création du répertoire de rapport: %v\n", err)
		os.Exit(1)
	}

	// Définir le chemin du fichier de rapport HTML
	reportFilePath := filepath.Join(reportDir, "report.html")

	// Modèle HTML pour le rapport
	htmlTemplate := `
<!DOCTYPE html>
<html>
<head>
    <title>Rapport d'Automatisation Gateway-Manager v77</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; }
        .section { margin-bottom: 20px; border: 1px solid #eee; padding: 15px; border-radius: 8px; }
        .status-success { color: green; font-weight: bold; }
        .status-failure { color: red; font-weight: bold; }
        pre { background-color: #f4f4f4; padding: 10px; border-radius: 4px; overflow-x: auto; }
        .error-message { color: red; font-weight: bold; }
    </style>
</head>
<body>
    <h1>Rapport d'Automatisation Gateway-Manager v77</h1>
    <p><strong>Date de génération:</strong> {{.Timestamp}}</p>
    <p><strong>Statut Global:</strong> <span class="{{if eq .OverallStatus "SUCCÈS"}}status-success{{else}}status-failure{{end}}">{{.OverallStatus}}</span></p>
    <p><strong>Couverture des tests unitaires (GatewayManager):</strong> {{.Coverage}}</p>

    {{if .Errors}}
    <div class="section error-section">
        <h2>Erreurs détectées:</h2>
        {{range .Errors}}
        <p class="error-message">- {{.}}</p>
        {{end}}
    </div>
    {{end}}

    <div class="section">
        <h2>Résultats des Tests Unitaires (development/managers/gateway-manager/...)</h2>
        <pre>{{.UnitTests}}</pre>
    </div>

    <div class="section">
        <h2>Résultats des Tests d'Intégration (tests/integration/...)</h2>
        <pre>{{.IntegrationTests}}</pre>
    </div>

    <footer>
        <p>Ce rapport a été généré automatiquement.</p>
    </footer>
</body>
</html>
`

	// Parser le modèle HTML
	tmpl, err := template.New("report").Parse(htmlTemplate)
	if err != nil {
		fmt.Printf("Erreur lors du parsing du modèle HTML: %v\n", err)
		os.Exit(1)
	}

	// Créer le fichier de sortie
	file, err := os.Create(reportFilePath)
	if err != nil {
		fmt.Printf("Erreur lors de la création du fichier de rapport HTML: %v\n", err)
		os.Exit(1)
	}
	defer file.Close()

	// Exécuter le modèle et écrire dans le fichier
	if err := tmpl.Execute(file, reportData); err != nil {
		fmt.Printf("Erreur lors de l'exécution du modèle HTML: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Rapport HTML généré avec succès: %s\n", reportFilePath)
}
