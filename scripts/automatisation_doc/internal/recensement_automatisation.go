// recensement_automatisation.go
// Package automatisationdoc : scan des besoins d’automatisation documentaire Roo Code et génération YAML.
package automatisation_doc

import (
	"fmt"
	"io/ioutil"
	"log"
	"os"
	"path/filepath"
	"strings"

	"gopkg.in/yaml.v3"
)

// BesoinAutoDoc représente un besoin d’automatisation documentaire.
type BesoinAutoDoc struct {
	Fichier  string `yaml:"fichier"`
	Resume   string `yaml:"resume"`
	Contexte string `yaml:"contexte,omitempty"`
}

// RapportAutoDoc regroupe les besoins détectés.
type RapportAutoDoc struct {
	Besoins []BesoinAutoDoc `yaml:"besoins"`
}

// GenerateBesoinsAutomatisationDoc scanne le projet et génère le YAML des besoins d’automatisation documentaire.
func GenerateBesoinsAutomatisationDoc(root string, output string) error {
	var besoins []BesoinAutoDoc

	// Recherche dans les fichiers markdown et yaml du projet
	err := filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			log.Printf("Erreur accès %s: %v", path, err)
			return nil
		}
		if !info.IsDir() && (strings.HasSuffix(path, ".md") || strings.HasSuffix(path, ".yaml")) {
			content, err := ioutil.ReadFile(path)
			if err != nil {
				log.Printf("Erreur lecture %s: %v", path, err)
				return nil
			}
			// Extraction naïve : lignes contenant "besoin", "automatisation", "doc"
			lines := strings.Split(string(content), "\n")
			for _, l := range lines {
				if strings.Contains(strings.ToLower(l), "besoin") &&
					(strings.Contains(strings.ToLower(l), "automatisation") || strings.Contains(strings.ToLower(l), "doc")) {
					besoins = append(besoins, BesoinAutoDoc{
						Fichier: path,
						Resume:  strings.TrimSpace(l),
					})
				}
			}
		}
		return nil
	})
	if err != nil {
		return fmt.Errorf("Erreur parcours fichiers: %v", err)
	}

	rapport := RapportAutoDoc{Besoins: besoins}
	data, err := yaml.Marshal(&rapport)
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
