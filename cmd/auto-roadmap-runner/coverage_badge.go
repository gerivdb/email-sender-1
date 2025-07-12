// cmd/auto-roadmap-runner/coverage_badge.go
package main

import (
	"fmt"
	"os"
)

func GenerateCoverageBadge(coverage float64) error {
	badge := fmt.Sprintf("![Coverage](https://img.shields.io/badge/coverage-%.1f%%25-brightgreen)\n", coverage)
	f, err := os.OpenFile("projet/roadmaps/plans/consolidated/coverage_badge.md", os.O_CREATE|os.O_WRONLY|os.O_TRUNC, 0o644)
	if err != nil {
		return err
	}
	defer f.Close()
	_, err = f.WriteString(badge)
	return err
}
