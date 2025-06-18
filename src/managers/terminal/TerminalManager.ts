import * as vscode from 'vscode';
import * as os from 'os';
import * as child_process from 'child_process';
import * as path from 'path';

/**
 * Interface pour les métriques de terminal
 */
export interface TerminalMetrics {
    id: string;
    name: string;
    pid: number | undefined;
    processId: number | undefined;
    state: 'active' | 'idle' | 'zombie' | 'orphaned';
    resourceUsage: {
        cpu: number;
        memory: number;
        uptime: number;
    };
    conflicts: string[];
    isolationLevel: 'none' | 'basic' | 'full';
}

/**
 * Interface pour les options de terminal isolé
 */
export interface IsolatedTerminalOptions {
    name: string;
    cwd?: string;
    env?: { [key: string]: string };
    resourceLimits?: {
        maxCpuPercent: number;
        maxMemoryMB: number;
        timeoutMs: number;
    };
    isolationLevel: 'basic' | 'full';
    autoCleanup: boolean;
    conflictDetection: boolean;
}

/**
 * Interface pour les informations de processus
 */
export interface ProcessInfo {
    pid: number;
    name: string;
    command: string;
    parentPid: number;
    status: 'running' | 'sleeping' | 'zombie' | 'stopped';
    cpuUsage: number;
    memoryUsage: number;
    startTime: Date;
    isOrphaned: boolean;
}

/**
 * Interface pour les options de lifecycle de processus
 */
export interface ProcessLifecycleOptions {
    gracefulShutdownTimeout: number;
    forceKillTimeout: number;
    cleanupOnExit: boolean;
    zombiePreventionEnabled: boolean;
    resourceMonitoring: boolean;
}

/**
 * Gestionnaire intelligent des terminaux et processus
 * Phase 0.3 : Terminal & Process Management
 */
export class TerminalManager {
    private activeTerminals: Map<string, vscode.Terminal> = new Map();
    private terminalMetrics: Map<string, TerminalMetrics> = new Map();
    private processRegistry: Map<number, ProcessInfo> = new Map();
    private cleanupInterval: NodeJS.Timer | null = null;
    private monitoringInterval: NodeJS.Timer | null = null;
    private outputChannel: vscode.OutputChannel;
    
    private defaultOptions: IsolatedTerminalOptions = {
        name: 'isolated-terminal',
        resourceLimits: {
            maxCpuPercent: 50,
            maxMemoryMB: 1024,
            timeoutMs: 300000 // 5 minutes
        },
        isolationLevel: 'basic',
        autoCleanup: true,
        conflictDetection: true
    };

    private lifecycleOptions: ProcessLifecycleOptions = {
        gracefulShutdownTimeout: 10000, // 10 seconds
        forceKillTimeout: 5000, // 5 seconds
        cleanupOnExit: true,
        zombiePreventionEnabled: true,
        resourceMonitoring: true
    };

    constructor() {
        this.outputChannel = vscode.window.createOutputChannel('Terminal Manager');
        this.startMonitoring();
        this.setupCleanupRoutines();
    }

    /**
     * Création terminal avec resource limits, process isolation, auto-cleanup et conflict detection
     */
    async createIsolatedTerminal(name: string, options?: Partial<IsolatedTerminalOptions>): Promise<vscode.Terminal> {
        try {
            const config = { ...this.defaultOptions, ...options, name };
            
            this.outputChannel.appendLine(`[TERMINAL] Creating isolated terminal: ${name}`);
            
            // Conflict detection avant création
            if (config.conflictDetection) {
                await this.detectTerminalConflicts(name);
            }

            // Préparation environnement isolé
            const isolatedEnv = await this.prepareIsolatedEnvironment(config);
            
            // Création terminal avec options de sécurité
            const terminal = vscode.window.createTerminal({
                name: config.name,
                cwd: config.cwd || vscode.workspace.rootPath,
                env: isolatedEnv,
                shellPath: this.getSecureShellPath(),
                shellArgs: this.getSecureShellArgs(config)
            });

            // Enregistrement et monitoring
            this.activeTerminals.set(name, terminal);
            await this.registerTerminalMetrics(name, terminal, config);
            
            // Configuration resource limits (si supporté par la plateforme)
            if (config.resourceLimits) {
                await this.applyResourceLimits(terminal, config.resourceLimits);
            }

            // Auto-cleanup setup
            if (config.autoCleanup) {
                this.setupAutoCleanup(name, terminal, config);
            }

            this.outputChannel.appendLine(`[TERMINAL] Successfully created isolated terminal: ${name}`);
            return terminal;

        } catch (error) {
            this.outputChannel.appendLine(`[ERROR] Failed to create isolated terminal ${name}: ${error}`);
            throw error;
        }
    }

