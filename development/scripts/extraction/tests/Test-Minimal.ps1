# Test minimal
Write-Host "Test minimal en cours d'exÃ©cution..."

# DÃ©finir une classe simple
class TestClass {
    [string]$Name
    
    TestClass([string]$name) {
        $this.Name = $name
    }
    
    [string] GetName() {
        return $this.Name
    }
}

# CrÃ©er une instance
$test = [TestClass]::new("Test")
Write-Host "Nom: $($test.GetName())"

Write-Host "Test terminÃ© avec succÃ¨s!" -ForegroundColor Green
