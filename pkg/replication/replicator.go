package replication

import (
	"context"
	"io"
	"os"
	"path/filepath"
	"sync"
	"time"
)

// Replicator gère la réplication de fichiers (backups, configs) entre régions/sites
type Replicator struct {
	regions  []string // chemins ou endpoints distants
	interval time.Duration
	logger   io.Writer
	stopCh   chan struct{}
	mu       sync.Mutex
}

// NewReplicator crée un replicator multi-région
func NewReplicator(regions []string, interval time.Duration, logger io.Writer) *Replicator {
	return &Replicator{
		regions:  regions,
		interval: interval,
		logger:   logger,
		stopCh:   make(chan struct{}),
	}
}

// Start lance la réplication périodique d’un dossier source vers toutes les régions
func (r *Replicator) Start(ctx context.Context, srcDir string) {
	go func() {
		ticker := time.NewTicker(r.interval)
		defer ticker.Stop()
		for {
			select {
			case <-r.stopCh:
				return
			case <-ticker.C:
				r.replicateAll(srcDir)
			}
		}
	}()
}

// Stop arrête la réplication
func (r *Replicator) Stop() {
	close(r.stopCh)
}

// replicateAll copie tous les fichiers du dossier source vers chaque région
func (r *Replicator) replicateAll(srcDir string) {
	files, err := filepath.Glob(filepath.Join(srcDir, "*"))
	if err != nil {
		r.log("Replication error: " + err.Error())
		return
	}
	for _, region := range r.regions {
		for _, file := range files {
			dst := filepath.Join(region, filepath.Base(file))
			if err := copyFile(file, dst); err != nil {
				r.log("Failed to replicate " + file + " to " + dst + ": " + err.Error())
			}
		}
	}
	r.log("Replication complete for " + srcDir)
}

// copyFile copie un fichier localement (pour S3/GCS, remplacer ici)
func copyFile(src, dst string) error {
	in, err := os.Open(src)
	if err != nil {
		return err
	}
	defer in.Close()
	out, err := os.Create(dst)
	if err != nil {
		return err
	}
	defer out.Close()
	_, err = io.Copy(out, in)
	return err
}

func (r *Replicator) log(msg string) {
	if r.logger != nil {
		r.logger.Write([]byte(time.Now().Format(time.RFC3339) + " " + msg + "\n"))
	}
}

// Example usage:
/*
func main() {
rep := replication.NewReplicator([]string{"./region1", "./region2"}, 10*time.Minute, os.Stdout)
rep.Start(context.Background(), "./backups")
defer rep.Stop()
}
*/
