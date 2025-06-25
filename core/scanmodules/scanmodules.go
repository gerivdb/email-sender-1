package scanmodules

import (
    "os"
    "path/filepath"
    "encoding/json"
)

type ModuleInfo struct {
    Name    string   `json:"name"`
    Path    string   `json:"path"`
    Type    string   `json:"type"`
    Lang    string   `json:"lang"`
    Role    string   `json:"role"`
    Deps    []string `json:"deps"`
    Outputs []string `json:"outputs"`
}

func ScanDir(root string) ([]ModuleInfo, error) {
    var modules []ModuleInfo
    filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
        if err != nil { return err }
        if info.IsDir() { return nil }
        lang := DetectLang(info.Name())
        modules = append(modules, ModuleInfo{
            Name: info.Name(),
            Path: path,
            Type: "file",
            Lang: lang,
            Role: "",
            Deps: []string{},
            Outputs: []string{},
        })
        return nil
    })
    return modules, nil
}

func DetectLang(filename string) string {
    switch filepath.Ext(filename) {
    case ".go": return "Go"
    case ".js": return "Node.js"
    case ".py": return "Python"
    default: return "unknown"
    }
}

func ExportModules(modules []ModuleInfo, outPath string) error {
    data, err := json.MarshalIndent(modules, "", "  ")
    if err != nil { return err }
    return os.WriteFile(outPath, data, 0644)
}
