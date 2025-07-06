package main

import (
	"fmt"
	"os"

	"github.com/gerivdb/email-sender-1/core/scanmodules"
)

func main() {
	if len(os.Args) < 2 {
		fmt.Println("Usage: scanmodules <root_dir> [output_file]")
		os.Exit(1)
	}
	root := os.Args[1]
	output := "init-cartographie-scan.json"
	if len(os.Args) > 2 {
		output = os.Args[2]
	}
	modules, err := scanmodules.ScanDir(root)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur lors du scan: %v\n", err)
		os.Exit(2)
	}
	err = scanmodules.ExportModules(modules, output)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur lors de l'export: %v\n", err)
		os.Exit(3)
	}
	fmt.Printf("Scan terminé, voir %s\n", output)
}
