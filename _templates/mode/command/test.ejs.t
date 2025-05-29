---
to: commands/<%= name %>.Tests.ps1
---
<%
const { createLogger } = require('../../helpers/logger-helper.js');
const logger = createLogger({ verbosity: 'info', useEmoji: true });
logger.info(`Generating test file for: ${name}.ps1`);
%>
BeforeAll {
    . $PSScriptRoot/<%= name %>.ps1
    $logger = Get-Logger
    $logger.info("Starting <%= name %> command tests")
}

Describe "<%= name %> Command Tests" {
    Context "Parameter Validation" {
        It "Should require <%= parameters[0] %> parameter" {
            { <%= name %> } | Should -Throw "*<%= parameters[0] %>*"
        }

<% parameters.slice(1).forEach(param => { -%>
        It "Should accept optional <%= param %> parameter" {
            { <%= name %> -<%= parameters[0] %> "test" -<%= param %> "value" } | Should -Not -Throw
        }

<% }) -%>
    }

    Context "Command Execution" {
        It "Should execute without errors" {
            { <%= name %> -<%= parameters[0] %> "test" } | Should -Not -Throw
        }

        It "Should log execution status" {
            $logger = Get-Logger
            Mock -CommandName $logger.info -MockWith { }
            
            <%= name %> -<%= parameters[0] %> "test"
            
            Should -Invoke -CommandName $logger.info -Times 2
        }
    }
}
