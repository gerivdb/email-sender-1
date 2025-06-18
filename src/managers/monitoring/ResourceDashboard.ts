import * as vscode from 'vscode';
import * as os from 'os';
import * as child_process from 'child_process';
import { EventEmitter } from 'events';

/**
 * Interface pour les métriques système
 */
export interface SystemMetrics {
    cpu: CPUMetrics;
    ram: MemoryMetrics;
    processes: ProcessMetrics[];
    services: ServiceMetrics[];
    disk: DiskMetrics;
    network: NetworkMetrics;
    timestamp: number;
}

export interface CPUMetrics {
    usage: number;
    cores: number;
    temperature?: number;
    frequency: number;
    loadAverage: number[];
}

export interface MemoryMetrics {
    total: number;
    used: number;
    free: number;
    available: number;
    usage: number;
    swapUsed: number;
    swapTotal: number;
}

export interface ProcessMetrics {
    pid: number;
    name: string;
    cpu: number;
    memory: number;
    status: 'running' | 'sleeping' | 'zombie' | 'stopped';
    uptime: number;
    command: string;
}

export interface ServiceMetrics {
    name: string;
    status: 'active' | 'inactive' | 'failed' | 'unknown';
    cpu: number;
    memory: number;
    restarts: number;
    uptime: number;
}

export interface DiskMetrics {
    total: number;
    used: number;
    free: number;
    usage: number;
    readSpeed: number;
    writeSpeed: number;
}

export interface NetworkMetrics {
    bytesReceived: number;
    bytesSent: number;
    packetsReceived: number;
    packetsSent: number;
    downloadSpeed: number;
    uploadSpeed: number;
}

/**
 * Interface pour les alertes prédictives
 */
export interface Alert {
    id: string;
    type: 'warning' | 'error' | 'critical';
    metric: string;
    message: string;
    threshold: number;
    currentValue: number;
    timestamp: number;
    predicted?: boolean;
    severity: 1 | 2 | 3 | 4 | 5;
}

/**
 * Interface pour les seuils d'alerte
 */
export interface AlertThresholds {
    cpu: {
        warning: number;
        error: number;
        critical: number;
    };
    memory: {
        warning: number;
        error: number;
        critical: number;
    };
    disk: {
        warning: number;
        error: number;
        critical: number;
    };
    temperature: {
        warning: number;
        error: number;
        critical: number;
    };
}

/**
 * Real-Time Resource Dashboard pour monitoring système avancé
 */
export class ResourceDashboard extends EventEmitter {
    private isMonitoring: boolean = false;
    private metricsInterval: NodeJS.Timeout | null = null;
    private currentMetrics: SystemMetrics | null = null;
    private alertHistory: Alert[] = [];
    private metricsHistory: SystemMetrics[] = [];
    private readonly maxHistorySize = 1000; // 1000 points de données
    
    private alertThresholds: AlertThresholds = {
        cpu: { warning: 70, error: 85, critical: 95 },
        memory: { warning: 75, error: 90, critical: 98 },
        disk: { warning: 80, error: 90, critical: 95 },
        temperature: { warning: 70, error: 80, critical: 90 }
    };

    constructor(
        private readonly updateInterval: number = 2000, // 2 secondes
        private readonly enablePredictiveAlerts: boolean = true
    ) {
        super();
        this.setupEmergencyHandlers();
    }

    /**
     * Démarre le monitoring en temps réel
     */
    public async startMonitoring(): Promise<void> {
        if (this.isMonitoring) {
            return;
        }

        this.isMonitoring = true;
        this.emit('monitoringStarted');

        // Collecte initiale des métriques
        await this.collectMetrics();

        // Démarrage de la collecte périodique
        this.metricsInterval = setInterval(async () => {
            try {
                await this.collectMetrics();
            } catch (error) {
                this.emit('error', new Error(`Metrics collection failed: ${error}`));
            }
        }, this.updateInterval);

        vscode.window.showInformationMessage('🚀 Resource monitoring started successfully');
    }

