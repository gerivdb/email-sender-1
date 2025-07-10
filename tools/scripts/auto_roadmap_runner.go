// tools/scripts/auto_roadmap_runner.go
package main

import (
	"fmt"
	"os/exec"
)

func run(cmd string, args ...string) {
	fmt.Printf("\n=== %s %v ===\n", cmd, args)
	c := exec.Command(cmd, args...)
	c.Stdout = nil
	c.Stderr = nil
	err := c.Run()
	if err != nil {
		fmt.Printf("Erreur lors de %s %v : %v\n", cmd, args, err)
	} else {
		fmt.Printf("OK : %s %v\n", cmd, args)
	}
}

func main() {
	run("go", "run", "tools/scripts/list_neutralized.go")
	run("go", "run", "tools/scripts/gap_analysis.go")
	run("go", "run", "tools/scripts/collect_needs.go")
	run("go", "run", "tools/scripts/gen_stub_specs.go")
	run("go", "run", "tools/scripts/gen_stubs.go")
	run("go", "run", "tools/scripts/fix_imports.go")
	run("go", "run", "tools/scripts/gen_tests.go")
	run("go", "run", "tools/scripts/gen_integration_tests.go")
	run("go", "run", "tools/scripts/gen_build_and_coverage_reports.go")
	run("go", "run", "tools/scripts/gen_docs_and_archive.go")
	fmt.Println("\n=== Orchestration complète v101 terminée ===")
}
