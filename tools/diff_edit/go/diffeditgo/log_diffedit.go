// Go
// Package diffeditgo fournit des outils pour automatiser l'application de patchs.
package diffeditgo

import (
	"fmt"
	"log"
	"os"
	"os/user"
	"time"
)

// LogDiffEdit gère un log avancé pour diffedit.
func LogDiffEdit(action, file, patch string, success bool, errMsg string) {
	u, _ := user.Current()
	timestamp := time.Now().Format("2006-01-02 15:04:05")
	logFile, err := os.OpenFile("diffedit.log", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0o644)
	if err != nil {
		fmt.Printf("Erreur ouverture log: %v\n", err)
		return
	}
	defer logFile.Close()
	logger := log.New(logFile, "", 0)
	status := "OK"
	if !success {
		status = "FAIL"
	}
	logger.Printf("[%s] %s | %s | %s | %s | %s | %s", timestamp, u.Username, action, file, patch, status, errMsg)
}
