package main

import (
	"encoding/json"
	"fmt"
	"os"

	"github.com/gerivdb/email-sender-1/integration" // Adjust this import path if necessary
	"github.com/spf13/cobra"
)

var scanPath string

func main() {
	rootCmd := &cobra.Command{
		Use:   "langscanner",
		Short: "Scanne les répertoires pour détecter les types de projets",
		Long:  `Un outil CLI qui scanne un chemin spécifié et identifie les projets Go, Python, Node.js, PowerShell, etc.`,
		Run: func(cmd *cobra.Command, args []string) {
			scanner := integration.NewLangScanner()
			projects, err := scanner.Scan(scanPath)
			if err != nil {
				fmt.Fprintf(os.Stderr, "Erreur lors du scan: %v\n", err)
				os.Exit(1)
			}

			// Output projects as JSON
			jsonOutput, err := json.MarshalIndent(projects, "", "  ")
			if err != nil {
				fmt.Fprintf(os.Stderr, "Erreur lors de la sérialisation JSON: %v\n", err)
				os.Exit(1)
			}
			fmt.Println(string(jsonOutput))
		},
	}

	rootCmd.Flags().StringVarP(&scanPath, "path", "p", ".", "Chemin du répertoire à scanner")

	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Erreur: %v\n", err)
		os.Exit(1)
	}
}
