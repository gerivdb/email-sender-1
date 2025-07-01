package avg_test

import (
	"fmt"
	"os"
	"time"
)

func main() {
	fmt.Println("Test d'exclusion AVG pour les fichiers .exe")
	fmt.Println("Compilation réussie à", time.Now().Format("2006-01-02 15:04:05"))

	// Créer un fichier de succès
	successFile := "test_success.txt"
	f, err := os.Create(successFile)
	if err == nil {
		f.WriteString("Compilation et exécution réussies à " + time.Now().Format("2006-01-02 15:04:05"))
		f.Close()
		fmt.Println("Fichier de succès créé:", successFile)
	}
}
