package main

import (
	"bytes"
	"flag"
	"fmt"
	"go/doc"
	"go/parser"
	"go/printer" // Import the printer package
	"go/token"
	"log"
	"os"
	"path/filepath"
	"strings"
)

func main() {
	path := flag.String("path", ".", "Path to the Go package to document")
	outputFile := flag.String("output", "", "Output file for the Markdown documentation (default: stdout)")
	flag.Parse()

	absPath, err := filepath.Abs(*path)
	if err != nil {
		log.Fatalf("Error getting absolute path for %s: %v", *path, err)
	}
	log.Printf("Attempting to parse directory: %s", absPath)

	if *path == "" {
		log.Fatal("Path cannot be empty.")
	}

	fset := token.NewFileSet()
	pkgs, err := parser.ParseDir(fset, *path, func(info os.FileInfo) bool {
		return !strings.HasSuffix(info.Name(), "_test.go")
	}, parser.ParseComments)
	if err != nil {
		log.Fatalf("Error parsing directory %s: %v", *path, err)
	}

	var buf bytes.Buffer
	for _, pkg := range pkgs {
		p := doc.New(pkg, "./", 0)

		buf.WriteString(fmt.Sprintf("# Package %s\n\n", p.Name))
		if p.Doc != "" {
			buf.WriteString(p.Doc + "\n\n")
		}

		// Types
		if len(p.Types) > 0 {
			buf.WriteString("## Types\n\n")
			for _, t := range p.Types {
				buf.WriteString(fmt.Sprintf("### %s\n\n", t.Name))
				if t.Doc != "" {
					buf.WriteString(t.Doc + "\n\n")
				}
				// Methods
				if len(t.Methods) > 0 {
					buf.WriteString("#### Methods\n\n")
					for _, m := range t.Methods {
						buf.WriteString(fmt.Sprintf("##### %s.%s\n\n", t.Name, m.Name))
						if m.Doc != "" {
							buf.WriteString(m.Doc + "\n\n")
						}
						// Use printer to get the correct string representation of the method declaration
						var methodDeclBuf bytes.Buffer
						if err := printer.Fprint(&methodDeclBuf, fset, m.Decl); err != nil {
							log.Printf("Error printing method declaration: %v", err)
							buf.WriteString(fmt.Sprintf("```go\n%s\n```\n\n", m.Name)) // Fallback
						} else {
							buf.WriteString(fmt.Sprintf("```go\n%s\n```\n\n", methodDeclBuf.String()))
						}
					}
				}
			}
		}

		// Functions
		if len(p.Funcs) > 0 {
			buf.WriteString("## Functions\n\n")
			for _, f := range p.Funcs {
				buf.WriteString(fmt.Sprintf("### %s\n\n", f.Name))
				if f.Doc != "" {
					buf.WriteString(f.Doc + "\n\n")
				}
				// Use printer to get the correct string representation of the function declaration
				var funcDeclBuf bytes.Buffer
				if err := printer.Fprint(&funcDeclBuf, fset, f.Decl); err != nil {
					log.Printf("Error printing function declaration: %v", err)
					buf.WriteString(fmt.Sprintf("```go\n%s\n```\n\n", f.Name)) // Fallback
				} else {
					buf.WriteString(fmt.Sprintf("```go\n%s\n```\n\n", funcDeclBuf.String()))
				}
			}
		}

		// Variables
		if len(p.Vars) > 0 {
			buf.WriteString("## Variables\n\n")
			for _, v := range p.Vars {
				buf.WriteString(fmt.Sprintf("### %s\n\n", strings.Join(v.Names, ", ")))
				if v.Doc != "" {
					buf.WriteString(v.Doc + "\n\n")
				}
				// Use printer to get the correct string representation of the variable declaration
				var varDeclBuf bytes.Buffer
				if err := printer.Fprint(&varDeclBuf, fset, v.Decl); err != nil {
					log.Printf("Error printing variable declaration: %v", err)
					buf.WriteString(fmt.Sprintf("```go\n%s\n```\n\n", strings.Join(v.Names, ", "))) // Fallback
				} else {
					buf.WriteString(fmt.Sprintf("```go\n%s\n```\n\n", varDeclBuf.String()))
				}
			}
		}

		// Constants
		if len(p.Consts) > 0 {
			buf.WriteString("## Constants\n\n")
			for _, c := range p.Consts {
				buf.WriteString(fmt.Sprintf("### %s\n\n", strings.Join(c.Names, ", ")))
				if c.Doc != "" {
					buf.WriteString(c.Doc + "\n\n")
				}
				// Use printer to get the correct string representation of the constant declaration
				var constDeclBuf bytes.Buffer
				if err := printer.Fprint(&constDeclBuf, fset, c.Decl); err != nil {
					log.Printf("Error printing constant declaration: %v", err)
					buf.WriteString(fmt.Sprintf("```go\n%s\n```\n\n", strings.Join(c.Names, ", "))) // Fallback
				} else {
					buf.WriteString(fmt.Sprintf("```go\n%s\n```\n\n", constDeclBuf.String()))
				}
			}
		}
	}

	output := buf.Bytes()
	if *outputFile != "" {
		absOutputFile, err := filepath.Abs(*outputFile)
		if err != nil {
			log.Fatalf("Error getting absolute path for output file %s: %v", *outputFile, err)
		}
		log.Printf("Attempting to write documentation to: %s", absOutputFile)

		err = os.WriteFile(*outputFile, output, 0o644)
		if err != nil {
			log.Fatalf("Error writing to output file %s: %v", *outputFile, err)
		}
		fmt.Printf("Documentation written to %s\n", *outputFile)
	} else {
		fmt.Print(string(output))
	}
}
