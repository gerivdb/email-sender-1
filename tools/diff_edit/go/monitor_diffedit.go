package go

import (
	"fmt"
	"os/exec"
	"runtime"
	"time"
)

// monitor_diffedit.go : logge l’utilisation CPU/mémoire avant/après un batch diff Edit
func main() {
	fmt.Println("# Monitoring ressources diff Edit (Go natif)")
	cpu := runtime.NumCPU()
	fmt.Printf("- CPU logiques disponibles : %d\n", cpu)
	memBefore := getMem()
	fmt.Printf("- Mémoire avant batch : %s\n", memBefore)
	t0 := time.Now()
	// ... ici lancer le batch diff Edit ...
	t1 := time.Now()
	memAfter := getMem()
	fmt.Printf("- Mémoire après batch : %s\n", memAfter)
	fmt.Printf("- Durée batch : %v\n", t1.Sub(t0))
}

func getMem() string {
	out, err := exec.Command("powershell", "Get-Process -Id $PID | Select-Object -ExpandProperty WorkingSet").Output()
	if err != nil {
		return "N/A"
	}
	return string(out)
}
