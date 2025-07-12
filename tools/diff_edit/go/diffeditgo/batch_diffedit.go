// Go
// Package diffeditgo fournit des outils pour automatiser l'application de patchs.
package diffeditgo

import (
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
)

// BatchDiffEdit applique un patch diff Edit à plusieurs fichiers listés dans un fichier texte.
// Note: Cette fonction lit les arguments directement depuis os.Args, ce qui est inhabituel pour une fonction de bibliothèque.
// Il serait préférable de passer les chemins en paramètres.
func BatchDiffEdit() {
	if len(os.Args) < 5 {
		fmt.Println("Usage: go run <votre_main>.go --files <list.txt> --patch <patch.txt>")
		os.Exit(1)
	}
	var filesList, patchPath string
	for i, arg := range os.Args {
		if arg == "--files" && i+1 < len(os.Args) {
			filesList = os.Args[i+1]
		}
		if arg == "--patch" && i+1 < len(os.Args) {
			patchPath = os.Args[i+1]
		}
	}
	if filesList == "" || patchPath == "" {
		fmt.Println("Fichier de liste ou patch manquant.")
		os.Exit(1)
	}
	_, err := ioutil.ReadFile(patchPath)
	if err != nil {
		fmt.Printf("Erreur lecture patch: %v\n", err)
		os.Exit(1)
	}
	files, err := ioutil.ReadFile(filesList)
	if err != nil {
		fmt.Printf("Erreur lecture liste: %v\n", err)
		os.Exit(1)
	}
	for _, line := range strings.Split(string(files), "\n") {
		file := strings.TrimSpace(line)
		if file == "" {
			continue
		}
		cmd := fmt.Sprintf("go run %s/diffedit.go --file %s --patch %s", filepath.Dir(os.Args[0]), file, patchPath)
		fmt.Printf("[BATCH] Patch sur %s...\n", file)
		os.Stdout.Sync()
		os.Stderr.Sync()
		// Appel du CLI Go natif (simple, sans gestion avancée d’erreur ici)
		cmdExec := exec.Command("powershell", "-Command", cmd)
		err = cmdExec.Run()
		if err != nil {
			fmt.Printf("Erreur exécution commande: %v\n", err)
		}
	}
	fmt.Println("Batch terminé.")
}
