<#
.SYNOPSIS
    Fournit des wrappers pour les commandes spÃ©cifiques Ã  l'OS.

.DESCRIPTION
    Ce script fournit des fonctions wrapper pour les commandes courantes qui ont
    des implÃ©mentations diffÃ©rentes selon le systÃ¨me d'exploitation. Il permet
    d'Ã©crire du code qui fonctionne de maniÃ¨re transparente sur diffÃ©rents systÃ¨mes.

.EXAMPLE
    . .\OSCommandWrappers.ps1
    Get-OSProcessList | Where-Object { $_.Name -like "*chrome*" }

.NOTES
    Auteur: SystÃ¨me d'analyse d'erreurs
    Date de crÃ©ation: 07/04/2025
    Version: 1.0
#>

# Charger le module de dÃ©tection d'environnement
$environmentDetectorPath = Join-Path -Path (Split-Path -Parent $PSCommandPath) -ChildPath "EnvironmentDetector.ps1"
if (Test-Path -Path $environmentDetectorPath -PathType Leaf) {
    . $environmentDetectorPath
}
else {
    Write-Warning "Le module de dÃ©tection d'environnement n'a pas Ã©tÃ© trouvÃ©. Certaines fonctionnalitÃ©s peuvent ne pas fonctionner correctement."
}

# Obtenir les informations sur l'environnement
$script:EnvironmentInfo = if (Get-Command -Name Get-EnvironmentInfo -ErrorAction SilentlyContinue) {
    Get-EnvironmentInfo
}
else {
    # CrÃ©er un objet d'informations sur l'environnement minimal
    [PSCustomObject]@{
        IsWindows = $PSVersionTable.PSVersion.Major -lt 6 -or ($PSVersionTable.PSVersion.Major -ge 6 -and $IsWindows)
        IsLinux = $PSVersionTable.PSVersion.Major -ge 6 -and $IsLinux
        IsMacOS = $PSVersionTable.PSVersion.Major -ge 6 -and $IsMacOS
        IsUnix = ($PSVersionTable.PSVersion.Major -ge 6 -and ($IsLinux -or $IsMacOS))
    }
}

# Fonction pour obtenir la liste des processus
function Get-OSProcessList {
    [CmdletBinding()]
    param ()
    
    if ($script:EnvironmentInfo.IsWindows) {
        # Utiliser Get-Process sur Windows
        Get-Process
    }
    else {
        # Utiliser ps sur Unix
        $processes = @()
        $psOutput = & ps -e -o pid,ppid,user,pcpu,pmem,comm
        
        # Analyser la sortie de ps
        $psOutput | Select-Object -Skip 1 | ForEach-Object {
            $line = $_ -replace '\s+', ' ' -replace '^\s+', '' -replace '\s+$', ''
            $fields = $line -split ' '
            
            if ($fields.Count -ge 6) {
                $processes += [PSCustomObject]@{
                    Id = [int]$fields[0]
                    ParentId = [int]$fields[1]
                    User = $fields[2]
                    CPU = [double]$fields[3]
                    Memory = [double]$fields[4]
                    Name = $fields[5]
                    CommandLine = $fields[5..($fields.Count - 1)] -join ' '
                }
            }
        }
        
        return $processes
    }
}

# Fonction pour obtenir des informations sur un processus spÃ©cifique
function Get-OSProcess {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "ById")]
        [int]$Id,
        
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "ByName")]
        [string]$Name
    )
    
    if ($script:EnvironmentInfo.IsWindows) {
        # Utiliser Get-Process sur Windows
        if ($PSCmdlet.ParameterSetName -eq "ById") {
            Get-Process -Id $Id -ErrorAction SilentlyContinue
        }
        else {
            Get-Process -Name $Name -ErrorAction SilentlyContinue
        }
    }
    else {
        # Utiliser ps sur Unix
        if ($PSCmdlet.ParameterSetName -eq "ById") {
            $psOutput = & ps -p $Id -o pid,ppid,user,pcpu,pmem,comm
        }
        else {
            $psOutput = & ps -e -o pid,ppid,user,pcpu,pmem,comm | Where-Object { $_ -match $Name }
        }
        
        # Analyser la sortie de ps
        $processes = @()
        $psOutput | Select-Object -Skip 1 | ForEach-Object {
            $line = $_ -replace '\s+', ' ' -replace '^\s+', '' -replace '\s+$', ''
            $fields = $line -split ' '
            
            if ($fields.Count -ge 6) {
                $processes += [PSCustomObject]@{
                    Id = [int]$fields[0]
                    ParentId = [int]$fields[1]
                    User = $fields[2]
                    CPU = [double]$fields[3]
                    Memory = [double]$fields[4]
                    Name = $fields[5]
                    CommandLine = $fields[5..($fields.Count - 1)] -join ' '
                }
            }
        }
        
        return $processes
    }
}

