// Package diffeditgo provides tools for batch diff editing and monitoring.
package diffeditgo

import (
	"errors"
	"fmt"
	"log"
	"os"
	"os/exec"
	"runtime"
	"strings"
	"time"
)

var (
	ErrScriptPathUnsafe   = errors.New("scriptPath contient des caractères non sécurisés")
	ErrPythonScriptFailed = errors.New("échec de l'exécution du script Python")
	ErrGetMemWindowsOnly  = errors.New("getMem est supporté uniquement sur Windows")
)

// MonitorDiffEdit exécute le script Python diff_edit.py et mesure les performances (CPU/mémoire).
func MonitorDiffEdit(scriptPath string, fileArg, patchArg string, dryRun bool) error {
	log.Println("# Monitoring ressources diff Edit (Go natif)")

	cpu := runtime.NumCPU()
	log.Printf("- CPU logiques disponibles : %d\n", cpu)

	memBefore, err := getMem()
	if err != nil {
		log.Printf("- Mémoire avant batch : Erreur de mesure (%v)\n", err)
	} else {
		log.Printf("- Mémoire avant batch : %s octets\n", memBefore)
	}

	t0 := time.Now()

	// Validation basique du chemin scriptPath (G204)
	if strings.Contains(scriptPath, "..") || strings.ContainsAny(scriptPath, `\/:*?"<>|&;`) {
		return ErrScriptPathUnsafe
	}

	cmdArgs := []string{scriptPath, "--file", fileArg, "--patch", patchArg}
	if dryRun {
		cmdArgs = append(cmdArgs, "--dry-run")
	}

	cmd := exec.Command("python3", cmdArgs...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr

	runErr := cmd.Run()
	if runErr != nil {
		return fmt.Errorf("%w: %v", ErrPythonScriptFailed, runErr)
	}

	t1 := time.Now()

	var memAfter string

	memAfter, err = getMem()
	if err != nil {
		log.Printf("- Mémoire après batch : Erreur de mesure (%v)\n", err)
	} else {
		log.Printf("- Mémoire après batch : %s octets\n", memAfter)
	}
	log.Printf("- Durée batch : %v\n", t1.Sub(t0))

	return nil
}

// getMem récupère l'utilisation mémoire du processus actuel via PowerShell (Windows uniquement).
func getMem() (string, error) {
	if runtime.GOOS != "windows" {
		return "N/A", errors.New("getMem est supporté uniquement sur Windows")
	}

	out, err := exec.Command("powershell", "-Command", "Get-Process -Id $PID | Select-Object -ExpandProperty WorkingSet").Output()
	if err != nil {
		return "N/A", err
	}
	return strings.TrimSpace(string(out)), nil
}
