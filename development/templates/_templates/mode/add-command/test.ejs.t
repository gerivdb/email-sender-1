---
to: development/scripts/modes/tests/<%= modeLower %>-mode.tests.ps1
inject: true
after: "Context \"Tests des commandes spécifiques\""
skip_if: "La commande <%= name %> appelle <%= function %>"
---
        It "La commande <%= name %> appelle <%= function %>" {
            Mock -CommandName <%= function %> -MockWith { }
            & $scriptPath -Command "<%= name %>" -Target "test" -Options @{}
            Should -Invoke -CommandName <%= function %> -Times 1 -Exactly
        }
