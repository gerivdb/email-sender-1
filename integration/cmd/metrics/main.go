package main

import (
	"encoding/json" // Import for JSON encoding
	"flag"
	"fmt"
	"log"

	"github.com/gerivdb/email-sender-1/integration" // Adjust module path as needed
)

func main() {
	collectMetrics := flag.Bool("collect", false, "Collect metrics")
	reportMetrics := flag.Bool("report", false, "Report metrics")
	flag.Parse()

	metricsManager := &integration.MetricsManager{}

	if *collectMetrics {
		metrics, err := metricsManager.Collect()
		if err != nil {
			log.Fatalf("Error collecting metrics: %v", err)
		}
		// Output metrics as JSON to stdout for the Python script to parse
		jsonBytes, err := json.Marshal(metrics)
		if err != nil {
			log.Fatalf("Error marshalling metrics to JSON: %v", err)
		}
		fmt.Println(string(jsonBytes))
	} else if *reportMetrics {
		err := metricsManager.Report()
		if err != nil {
			log.Fatalf("Error reporting metrics: %v", err)
		}
	} else {
		fmt.Println("No action specified. Use --collect or --report.")
	}
}
