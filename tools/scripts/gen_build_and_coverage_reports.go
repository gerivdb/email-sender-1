// tools/scripts/gen_build_and_coverage_reports.go
package main

import (
	"fmt"
	"os"
	"os/exec"
)

func main() {
	fmt.Println("=== Génération du rapport de build ===")
	build := exec.Command("go", "build", "./...")
	build.Stdout = os.Stdout
	build.Stderr = os.Stderr
	if err := build.Run(); err != nil {
		fmt.Println("Erreur de build :", err)
		os.Exit(1)
	}
	fmt.Println("Build réussi.")

	fmt.Println("\n=== Génération du rapport de couverture ===")
	test := exec.Command("go", "test", "./...", "-coverprofile=coverage.out")
	test.Stdout = os.Stdout
	test.Stderr = os.Stderr
	if err := test.Run(); err != nil {
		fmt.Println("Erreur lors des tests :", err)
		os.Exit(1)
	}
	cover := exec.Command("go", "tool", "cover", "-html=coverage.out", "-o", "coverage_report.html")
	cover.Stdout = os.Stdout
	cover.Stderr = os.Stderr
	if err := cover.Run(); err != nil {
		fmt.Println("Erreur lors de la génération du rapport HTML :", err)
		os.Exit(1)
	}
	fmt.Println("Rapport de couverture généré : coverage_report.html")
}
