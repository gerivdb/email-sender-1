package main

import (
	"encoding/csv"
	"fmt"
	"os"
	"time"
)

// Script d'automatisation de la collecte de feedback UX/dev
func main() {
	fmt.Println("Collecte automatisée des feedbacks roadmap SOTA...")
	feedbackFile := "feedback/auto-feedback.csv"
	f, err := os.OpenFile(feedbackFile, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		fmt.Println("Erreur ouverture fichier feedback:", err)
		return
	}
	writer := csv.NewWriter(f)
	defer f.Close()
	defer writer.Flush()
	// Exemple de feedback
	record := []string{
		"dev1",
		"tests",
		"trop lent",
		time.Now().Format(time.RFC3339),
	}
	writer.Write(record)
	fmt.Println("Feedback ajouté à", feedbackFile)
}
