// cmd/backup-modified-files/main.go
// Sauvegarde automatique avant modification majeure, génération de fichiers .bak

package main

import (
	"fmt"
	"io"
	"os"
	"time"
)

func backupFile(src string) error {
	dst := src + ".bak"
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()
	out, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer out.Close()
	_, err = io.Copy(out, in)
	return err
}

func main() {
	files := []string{
		"besoins.json", "specs.json", "module-output.json", "reporting.md", "validation.md",
	}
	for _, f := range files {
		if _, err := os.Stat(f); err == nil {
			err := backupFile(f)
			if err != nil {
				fmt.Printf("Erreur backup %s: %v\n", f, err)
			} else {
				fmt.Printf("Backup effectué: %s.bak\n", f)
			}
		}
	}
	logf, err := os.OpenFile("rollback.log", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err == nil {
		defer logf.Close()
		logf.WriteString(fmt.Sprintf("%s | Backup effectué sur %d fichiers\n", time.Now().Format(time.RFC3339), len(files)))
	}
	fmt.Println("Sauvegarde automatique terminée, rollback.log mis à jour.")
}