    /**
     * Arrête le monitoring
     */
    public stopMonitoring(): void {
        if (!this.isMonitoring) {
            return;
        }

        this.isMonitoring = false;
        
        if (this.metricsInterval) {
            clearInterval(this.metricsInterval);
            this.metricsInterval = null;
        }

        this.emit('monitoringStopped');
        vscode.window.showInformationMessage('⏹️ Resource monitoring stopped');
    }

    /**
     * Collecte les métriques système complètes
     */
    private async collectMetrics(): Promise<void> {
        try {
            const metrics: SystemMetrics = {
                cpu: await this.getCPUMetrics(),
                ram: await this.getMemoryMetrics(),
                processes: await this.getProcessMetrics(),
                services: await this.getServiceMetrics(),
                disk: await this.getDiskMetrics(),
                network: await this.getNetworkMetrics(),
                timestamp: Date.now()
            };

            this.currentMetrics = metrics;
            this.addToHistory(metrics);

            // Analyse des alertes
            await this.analyzeAlerts(metrics);

            // Prédictions si activées
            if (this.enablePredictiveAlerts) {
                await this.runPredictiveAnalysis();
            }

            this.emit('metricsUpdated', metrics);

        } catch (error) {
            this.emit('error', new Error(`Failed to collect metrics: ${error}`));
        }
    }

    /**
     * Collecte les métriques CPU
     */
    private async getCPUMetrics(): Promise<CPUMetrics> {
        const cpus = os.cpus();
        const loadAvg = os.loadavg();
        
        // Calcul d'utilisation CPU (approximation)
        let totalIdle = 0;
        let totalTick = 0;
        
        cpus.forEach(cpu => {
            for (const type in cpu.times) {
                totalTick += cpu.times[type as keyof typeof cpu.times];
            }
            totalIdle += cpu.times.idle;
        });

        const usage = Math.round(100 - (100 * totalIdle / totalTick));

        return {
            usage,
            cores: cpus.length,
            frequency: cpus[0]?.speed || 0,
            loadAverage: loadAvg,
            temperature: await this.getCPUTemperature()
        };
    }

    /**
     * Collecte les métriques mémoire
     */
    private async getMemoryMetrics(): Promise<MemoryMetrics> {
        const totalMem = os.totalmem();
        const freeMem = os.freemem();
        const usedMem = totalMem - freeMem;
        const usage = Math.round((usedMem / totalMem) * 100);

        return {
            total: Math.round(totalMem / (1024 * 1024 * 1024)), // GB
            used: Math.round(usedMem / (1024 * 1024 * 1024)), // GB
            free: Math.round(freeMem / (1024 * 1024 * 1024)), // GB
            available: Math.round(freeMem / (1024 * 1024 * 1024)), // GB
            usage,
            swapUsed: 0, // Approximation
            swapTotal: 0 // Approximation
        };
    }

    /**
     * Collecte les métriques des processus
     */
    private async getProcessMetrics(): Promise<ProcessMetrics[]> {
        try {
            return new Promise((resolve) => {
                if (process.platform === 'win32') {
                    // Windows: utiliser wmic ou Get-Process
                    child_process.exec('powershell "Get-Process | Select-Object Name,Id,CPU,WorkingSet,ProcessName | ConvertTo-Json"', 
                        (error, stdout) => {
                            if (error) {
                                resolve([]);
                                return;
                            }
                            
                            try {
                                const processes = JSON.parse(stdout);
                                const metrics = (Array.isArray(processes) ? processes : [processes])
                                    .slice(0, 10) // Top 10 processus
                                    .map((proc: any) => ({
                                        pid: proc.Id || 0,
                                        name: proc.Name || proc.ProcessName || 'Unknown',
                                        cpu: parseFloat(proc.CPU) || 0,
                                        memory: Math.round((proc.WorkingSet || 0) / (1024 * 1024)), // MB
                                        status: 'running' as const,
                                        uptime: 0,
                                        command: proc.Name || 'Unknown'
                                    }));
                                resolve(metrics);
                            } catch {
                                resolve([]);
                            }
                        });
                } else {
                    // Linux/macOS: utiliser ps
                    child_process.exec('ps aux --sort=-%cpu | head -10', (error, stdout) => {
                        if (error) {
                            resolve([]);
                            return;
                        }
                        
                        const lines = stdout.split('\n').slice(1);
                        const metrics = lines.map(line => {
                            const parts = line.trim().split(/\s+/);
                            return {
                                pid: parseInt(parts[1]) || 0,
                                name: parts[10] || 'Unknown',
                                cpu: parseFloat(parts[2]) || 0,
                                memory: parseFloat(parts[3]) || 0,
                                status: 'running' as const,
                                uptime: 0,
                                command: parts.slice(10).join(' ') || 'Unknown'
                            };
                        }).filter(p => p.pid > 0);
                        resolve(metrics);
                    });
                }
            });
        } catch {
            return [];
        }
    }

