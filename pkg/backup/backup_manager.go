package backup

import (
	"context"
	"fmt"
	"os"
	"path/filepath"
	"sync"
	"time"
)

// BackupManager gère les sauvegardes/restaurations automatiques
type BackupManager struct {
	backupDir  string
	interval   time.Duration
	lastBackup time.Time
	mu         sync.Mutex
	stopCh     chan struct{}
}

// NewBackupManager crée un gestionnaire de backup
func NewBackupManager(backupDir string, interval time.Duration) *BackupManager {
	return &BackupManager{
		backupDir: backupDir,
		interval:  interval,
		stopCh:    make(chan struct{}),
	}
}

// Start lance la boucle de sauvegarde automatique
func (bm *BackupManager) Start(ctx context.Context, backupFunc func() ([]byte, error)) {
	go func() {
		ticker := time.NewTicker(bm.interval)
		defer ticker.Stop()
		for {
			select {
			case <-bm.stopCh:
				return
			case <-ticker.C:
				bm.BackupNow(backupFunc)
			}
		}
	}()
}

// Stop arrête la boucle de backup
func (bm *BackupManager) Stop() {
	close(bm.stopCh)
}

// BackupNow effectue une sauvegarde immédiate
func (bm *BackupManager) BackupNow(backupFunc func() ([]byte, error)) error {
	bm.mu.Lock()
	defer bm.mu.Unlock()
	data, err := backupFunc()
	if err != nil {
		return err
	}
	ts := time.Now().Format("20060102_150405")
	filename := filepath.Join(bm.backupDir, fmt.Sprintf("backup_%s.bak", ts))
	if err := os.MkdirAll(bm.backupDir, 0o755); err != nil {
		return err
	}
	if err := os.WriteFile(filename, data, 0o644); err != nil {
		return err
	}
	bm.lastBackup = time.Now()
	return nil
}

// Restore restaure depuis un fichier de backup
func (bm *BackupManager) Restore(filename string, restoreFunc func([]byte) error) error {
	bm.mu.Lock()
	defer bm.mu.Unlock()
	data, err := os.ReadFile(filename)
	if err != nil {
		return err
	}
	return restoreFunc(data)
}

// ListBackups liste les fichiers de backup disponibles
func (bm *BackupManager) ListBackups() ([]string, error) {
	files, err := filepath.Glob(filepath.Join(bm.backupDir, "backup_*.bak"))
	if err != nil {
		return nil, err
	}
	return files, nil
}

// Example usage (to be integrated in main.go)
/*
func main() {
bm := backup.NewBackupManager("./backups", 1*time.Hour)
bm.Start(context.Background(), func() ([]byte, error) {
  // Serialize state (e.g. jobs, configs, tenants)
  return json.Marshal(state)
})
defer bm.Stop()
}
*/
