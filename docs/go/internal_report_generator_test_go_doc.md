# Package report

Package report provides report generation functionality


## Types

### Format

Format represents the output format of a report


### Generator

Generator provides a simplified interface for template-based report generation


#### Methods

##### Generator.Generate

Generate generates output using the provided template and data


```go
func (g *Generator) Generate(w io.Writer, templateStr string, data interface{}) error
```

### Report

Report represents a report


### ReportGenerator

ReportGenerator generates reports


#### Methods

##### ReportGenerator.Generate

Generate generates a report in the specified format


```go
func (rg *ReportGenerator) Generate(report *Report, format Format, w io.Writer) error
```

### Section

Section represents a section in a report


