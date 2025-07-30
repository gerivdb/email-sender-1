//go:build tools
// +build tools

package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
)

// Scan du dossier .roo/rules/ pour détecter les fichiers .md à synchroniser
func ScanRulesDir(dir string) ([]string, error) {
	var files []string
	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil, err
	}
	for _, entry := range entries {
		if !entry.IsDir() && filepath.Ext(entry.Name()) == ".md" {
			files = append(files, entry.Name())
		}
	}
	return files, nil
}

// Injection ou mise à jour de la section "Références croisées" en fin de fichier
func InjectCrossRefsSection(filePath string, refs []string, formatSection, formatItem string) error {
	data, err := ioutil.ReadFile(filePath)
	if err != nil {
		return err
	}
	content := string(data)
	sectionHeader := formatSection
	sectionStart := strings.LastIndex(content, sectionHeader)
	var newSection strings.Builder
	newSection.WriteString("\n" + sectionHeader + "\n\n")
	for _, ref := range refs {
		newSection.WriteString(fmt.Sprintf(formatItem, ref, ref, "Lien documentaire Roo-Code") + "\n")
	}
	if sectionStart != -1 {
		// Remplacer la section existante
		content = content[:sectionStart] + newSection.String()
	} else {
		// Ajouter à la fin
		content += newSection.String()
	}
	// Backup avant modification
	err = ioutil.WriteFile(filePath+".bak", data, 0644)
	if err != nil {
		return err
	}
	return ioutil.WriteFile(filePath, []byte(content), 0644)
}

// Vérification des verrous/droits sur les fichiers
func CheckLocks(dir string) ([]string, error) {
	var locked []string
	entries, err := os.ReadDir(dir)
	if err != nil {
		return nil, err
	}
	for _, entry := range entries {
		if !entry.IsDir() && filepath.Ext(entry.Name()) == ".md" {
			path := filepath.Join(dir, entry.Name())
			f, err := os.OpenFile(path, os.O_WRONLY, 0644)
			if err != nil {
				locked = append(locked, entry.Name())
			}
			f.Close()
		}
	}
	return locked, nil
}

// Mode dry-run : simulation de l’injection sans écriture
func DryRunInject(filePath string, refs []string, formatSection, formatItem string) (string, error) {
	data, err := ioutil.ReadFile(filePath)
	if err != nil {
		return "", err
	}
	content := string(data)
	sectionHeader := formatSection
	sectionStart := strings.LastIndex(content, sectionHeader)
	var newSection strings.Builder
	newSection.WriteString("\n" + sectionHeader + "\n\n")
	for _, ref := range refs {
		newSection.WriteString(fmt.Sprintf(formatItem, ref, ref, "Lien documentaire Roo-Code") + "\n")
	}
	if sectionStart != -1 {
		content = content[:sectionStart] + newSection.String()
	} else {
		content += newSection.String()
	}
	return content, nil
}

// CLI
func main() {
	args := os.Args
	if len(args) < 2 {
		fmt.Println("Usage: go run refs_sync.go --scan|--inject|--check-locks|--dry-run")
		return
	}
	switch args[1] {
	case "--scan":
		files, err := ScanRulesDir(".roo/rules/")
		if err != nil {
			fmt.Println("Erreur scan:", err)
			os.Exit(1)
		}
		fmt.Println("Fichiers détectés:", files)
	case "--inject":
		files, err := ScanRulesDir(".roo/rules/")
		if err != nil {
			fmt.Println("Erreur scan:", err)
			os.Exit(1)
		}
		for _, f := range files {
			err := InjectCrossRefsSection(filepath.Join(".roo/rules/", f), files, "## Références croisées", "- [%s](%s): %s")
			if err != nil {
				fmt.Printf("Erreur injection %s: %v\n", f, err)
			} else {
				fmt.Printf("Section injectée dans %s\n", f)
			}
		}
	case "--check-locks":
		locked, err := CheckLocks(".roo/rules/")
		if err != nil {
			fmt.Println("Erreur vérification locks:", err)
			os.Exit(1)
		}
		if len(locked) > 0 {
			fmt.Println("Fichiers verrouillés:", locked)
		} else {
			fmt.Println("Aucun fichier verrouillé.")
		}
	case "--dry-run":
		files, err := ScanRulesDir(".roo/rules/")
		if err != nil {
			fmt.Println("Erreur scan:", err)
			os.Exit(1)
		}
		for _, f := range files {
			sim, err := DryRunInject(filepath.Join(".roo/rules/", f), files, "## Références croisées", "- [%s](%s): %s")
			if err != nil {
				fmt.Printf("Erreur dry-run %s: %v\n", f, err)
			} else {
				fmt.Printf("Simulation pour %s:\n%s\n", f, sim)
			}
		}
	default:
		fmt.Println("Option inconnue.")
	}
}