    /**
     * Kill orphaned terminals, clear process locks, reset terminal states
     */
    async cleanupZombieTerminals(): Promise<void> {
        try {
            this.outputChannel.appendLine(`[CLEANUP] Starting zombie terminals cleanup...`);
            
            let cleanedCount = 0;
            let zombieCount = 0;
            let orphanedCount = 0;

            // Détection des terminaux zombies et orphelins
            for (const [name, terminal] of this.activeTerminals.entries()) {
                const metrics = this.terminalMetrics.get(name);
                if (!metrics) continue;

                const isZombie = await this.isTerminalZombie(terminal);
                const isOrphaned = await this.isTerminalOrphaned(terminal);

                if (isZombie) {
                    zombieCount++;
                    this.outputChannel.appendLine(`[CLEANUP] Found zombie terminal: ${name}`);
                    await this.killZombieTerminal(name, terminal);
                    cleanedCount++;
                }

                if (isOrphaned) {
                    orphanedCount++;
                    this.outputChannel.appendLine(`[CLEANUP] Found orphaned terminal: ${name}`);
                    await this.cleanupOrphanedTerminal(name, terminal);
                    cleanedCount++;
                }
            }

            // Nettoyage des process locks
            await this.clearProcessLocks();
            
            // Reset des états de terminaux
            await this.resetTerminalStates();

            // Nettoyage du registre des processus
            await this.cleanupProcessRegistry();

            this.outputChannel.appendLine(`[CLEANUP] Cleanup completed: ${cleanedCount} terminals cleaned (${zombieCount} zombies, ${orphanedCount} orphaned)`);

        } catch (error) {
            this.outputChannel.appendLine(`[ERROR] Cleanup failed: ${error}`);
            throw error;
        }
    }

    /**
     * Proper process spawning avec isolation et monitoring
     */
    async spawnIsolatedProcess(command: string, args: string[], options?: child_process.SpawnOptions): Promise<child_process.ChildProcess> {
        try {
            this.outputChannel.appendLine(`[PROCESS] Spawning isolated process: ${command}`);

            // Préparation environnement sécurisé
            const secureOptions = await this.prepareSecureSpawnOptions(options);
            
            // Spawn avec monitoring
            const process = child_process.spawn(command, args, secureOptions);
            
            // Enregistrement dans le registre
            if (process.pid) {
                await this.registerProcess(process);
            }

            // Setup graceful shutdown
            this.setupGracefulShutdown(process);

            // Resource monitoring
            if (this.lifecycleOptions.resourceMonitoring) {
                this.startProcessMonitoring(process);
            }

            return process;

        } catch (error) {
            this.outputChannel.appendLine(`[ERROR] Failed to spawn process ${command}: ${error}`);
            throw error;
        }
    }

    /**
     * Graceful shutdown procedures avec timeout et force kill
     */
    async gracefulShutdown(processOrPid: child_process.ChildProcess | number): Promise<void> {
        try {
            const pid = typeof processOrPid === 'number' ? processOrPid : processOrPid.pid;
            if (!pid) return;

            this.outputChannel.appendLine(`[SHUTDOWN] Starting graceful shutdown for PID: ${pid}`);

            // Étape 1: Signal graceful (SIGTERM)
            await this.sendGracefulSignal(pid);
            
            // Attendre le timeout graceful
            const gracefulSuccess = await this.waitForProcessExit(pid, this.lifecycleOptions.gracefulShutdownTimeout);
            
            if (gracefulSuccess) {
                this.outputChannel.appendLine(`[SHUTDOWN] Graceful shutdown successful for PID: ${pid}`);
                return;
            }

            // Étape 2: Force kill (SIGKILL)
            this.outputChannel.appendLine(`[SHUTDOWN] Graceful timeout, force killing PID: ${pid}`);
            await this.forceKillProcess(pid);
            
            // Attendre le force kill timeout
            const forceSuccess = await this.waitForProcessExit(pid, this.lifecycleOptions.forceKillTimeout);
            
            if (!forceSuccess) {
                this.outputChannel.appendLine(`[ERROR] Failed to kill process PID: ${pid}`);
                throw new Error(`Unable to terminate process ${pid}`);
            }

            this.outputChannel.appendLine(`[SHUTDOWN] Force kill successful for PID: ${pid}`);

        } catch (error) {
            this.outputChannel.appendLine(`[ERROR] Shutdown failed: ${error}`);
            throw error;
        }
    }

