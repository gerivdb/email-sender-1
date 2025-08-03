// scripts/automatisation_doc/recensement_automatisation.go
//
// Script Roo-Code : Recensement des besoins d’automatisation documentaire
// Phase 1 plan v113 — Génère un fichier YAML structuré listant les besoins détectés.
//
// Entrée : aucune (scan statique ou placeholder, à adapter selon contexte réel).
// Sortie : besoins_automatisation.yaml (structure Roo, voir doc plan v113).
//
// Usage : go run scripts/automatisation_doc/recensement_automatisation.go
//
// Testabilité : chaque fonction est testable indépendamment (voir tests à créer).
// Gestion d’erreur centralisée (ErrorManager ou log.Fatal pour MVP).
//
// Auteur : Roo-Code Generator
// Conventions : Roo, AGENTS.md, rules-code.md, plandev-engineer-reference.md

package automatisation_doc

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"strings"
	"time"

	"gopkg.in/yaml.v3"
)

// BesoinAutomatisation représente un besoin d’automatisation documentaire Roo enrichi.
type BesoinAutomatisation struct {
	ID          string   `yaml:"id"`
	Description string   `yaml:"description"`
	Priorite    string   `yaml:"priorite"`
	Agents      []string `yaml:"agents,omitempty"`
	Statut      string   `yaml:"statut"`
	Fichier     string   `yaml:"fichier,omitempty"`
	Contexte    string   `yaml:"contexte,omitempty"`
}

// Recensement regroupe l’ensemble des besoins détectés.
type Recensement struct {
	Phase     string                 `yaml:"phase"`
	Date      string                 `yaml:"date"`
	Besoins   []BesoinAutomatisation `yaml:"besoins"`
	Contexte  string                 `yaml:"contexte,omitempty"`
	Reference string                 `yaml:"reference"`
}

/*
ScanBesoinsAutomatisation parcourt récursivement le dossier racine et extrait dynamiquement les besoins d’automatisation documentaire Roo.
Attribue un ID, détecte les agents, et enrichit la struct Roo.
*/
func ScanBesoinsAutomatisation(root string) ([]BesoinAutomatisation, error) {
	var besoins []BesoinAutomatisation
	idc := 1
	err := filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() && (strings.HasSuffix(path, ".md") || strings.HasSuffix(path, ".yaml")) {
			content, err := ioutil.ReadFile(path)
			if err != nil {
				return err
			}
			lines := strings.Split(string(content), "\n")
			for _, l := range lines {
				if strings.Contains(strings.ToLower(l), "besoin") &&
					(strings.Contains(strings.ToLower(l), "automatisation") || strings.Contains(strings.ToLower(l), "doc")) {
					agents := DetectAgentsFromLine(l)
					besoins = append(besoins, BesoinAutomatisation{
						ID:          fmt.Sprintf("BA-%03d", idc),
						Description: strings.TrimSpace(l),
						Priorite:    "à qualifier",
						Agents:      agents,
						Statut:      "à valider",
						Fichier:     path,
						Contexte:    "Extraction automatique",
					})
					idc++
				}
			}
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return besoins, nil
}

// DetectAgentsFromLine tente de détecter les agents Roo pertinents à partir d’une ligne de texte.
func DetectAgentsFromLine(line string) []string {
	l := strings.ToLower(line)
	var agents []string
	if strings.Contains(l, "docmanager") {
		agents = append(agents, "DocManager")
	}
	if strings.Contains(l, "script") {
		agents = append(agents, "ScriptManager")
	}
	if strings.Contains(l, "cleanup") || strings.Contains(l, "doublon") {
		agents = append(agents, "CleanupManager")
	}
	// Ajoutez ici d’autres heuristiques selon AGENTS.md
	return agents
}

/*
ExportRecensementAutomatisation exporte la structure Recensement au format YAML Roo.
Gère la sauvegarde de l’ancienne version et la gestion d’erreur centralisée.
*/
func ExportRecensementAutomatisation(recensement Recensement, output string) error {
	data, err := yaml.Marshal(&recensement)
	if err != nil {
		return fmt.Errorf("Erreur génération YAML: %v", err)
	}
	// Sauvegarde de l’ancien fichier si présent
	if _, err := os.Stat(output); err == nil {
		err = os.Rename(output, output+".bak")
		if err != nil {
			log.Printf("Erreur sauvegarde ancienne version: %v", err)
		}
	}
	err = ioutil.WriteFile(output, data, 0644)
	if err != nil {
		return fmt.Errorf("Erreur écriture YAML: %v", err)
	}
	return nil
}

/*
RunRecensementAutomatisation orchestre le scan dynamique et l’export YAML des besoins Roo.
À appeler depuis main.go.
*/
func RunRecensementAutomatisation(root string, output string) error {
	besoins, err := ScanBesoinsAutomatisation(root)
	if err != nil {
		return fmt.Errorf("Erreur scan besoins: %v", err)
	}
	recensement := Recensement{
		Phase:     "Phase 1 - Recensement des besoins d’automatisation documentaire Roo",
		Date:      time.Now().Format("2006-01-02"),
		Besoins:   besoins,
		Contexte:  "Scan initial automatisé, résultats à enrichir par feedback utilisateur.",
		Reference: "plan-dev-v113-autmatisation-doc-roo.md",
	}

	data, err := yaml.Marshal(&recensement)
	if err != nil {
		return fmt.Errorf("Erreur lors de la sérialisation YAML : %w", err)
	}

	outputFile := "besoins_automatisation.yaml"
	if err := os.WriteFile(outputFile, data, 0644); err != nil {
		return fmt.Errorf("Erreur lors de l’écriture du fichier %s : %w", outputFile, err)
	}

	fmt.Printf("Recensement des besoins d’automatisation documentaire Roo exporté dans %s\n", outputFile)
	return nil
}

// RunScanBesoinsAutomatisation retourne la liste des besoins détectés (MVP statique, à adapter).
