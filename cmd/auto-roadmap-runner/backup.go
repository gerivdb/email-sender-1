// cmd/auto-roadmap-runner/backup.go
package main

import (
	"fmt"
	"io"
	"log"
	"os"
	"path/filepath"
)

func BackupFile(src string) error {
	// Validation du chemin (G304)
	src = filepath.Clean(src)
	if filepath.IsAbs(src) || src == "" || src == "." || src == ".." {
		return fmt.Errorf("chemin source invalide: %s", src)
	}
	dst := src + ".bak"

	in, err := os.Open(src)
	if err != nil {
		return fmt.Errorf("échec ouverture source: %w", err)
	}
	defer func() {
		if cerr := in.Close(); cerr != nil {
			log.Printf("Avertissement: fermeture input échouée: %v", cerr)
		}
	}()

	out, err := os.Create(dst)
	if err != nil {
		return fmt.Errorf("échec création backup: %w", err)
	}
	defer func() {
		if cerr := out.Close(); cerr != nil {
			log.Printf("Avertissement: fermeture output échouée: %v", cerr)
		}
	}()

	if _, err = io.Copy(out, in); err != nil {
		return fmt.Errorf("échec copie: %w", err)
	}

	log.Printf("Backup créé: %s", dst)
	return nil
}
