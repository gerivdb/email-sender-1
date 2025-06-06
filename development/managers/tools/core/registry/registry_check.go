package registry

import (
"fmt"
"os"

"github.com/yourusername/email_sender_1/development/managers/tools"
)

func main() {
fmt.Println("Testing tool registry...")
registry := GetGlobalRegistry()
if registry == nil {
fmt.Println("ERROR: Registry is nil")
os.Exit(1)
}

ops := registry.ListOperations()
fmt.Printf("Found %d registered operations\n", len(ops))

for _, op := range ops {
fmt.Printf("- %s\n", op)
}
}


