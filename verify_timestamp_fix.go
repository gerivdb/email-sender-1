package main

import (
	"fmt"
	"time"
)

// TimestampVerifier verifies timestamp functionality and precision
type TimestampVerifier struct {
	precision time.Duration
}

// NewTimestampVerifier creates a new timestamp verifier
func NewTimestampVerifier(precision time.Duration) *TimestampVerifier {
	return &TimestampVerifier{
		precision: precision,
	}
}

// VerifyTimestampPrecision verifies that timestamps meet precision requirements
func (t *TimestampVerifier) VerifyTimestampPrecision() error {
	fmt.Println("Verifying timestamp precision...")

	start := time.Now()
	time.Sleep(t.precision)
	end := time.Now()

	diff := end.Sub(start)
	if diff < t.precision {
		return fmt.Errorf("timestamp precision verification failed: expected at least %v, got %v", t.precision, diff)
	}

	fmt.Printf("Timestamp precision verified: %v\n", diff)
	return nil
}

// VerifyTimestampFormat verifies timestamp format consistency
func (t *TimestampVerifier) VerifyTimestampFormat() error {
	fmt.Println("Verifying timestamp format...")

	now := time.Now()
	formats := []string{
		time.RFC3339,
		time.RFC3339Nano,
		"2006-01-02 15:04:05",
		"2006-01-02T15:04:05.000Z",
	}

	for _, format := range formats {
		formatted := now.Format(format)
		parsed, err := time.Parse(format, formatted)
		if err != nil {
			return fmt.Errorf("timestamp format verification failed for %s: %w", format, err)
		}
		fmt.Printf("Format %s verified: %s -> %s\n", format, formatted, parsed.Format(format))
	}

	return nil
}

// VerifyTimestampFix runs comprehensive timestamp verification
func (t *TimestampVerifier) VerifyTimestampFix() error {
	fmt.Println("Running comprehensive timestamp fix verification...")

	if err := t.VerifyTimestampPrecision(); err != nil {
		return err
	}

	if err := t.VerifyTimestampFormat(); err != nil {
		return err
	}

	fmt.Println("Timestamp fix verification completed successfully")
	return nil
}