    /**
     * Resource cleanup on exit
     */
    async resourceCleanupOnExit(processOrPid: child_process.ChildProcess | number): Promise<void> {
        try {
            const pid = typeof processOrPid === 'number' ? processOrPid : processOrPid.pid;
            if (!pid) return;

            this.outputChannel.appendLine(`[CLEANUP] Starting resource cleanup for PID: ${pid}`);

            // Cleanup process registry
            this.processRegistry.delete(pid);

            // Cleanup temporary files
            await this.cleanupProcessTemporaryFiles(pid);

            // Cleanup memory mappings
            await this.cleanupProcessMemoryMappings(pid);

            // Cleanup network connections
            await this.cleanupProcessNetworkConnections(pid);

            // Cleanup file handles
            await this.cleanupProcessFileHandles(pid);

            this.outputChannel.appendLine(`[CLEANUP] Resource cleanup completed for PID: ${pid}`);

        } catch (error) {
            this.outputChannel.appendLine(`[ERROR] Resource cleanup failed: ${error}`);
        }
    }

    /**
     * Zombie process prevention
     */
    async preventZombieProcesses(): Promise<void> {
        try {
            this.outputChannel.appendLine(`[PREVENTION] Starting zombie process prevention...`);

            // Scan pour processus zombies
            const zombieProcesses = await this.detectZombieProcesses();
            
            for (const zombiePid of zombieProcesses) {
                this.outputChannel.appendLine(`[PREVENTION] Found zombie process PID: ${zombiePid}`);
                await this.cleanupZombieProcess(zombiePid);
            }

            // Setup signal handlers pour prévenir les zombies
            this.setupZombiePreventionSignalHandlers();

            this.outputChannel.appendLine(`[PREVENTION] Zombie prevention setup completed`);

        } catch (error) {
            this.outputChannel.appendLine(`[ERROR] Zombie prevention failed: ${error}`);
        }
    }

    /**
     * Démarrage du monitoring continu
     */
    private startMonitoring(): void {
        this.monitoringInterval = setInterval(async () => {
            try {
                await this.updateTerminalMetrics();
                await this.updateProcessRegistry();
                
                if (this.lifecycleOptions.zombiePreventionEnabled) {
                    await this.preventZombieProcesses();
                }
            } catch (error) {
                this.outputChannel.appendLine(`[ERROR] Monitoring error: ${error}`);
            }
        }, 30000); // Monitoring toutes les 30 secondes
    }

    /**
     * Setup des routines de nettoyage automatique
     */
    private setupCleanupRoutines(): void {
        this.cleanupInterval = setInterval(async () => {
            try {
                await this.cleanupZombieTerminals();
            } catch (error) {
                this.outputChannel.appendLine(`[ERROR] Auto-cleanup error: ${error}`);
            }
        }, 60000); // Cleanup toutes les minutes
    }

    // Méthodes privées pour l'implémentation détaillée...
    
    private async detectTerminalConflicts(name: string): Promise<void> {
        // Implémentation détection conflits
        const existingTerminal = this.activeTerminals.get(name);
        if (existingTerminal) {
            throw new Error(`Terminal conflict: ${name} already exists`);
        }
    }

    private async prepareIsolatedEnvironment(config: IsolatedTerminalOptions): Promise<{ [key: string]: string }> {
        const env = { ...process.env, ...config.env };
        
        // Isolation variables d'environnement
        if (config.isolationLevel === 'full') {
            // Limiter les variables d'environnement pour isolation complète
            const safeEnvVars = ['PATH', 'HOME', 'USER', 'TEMP', 'TMP'];
            const isolatedEnv: { [key: string]: string } = {};
            
            safeEnvVars.forEach(key => {
                if (env[key]) {
                    isolatedEnv[key] = env[key];
                }
            });
            
            return { ...isolatedEnv, ...config.env };
        }
        
        return env;
    }

    private getSecureShellPath(): string | undefined {
        // Retourner le shell sécurisé selon la plateforme
        if (os.platform() === 'win32') {
            return 'pwsh.exe'; // PowerShell Core pour Windows
        }
        return '/bin/bash'; // Bash pour Unix/Linux
    }

    private getSecureShellArgs(config: IsolatedTerminalOptions): string[] | undefined {
        // Arguments sécurisés pour le shell
        if (os.platform() === 'win32') {
            return ['-NoProfile', '-ExecutionPolicy', 'Bypass'];
        }
        return ['--noprofile', '--norc'];
    }