# Fonction pour arrÃªter un processus
function Stop-OSProcess {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = "High")]
    param (
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "ById")]
        [int]$Id,
        
        [Parameter(Mandatory = $true, Position = 0, ParameterSetName = "ByName")]
        [string]$Name,
        
        [Parameter(Mandatory = $false)]
        [switch]$Force
    )
    
    if ($script:EnvironmentInfo.IsWindows) {
        # Utiliser Stop-Process sur Windows
        if ($PSCmdlet.ParameterSetName -eq "ById") {
            if ($PSCmdlet.ShouldProcess("Process with ID $Id", "Stop")) {
                Stop-Process -Id $Id -Force:$Force -ErrorAction SilentlyContinue
            }
        }
        else {
            if ($PSCmdlet.ShouldProcess("Process with name $Name", "Stop")) {
                Stop-Process -Name $Name -Force:$Force -ErrorAction SilentlyContinue
            }
        }
    }
    else {
        # Utiliser kill sur Unix
        if ($PSCmdlet.ParameterSetName -eq "ById") {
            if ($PSCmdlet.ShouldProcess("Process with ID $Id", "Stop")) {
                if ($Force) {
                    & kill -9 $Id 2>/dev/null
                }
                else {
                    & kill $Id 2>/dev/null
                }
            }
        }
        else {
            if ($PSCmdlet.ShouldProcess("Process with name $Name", "Stop")) {
                $processes = Get-OSProcess -Name $Name
                foreach ($process in $processes) {
                    if ($Force) {
                        & kill -9 $process.Id 2>/dev/null
                    }
                    else {
                        & kill $process.Id 2>/dev/null
                    }
                }
            }
        }
    }
}

