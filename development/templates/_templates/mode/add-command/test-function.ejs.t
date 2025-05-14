---
to: development/scripts/modes/tests/<%= modeLower %>-mode.tests.ps1
inject: true
after: "Context \"Tests des fonctions spécifiques\""
skip_if: "<%= function %> fonctionne correctement"
---
        It "<%= function %> fonctionne correctement" {
            # TODO: Implémenter des tests spécifiques pour <%= function %>
            $true | Should -Be $true
        }
