// Package main est le point d'entrée pour l'outil de monitoring des patchs.
package main

import (
	"fmt"
	"os"

	"github.com/gerivdb/email-sender-1/tools/diff_edit/go/diffeditgo"
)

func main() {
	if len(os.Args) < 3 {
		fmt.Println("Usage: monitor_diffedit <file> <patch> [--dry-run]")
		os.Exit(1)
	}

	fileArg := os.Args[1]
	patchArg := os.Args[2]
	dryRun := len(os.Args) > 3 && os.Args[3] == "--dry-run"

	if err := diffeditgo.MonitorDiffEdit("diff_edit.py", fileArg, patchArg, dryRun); err != nil {
		fmt.Fprintf(os.Stderr, "Erreur: %v\n", err)
		os.Exit(1)
	}
}