# Fonction pour obtenir des informations sur le systÃ¨me
function Get-OSSystemInfo {
    [CmdletBinding()]
    param ()
    
    if ($script:EnvironmentInfo.IsWindows) {
        # Utiliser Get-ComputerInfo ou WMI sur Windows
        if (Get-Command -Name Get-ComputerInfo -ErrorAction SilentlyContinue) {
            $computerInfo = Get-ComputerInfo
            
            return [PSCustomObject]@{
                OSName = $computerInfo.WindowsProductName
                OSVersion = $computerInfo.WindowsVersion
                OSBuildNumber = $computerInfo.WindowsBuildNumber
                OSArchitecture = $computerInfo.OSArchitecture
                ComputerName = $computerInfo.CsName
                Manufacturer = $computerInfo.CsManufacturer
                Model = $computerInfo.CsModel
                ProcessorName = $computerInfo.CsProcessors.Name | Select-Object -First 1
                ProcessorCores = ($computerInfo.CsProcessors.NumberOfCores | Measure-Object -Sum).Sum
                TotalMemory = $computerInfo.CsTotalPhysicalMemory
                BootTime = $computerInfo.OsLastBootUpTime
                TimeZone = $computerInfo.TimeZone
            }
        }
        else {
            # Fallback pour les anciennes versions de PowerShell
            $os = Get-WmiObject -Class Win32_OperatingSystem
            $cs = Get-WmiObject -Class Win32_ComputerSystem
            $proc = Get-WmiObject -Class Win32_Processor | Select-Object -First 1
            
            return [PSCustomObject]@{
                OSName = $os.Caption
                OSVersion = $os.Version
                OSBuildNumber = $os.BuildNumber
                OSArchitecture = $os.OSArchitecture
                ComputerName = $cs.Name
                Manufacturer = $cs.Manufacturer
                Model = $cs.Model
                ProcessorName = $proc.Name
                ProcessorCores = $cs.NumberOfProcessors * $proc.NumberOfCores
                TotalMemory = $cs.TotalPhysicalMemory
                BootTime = $os.LastBootUpTime
                TimeZone = $os.CurrentTimeZone
            }
        }
    }
    else {
        # Utiliser des commandes Unix
        $osName = if ($script:EnvironmentInfo.IsLinux) {
            (& lsb_release -d 2>/dev/null) -replace "Description:\s*", ""
        }
        elseif ($script:EnvironmentInfo.IsMacOS) {
            "macOS $(& sw_vers -productVersion 2>/dev/null)"
        }
        else {
            "Unix"
        }
        
        $osVersion = if ($script:EnvironmentInfo.IsLinux) {
            (& uname -r 2>/dev/null)
        }
        elseif ($script:EnvironmentInfo.IsMacOS) {
            (& sw_vers -productVersion 2>/dev/null)
        }
        else {
            (& uname -r 2>/dev/null)
        }
        
        $osArchitecture = (& uname -m 2>/dev/null)
        $computerName = (& hostname 2>/dev/null)
        
        $processorInfo = if ($script:EnvironmentInfo.IsLinux) {
            (& cat /proc/cpuinfo 2>/dev/null | Select-String -Pattern "model name" | Select-Object -First 1) -replace "model name\s*:\s*", ""
        }
        elseif ($script:EnvironmentInfo.IsMacOS) {
            (& sysctl -n machdep.cpu.brand_string 2>/dev/null)
        }
        else {
            "Unknown"
        }
        
        $processorCores = if ($script:EnvironmentInfo.IsLinux) {
            (& nproc 2>/dev/null)
        }
        elseif ($script:EnvironmentInfo.IsMacOS) {
            (& sysctl -n hw.ncpu 2>/dev/null)
        }
        else {
            1
        }
        
        $totalMemory = if ($script:EnvironmentInfo.IsLinux) {
            $memInfo = & free -b 2>/dev/null
            if ($memInfo) {
                ($memInfo | Select-Object -Skip 1 | Select-Object -First 1) -split '\s+' | Select-Object -Index 1
            }
            else {
                0
            }
        }
        elseif ($script:EnvironmentInfo.IsMacOS) {
            [int](& sysctl -n hw.memsize 2>/dev/null)
        }
        else {
            0
        }
        
        $bootTime = if ($script:EnvironmentInfo.IsLinux) {
            $uptime = & uptime -s 2>/dev/null
            if ($uptime) {
                try {
                    [datetime]$uptime
                }
                catch {
                    Get-Date
                }
            }
            else {
                Get-Date
            }
        }
        else {
            Get-Date
        }
        
        $timeZone = if ($script:EnvironmentInfo.IsLinux -or $script:EnvironmentInfo.IsMacOS) {
            (& date +%Z 2>/dev/null)
        }
        else {
            "Unknown"
        }
        
        return [PSCustomObject]@{
            OSName = $osName
            OSVersion = $osVersion
            OSBuildNumber = $osVersion
            OSArchitecture = $osArchitecture
            ComputerName = $computerName
            Manufacturer = "Unknown"
            Model = "Unknown"
            ProcessorName = $processorInfo
            ProcessorCores = $processorCores
            TotalMemory = $totalMemory
            BootTime = $bootTime
            TimeZone = $timeZone
        }
    }
}

