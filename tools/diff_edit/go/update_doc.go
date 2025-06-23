package main

import (
	"fmt"
	"os/exec"
)

// Ce script Go natif génère un changelog de documentation à partir des derniers commits Git
// et l'affiche en sortie standard. Il peut être adapté pour écrire dans un fichier markdown.

func main() {
	cmd := exec.Command("git", "log", "--pretty=format:- %ad : %s", "--date=short", "--", "tools/diff_edit/README.md", "tools/diff_edit/MODULES_EXTENSIONS.md", "tools/diff_edit/FAQ_PROBLEMES.md")
	output, err := cmd.CombinedOutput()
	if err != nil {
		fmt.Println("Erreur lors de l'exécution de git log:", err)
		return
	}
	fmt.Println("# Historique des mises à jour de la documentation\n")
	fmt.Println(string(output))
}
