package logging

import (
	"os"
	"path/filepath"
	"time"
)

// PurgeOldLogs supprime les fichiers de logs/audit plus vieux que retention
func PurgeOldLogs(logDir string, retention time.Duration) error {
	cutoff := time.Now().Add(-retention)
	files, err := filepath.Glob(filepath.Join(logDir, "*.log"))
	if err != nil {
		return err
	}
	for _, file := range files {
		info, err := os.Stat(file)
		if err != nil {
			continue
		}
		if info.ModTime().Before(cutoff) {
			_ = os.Remove(file)
		}
	}
	return nil
}

// Example usage:
/*
func main() {
err := logging.PurgeOldLogs("./logs", 30*24*time.Hour) // 30 jours
if err != nil {
fmt.Println("Purge error:", err)
}
}
*/