# Fonction pour obtenir l'utilisation du disque
function Get-OSDiskUsage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [string]$Path = "/"
    )
    
    if ($script:EnvironmentInfo.IsWindows) {
        # Utiliser Get-PSDrive sur Windows
        $drive = if ([System.IO.Path]::IsPathRooted($Path)) {
            $root = [System.IO.Path]::GetPathRoot($Path)
            $driveLetter = $root.TrimEnd(':\')
            Get-PSDrive -Name $driveLetter -PSProvider FileSystem -ErrorAction SilentlyContinue
        }
        else {
            $currentPath = (Get-Location).Path
            $root = [System.IO.Path]::GetPathRoot($currentPath)
            $driveLetter = $root.TrimEnd(':\')
            Get-PSDrive -Name $driveLetter -PSProvider FileSystem -ErrorAction SilentlyContinue
        }
        
        if ($drive) {
            return [PSCustomObject]@{
                Path = $drive.Root
                TotalSize = $drive.Used + $drive.Free
                UsedSize = $drive.Used
                FreeSize = $drive.Free
                UsedPercent = [math]::Round(($drive.Used / ($drive.Used + $drive.Free)) * 100, 2)
            }
        }
        else {
            Write-Warning "Impossible d'obtenir les informations sur le disque pour le chemin '$Path'."
            return $null
        }
    }
    else {
        # Utiliser df sur Unix
        $dfOutput = & df -k $Path 2>/dev/null
        
        if ($dfOutput) {
            $dfLine = $dfOutput | Select-Object -Skip 1 | Select-Object -First 1
            $dfLine = $dfLine -replace '\s+', ' ' -replace '^\s+', '' -replace '\s+$', ''
            $fields = $dfLine -split ' '
            
            if ($fields.Count -ge 6) {
                return [PSCustomObject]@{
                    Path = $fields[5]
                    TotalSize = [long]$fields[1] * 1KB
                    UsedSize = [long]$fields[2] * 1KB
                    FreeSize = [long]$fields[3] * 1KB
                    UsedPercent = [double]($fields[4] -replace '%', '')
                }
            }
            else {
                Write-Warning "Format de sortie df inattendu."
                return $null
            }
        }
        else {
            Write-Warning "Impossible d'obtenir les informations sur le disque pour le chemin '$Path'."
            return $null
        }
    }
}

# Fonction pour obtenir l'utilisation de la mÃ©moire
function Get-OSMemoryUsage {
    [CmdletBinding()]
    param ()
    
    if ($script:EnvironmentInfo.IsWindows) {
        # Utiliser Get-CimInstance ou WMI sur Windows
        if (Get-Command -Name Get-CimInstance -ErrorAction SilentlyContinue) {
            $os = Get-CimInstance -ClassName Win32_OperatingSystem
            
            return [PSCustomObject]@{
                TotalMemory = $os.TotalVisibleMemorySize * 1KB
                FreeMemory = $os.FreePhysicalMemory * 1KB
                UsedMemory = ($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) * 1KB
                UsedPercent = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 2)
            }
        }
        else {
            # Fallback pour les anciennes versions de PowerShell
            $os = Get-WmiObject -Class Win32_OperatingSystem
            
            return [PSCustomObject]@{
                TotalMemory = $os.TotalVisibleMemorySize * 1KB
                FreeMemory = $os.FreePhysicalMemory * 1KB
                UsedMemory = ($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) * 1KB
                UsedPercent = [math]::Round((($os.TotalVisibleMemorySize - $os.FreePhysicalMemory) / $os.TotalVisibleMemorySize) * 100, 2)
            }
        }
    }
    else {
        # Utiliser free sur Unix
        $freeOutput = & free -b 2>/dev/null
        
        if ($freeOutput) {
            $memLine = $freeOutput | Select-Object -Skip 1 | Select-Object -First 1
            $memLine = $memLine -replace '\s+', ' ' -replace '^\s+', '' -replace '\s+$', ''
            $fields = $memLine -split ' '
            
            if ($fields.Count -ge 3) {
                $totalMemory = [long]$fields[1]
                $usedMemory = [long]$fields[2]
                $freeMemory = $totalMemory - $usedMemory
                
                return [PSCustomObject]@{
                    TotalMemory = $totalMemory
                    FreeMemory = $freeMemory
                    UsedMemory = $usedMemory
                    UsedPercent = [math]::Round(($usedMemory / $totalMemory) * 100, 2)
                }
            }
            else {
                Write-Warning "Format de sortie free inattendu."
                return $null
            }
        }
        else {
            Write-Warning "Impossible d'obtenir les informations sur la mÃ©moire."
            return $null
        }
    }
}

