---
to: "<%= createConfig ? `projet/mcp/config/servers/${name}.json` : null %>"
---
{
<% if (port) { %>
  "port": <%= port %>,
<% } %>
  "enabled": true,
  "description": "<%= description %>",
<% if (name === 'git-ingest') { %>
  "outputDir": "D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/projet/mcp/servers/git-ingest/output",
  "cloneDir": "D:/DO/WEB/N8N_tests/PROJETS/EMAIL_SENDER_1/projet/mcp/servers/git-ingest/repos",
  "maxFiles": 100,
  "excludePatterns": [
    "node_modules/**",
    ".git/**",
    "**/*.min.js",
    "**/*.bundle.js",
    "**/*.map",
    "**/dist/**",
    "**/build/**"
  ],
  "includePatterns": [
    "**/*.md",
    "**/*.py",
    "**/*.js",
    "**/*.ts",
    "**/*.json",
    "**/*.yaml",
    "**/*.yml"
  ],
<% } %>
  "cacheEnabled": true,
  "cacheTTL": 3600
}
