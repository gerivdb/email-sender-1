package main

import (
	"bufio"
	"flag"
	"fmt"
	"os"
	// "github.com/gerivdb/email-sender-1/pkg/common"
)

func main() {
	var filePath string
	var blockSize int
	var action string
	var targetBlock int

	flag.StringVar(&filePath, "file", "", "Chemin vers le fichier à lire")
	flag.IntVar(&blockSize, "block-size", 50, "Taille du bloc pour la navigation (en lignes)")
	flag.StringVar(&action, "action", "first", "Action à effectuer: first, next, prev, goto <num>, start, end")
	flag.IntVar(&targetBlock, "block", 1, "Numéro du bloc cible pour l'action 'goto'")

	flag.Parse()

	if filePath == "" {
		fmt.Println("Erreur: Le chemin du fichier est obligatoire. Utilisez --file <chemin>")
		flag.Usage()
		os.Exit(1)
	}

	// Créer un fichier de test si non existant pour faciliter les tests
	// err := common.CreateLargeTestFile(filePath, 1000) // Crée un fichier de 1000 lignes
	if err != nil {
		fmt.Printf("Erreur lors de la création du fichier de test: %v\n", err)
	}

	// Obtenir le nombre total de lignes pour les actions 'end' et 'goto'
	totalLines, err := countLines(filePath)
	if err != nil {
		fmt.Printf("Erreur lors du comptage des lignes du fichier: %v\n", err)
		os.Exit(1)
	}
	totalPages := (totalLines + blockSize - 1) / blockSize

	currentBlock := 1 // Initialiser le bloc courant

	// Simuler la gestion de l'état du bloc courant si on était dans une session interactive
	// Pour cette implémentation simple, on se base sur l'action demandée.
	switch action {
	case "first", "start":
		currentBlock = 1
	case "next":
		// Dans une vraie CLI interactive, on lirait l'état précédent. Ici, on simule 2.
		currentBlock = 2 // Placeholder: assume we were at block 1
	case "prev":
		// Dans une vraie CLI interactive, on lirait l'état précédent. Ici, on simule 1.
		currentBlock = 1 // Placeholder: assume we were at block 2
	case "goto":
		currentBlock = targetBlock
	case "end":
		currentBlock = totalPages
	default:
		fmt.Println("Action non reconnue. Utilisez: first, next, prev, goto <num>, start, end")
		flag.Usage()
		os.Exit(1)
	}

	if currentBlock < 1 {
		currentBlock = 1
	}
	if currentBlock > totalPages {
		currentBlock = totalPages
	}

	startLine := (currentBlock-1)*blockSize + 1
	endLine := currentBlock * blockSize

	// lines, err := common.ReadFileRange(filePath, startLine, endLine)
	// 	if err != nil {
	// 		fmt.Printf("Erreur lors de la lecture du fichier: %v\n", err)
	// 		os.Exit(1)
	// 	}

	fmt.Printf("--- Affichage du Bloc %d/%d (Lignes %d-%d) ---\n", currentBlock, totalPages, startLine, endLine)
	// for _, line := range lines {
	// 	fmt.Println(line)
	// }
	fmt.Println("--- Fin du Bloc ---")
}

// countLines compte le nombre total de lignes dans un fichier.
func countLines(filePath string) (int, error) {
	file, err := os.Open(filePath)
	if err != nil {
		return 0, err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	count := 0
	for scanner.Scan() {
		count++
	}
	return count, scanner.Err()
}
