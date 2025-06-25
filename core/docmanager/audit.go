// core/docmanager/audit.go
// Audit de l’existant pour DocManager v66 Fusion

package docmanager

import (
	"os"
	"path/filepath"
)

type AuditResult struct {
	FilesFound []string
}

func AuditExistingScripts(root string) (AuditResult, error) {
	var result AuditResult
	err := filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if err != nil {
			return err
		}
		if !info.IsDir() && (filepath.Ext(path) == ".go" || filepath.Ext(path) == ".js" || filepath.Ext(path) == ".py" || filepath.Ext(path) == ".md") {
			result.FilesFound = append(result.FilesFound, path)
		}
		return nil
	})
	return result, err
}