# Fonction pour obtenir l'utilisation du CPU
function Get-OSCpuUsage {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)]
        [int]$SampleInterval = 1
    )
    
    if ($script:EnvironmentInfo.IsWindows) {
        # Utiliser Get-Counter sur Windows
        if (Get-Command -Name Get-Counter -ErrorAction SilentlyContinue) {
            $counter = Get-Counter -Counter "\Processor(_Total)\% Processor Time" -SampleInterval $SampleInterval -MaxSamples 1
            $cpuUsage = $counter.CounterSamples[0].CookedValue
            
            return [PSCustomObject]@{
                CpuUsage = [math]::Round($cpuUsage, 2)
                SampleTime = $counter.CounterSamples[0].Timestamp
            }
        }
        else {
            # Fallback pour les anciennes versions de PowerShell
            $cpuUsage = (Get-WmiObject -Class Win32_Processor | Measure-Object -Property LoadPercentage -Average).Average
            
            return [PSCustomObject]@{
                CpuUsage = [math]::Round($cpuUsage, 2)
                SampleTime = Get-Date
            }
        }
    }
    else {
        # Utiliser top sur Unix
        $topOutput = & top -b -n 1 2>/dev/null
        
        if ($topOutput) {
            $cpuLine = $topOutput | Where-Object { $_ -match '%Cpu\(s\):' -or $_ -match 'CPU usage:' } | Select-Object -First 1
            
            if ($cpuLine) {
                if ($cpuLine -match '(\d+\.\d+)\s*%?\s*us') {
                    $userCpu = [double]$Matches[1]
                }
                elseif ($cpuLine -match '(\d+\.\d+)\s*%?\s*user') {
                    $userCpu = [double]$Matches[1]
                }
                else {
                    $userCpu = 0
                }
                
                if ($cpuLine -match '(\d+\.\d+)\s*%?\s*sy') {
                    $systemCpu = [double]$Matches[1]
                }
                elseif ($cpuLine -match '(\d+\.\d+)\s*%?\s*system') {
                    $systemCpu = [double]$Matches[1]
                }
                else {
                    $systemCpu = 0
                }
                
                return [PSCustomObject]@{
                    CpuUsage = [math]::Round($userCpu + $systemCpu, 2)
                    UserCpuUsage = [math]::Round($userCpu, 2)
                    SystemCpuUsage = [math]::Round($systemCpu, 2)
                    SampleTime = Get-Date
                }
            }
            else {
                Write-Warning "Format de sortie top inattendu."
                return $null
            }
        }
        else {
            Write-Warning "Impossible d'obtenir les informations sur l'utilisation du CPU."
            return $null
        }
    }
}

# Fonction pour exÃ©cuter une commande avec les adaptations nÃ©cessaires selon l'OS
function Invoke-OSCommand {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$WindowsCommand,
        
        [Parameter(Mandatory = $true)]
        [string]$UnixCommand,
        
        [Parameter(Mandatory = $false)]
        [string]$MacOSCommand = "",
        
        [Parameter(Mandatory = $false)]
        [switch]$PassThru
    )
    
    $command = if ($script:EnvironmentInfo.IsWindows) {
        $WindowsCommand
    }
    elseif ($script:EnvironmentInfo.IsMacOS -and -not [string]::IsNullOrEmpty($MacOSCommand)) {
        $MacOSCommand
    }
    else {
        $UnixCommand
    }
    
    if ($PassThru) {
        return $command
    }
    else {
        Invoke-Expression -Command $command
    }
}

# Exporter les fonctions
Export-ModuleMember -Function Get-OSProcessList, Get-OSProcess, Stop-OSProcess, Get-OSSystemInfo, Get-OSDiskUsage, Get-OSMemoryUsage, Get-OSCpuUsage, Invoke-OSCommand
