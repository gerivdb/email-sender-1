package cmd

import (
	"fmt"

	"github.com/spf13/cobra"
)

var indexCmd = &cobra.Command{
	Use:   "index [file]",
	Short: "Index documents into the vector database",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		file := args[0]
		collection, _ := cmd.Flags().GetString("collection")

		fmt.Printf("Indexing file: %s into collection: %s\n", file, collection)
		return nil
	},
}

func init() {
	indexCmd.Flags().StringP("collection", "c", "default", "Target collection")
	rootCmd.AddCommand(indexCmd)
}
