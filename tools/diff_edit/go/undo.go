package main

import (
	"fmt"
	"io/ioutil"
	"os"
)

// undo.go : restaure le dernier backup d’un fichier patché par diffedit.go
// Usage : go run undo.go --file <fichier>

func main() {
	if len(os.Args) < 3 || os.Args[1] != "--file" {
		fmt.Println("Usage: go run undo.go --file <fichier>")
		os.Exit(1)
	}
	file := os.Args[2]
	files, err := ioutil.ReadDir(".")
	if err != nil {
		fmt.Printf("Erreur lecture dossier: %v\n", err)
		os.Exit(1)
	}
	var lastBackup string
	for _, f := range files {
		if !f.IsDir() && len(f.Name()) > len(file)+5 && f.Name()[:len(file)] == file && f.Name()[len(file):len(file)+5] == ".bak-" {
			if lastBackup == "" || f.ModTime().After(getFileModTime(lastBackup)) {
				lastBackup = f.Name()
			}
		}
	}
	if lastBackup == "" {
		fmt.Println("Aucun backup trouvé.")
		os.Exit(1)
	}
	data, err := ioutil.ReadFile(lastBackup)
	if err != nil {
		fmt.Printf("Erreur lecture backup: %v\n", err)
		os.Exit(1)
	}
	err = ioutil.WriteFile(file, data, 0644)
	if err != nil {
		fmt.Printf("Erreur restauration: %v\n", err)
		os.Exit(1)
	}
	fmt.Printf("Rollback effectué depuis %s\n", lastBackup)
}

func getFileModTime(name string) (t os.FileInfo) {
	f, _ := os.Stat(name)
	return f
}
