package main

import (
	"testing"
)

func TestSimple(t *testing.T) {
	t.Log("Simple test is running")
	if 1+1 != 2 {
		t.Error("Math is broken")
	}
}
