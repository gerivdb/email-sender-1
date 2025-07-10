package main

import (
	"fmt"
	"io"
	"os"
)

func main() {
	src := "../../tests/authentification/authentification_test.go"
	dst := "../../tests/authentification/authentification_test.go.bak"
	in, err := os.Open(src)
	if err != nil {
		fmt.Println("Erreur ouverture source:", err)
		return
	}
	defer in.Close()
	out, err := os.Create(dst)
	if err != nil {
		fmt.Println("Erreur création backup:", err)
		return
	}
	defer out.Close()
	_, err = io.Copy(out, in)
	if err != nil {
		fmt.Println("Erreur copie:", err)
		return
	}
	fmt.Println("Backup réalisé avec succès:", dst)
}
