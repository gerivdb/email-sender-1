// scripts/fix-yaml.go
// Corrige automatiquement l’indentation et les erreurs courantes des fichiers YAML (Helm, CI/CD).
// Usage : go run scripts/fix-yaml.go

package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"gopkg.in/yaml.v3"
)

func fixYAMLFile(path string) error {
	backup := path + ".bak"
	_ = copyFile(path, backup)

	data, err := os.ReadFile(path)
	if err != nil {
		return fmt.Errorf("lecture: %w", err)
	}
	var out interface{}
	if err := yaml.Unmarshal(data, &out); err != nil {
		return fmt.Errorf("parse: %w", err)
	}
	f, err := os.Create(path)
	if err != nil {
		_ = os.Rename(backup, path)
		return fmt.Errorf("écriture: %w", err)
	}
	defer f.Close()
	enc := yaml.NewEncoder(f)
	enc.SetIndent(2)
	if err := enc.Encode(out); err != nil {
		_ = os.Rename(backup, path)
		return fmt.Errorf("encode: %w", err)
	}
	return nil
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
	// Limite le scope aux dossiers YAML métier
	targetDirs := []string{
		"charts",
		".github/workflows",
		"deploy",
	}
	var files []string
	for _, dir := range targetDirs {
		_ = filepath.Walk(dir, func(path string, info os.FileInfo, err error) error {
			if err == nil && !info.IsDir() &&
				(strings.HasSuffix(info.Name(), ".yaml") || strings.HasSuffix(info.Name(), ".yml")) &&
				!strings.HasSuffix(info.Name(), ".bak") && !strings.Contains(info.Name(), "tmp") {
				files = append(files, path)
			}
			return nil
		})
	}

	fmt.Printf("Correction de %d fichiers YAML dans %v\n", len(files), targetDirs)
	nbErr := 0
	for _, file := range files {
		fmt.Printf("Correction de %s...\n", file)
		if err := fixYAMLFile(file); err != nil {
			fmt.Fprintf(os.Stderr, "Erreur sur %s : %v\n", file, err)
			nbErr++
			continue
		}
		fmt.Printf("OK : %s (backup : %s.bak)\n", file, file)
	}
	fmt.Printf("Total erreurs de correction YAML : %d\n", nbErr)
}
