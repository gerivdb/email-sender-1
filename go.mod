module docmanager

go 1.21

replace core/scanmodules => ./core/scanmodules

replace core/gapanalyzer => ./core/gapanalyzer

require (
	core/scanmodules v0.0.0
	core/gapanalyzer v0.0.0
)

replace github.com/mcp-ecosystem/mcp-gateway => github.com/gerivdb/unla v0.8.0
