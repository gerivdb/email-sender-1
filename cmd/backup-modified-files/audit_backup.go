// cmd/backup-modified-files/audit_backup.go
// Audit de cohérence des backups, logs, notifications et synchronisation Roo/Kilo

package main

import (
	"fmt"
	"os"
)

func AuditBackup() {
	files := []string{
		"besoins.json.bak", "specs.json.bak", "module-output.json.bak", "reporting.md.bak", "rollback.log",
	}
	missing := 0
	for _, f := range files {
		if _, err := os.Stat(f); err != nil {
			fmt.Printf("Manquant : %s\n", f)
			missing++
		} else {
			fmt.Printf("Présent : %s\n", f)
		}
	}
	if missing == 0 {
		fmt.Println("Audit OK : tous les backups et logs sont présents.")
	} else {
		fmt.Printf("Audit incomplet : %d fichiers manquants.\n", missing)
	}
	fmt.Println("Vérifier la notification Kilo Code et la synchronisation Roo/Kilo.")
}
