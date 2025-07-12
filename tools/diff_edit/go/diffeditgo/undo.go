// Package diffeditgo fournit les fonctions pour l’édition de diff.
package diffeditgo

import (
	"fmt"
	"io/fs"
	"os"
	"path/filepath"
	"strings"
	"time"
)

// CleanBackups searches for backup files in the specified directory and deletes those older than 24 hours.
func CleanBackups(dirPath string) error {
	var filesToDelete []string

	filepath.Walk(dirPath, func(path string, f fs.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if strings.Contains(path, ".bak_") {
			lastBackup := path
			if lastBackup == "" || f.ModTime().After(time.Now().Add(-24*time.Hour)) {
				filesToDelete = append(filesToDelete, path)
			}
		}
		return nil
	})

	for _, file := range filesToDelete {
		err := os.Remove(file)
		if err != nil {
			fmt.Printf("Erreur lors de la suppression du fichier %s: %v\n", file, err)
		}
	}
	return nil
}
