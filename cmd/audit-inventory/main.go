// cmd/audit-inventory/main.go
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"time"
)

// Inventory représente la structure de l'inventaire.
// Les noms de champs sont en majuscules pour être exportés (visibles par le package json).
type Inventory struct {
	Modes    []Mode    `json:"modes"`
	Personas []Persona `json:"personas"`
}

// Mode représente un mode dans l'inventaire.
type Mode struct {
	Name string `json:"name"`
}

// Persona représente un persona dans l'inventaire.
type Persona struct {
	Name string `json:"name"`
}

func main() {
	// Définir et parser les arguments de la ligne de commande
	outputPath := flag.String("output", "inventory-personas-modes.json", "Chemin du fichier de sortie JSON")
	flag.Parse()

	var files []string
	err := filepath.Walk(".", func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() {
			files = append(files, path)
		}
		return nil
	})
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur lors du scan: %v\n", err)
		os.Exit(1)
	}

	// Créer un inventaire factice (la logique de recensement réelle sera implémentée plus tard)
	inventory := Inventory{
		Modes: []Mode{
			{Name: "Architect"},
			{Name: "Code"},
			{Name: "Ask"},
			{Name: "Debug"},
			{Name: "Orchestrator"},
			{Name: "Project Research"},
			{Name: "Documentation Writer"},
			{Name: "Mode Writer"},
			{Name: "KiloCode"},
		},
		Personas: []Persona{
			{Name: "Architecte"},
			{Name: "Développeur"},
			{Name: "Utilisateur"},
			{Name: "Chef de projet"},
			{Name: "Analyste"},
			{Name: "Rédacteur technique"},
			{Name: "Développeur avancé"},
		},
	}

	// Sauvegarde JSON
	data, err := json.MarshalIndent(inventory, "", "  ")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur de marshaling JSON: %v\n", err)
		os.Exit(1)
	}

	err = os.WriteFile(*outputPath, data, 0o644)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur d'écriture du fichier: %v\n", err)
		os.Exit(1)
	}

	fmt.Printf("Inventaire généré dans : %s\n", *outputPath)

	// Log d’exécution
	logPath := "logs/inventory.log"
	_ = os.MkdirAll("logs", 0o755)
	lf, err := os.OpenFile(logPath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644)
	if err == nil {
		defer lf.Close()
		lf.WriteString(fmt.Sprintf("%s - Inventaire généré (%d fichiers) pour %s\n", time.Now().Format(time.RFC3339), len(files), *outputPath)) // Ajout du nom du fichier de sortie au log
	}
}
