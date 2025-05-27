# 🔄 Interface Contracts - PowerShell
# Contract-First Development pour 24 scripts

# Interface principale pour tous les scripts d'analyse
class IAnalysisScript {
    [string] GetScriptName() { 
        throw "Must implement GetScriptName()" 
    }
    
    [hashtable] GetRequiredModules() { 
        throw "Must implement GetRequiredModules()" 
    }
    
    [string[]] GetDependencies() { 
        throw "Must implement GetDependencies()" 
    }
    
    [object] Execute([hashtable]$params) { 
        throw "Must implement Execute()" 
    }
    
    [bool] ValidatePrerequisites() { 
        throw "Must implement ValidatePrerequisites()" 
    }
    
    [hashtable] GetMetadata() {
        return @{
            Name = $this.GetScriptName()
            RequiredModules = $this.GetRequiredModules()
            Dependencies = $this.GetDependencies()
            Version = "1.0.0"
            Author = "Email Sender 1 Team"
        }
    }
}

# Interface pour scripts de test
class ITestScript : IAnalysisScript {
    [object] RunTests([hashtable]$testParams) { 
        throw "Must implement RunTests()" 
    }
    
    [bool] ValidateTestEnvironment() { 
        throw "Must implement ValidateTestEnvironment()" 
    }
    
    [hashtable] GetTestResults() { 
        throw "Must implement GetTestResults()" 
    }
}

# Interface pour scripts QDrant
class IQdrantScript : IAnalysisScript {
    [bool] ValidateQdrantConnection([string]$url) { 
        throw "Must implement ValidateQdrantConnection()" 
    }
    
    [object] ExecuteQdrantOperation([hashtable]$operation) { 
        throw "Must implement ExecuteQdrantOperation()" 
    }
}

# Export des interfaces
Export-ModuleMember -Type IAnalysisScript, ITestScript, IQdrantScript