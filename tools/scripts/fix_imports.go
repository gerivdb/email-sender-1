// tools/scripts/fix_imports.go
package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strings"
)

var orphans = []string{
	"github.com/gerivdb/email-sender-1/pkg/common",
	"github.com/gerivdb/email-sender-1/pkg/docmanager",
	"github.com/gerivdb/email-sender-1/tools/operations/validation",
	"github.com/gerivdb/email-sender-1/tools/pkg/manager",
	"github.com/gerivdb/email-sender-1/cmd/roadmap-cli",
	"github.com/email-sender-manager/interfaces",
}

func main() {
	filepath.Walk(".", func(path string, info os.FileInfo, err error) error {
		if strings.HasSuffix(path, ".go") {
			input, _ := os.ReadFile(path)
			lines := strings.Split(string(input), "\n")
			changed := false
			for i, line := range lines {
				for _, orphan := range orphans {
					if strings.Contains(line, orphan) {
						lines[i] = "// [neutralisé] " + line
						changed = true
					}
				}
			}
			if changed {
				output := strings.Join(lines, "\n")
				os.WriteFile(path, []byte(output), 0o644)
				fmt.Println("Imports orphelins neutralisés dans :", path)
			}
		}
		return nil
	})
	fmt.Println("\n*Généré automatiquement par fix_imports.go*")
}
