
package cmd

import (
	"fmt"
	"github.com/spf13/cobra"
)

var serveCmd = &cobra.Command{
	Use:   "serve",
	Short: "Start the RAG API server",
	RunE: func(cmd *cobra.Command, args []string) error {
		port, _ := cmd.Flags().GetInt("port")
		host, _ := cmd.Flags().GetString("host")
		
		fmt.Printf("Starting RAG server on %s:%d\n", host, port)
		return nil
	},
}

func init() {
	serveCmd.Flags().IntP("port", "p", 8080, "Server port")
	serveCmd.Flags().StringP("host", "h", "localhost", "Server host")
	rootCmd.AddCommand(serveCmd)
}