    /**
     * Collecte les métriques des services
     */
    private async getServiceMetrics(): Promise<ServiceMetrics[]> {
        // Services VS Code principaux à surveiller
        const vscodeServices = [
            'Code.exe',
            'node.exe',
            'typescript',
            'eslint',
            'git'
        ];

        return vscodeServices.map(service => ({
            name: service,
            status: 'active' as const,
            cpu: Math.random() * 10, // Simulation pour démo
            memory: Math.random() * 100,
            restarts: 0,
            uptime: Date.now()
        }));
    }

    /**
     * Collecte les métriques disque
     */
    private async getDiskMetrics(): Promise<DiskMetrics> {
        // Simulation des métriques disque
        return {
            total: 500, // GB
            used: 250, // GB
            free: 250, // GB
            usage: 50, // %
            readSpeed: Math.random() * 100, // MB/s
            writeSpeed: Math.random() * 50 // MB/s
        };
    }

    /**
     * Collecte les métriques réseau
     */
    private async getNetworkMetrics(): Promise<NetworkMetrics> {
        // Simulation des métriques réseau
        return {
            bytesReceived: Math.floor(Math.random() * 1000000),
            bytesSent: Math.floor(Math.random() * 500000),
            packetsReceived: Math.floor(Math.random() * 10000),
            packetsSent: Math.floor(Math.random() * 5000),
            downloadSpeed: Math.random() * 50, // MB/s
            uploadSpeed: Math.random() * 20 // MB/s
        };
    }

    /**
     * Obtient la température CPU (si disponible)
     */
    private async getCPUTemperature(): Promise<number | undefined> {
        // Implémentation spécifique à la plateforme
        if (process.platform === 'win32') {
            // Windows: utiliser WMI si disponible
            return Math.random() * 30 + 40; // Simulation 40-70°C
        }
        return undefined;
    }

    /**
     * Analyse les alertes basées sur les seuils
     */
    private async analyzeAlerts(metrics: SystemMetrics): Promise<void> {
        const alerts: Alert[] = [];

        // Alerte CPU
        if (metrics.cpu.usage >= this.alertThresholds.cpu.critical) {
            alerts.push(this.createAlert('critical', 'cpu', 'Critical CPU usage detected', 
                this.alertThresholds.cpu.critical, metrics.cpu.usage));
        } else if (metrics.cpu.usage >= this.alertThresholds.cpu.error) {
            alerts.push(this.createAlert('error', 'cpu', 'High CPU usage detected', 
                this.alertThresholds.cpu.error, metrics.cpu.usage));
        } else if (metrics.cpu.usage >= this.alertThresholds.cpu.warning) {
            alerts.push(this.createAlert('warning', 'cpu', 'Elevated CPU usage detected', 
                this.alertThresholds.cpu.warning, metrics.cpu.usage));
        }

        // Alerte Mémoire
        if (metrics.ram.usage >= this.alertThresholds.memory.critical) {
            alerts.push(this.createAlert('critical', 'memory', 'Critical memory usage detected', 
                this.alertThresholds.memory.critical, metrics.ram.usage));
        } else if (metrics.ram.usage >= this.alertThresholds.memory.error) {
            alerts.push(this.createAlert('error', 'memory', 'High memory usage detected', 
                this.alertThresholds.memory.error, metrics.ram.usage));
        } else if (metrics.ram.usage >= this.alertThresholds.memory.warning) {
            alerts.push(this.createAlert('warning', 'memory', 'Elevated memory usage detected', 
                this.alertThresholds.memory.warning, metrics.ram.usage));
        }

        // Alerte Disque
        if (metrics.disk.usage >= this.alertThresholds.disk.critical) {
            alerts.push(this.createAlert('critical', 'disk', 'Critical disk usage detected', 
                this.alertThresholds.disk.critical, metrics.disk.usage));
        }

        // Alerte Température
        if (metrics.cpu.temperature && metrics.cpu.temperature >= this.alertThresholds.temperature.critical) {
            alerts.push(this.createAlert('critical', 'temperature', 'Critical CPU temperature detected', 
                this.alertThresholds.temperature.critical, metrics.cpu.temperature));
        }

        // Ajout des nouvelles alertes
        for (const alert of alerts) {
            this.addAlert(alert);
        }
    }

