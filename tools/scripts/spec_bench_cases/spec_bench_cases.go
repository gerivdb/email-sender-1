package main

import (
	"fmt"
)

func main() {
	fmt.Println("# Spécification des scénarios de benchmark")
	fmt.Println("- CalculScore : 10k entrées, 100k entrées")
	fmt.Println("- TraitementBatch : 100 batchs, 1000 batchs")
	fmt.Println("- ExportCSV : 1Mo, 100Mo, 1Go")
}
