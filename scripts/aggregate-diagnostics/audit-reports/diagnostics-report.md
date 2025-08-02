# Rapport d’audit automatisé
## Diagnostics Go (golangci-lint)
```
>>> golangci-lint run ./...
scripts\aggregate-diagnostics\aggregate-diagnostics.go:19:20: Error return value of `report.WriteString` is not checked (errcheck)
	report.WriteString(">>> " + name + " " + strings.Join(args, " ") + "\n")
	                  ^
scripts\aggregate-diagnostics\aggregate-diagnostics.go:20:14: Error return value of `report.Write` is not checked (errcheck)
	report.Write(out)
	            ^
scripts\aggregate-diagnostics\aggregate-diagnostics.go:22:21: Error return value of `report.WriteString` is not checked (errcheck)
		report.WriteString("Erreur d'exécution : " + err.Error() + "\n")
		                  ^
scripts\aggregate-diagnostics\aggregate-diagnostics.go:24:20: Error return value of `report.WriteString` is not checked (errcheck)
	report.WriteString("\n")
	                  ^
scripts\aggregate-diagnostics\aggregate-diagnostics.go:29:2: Error return value of `os.MkdirAll` is not checked (errcheck)
	_ = os.MkdirAll("audit-reports", 0755)
	^
scripts\aggregate-diagnostics\aggregate-diagnostics.go:35:20: Error return value of `report.Close` is not checked (errcheck)
	defer report.Close()
	                  ^
scripts\aggregate-diagnostics\aggregate-diagnostics.go:37:14: Error return value of `fmt.Fprintln` is not checked (errcheck)
	fmt.Fprintln(report, "# Rapport d’audit automatisé")
	            ^
scripts\aggregate-diagnostics\aggregate-diagnostics.go:38:14: Error return value of `fmt.Fprintln` is not checked (errcheck)
	fmt.Fprintln(report, "## Diagnostics Go (golangci-lint)")
	            ^
scripts\aggregate-diagnostics\aggregate-diagnostics.go:39:14: Error return value of `fmt.Fprintln` is not checked (errcheck)
	fmt.Fprintln(report, "```")
	            ^
scripts\aggregate-diagnostics\aggregate-diagnostics.go:50:15: Error return value of `filepath.Walk` is not checked (errcheck)
	filepath.Walk(".", func(path string, info os.FileInfo, err error) error {
	             ^
scripts\aggregate-diagnostics\aggregate-diagnostics.go:52:15: Error return value of `fmt.Fprintf` is not checked (errcheck)
			fmt.Fprintf(report, "Fichier : %s\n", path)
			           ^
scripts\aggregate-diagnostics\aggregate-diagnostics.go:59:2: use of `fmt.Printf` forbidden by pattern `^(fmt\.Print(|f|ln)|print|println)$` (forbidigo)
	fmt.Printf("Rapport généré : %s\n", reportPath)
	^
scripts\aggregate-diagnostics\aggregate-diagnostics.go:21:2: missing whitespace above this line (invalid statement above if) (wsl_v5)
	if err != nil {
	^
scripts\aggregate-diagnostics\aggregate-diagnostics.go:30:2: missing whitespace above this line (too many statements above if) (wsl_v5)
	report, err := os.Create(reportPath)
	^
scripts\aggregate-diagnostics\aggregate-diagnostics.go:55:3: missing whitespace above this line (too many lines above return) (wsl_v5)
		return nil
		^
15 issues:
* errcheck: 11
* forbidigo: 1
* wsl_v5: 3
Erreur d'exécution : exit status 1

```
## Diagnostics Go Vet
```
>>> go vet ./...

```
## Diagnostics YAML
```
```
