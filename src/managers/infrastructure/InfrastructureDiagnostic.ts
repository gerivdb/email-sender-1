// Infrastructure Diagnostic Manager - Phase 0.1
// Diagnostic et Réparation Infrastructure Automatisée

export interface DiagnosticReport {
  apiServer: ServiceStatus;
  dockerHealth: DockerStatus;
  servicesPorts: PortStatus[];
  resourceUsage: ResourceUsage;
  processConflicts: ProcessConflict[];
  timestamp: string;
  overallHealth: 'healthy' | 'warning' | 'critical';
}

export interface ServiceStatus {
  endpoint: string;
  status: 'running' | 'stopped' | 'error';
  responseTime?: number;
  errorMessage?: string;
  lastCheck: string;
}

export interface DockerStatus {
  isRunning: boolean;
  containers: ContainerInfo[];
  totalMemoryUsage: number;
  networkStatus: string;
}

export interface ContainerInfo {
  name: string;
  status: string;
  memoryUsage: number;
  ports: string[];
}

export interface PortStatus {
  port: number;
  service: string;
  status: 'available' | 'occupied' | 'conflict';
  processId?: number;
  processName?: string;
}

export interface ResourceUsage {
  cpu: number;
  memory: number;
  disk: number;
  networkIO: number;
}

export interface ProcessConflict {
  processName: string;
  pid: number;
  port?: number;
  memoryUsage: number;
  conflictType: 'port' | 'resource' | 'duplicate';
}

export interface RepairResult {
  action: string;
  success: boolean;
  details: string;
  timestamp: string;
}

export class InfrastructureDiagnostic {
  private readonly API_ENDPOINTS = [
    'http://localhost:8080/health',
    'http://localhost:8080/api/v1/infrastructure/status',
    'http://localhost:8080/api/v1/monitoring/status'
  ];

  private readonly CRITICAL_PORTS = [8080, 5432, 6379, 6333];
  private readonly DOCKER_SERVICES = ['postgres', 'redis', 'qdrant', 'api-server'];

  async runCompleteDiagnostic(): Promise<DiagnosticReport> {
    console.log('🩺 Starting Complete Infrastructure Diagnostic...');
    
    const report: DiagnosticReport = {
      apiServer: await this.checkApiServerStatus(),
      dockerHealth: await this.checkDockerStatus(),
      servicesPorts: await this.checkPortsAvailability(),
      resourceUsage: await this.checkSystemResources(),
      processConflicts: await this.detectProcessConflicts(),
      timestamp: new Date().toISOString(),
      overallHealth: 'healthy'
    };

    // Déterminer l'état général
    report.overallHealth = this.calculateOverallHealth(report);
    
    console.log(`📊 Diagnostic completed - Overall health: ${report.overallHealth}`);
    return report;
  }

  private async checkApiServerStatus(): Promise<ServiceStatus> {
    const primaryEndpoint = this.API_ENDPOINTS[0];
    const startTime = Date.now();

    try {
      const response = await fetch(primaryEndpoint, { 
        method: 'GET',
        signal: AbortSignal.timeout(5000)
      });

      if (response.ok) {
        const responseTime = Date.now() - startTime;
        return {
          endpoint: primaryEndpoint,
          status: 'running',
          responseTime,
          lastCheck: new Date().toISOString()
        };
      } else {
        return {
          endpoint: primaryEndpoint,
          status: 'error',
          errorMessage: `HTTP ${response.status}: ${response.statusText}`,
          lastCheck: new Date().toISOString()
        };
      }
    } catch (error) {
      return {
        endpoint: primaryEndpoint,
        status: 'stopped',
        errorMessage: error instanceof Error ? error.message : 'Unknown error',
        lastCheck: new Date().toISOString()
      };
    }
  }

  private async checkDockerStatus(): Promise<DockerStatus> {
    try {
      // Simuler l'appel à Docker API (à adapter selon l'environnement)
      const dockerInfo = await this.executeCommand('docker ps --format "table {{.Names}}\\t{{.Status}}\\t{{.Ports}}"');
      
      return {
        isRunning: true,
        containers: await this.parseDockerContainers(dockerInfo),
        totalMemoryUsage: await this.getDockerMemoryUsage(),
        networkStatus: 'healthy'
      };
    } catch (error) {
      return {
        isRunning: false,
        containers: [],
        totalMemoryUsage: 0,
        networkStatus: 'error'
      };
    }
  }

  private async checkPortsAvailability(): Promise<PortStatus[]> {
    const portStatuses: PortStatus[] = [];

    for (const port of this.CRITICAL_PORTS) {
      try {
        const portInfo = await this.executeCommand(`netstat -ano | findstr :${port}`);
        const isOccupied = portInfo.trim().length > 0;

        if (isOccupied) {
          const processInfo = this.parseNetstatOutput(portInfo);
          portStatuses.push({
            port,
            service: this.getServiceForPort(port),
            status: 'occupied',
            processId: processInfo.pid,
            processName: processInfo.name
          });
        } else {
          portStatuses.push({
            port,
            service: this.getServiceForPort(port),
            status: 'available'
          });
        }
      } catch (error) {
        portStatuses.push({
          port,
          service: this.getServiceForPort(port),
          status: 'conflict'
        });
      }
    }

    return portStatuses;
  }

