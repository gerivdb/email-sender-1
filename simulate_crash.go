// simulate_crash.go
package main

import (
	"fmt"
	"os"
	"time"
)

func main() {
	fmt.Println("Simulation d’un crash du service principal...")
	time.Sleep(2 * time.Second)
	fmt.Println("Crash simulé. Service arrêté.")
	os.Exit(1)
}
