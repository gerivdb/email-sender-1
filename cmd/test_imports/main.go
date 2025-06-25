package main

import (
	"fmt"

	"github.com/gerivdb/email-sender-1/tools/core/toolkit"
	"github.com/gerivdb/email-sender-1/tools/operations/validation"
	toolkitpkg "github.com/gerivdb/email-sender-1/tools/pkg/manager"
)

func main() {
	fmt.Println("Testing imports...")
	fmt.Printf("toolkit: %T\n", &toolkit.ToolkitConfig{})
	fmt.Printf("validation: %T\n", &validation.StructValidator{})
	fmt.Printf("toolkitpkg: %T\n", &toolkitpkg.ManagerToolkit{})
}