    /**
     * Analyse prédictive des tendances
     */
    private async runPredictiveAnalysis(): Promise<void> {
        if (this.metricsHistory.length < 10) {
            return; // Pas assez de données
        }

        const recentMetrics = this.metricsHistory.slice(-10);
        
        // Prédiction CPU
        const cpuTrend = this.calculateTrend(recentMetrics.map(m => m.cpu.usage));
        if (cpuTrend.slope > 2 && cpuTrend.prediction > this.alertThresholds.cpu.warning) {
            const alert = this.createAlert('warning', 'cpu', 
                `CPU usage trending upward - predicted ${cpuTrend.prediction.toFixed(1)}% in next period`,
                this.alertThresholds.cpu.warning, cpuTrend.prediction, true);
            this.addAlert(alert);
        }

        // Prédiction Mémoire
        const memoryTrend = this.calculateTrend(recentMetrics.map(m => m.ram.usage));
        if (memoryTrend.slope > 1 && memoryTrend.prediction > this.alertThresholds.memory.warning) {
            const alert = this.createAlert('warning', 'memory', 
                `Memory usage trending upward - predicted ${memoryTrend.prediction.toFixed(1)}% in next period`,
                this.alertThresholds.memory.warning, memoryTrend.prediction, true);
            this.addAlert(alert);
        }
    }

    /**
     * Calcule la tendance pour une série de valeurs
     */
    private calculateTrend(values: number[]): { slope: number; prediction: number } {
        const n = values.length;
        const sumX = (n * (n - 1)) / 2;
        const sumY = values.reduce((a, b) => a + b, 0);
        const sumXY = values.reduce((sum, y, x) => sum + x * y, 0);
        const sumX2 = values.reduce((sum, _, x) => sum + x * x, 0);

        const slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
        const intercept = (sumY - slope * sumX) / n;
        const prediction = slope * n + intercept;

        return { slope, prediction: Math.max(0, Math.min(100, prediction)) };
    }

