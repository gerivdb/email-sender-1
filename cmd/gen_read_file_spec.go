<<<<<<< HEAD
package cmd
=======
package main
>>>>>>> migration/gateway-manager-v77

import (
	"fmt"
)

func runGenReadFileSpec() {
	fmt.Println("# Spécification fonctionnelle et technique read_file")
	fmt.Println("")
	fmt.Println("## 1. Fonctionnalités")
	fmt.Println("")
	fmt.Println("| ID | Fonctionnalité | Description |")
	fmt.Println("|---|---|---|")
	fmt.Println("| F-01 | Lecture par plage | Lire un fichier par blocs de lignes (ex: 1-100, 101-200) |")
	fmt.Println("| F-02 | Navigation | Se déplacer au début, à la fin, au bloc suivant/précédent |")
	fmt.Println("| F-03 | Détection binaire | Identifier si un fichier est binaire pour éviter de l'afficher |")
	fmt.Println("| F-04 | Preview binaire | Afficher un aperçu hexadécimal des fichiers binaires |")
	fmt.Println("")
	fmt.Println("## 2. API")
	fmt.Println("")
	fmt.Println("```go")
	fmt.Println("// pkg/common/read_file.go")
	fmt.Println("package common")
	fmt.Println("")
	fmt.Println("func ReadFileRange(path string, start, end int) ([]string, error)")
	fmt.Println("func IsBinaryFile(path string) (bool, error)")
	fmt.Println("func PreviewHex(path string, start, end int) ([]byte, error)")
	fmt.Println("```")
}

func main() {
	runGenReadFileSpec()
}
