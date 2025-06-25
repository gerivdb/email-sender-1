package validation_test

import (
	"fmt"
	"os"

	"github.com/gerivdb/email-sender-1/tools/operations/validation"
)

func main() {
	fmt.Println("Testing basic import...")

	// Try to create a temporary directory
	tempDir, err := os.MkdirTemp("", "test")
	if err != nil {
		fmt.Printf("Error creating temp dir: %v\n", err)
		return
	}
	defer os.RemoveAll(tempDir)

	// Try to create a StructValidator
	validator, err := validation.NewStructValidator(tempDir, nil, false)
	if err != nil {
		fmt.Printf("Error creating StructValidator: %v\n", err)
		return
	}

	fmt.Printf("Success! StructValidator created: %T\n", validator)
}
