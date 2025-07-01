package go

import (
	"fmt"
	"log"
	"os"
	"os/user"
	"time"
)

// log_diffedit.go : log avancé pour diffedit.go (à intégrer dans diffedit.go si besoin)
func logDiffEdit(action, file, patch string, success bool, errMsg string) {
	u, _ := user.Current()
	timestamp := time.Now().Format("2006-01-02 15:04:05")
	logFile, err := os.OpenFile("diffedit.log", os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
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

// Exemple d’appel : logDiffEdit("PATCH", "fichier.md", "patch.txt", true, "")
