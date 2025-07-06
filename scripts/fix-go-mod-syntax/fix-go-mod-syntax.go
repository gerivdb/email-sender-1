// scripts/fix-go-mod-syntax.go
// Corrige automatiquement les erreurs de syntaxe courantes dans les fichiers go.mod (directive mal orthographiée, ligne 1 incorrecte, etc.)
// Usage : go run scripts/fix-go-mod-syntax.go

package main

import (
	"bufio"
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

func fixGoModSyntax(path string) (bool, error) {
	backup := path + ".bak"
	_ = copyFile(path, backup)

	in, err := os.Open(path)
	if err != nil {
		return false, fmt.Errorf("ouverture: %w", err)
	}
	defer in.Close()

	var lines []string
	scanner := bufio.NewScanner(in)
	lineNum := 0
	changed := false
	for scanner.Scan() {
		line := scanner.Text()
		lineNum++
		// Correction de la première ligne : doit commencer par "module"
		if lineNum == 1 && !strings.HasPrefix(strings.TrimSpace(line), "module ") {
			// Correction typique : "m odule" ou autre typo
			if strings.Contains(line, "odule") {
				line = "module " + strings.TrimSpace(strings.TrimPrefix(line, "m odule"))
				changed = true
			} else {
				// Ligne incorrecte, on tente de la remplacer par "module <nom>"
				// On laisse vide, à compléter manuellement si non détectable
				line = "module "
				changed = true
			}
		}
		// Correction d'autres directives mal orthographiées (ex: "r equire" → "require")
		line = strings.ReplaceAll(line, "r equire", "require")
		line = strings.ReplaceAll(line, "r eplace", "replace")
		line = strings.ReplaceAll(line, "e xclude", "exclude")
		if line != scanner.Text() {
			changed = true
		}
		lines = append(lines, line)
	}
	if err := scanner.Err(); err != nil {
		_ = os.Rename(backup, path)
		return false, fmt.Errorf("scan: %w", err)
	}
	if changed {
		out, err := os.Create(path)
		if err != nil {
			_ = os.Rename(backup, path)
			return false, fmt.Errorf("écriture: %w", err)
		}
		defer out.Close()
		for _, l := range lines {
			fmt.Fprintln(out, l)
		}
	}
	return changed, nil
}

func copyFile(src, dst string) error {
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
	_, err = out.ReadFrom(in)
	return err
}

func main() {
	root := "."
	var files []string
	_ = filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err == nil && info.Name() == "go.mod" {
			files = append(files, path)
		}
		return nil
	})

	report := []string{"# Rapport corrections syntaxe go.mod"}
	for _, file := range files {
		fmt.Printf("Correction syntaxe %s...\n", file)
		changed, err := fixGoModSyntax(file)
		if err != nil {
			report = append(report, fmt.Sprintf("- %s : Erreur : %v", file, err))
			continue
		}
		if changed {
			report = append(report, fmt.Sprintf("- %s : Corrigé (backup : %s.bak)", file, file))
		} else {
			report = append(report, fmt.Sprintf("- %s : OK (aucune correction)", file))
		}
	}
	_ = os.MkdirAll("audit-reports", 0755)
	out, _ := os.Create("audit-reports/go-mod-syntax-fix-report.md")
	defer out.Close()
	for _, l := range report {
		fmt.Fprintln(out, l)
	}
	fmt.Println("Rapport généré : audit-reports/go-mod-syntax-fix-report.md")
}
