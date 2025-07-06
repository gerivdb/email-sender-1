# 🚀 Roadmap v77b — Migration Gateway-Manager 100% Go natif (Exemple de conversion)

## Exemple détaillé de conversion Bash → Go natif

### Script Bash original (extrait)

```bash
cp -r /tmp/mcp-gateway/* development/managers/gateway-manager/
rm -rf development/managers/gateway-manager/.git*
grep -r gateway-manager ./ | tee migration/gateway-manager-v77/dependency-scan.md
```

### Version Go native

```go
package main

import (
    "io"
    "io/fs"
    "os"
    "path/filepath"
    "regexp"
    "strings"
)

func copyDir(src, dst string) error {
    return filepath.Walk(src, func(path string, info fs.FileInfo, err error) error {
        if err != nil {
            return err
        }
        rel, _ := filepath.Rel(src, path)
        target := filepath.Join(dst, rel)
        if info.IsDir() {
            return os.MkdirAll(target, info.Mode())
        }
        srcFile, _ := os.Open(path)
        defer srcFile.Close()
        dstFile, _ := os.Create(target)
        defer dstFile.Close()
        _, err = io.Copy(dstFile, srcFile)
        return err
    })
}

func removeGitArtifacts(dir string) error {
    return filepath.Walk(dir, func(path string, info fs.FileInfo, err error) error {
        if err != nil {
            return err
        }
        if strings.HasPrefix(filepath.Base(path), ".git") {
            return os.RemoveAll(path)
        }
        return nil
    })
}

func grepRecursive(root, pattern, output string) error {
    re := regexp.MustCompile(pattern)
    var results []string
    filepath.Walk(root, func(path string, info fs.FileInfo, err error) error {
        if err != nil || info.IsDir() || !strings.HasSuffix(path, ".go") { // Adjusted to search .go files for this example
            return nil
        }
        data, _ := os.ReadFile(path)
        if re.Match(data) {
            results = append(results, path)
        }
        return nil
    })
    return os.WriteFile(output, []byte(strings.Join(results, "\n")), 0644)
}

func main() {
    // Example usage:
    // Ensure /tmp/mcp-gateway exists with some content for this to work
    // copyDir("/tmp/mcp-gateway", "development/managers/gateway-manager")
    // removeGitArtifacts("development/managers/gateway-manager")
    // grepRecursive(".", "gateway-manager", "migration/gateway-manager-v77/dependency-scan.md")
}
