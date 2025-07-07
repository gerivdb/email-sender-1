package cmd

import (
	"os"

	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:   "rag",
	Short: "RAG Ultra-Rapid System CLI",
	Long:  "A high-performance Retrieval-Augmented Generation system with QDrant integration",
}

func Execute() {
	err := rootCmd.Execute()
	if err != nil {
		os.Exit(1)
	}
}

func init() {
	rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default is $HOME/.rag.yaml)")
	rootCmd.PersistentFlags().BoolVar(&verbose, "verbose", false, "verbose output")
}

var cfgFile string
var verbose bool
