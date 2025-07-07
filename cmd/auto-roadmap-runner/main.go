package main

import (
	"fmt"
	"log"
	"os/exec"
)

func runScript(name string, args ...string) {
	fmt.Printf("=== %s ===\n", name)
	cmd := exec.Command("go", append([]string{"run", name}, args...)...)
	out, err := cmd.CombinedOutput()
	fmt.Println(string(out))
	if err != nil {
		fmt.Printf("Erreur lors de l'exécution de %s: %v\n", name, err)
	}
}

func runAutoRoadmap() {
	runScript("cmd/audit-inventory")
	runScript("cmd/standards-inventory")
	runScript("cmd/audit-gap-analysis")
	runScript("cmd/standards-duplication-check")
	runScript("cmd/roadmap-indexer")
	runScript("cmd/cross-doc-inventory")
}

func main() {
	log.Println("cmd/auto-roadmap-runner/main.go: main() called")
	runAutoRoadmap()
}
