// scripts/fix-go-mods.go
// Corrige automatiquement les fichiers go.mod et go.work : backup, suppression directives interdites/imports locaux, rollback si échec.
// Usage : go run scripts/fix-go-mods.go

package main

import (
	"bufio"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"
)

var (
	forbiddenDirectives        = []string{"replace", "exclude"}
	forbiddenLocalImportPrefix = "./"
)

func processFile(path string) error {
	backup := path + ".bak"
	_ = copyFile(path, backup)

	in, err := os.Open(path)
	if err != nil {
		return fmt.Errorf("ouverture: %w", err)
	}
	defer in.Close()

	out, err := os.Create(path + ".tmp")
	if err != nil {
		return fmt.Errorf("création tmp: %w", err)
	}
	defer out.Close()

	scanner := bufio.NewScanner(in)
	for scanner.Scan() {
		line := scanner.Text()
		skip := false
		for _, d := range forbiddenDirectives {
			if strings.HasPrefix(strings.TrimSpace(line), d+" ") {
				skip = true
			}
		}
		if strings.Contains(line, forbiddenLocalImportPrefix) {
			skip = true
		}
		if !skip {
			fmt.Fprintln(out, line)
		}
	}
	if err := scanner.Err(); err != nil {
		_ = os.Rename(backup, path)
		return fmt.Errorf("scan: %w", err)
	}
	out.Close()
	if err := os.Rename(path+".tmp", path); err != nil {
		_ = os.Rename(backup, path)
		return fmt.Errorf("rename: %w", err)
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
	_, err = io.Copy(out, in)
	return err
}

func main() {
	root := "."
	var files []string
	_ = filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err == nil && (info.Name() == "go.mod" || info.Name() == "go.work") {
			files = append(files, path)
		}
		return nil
	})

	for _, file := range files {
		fmt.Printf("Correction de %s...\n", file)
		if err := processFile(file); err != nil {
			fmt.Fprintf(os.Stderr, "Erreur sur %s : %v\n", file, err)
			continue
		}
		fmt.Printf("OK : %s (backup : %s.bak)\n", file, file)
	}
}
