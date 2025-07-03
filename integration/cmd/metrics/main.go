package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"

	"github.com/gerivdb/email-sender-1/integration" // Adjust module path as needed
)

var (
	collectMetrics bool
	reportMetrics  bool
	outputFormat   string
)

func main() {
	flag.BoolVar(&collectMetrics, "collect", false, "Collect metrics and output as JSON")
	flag.BoolVar(&reportMetrics, "report", false, "Generate a human-readable report")
	flag.StringVar(&outputFormat, "format", "json", "Output format for collected metrics (json, text)")
	flag.Parse()

	manager := integration.NewMetricsManager()

	if collectMetrics {
		metrics, err := manager.Collect()
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error collecting metrics: %v\n", err)
			os.Exit(1)
		}
		if outputFormat == "json" {
			jsonOutput, err := json.Marshal(metrics)
			if err != nil {
				fmt.Fprintf(os.Stderr, "Error marshalling metrics to JSON: %v\n", err)
				os.Exit(1)
			}
			fmt.Println(string(jsonOutput))
		} else {
			fmt.Printf("Quality: %.2f, Coverage: %.2f, Usage: %.2f\n", metrics.Quality, metrics.Coverage, metrics.Usage)
		}
	} else if reportMetrics {
		err := manager.Report()
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error reporting metrics: %v\n", err)
			os.Exit(1)
		}
	} else {
		fmt.Println("Usage: metrics --collect [--format json|text] or metrics --report")
		os.Exit(1)
	}
}