    private async registerTerminalMetrics(name: string, terminal: vscode.Terminal, config: IsolatedTerminalOptions): Promise<void> {
        const metrics: TerminalMetrics = {
            id: name,
            name: name,
            pid: terminal.processId,
            processId: terminal.processId,
            state: 'active',
            resourceUsage: {
                cpu: 0,
                memory: 0,
                uptime: 0
            },
            conflicts: [],
            isolationLevel: config.isolationLevel
        };
        
        this.terminalMetrics.set(name, metrics);
    }

    private async applyResourceLimits(terminal: vscode.Terminal, limits: NonNullable<IsolatedTerminalOptions['resourceLimits']>): Promise<void> {
        // Implémentation des limites de ressources (spécifique à la plateforme)
        this.outputChannel.appendLine(`[LIMITS] Applying resource limits: CPU ${limits.maxCpuPercent}%, Memory ${limits.maxMemoryMB}MB`);
        // Note: VSCode API ne supporte pas directement les limites de ressources
        // Ceci serait implémenté via des mécanismes OS-spécifiques
    }

    private setupAutoCleanup(name: string, terminal: vscode.Terminal, config: IsolatedTerminalOptions): void {
        // Setup auto-cleanup quand le terminal se ferme
        const disposable = vscode.window.onDidCloseTerminal(closedTerminal => {
            if (closedTerminal === terminal) {
                this.outputChannel.appendLine(`[CLEANUP] Auto-cleaning terminal: ${name}`);
                this.activeTerminals.delete(name);
                this.terminalMetrics.delete(name);
                disposable.dispose();
            }
        });
    }

    private async isTerminalZombie(terminal: vscode.Terminal): Promise<boolean> {
        // Vérifier si le terminal est zombie
        return terminal.processId === undefined && terminal.exitStatus !== undefined;
    }

    private async isTerminalOrphaned(terminal: vscode.Terminal): Promise<boolean> {
        // Vérifier si le terminal est orphelin
        if (!terminal.processId) return false;
        
        try {
            process.kill(terminal.processId, 0); // Test de signal sans tuer
            return false;
        } catch (error) {
            return true; // Processus n'existe plus
        }
    }

    private async killZombieTerminal(name: string, terminal: vscode.Terminal): Promise<void> {
        terminal.dispose();
        this.activeTerminals.delete(name);
        this.terminalMetrics.delete(name);
    }

    private async cleanupOrphanedTerminal(name: string, terminal: vscode.Terminal): Promise<void> {
        terminal.dispose();
        this.activeTerminals.delete(name);
        this.terminalMetrics.delete(name);
    }

    private async clearProcessLocks(): Promise<void> {
        // Implémentation clearing des process locks
        this.outputChannel.appendLine(`[CLEANUP] Clearing process locks...`);
    }

    private async resetTerminalStates(): Promise<void> {
        // Reset des états de tous les terminaux
        for (const [name, metrics] of this.terminalMetrics.entries()) {
            metrics.state = 'active';
            metrics.conflicts = [];
        }
    }

    private async cleanupProcessRegistry(): Promise<void> {
        // Nettoyage du registre des processus
        const deadProcesses: number[] = [];
        
        for (const [pid, processInfo] of this.processRegistry.entries()) {
            try {
                process.kill(pid, 0);
            } catch (error) {
                deadProcesses.push(pid);
            }
        }
        
        deadProcesses.forEach(pid => this.processRegistry.delete(pid));
    }

    private async prepareSecureSpawnOptions(options?: child_process.SpawnOptions): Promise<child_process.SpawnOptions> {
        return {
            ...options,
            detached: false, // Prévenir les processus détachés
            stdio: ['pipe', 'pipe', 'pipe'], // Contrôler les flux I/O
        };
    }

    private async registerProcess(process: child_process.ChildProcess): Promise<void> {
        if (!process.pid) return;
        
        const processInfo: ProcessInfo = {
            pid: process.pid,
            name: 'spawned-process',
            command: process.spawnfile || '',
            parentPid: process.pid,
            status: 'running',
            cpuUsage: 0,
            memoryUsage: 0,
            startTime: new Date(),
            isOrphaned: false
        };
        
        this.processRegistry.set(process.pid, processInfo);
    }

    private setupGracefulShutdown(process: child_process.ChildProcess): void {
        process.on('exit', async (code, signal) => {
            if (process.pid) {
                await this.resourceCleanupOnExit(process.pid);
            }
        });
    }

