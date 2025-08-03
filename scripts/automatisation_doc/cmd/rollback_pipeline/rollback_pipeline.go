// rollback_pipeline.go
//
// Script Roo pour restaurer un pipeline documentaire YAML à partir de sa sauvegarde `.bak`.
// Respecte le pattern manager/agent Roo. Gère l’intégrité, les logs, et les erreurs.
//
// Exemple d’utilisation :
//   go run rollback_pipeline.go --pipeline scripts/automatisation_doc/mon_pipeline.yaml
//
// # Entrée :
//   --pipeline : chemin du fichier pipeline YAML à restaurer.
//
// # Fonctionnement :
//   - Vérifie l’existence du fichier cible et de sa sauvegarde `.bak`.
//   - Vérifie l’intégrité de la sauvegarde (lecture, non vide, extension .bak).
//   - Remplace le pipeline YAML par sa version `.bak` (copie atomique).
//   - Génère un log d’opération (succès/échec, timestamp, chemin, message d’erreur).
//   - Affiche le résultat sur la sortie standard.
//
// # Log généré :
//   rollback_pipeline.log (dans le même dossier que le pipeline)
//
// # Auteur : Roo Code – PipelineManager/ScriptManager
// # Licence : Roo Code Project

package main

import (
	"fmt"
	"io"
	"os"
	"path/filepath"
	"time"
)

// LogEntry structure Roo pour journaliser chaque opération de rollback.
type LogEntry struct {
	Timestamp string `json:"timestamp"`
	Pipeline  string `json:"pipeline"`
	Backup    string `json:"backup"`
	Status    string `json:"status"`
	ErrorMsg  string `json:"error,omitempty"`
}

// restorePipeline restaure le pipeline à partir de la sauvegarde .bak.
func restorePipeline(pipelinePath string) error {
	backupPath := pipelinePath + ".bak"
	logPath := filepath.Join(filepath.Dir(pipelinePath), "rollback_pipeline.log")

	entry := LogEntry{
		Timestamp: time.Now().Format(time.RFC3339),
		Pipeline:  pipelinePath,
		Backup:    backupPath,
		Status:    "STARTED",
	}

	// Vérification existence pipeline et .bak
	if _, err := os.Stat(pipelinePath); err != nil {
		entry.Status = "FAIL"
		entry.ErrorMsg = fmt.Sprintf("Fichier pipeline introuvable: %v", err)
		appendLog(logPath, entry)
		return fmt.Errorf(entry.ErrorMsg)
	}
	if _, err := os.Stat(backupPath); err != nil {
		entry.Status = "FAIL"
		entry.ErrorMsg = fmt.Sprintf("Fichier backup introuvable: %v", err)
		appendLog(logPath, entry)
		return fmt.Errorf(entry.ErrorMsg)
	}

	// Vérification intégrité .bak (non vide)
	info, err := os.Stat(backupPath)
	if err != nil || info.Size() == 0 {
		entry.Status = "FAIL"
		entry.ErrorMsg = "Le fichier .bak est vide ou inaccessible"
		appendLog(logPath, entry)
		return fmt.Errorf(entry.ErrorMsg)
	}

	// Copie atomique du .bak vers le pipeline
	src, err := os.Open(backupPath)
	if err != nil {
		entry.Status = "FAIL"
		entry.ErrorMsg = fmt.Sprintf("Erreur ouverture .bak: %v", err)
		appendLog(logPath, entry)
		return fmt.Errorf(entry.ErrorMsg)
	}
	defer src.Close()

	tmpPath := pipelinePath + ".tmp"
	dst, err := os.Create(tmpPath)
	if err != nil {
		entry.Status = "FAIL"
		entry.ErrorMsg = fmt.Sprintf("Erreur création temporaire: %v", err)
		appendLog(logPath, entry)
		return fmt.Errorf(entry.ErrorMsg)
	}

	if _, err := io.Copy(dst, src); err != nil {
		dst.Close()
		entry.Status = "FAIL"
		entry.ErrorMsg = fmt.Sprintf("Erreur copie: %v", err)
		appendLog(logPath, entry)
		os.Remove(tmpPath)
		return fmt.Errorf(entry.ErrorMsg)
	}
	dst.Close()

	// Remplacement atomique
	if err := os.Rename(tmpPath, pipelinePath); err != nil {
		entry.Status = "FAIL"
		entry.ErrorMsg = fmt.Sprintf("Erreur remplacement pipeline: %v", err)
		appendLog(logPath, entry)
		os.Remove(tmpPath)
		return fmt.Errorf(entry.ErrorMsg)
	}

	entry.Status = "SUCCESS"
	appendLog(logPath, entry)
	return nil
}

// appendLog ajoute une entrée de log JSONL dans le fichier de log.
func appendLog(logPath string, entry LogEntry) {
	f, err := os.OpenFile(logPath, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Erreur écriture log: %v\n", err)
		return
	}
	defer f.Close()
	fmt.Fprintf(f, "%s\t%s\t%s\t%s\t%s\n", entry.Timestamp, entry.Pipeline, entry.Backup, entry.Status, entry.ErrorMsg)
}
