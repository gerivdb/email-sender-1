```markdown
# OpenCode.md

## Build/Lint/Test Commands:

- **Build:** (Example: `make build` or `npm run build`)
- **Lint:** (Example: `make lint` or `npm run lint`)
- **Test:** (Example: `make test` or `npm run test`)
- **Single Test:** (Example: `make test-single FILE=path/to/test.go` or `npm run test path/to/test.js`)

## Code Style Guidelines:

- **Imports:** Follow standard library conventions, group by type (stdlib, 3rd party, local).
- **Formatting:** Use consistent indentation (e.g., 2 spaces) and line length (e.g., 80 chars).
- **Types:** Use explicit types where clarity is improved, especially for complex data structures.
- **Naming Conventions:** Use camelCase for variables and functions, PascalCase for types.
- **Error Handling:** Check errors explicitly and return early.

## Codacy/Copilot Rules (from .github/copilot-instructions.md):

- After ANY successful `edit_file` or `reapply` operation, run `codacy_cli_analyze`.
- Immediately after package manager operations, run `codacy_cli_analyze` with the `trivy` tool.
- If any issues are found, propose and apply fixes for them.
```