  private async checkSystemResources(): Promise<ResourceUsage> {
    try {
      // Utiliser des commandes PowerShell pour obtenir l'usage des ressources
      const cpuUsage = await this.getCpuUsage();
      const memoryUsage = await this.getMemoryUsage();
      const diskUsage = await this.getDiskUsage();

      return {
        cpu: cpuUsage,
        memory: memoryUsage,
        disk: diskUsage,
        networkIO: 0 // À implémenter si nécessaire
      };
    } catch (error) {
      return { cpu: 0, memory: 0, disk: 0, networkIO: 0 };
    }
  }

  private async detectProcessConflicts(): Promise<ProcessConflict[]> {
    const conflicts: ProcessConflict[] = [];

    try {
      // Détecter les processus qui utilisent trop de mémoire
      const processes = await this.getHighMemoryProcesses();
      
      // Détecter les doublons de processus critiques
      const duplicates = await this.detectDuplicateProcesses();
      
      conflicts.push(...processes, ...duplicates);
    } catch (error) {
      console.error('Error detecting process conflicts:', error);
    }

    return conflicts;
  }

  async repairApiServer(): Promise<RepairResult> {
    console.log('🔧 Starting API Server repair...');

    try {
      // Étape 1: Arrêter les processus api-server existants
      await this.executeCommand('taskkill /f /im "api-server-fixed.exe" 2>nul || echo "No existing process"');
      
      // Étape 2: Nettoyer le port 8080
      await this.clearPort(8080);
      
      // Étape 3: Redémarrer l'API Server
      await this.executeCommand('start /b cmd\\simple-api-server-fixed\\api-server-fixed.exe');
      
      // Étape 4: Attendre et vérifier
      await this.sleep(3000);
      const apiStatus = await this.checkApiServerStatus();
      
      if (apiStatus.status === 'running') {
        return {
          action: 'API Server repair',
          success: true,
          details: 'API Server successfully restarted and responding',
          timestamp: new Date().toISOString()
        };
      } else {
        return {
          action: 'API Server repair',
          success: false,
          details: `API Server restart failed: ${apiStatus.errorMessage}`,
          timestamp: new Date().toISOString()
        };
      }
    } catch (error) {
      return {
        action: 'API Server repair',
        success: false,
        details: `Repair failed: ${error instanceof Error ? error.message : 'Unknown error'}`,
        timestamp: new Date().toISOString()
      };
    }
  }

  // Méthodes utilitaires privées
  private calculateOverallHealth(report: DiagnosticReport): 'healthy' | 'warning' | 'critical' {
    if (report.apiServer.status === 'stopped' || report.processConflicts.length > 5) {
      return 'critical';
    }
    if (report.apiServer.status === 'error' || report.resourceUsage.memory > 90) {
      return 'warning';
    }
    return 'healthy';
  }

  private async executeCommand(command: string): Promise<string> {
    // À implémenter selon l'environnement (Node.js child_process, etc.)
    return new Promise((resolve) => {
      // Simulation pour l'exemple
      resolve('command output');
    });
  }

  private parseNetstatOutput(output: string): { pid: number; name: string } {
    // Parser la sortie netstat pour extraire PID et nom du processus
    const match = output.match(/\s+(\d+)\s*$/);
    const pid = match ? parseInt(match[1]) : 0;
    return { pid, name: 'unknown' };
  }

  private getServiceForPort(port: number): string {
    const serviceMap: { [key: number]: string } = {
      8080: 'API Server',
      5432: 'PostgreSQL',
      6379: 'Redis',
      6333: 'Qdrant'
    };
    return serviceMap[port] || 'Unknown';
  }

  private async parseDockerContainers(output: string): Promise<ContainerInfo[]> {
    // Parser la sortie docker ps
    return []; // À implémenter
  }

  private async getDockerMemoryUsage(): Promise<number> {
    // Obtenir l'usage mémoire total de Docker
    return 0; // À implémenter
  }

  private async getCpuUsage(): Promise<number> {
    // Obtenir l'usage CPU
    return 0; // À implémenter
  }

  private async getMemoryUsage(): Promise<number> {
    // Obtenir l'usage mémoire
    return 0; // À implémenter
  }

  private async getDiskUsage(): Promise<number> {
    // Obtenir l'usage disque
    return 0; // À implémenter
  }

  private async getHighMemoryProcesses(): Promise<ProcessConflict[]> {
    // Détecter les processus gourmands en mémoire
    return []; // À implémenter
  }

  private async detectDuplicateProcesses(): Promise<ProcessConflict[]> {
    // Détecter les processus dupliqués
    return []; // À implémenter
  }

  private async clearPort(port: number): Promise<void> {
    // Libérer un port spécifique
    await this.executeCommand(`for /f "tokens=5" %a in ('netstat -aon ^| findstr :${port}') do taskkill /f /pid %a 2>nul`);
  }

  private sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}
