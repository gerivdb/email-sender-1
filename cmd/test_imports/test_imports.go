package test_imports

import (
	"fmt"

	"EMAIL_SENDER_1/tools/core/toolkit"
	"EMAIL_SENDER_1/tools/operations/validation"
	toolkitpkg "EMAIL_SENDER_1/tools/pkg/manager"
)

func main() {
	fmt.Println("Testing imports...")
	fmt.Printf("toolkit: %T\n", &toolkit.ToolkitConfig{})
	fmt.Printf("validation: %T\n", &validation.StructValidator{})
	fmt.Printf("toolkitpkg: %T\n", &toolkitpkg.ManagerToolkit{})
}
