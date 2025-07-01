package go

import (
	"bufio"
	"bytes"
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"strings"
	"time"
)

var (
	filePath	= flag.String("file", "", "Fichier cible à patcher")
	patchPath	= flag.String("patch", "", "Fichier contenant le bloc diff Edit")
	dryRun		= flag.Bool("dry-run", false, "Prévisualiser le diff sans appliquer")
)

func main() {
	flag.Parse()
	if *filePath == "" || *patchPath == "" {
		log.Fatal("Usage: diffedit-go --file <fichier> --patch <bloc-diff> [--dry-run]")
	}

	// Lecture du fichier cible
	content, err := ioutil.ReadFile(*filePath)
	if err != nil {
		log.Fatalf("Erreur lecture fichier cible: %v", err)
	}

	// Lecture du patch
	patch, err := ioutil.ReadFile(*patchPath)
	if err != nil {
		log.Fatalf("Erreur lecture patch: %v", err)
	}

	search, replace, err := parseDiffEditBlock(string(patch))
	if err != nil {
		log.Fatalf("Erreur parsing bloc diff Edit: %v", err)
	}

	// Vérification unicité
	occurrences := bytes.Count(content, []byte(search))
	if occurrences == 0 {
		log.Fatalf("Bloc SEARCH non trouvé dans le fichier.")
	}
	if occurrences > 1 {
		log.Fatalf("Bloc SEARCH non unique (%d occurrences).", occurrences)
	}

	// Prévisualisation
	if *dryRun {
		fmt.Println("--- DIFF (dry-run) ---")
		fmt.Println("--- AVANT ---")
		fmt.Println(search)
		fmt.Println("--- APRES ---")
		fmt.Println(replace)
		return
	}

	// Backup
	backupPath := *filePath + ".bak-" + time.Now().Format("20060102-150405")
	err = ioutil.WriteFile(backupPath, content, 0644)
	if err != nil {
		log.Fatalf("Erreur backup: %v", err)
	}

	// Remplacement
	newContent := bytes.Replace(content, []byte(search), []byte(replace), 1)
	err = ioutil.WriteFile(*filePath, newContent, 0644)
	if err != nil {
		log.Fatalf("Erreur écriture fichier modifié: %v", err)
	}

	log.Printf("Patch appliqué avec succès. Backup: %s", backupPath)
}

func parseDiffEditBlock(block string) (string, string, error) {
	scanner := bufio.NewScanner(strings.NewReader(block))
	var (
		inSearch, inReplace	bool
		search, replace		strings.Builder
	)
	for scanner.Scan() {
		line := scanner.Text()
		if strings.HasPrefix(line, "------- SEARCH") {
			inSearch = true
			inReplace = false
			continue
		}
		if strings.HasPrefix(line, "=======") {
			inSearch = false
			inReplace = true
			continue
		}
		if strings.HasPrefix(line, "+++++++ REPLACE") {
			inReplace = false
			continue
		}
		if inSearch {
			search.WriteString(line + "\n")
		}
		if inReplace {
			replace.WriteString(line + "\n")
		}
	}
	if err := scanner.Err(); err != nil {
		return "", "", err
	}
	// Trim trailing newline
	return strings.TrimSuffix(search.String(), "\n"), strings.TrimSuffix(replace.String(), "\n"), nil
}
