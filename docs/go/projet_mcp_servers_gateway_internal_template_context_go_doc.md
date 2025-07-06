# Package template

## Types

### Context

Context represents the template context


### Renderer

Renderer is responsible for rendering templates


#### Methods

##### Renderer.Render

Render renders a template with the given context


```go
func (r *Renderer) Render(tmpl string, ctx *Context) (string, error)
```

### RequestWrapper

Context represents the template context


### ResponseWrapper

Context represents the template context


## Functions

### NormalizeJSONStringValues

```go
func NormalizeJSONStringValues(args map[string]any)
```

### RenderTemplate

RenderTemplate renders a template with the given context


```go
func RenderTemplate(tmpl string, ctx *Context) (string, error)
```

