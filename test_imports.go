package main

import (
	"fmt"

	"github.com/email-sender/tools/core/toolkit"
	"github.com/email-sender/tools/operations/validation"
	toolkitpkg "github.com/email-sender/tools/pkg/toolkit"
)

func main() {
	fmt.Println("Testing imports...")
	fmt.Printf("toolkit: %T\n", &toolkit.ToolkitConfig{})
	fmt.Printf("validation: %T\n", &validation.StructValidator{})
	fmt.Printf("toolkitpkg: %T\n", &toolkitpkg.ManagerToolkit{})
}
