package main

import (
	"encoding/json"
	"fmt"
	"os"

	"github.com/gerivdb/email-sender-1/integration"

	"github.com/spf13/cobra"
)

var (
	baseURL     string
	username    string
	password    string
	sourcePath  string
	forceUpdate bool
	docID       string
	content     string
)

func main() {
	rootCmd := &cobra.Command{
		Use:   "docmanager-cli",
		Short: "CLI pour interagir avec le Doc Manager",
		Long:  `Une interface en ligne de commande pour authentifier, synchroniser et mettre à jour la documentation via l'API du Doc Manager.`,
	}

	rootCmd.PersistentFlags().StringVarP(&baseURL, "base-url", "u", "http://localhost:8080", "URL de base de l'API du Doc Manager")
	rootCmd.PersistentFlags().StringVarP(&username, "username", "x", "", "Nom d'utilisateur pour l'authentification")
	rootCmd.PersistentFlags().StringVarP(&password, "password", "p", "", "Mot de passe pour l'authentification")

	// Commandes
	rootCmd.AddCommand(authCmd)
	rootCmd.AddCommand(syncCmd)
	rootCmd.AddCommand(updateCmd)

	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Erreur: %v\n", err)
		os.Exit(1)
	}
}

var authCmd = &cobra.Command{
	Use:   "auth",
	Short: "Authentifie l'utilisateur auprès du Doc Manager",
	Run: func(cmd *cobra.Command, args []string) {
		client := integration.NewDocManagerClient(baseURL)
		manager := integration.NewDocManager(client, baseURL, username, password)
		err := manager.Authenticate(username, password)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Erreur d'authentification: %v\n", err)
			return
		}
		fmt.Println("Authentification réussie.")
	},
}

var syncCmd = &cobra.Command{
	Use:   "sync",
	Short: "Synchronise la documentation",
	Run: func(cmd *cobra.Command, args []string) {
		client := integration.NewDocManagerClient(baseURL)
		manager := integration.NewDocManager(client, baseURL, username, password)
		err := manager.SyncDocs(sourcePath, forceUpdate)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Erreur de synchronisation: %v\n", err)
			return
		}
		fmt.Println("Synchronisation terminée.")
	},
}

var updateCmd = &cobra.Command{
	Use:   "update [doc-id]",
	Short: "Met à jour un document spécifique",
	Args:  cobra.ExactArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		docID = args[0]
		var docContent map[string]interface{}
		err := json.Unmarshal([]byte(content), &docContent)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Erreur de parsing du contenu du document: %v\n", err)
			return
		}

		client := integration.NewDocManagerClient(baseURL)
		manager := integration.NewDocManager(client, baseURL, username, password)
		err = manager.TriggerUpdate(docID, docContent)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Erreur de mise à jour: %v\n", err)
			return
		}
		fmt.Println("Mise à jour du document terminée.")
	},
}

func init() {
	syncCmd.Flags().StringVarP(&sourcePath, "source-path", "s", "./docs", "Chemin source de la documentation à synchroniser")
	syncCmd.Flags().BoolVarP(&forceUpdate, "force-update", "f", false, "Forcer la mise à jour même si aucune modification n'est détectée")

	updateCmd.Flags().StringVarP(&content, "content", "c", "{}", "Contenu du document au format JSON")
}
