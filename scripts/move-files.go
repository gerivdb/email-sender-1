// move-files.go
// Auteur : Roo (IA)
// Version : 1.0
// Date : 2025-08-01
// Description : Script Go pour déplacer des fichiers selon une config YAML, avec dry-run, rollback, log/audit.
// Usage : go run move-files.go [-config file-moves.yaml] [-dry-run] [-rollback] [-log move-files.log]

package main

import (
	"flag"
	"fmt"
	"io"
	"os"
	"time"

	"gopkg.in/yaml.v3" // Dépendance standard Go pour YAML (go get gopkg.in/yaml.v3)
)

type Move struct {
	Source      string `yaml:"source"`
	Destination string `yaml:"destination"`
}
type Config struct {
	Moves []Move `yaml:"moves"`
}

var (
	configPath string
	dryRun     bool
	rollback   bool
	logPath    string
)

func init() {
	flag.StringVar(&configPath, "config", "file-moves.yaml", "Chemin du fichier de configuration YAML")
	flag.BoolVar(&dryRun, "dry-run", false, "Simulation sans déplacement effectif")
	flag.BoolVar(&rollback, "rollback", false, "Annule les déplacements précédents")
	flag.StringVar(&logPath, "log", "move-files.log", "Fichier de log")
}

func writeLog(msg string) {
	f, err := os.OpenFile(logPath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur ouverture log: %v\n", err)
		return
	}
	defer f.Close()
	logLine := fmt.Sprintf("%s %s\n", time.Now().Format(time.RFC3339), msg)
	f.WriteString(logLine)
	fmt.Print(logLine)
}

func doMove(src, dst string) {
	if dryRun {
		writeLog(fmt.Sprintf("DRY-RUN : %s => %s", src, dst))
		return
	}
	if _, err := os.Stat(src); err == nil {
		err := os.Rename(src, dst)
		if err != nil {
			writeLog(fmt.Sprintf("ERREUR : move %s => %s : %v", src, dst, err))
		} else {
			writeLog(fmt.Sprintf("MOVE : %s => %s", src, dst))
		}
	} else {
		writeLog(fmt.Sprintf("ERREUR : Source introuvable %s", src))
	}
}

func doRollback() {
	f, err := os.Open(logPath)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur ouverture log rollback: %v\n", err)
		return
	}
	defer f.Close()
	var lines []string
	buf := make([]byte, 4096)
	for {
		n, err := f.Read(buf)
		if n > 0 {
			lines = append(lines, string(buf[:n]))
		}
		if err == io.EOF {
			break
		}
		if err != nil {
			fmt.Fprintf(os.Stderr, "Erreur lecture log: %v\n", err)
			return
		}
	}
	for _, line := range lines {
		var src, dst string
		_, err := fmt.Sscanf(line, "%s MOVE : %s => %s", new(string), &src, &dst)
		if err == nil {
			// rollback = move dst => src
			if _, err := os.Stat(dst); err == nil {
				os.Rename(dst, src)
				writeLog(fmt.Sprintf("ROLLBACK : %s => %s", dst, src))
			}
		}
	}
}

func main() {
	flag.Parse()
	writeLog("=== Début du script move-files.go ===")
	if rollback {
		doRollback()
		writeLog("Rollback terminé.")
		return
	}
	f, err := os.Open(configPath)
	if err != nil {
		writeLog(fmt.Sprintf("ERREUR : ouverture config %s : %v", configPath, err))
		os.Exit(1)
	}
	defer f.Close()
	var cfg Config
	dec := yaml.NewDecoder(f)
	if err := dec.Decode(&cfg); err != nil {
		writeLog(fmt.Sprintf("ERREUR : parsing YAML : %v", err))
		os.Exit(1)
	}
	if len(cfg.Moves) == 0 {
		writeLog("ERREUR : Section 'moves' manquante ou vide.")
		os.Exit(1)
	}
	for _, mv := range cfg.Moves {
		doMove(mv.Source, mv.Destination)
	}
	writeLog("=== Fin du script move-files.go ===")
}
