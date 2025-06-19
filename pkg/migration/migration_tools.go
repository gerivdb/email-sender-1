package migration

import (
	"context"
	"encoding/json"
	"fmt"
	"os"
	"time"
)

// MigrationManager gère l'import/export et la migration de données
type MigrationManager struct {
	backupDir string
}

// NewMigrationManager crée un gestionnaire de migration
func NewMigrationManager(backupDir string) *MigrationManager {
	return &MigrationManager{backupDir: backupDir}
}

// ExportData exporte des données arbitraires (ex: jobs, configs, tenants)
func (mm *MigrationManager) ExportData(ctx context.Context, name string, data interface{}) (string, error) {
	ts := time.Now().Format("20060102_150405")
	filename := fmt.Sprintf("%s/export_%s_%s.json", mm.backupDir, name, ts)
	f, err := os.Create(filename)
	if err != nil {
		return "", err
	}
	defer f.Close()
	enc := json.NewEncoder(f)
	enc.SetIndent("", "  ")
	if err := enc.Encode(data); err != nil {
		return "", err
	}
	return filename, nil
}

// ImportData importe des données arbitraires dans la structure cible
func (mm *MigrationManager) ImportData(ctx context.Context, filename string, target interface{}) error {
	f, err := os.Open(filename)
	if err != nil {
		return err
	}
	defer f.Close()
	dec := json.NewDecoder(f)
	if err := dec.Decode(target); err != nil {
		return err
	}
	return nil
}

// ListExports liste les fichiers d'export disponibles
func (mm *MigrationManager) ListExports() ([]string, error) {
	files, err := os.ReadDir(mm.backupDir)
	if err != nil {
		return nil, err
	}
	result := make([]string, 0)
	for _, f := range files {
		if !f.IsDir() && (len(f.Name()) > 7 && f.Name()[:7] == "export_") {
			result = append(result, f.Name())
		}
	}
	return result, nil
}

// Example usage:
/*
func main() {
mm := migration.NewMigrationManager("./backups")
jobs := []Job{...}
file, _ := mm.ExportData(context.Background(), "jobs", jobs)
var importedJobs []Job
mm.ImportData(context.Background(), file, &importedJobs)
}
*/
