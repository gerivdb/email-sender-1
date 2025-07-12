// Go
// Package diffeditgo fournit des outils pour automatiser l'application de patchs.
package diffeditgo

import (
	"fmt"
	"os"
	"os/exec"
	"runtime"
	"strings"
	"time"
)

// MonitorDiffEdit exécute le script Python diff_edit.py et mesure les performances (CPU/mémoire).
func MonitorDiffEdit(scriptPath string, fileArg, patchArg string, dryRun bool) error {
	fmt.Println("# Monitoring ressources diff Edit (Go natif)")

	cpu := runtime.NumCPU()
	fmt.Printf("- CPU logiques disponibles : %d\n", cpu)

	memBefore, err := getMem()
	if err != nil {
		fmt.Printf("- Mémoire avant batch : Erreur de mesure (%v)\n", err)
	} else {
		fmt.Printf("- Mémoire avant batch : %s octets\n", memBefore)
	}

	t0 := time.Now()
	cmdArgs := []string{scriptPath, "--file", fileArg, "--patch", patchArg}
	if dryRun {
		cmdArgs = append(cmdArgs, "--dry-run")
	}
	cmd := exec.Command("python3", cmdArgs...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("échec de l'exécution du script Python : %v", err)
	}
	t1 := time.Now()

	var memAfter string
	memAfter, err = getMem()
	if err != nil {
		fmt.Printf("- Mémoire après batch : Erreur de mesure (%v)\n", err)
	} else {
		fmt.Printf("- Mémoire après batch : %s octets\n", memAfter)
	}
	fmt.Printf("- Durée batch : %v\n", t1.Sub(t0))

	return nil
}

// getMem récupère l'utilisation mémoire du processus actuel via PowerShell (Windows uniquement).
func getMem() (string, error) {
	if runtime.GOOS != "windows" {
		return "N/A", fmt.Errorf("getMem est supporté uniquement sur Windows")
	}
	out, err := exec.Command("powershell", "-Command", "Get-Process -Id $PID | Select-Object -ExpandProperty WorkingSet").Output()
	if err != nil {
		return "N/A", err
	}
	return strings.TrimSpace(string(out)), nil
}
