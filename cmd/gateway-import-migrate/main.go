package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
)

const (
	oldImportPath = "development/managers/gateway-manager"
	newImportPath = "development/managers/gateway-manager"
)

func main() {
	fmt.Println("Démarrage de la migration des imports pour Gateway-Manager...")

	// Parcourir tous les fichiers Go dans le répertoire courant et ses sous-répertoires
	err := filepath.Walk(".", func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// Ignorer les répertoires et les fichiers non-Go
		if info.IsDir() || !strings.HasSuffix(path, ".go") {
			return nil
		}

		// Lire le contenu du fichier
		content, err := ioutil.ReadFile(path)
		if err != nil {
			return fmt.Errorf("erreur de lecture du fichier %s: %w", path, err)
		}

		// Remplacer les anciennes références par les nouvelles
		newContent := strings.ReplaceAll(string(content), oldImportPath, newImportPath)

		// Vérifier si des modifications ont été apportées
		if newContent != string(content) {
			fmt.Printf("Mise à jour des imports dans %s\n", path)
			err = ioutil.WriteFile(path, []byte(newContent), info.Mode())
			if err != nil {
				return fmt.Errorf("erreur d'écriture du fichier %s: %w", path, err)
			}
		}

		return nil
	})
	if err != nil {
		fmt.Printf("Migration des imports terminée avec des erreurs: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("Migration des imports terminée avec succès.")
}