    /**
     * Crée une nouvelle alerte
     */
    private createAlert(
        type: Alert['type'], 
        metric: string, 
        message: string, 
        threshold: number, 
        currentValue: number,
        predicted: boolean = false
    ): Alert {
        const severity = type === 'critical' ? 5 : type === 'error' ? 4 : type === 'warning' ? 3 : 2;
        
        return {
            id: `${metric}-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
            type,
            metric,
            message,
            threshold,
            currentValue,
            timestamp: Date.now(),
            predicted,
            severity
        };
    }

    /**
     * Ajoute une alerte à l'historique
     */
    private addAlert(alert: Alert): void {
        this.alertHistory.unshift(alert);
        
        // Limite l'historique des alertes
        if (this.alertHistory.length > 100) {
            this.alertHistory = this.alertHistory.slice(0, 100);
        }

        this.emit('alertGenerated', alert);

        // Affichage dans VS Code selon la sévérité
        const icon = alert.predicted ? '🔮' : alert.type === 'critical' ? '🚨' : alert.type === 'error' ? '⚠️' : '💡';
        const prefix = alert.predicted ? 'PREDICTED' : alert.type.toUpperCase();
        
        if (alert.type === 'critical') {
            vscode.window.showErrorMessage(`${icon} [${prefix}] ${alert.message}`);
        } else if (alert.type === 'error') {
            vscode.window.showWarningMessage(`${icon} [${prefix}] ${alert.message}`);
        } else {
            vscode.window.showInformationMessage(`${icon} [${prefix}] ${alert.message}`);
        }
    }

    /**
     * Ajoute des métriques à l'historique
     */
    private addToHistory(metrics: SystemMetrics): void {
        this.metricsHistory.push(metrics);
        
        // Limite l'historique
        if (this.metricsHistory.length > this.maxHistorySize) {
            this.metricsHistory = this.metricsHistory.slice(-this.maxHistorySize);
        }
    }

    /**
     * Configuration des gestionnaires d'urgence
     */
    private setupEmergencyHandlers(): void {
        // Gestionnaire d'arrêt d'urgence
        this.on('emergencyStop', () => {
            this.handleEmergencyStop();
        });

        // Gestionnaire de récupération
        this.on('recovery', () => {
            this.handleRecovery();
        });
    }

    /**
     * Gestionnaire d'arrêt d'urgence
     */
    private async handleEmergencyStop(): Promise<void> {
        vscode.window.showWarningMessage('🚨 Emergency stop initiated - Graceful shutdown in progress...');
        
        try {
            // Arrêt du monitoring
            this.stopMonitoring();
            
            // Sauvegarde de l'état actuel
            await this.preserveState();
            
            // Notification de l'arrêt d'urgence
            this.emit('emergencyStopCompleted');
            
            vscode.window.showInformationMessage('✅ Emergency stop completed successfully');
        } catch (error) {
            vscode.window.showErrorMessage(`❌ Emergency stop failed: ${error}`);
        }
    }

    /**
     * Gestionnaire de récupération
     */
    private async handleRecovery(): Promise<void> {
        vscode.window.showInformationMessage('🔄 Recovery procedures initiated...');
        
        try {
            // Restauration de l'état
            await this.restoreState();
            
            // Redémarrage du monitoring
            await this.startMonitoring();
            
            this.emit('recoveryCompleted');
            
            vscode.window.showInformationMessage('✅ Recovery completed successfully');
        } catch (error) {
            vscode.window.showErrorMessage(`❌ Recovery failed: ${error}`);
        }
    }

    /**
     * Sauvegarde l'état actuel du système
     */
    private async preserveState(): Promise<void> {
        const state = {
            metrics: this.currentMetrics,
            alerts: this.alertHistory.slice(0, 10), // Dernières 10 alertes
            thresholds: this.alertThresholds,
            timestamp: Date.now()
        };

        // Simulation de sauvegarde
        this.emit('stateSaved', state);
    }

    /**
     * Restaure l'état précédent du système
     */
    private async restoreState(): Promise<void> {
        // Simulation de restauration
        this.emit('stateRestored');
    }

    // Getters publics
    public getCurrentMetrics(): SystemMetrics | null {
        return this.currentMetrics;
    }

    public getAlerts(limit: number = 20): Alert[] {
        return this.alertHistory.slice(0, limit);
    }

    public getMetricsHistory(limit: number = 100): SystemMetrics[] {
        return this.metricsHistory.slice(-limit);
    }

    public isMonitoringActive(): boolean {
        return this.isMonitoring;
    }

    public updateThresholds(thresholds: Partial<AlertThresholds>): void {
        this.alertThresholds = { ...this.alertThresholds, ...thresholds };
        this.emit('thresholdsUpdated', this.alertThresholds);
    }

    /**
     * Déclenche un arrêt d'urgence
     */
    public triggerEmergencyStop(): void {
        this.emit('emergencyStop');
    }

    /**
     * Déclenche une procédure de récupération
     */
    public triggerRecovery(): void {
        this.emit('recovery');
    }

    /**
     * Nettoyage des ressources
     */
    public dispose(): void {
        this.stopMonitoring();
        this.removeAllListeners();
    }
}