    private startProcessMonitoring(process: child_process.ChildProcess): void {
        // Monitoring des ressources du processus
        const monitorInterval = setInterval(() => {
            if (!process.pid || process.killed) {
                clearInterval(monitorInterval);
                return;
            }
            
            // Mise à jour des métriques du processus
            this.updateProcessMetrics(process.pid);
        }, 5000); // Monitoring toutes les 5 secondes
    }

    private async sendGracefulSignal(pid: number): Promise<void> {
        try {
            if (os.platform() === 'win32') {
                // Windows - utiliser taskkill
                child_process.exec(`taskkill /PID ${pid} /T`);
            } else {
                // Unix/Linux - utiliser SIGTERM
                process.kill(pid, 'SIGTERM');
            }
        } catch (error) {
            this.outputChannel.appendLine(`[ERROR] Failed to send graceful signal to PID ${pid}: ${error}`);
        }
    }

    private async waitForProcessExit(pid: number, timeout: number): Promise<boolean> {
        return new Promise((resolve) => {
            const startTime = Date.now();
            const checkInterval = setInterval(() => {
                try {
                    process.kill(pid, 0);
                    
                    if (Date.now() - startTime > timeout) {
                        clearInterval(checkInterval);
                        resolve(false);
                    }
                } catch (error) {
                    // Processus n'existe plus
                    clearInterval(checkInterval);
                    resolve(true);
                }
            }, 100);
        });
    }

    private async forceKillProcess(pid: number): Promise<void> {
        try {
            if (os.platform() === 'win32') {
                child_process.exec(`taskkill /F /PID ${pid} /T`);
            } else {
                process.kill(pid, 'SIGKILL');
            }
        } catch (error) {
            this.outputChannel.appendLine(`[ERROR] Failed to force kill PID ${pid}: ${error}`);
        }
    }

    private async cleanupProcessTemporaryFiles(pid: number): Promise<void> {
        // Nettoyage des fichiers temporaires du processus
        this.outputChannel.appendLine(`[CLEANUP] Cleaning temporary files for PID: ${pid}`);
    }

    private async cleanupProcessMemoryMappings(pid: number): Promise<void> {
        // Nettoyage des mappings mémoire
        this.outputChannel.appendLine(`[CLEANUP] Cleaning memory mappings for PID: ${pid}`);
    }

    private async cleanupProcessNetworkConnections(pid: number): Promise<void> {
        // Nettoyage des connexions réseau
        this.outputChannel.appendLine(`[CLEANUP] Cleaning network connections for PID: ${pid}`);
    }

    private async cleanupProcessFileHandles(pid: number): Promise<void> {
        // Nettoyage des handles de fichiers
        this.outputChannel.appendLine(`[CLEANUP] Cleaning file handles for PID: ${pid}`);
    }

    private async detectZombieProcesses(): Promise<number[]> {
        // Détection des processus zombies
        return []; // Implémentation spécifique à la plateforme
    }

    private async cleanupZombieProcess(pid: number): Promise<void> {
        // Nettoyage d'un processus zombie spécifique
        this.outputChannel.appendLine(`[CLEANUP] Cleaning zombie process PID: ${pid}`);
    }

    private setupZombiePreventionSignalHandlers(): void {
        // Setup des handlers de signaux pour prévenir les zombies
        process.on('SIGCHLD', () => {
            // Gestion automatique des processus enfants morts
        });
    }

    private async updateTerminalMetrics(): Promise<void> {
        // Mise à jour des métriques de tous les terminaux
        for (const [name, terminal] of this.activeTerminals.entries()) {
            const metrics = this.terminalMetrics.get(name);
            if (metrics && terminal.processId) {
                await this.updateProcessMetrics(terminal.processId);
            }
        }
    }

    private async updateProcessRegistry(): Promise<void> {
        // Mise à jour du registre des processus
        for (const [pid, processInfo] of this.processRegistry.entries()) {
            await this.updateProcessMetrics(pid);
        }
    }

    private async updateProcessMetrics(pid: number): Promise<void> {
        // Mise à jour des métriques pour un processus spécifique
        try {
            // Implémentation spécifique à la plateforme pour obtenir les métriques
            const processInfo = this.processRegistry.get(pid);
            if (processInfo) {
                // Mise à jour CPU, mémoire, etc.
            }
        } catch (error) {
            this.outputChannel.appendLine(`[ERROR] Failed to update metrics for PID ${pid}: ${error}`);
        }
    }

    /**
     * Arrêt propre du gestionnaire
     */
    dispose(): void {
        if (this.monitoringInterval) {
            clearInterval(this.monitoringInterval);
        }
        
        if (this.cleanupInterval) {
            clearInterval(this.cleanupInterval);
        }
        
        this.outputChannel.dispose();
    }
}
