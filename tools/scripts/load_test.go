// tools/scripts/load_test.go
package main

import (
	"fmt"
	"time"
)

func main() {
	for i := 0; i < 1000; i++ {
		fmt.Printf("Requête %d envoyée\n", i)
		time.Sleep(10 * time.Millisecond)
	}
}
