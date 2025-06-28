
package main

import (
	"fmt"
)

func main() {
	fmt.Println("# Analyse d'écart de read_file")
	fmt.Println("")
	fmt.Println("| Besoin utilisateur | Couvert par l'existant | Priorité | Suggestion |")
	fmt.Println("|---|---|---|---|")
	fmt.Println("| Lecture de larges fichiers | Partiellement | Haute | Implémenter la lecture par blocs |")
	fmt.Println("| Navigation dans le fichier | Non | Haute | Ajouter des fonctions de navigation (next/prev) |")
	fmt.Println("| Détection de type de fichier | Non | Moyenne | Ajouter la détection binaire/texte |")
}
