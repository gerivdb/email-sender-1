package errormanager

import (
	"fmt"

	"github.com/pkg/errors"
)

// WrapError enriches an error with additional context
func WrapError(err error, message string) error {
	return errors.Wrap(err, message)
}

// TestWrapError simulates an error and tests the WrapError function
func TestWrapError() {
	baseErr := errors.New("base error")
	wrappedErr := WrapError(baseErr, "additional context")
	fmt.Println(wrappedErr)
}
