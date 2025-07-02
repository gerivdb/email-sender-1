package main

import (
	"fmt"
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

func main() {
	runScript("cmd/audit-inventory/main.go")
	runScript("cmd/standards-inventory/main.go")
	runScript("cmd/audit-gap-analysis/main.go")
	runScript("cmd/standards-duplication-check/main.go")
	runScript("cmd/roadmap-indexer/main.go")
	runScript("cmd/cross-doc-inventory/main.go")
}
