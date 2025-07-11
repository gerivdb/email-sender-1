package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

type EventHook struct {
	File    string `json:"file"`
	Type    string `json:"type"`
	Keyword string `json:"keyword"`
}

func main() {
	// Définir les types de fichiers à scanner
	fileTypes := []string{".go", ".sh", ".py"}

	// Définir les mots-clés à rechercher
	keywords := []string{"manager", "hook", "script", "event"}

	var eventHooks []EventHook

	// Parcourir le répertoire courant
	filepath.Walk(".", func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}

		// Vérifier si le fichier correspond à un type de fichier recherché
		for _, fileType := range fileTypes {
			if strings.HasSuffix(path, fileType) {
				// Lire le contenu du fichier
				content, err := os.ReadFile(path)
				if err != nil {
					return err
				}
				contentStr := string(content)

				// Rechercher les mots-clés dans le contenu
				for _, keyword := range keywords {
					if strings.Contains(contentStr, keyword) {
						eventHooks = append(eventHooks, EventHook{
							File:    path,
							Type:    fileType,
							Keyword: keyword,
						})
					}
				}
				return nil
			}
		}
		return nil
	})

	// Convertir les données en JSON
	jsonData, err := json.MarshalIndent(eventHooks, "", "  ")
	if err != nil {
		fmt.Println(err)
		return
	}

	// Écrire les données dans un fichier
	err = os.WriteFile("event_hooks.json", jsonData, 0o644)
	if err != nil {
		fmt.Println(err)
		return
	}
}
