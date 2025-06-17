import * as vscode from 'vscode';
import { ResourceManager, ResourceMetrics } from './ResourceManager';
import { IDEPerformanceGuardian, IDEPerformanceMetrics } from './IDEPerformanceGuardian';

/**
 * Interface pour la configuration globale de performance
 */
export interface PerformanceManagerConfig {
    resourceManager: {
        maxCpuUsage: number;
        maxRamUsage: number;
        monitoringInterval: number;
        enableContinuousMonitoring: boolean;
    };
    performanceGuardian: {
        maxUIResponseTime: number;
        maxAsyncOperationTime: number;
        workerThreadPoolSize: number;
        memoryCleanupInterval: number;
        enableFreezePreventionlast: boolean;
    };
    emergencyMode: {
        enabled: boolean;
        cpuThreshold: number;
        memoryThreshold: number;
        autoOptimization: boolean;
    };
}

/**
 * Interface pour le rapport de performance global
 */
export interface GlobalPerformanceReport {
    timestamp: Date;
    system: ResourceMetrics;
    ide: IDEPerformanceMetrics;
    overallHealth: 'excellent' | 'good' | 'warning' | 'critical';
    recommendations: string[];
    emergencyActionsTriggered: string[];
}

/**
 * Gestionnaire principal de performance - Phase 0.2
 * Intègre ResourceManager et IDEPerformanceGuardian
 */
export class PerformanceManager {
    private resourceManager: ResourceManager;
    private performanceGuardian: IDEPerformanceGuardian;
    private outputChannel: vscode.OutputChannel;
    private isActive = false;
    private reportingInterval: NodeJS.Timer | null = null;
    
    private config: PerformanceManagerConfig = {
        resourceManager: {
            maxCpuUsage: 70,
            maxRamUsage: 6,
            monitoringInterval: 5000,
            enableContinuousMonitoring: true
        },
        performanceGuardian: {
            maxUIResponseTime: 100,
            maxAsyncOperationTime: 5000,
            workerThreadPoolSize: 4,
            memoryCleanupInterval: 30000,
            enableFreezePreventionlast: true
        },
        emergencyMode: {
            enabled: true,
            cpuThreshold: 85,
            memoryThreshold: 90,
            autoOptimization: true
        }
    };

    constructor(config?: Partial<PerformanceManagerConfig>) {
        this.config = { ...this.config, ...config };
        this.resourceManager = new ResourceManager();
        this.performanceGuardian = new IDEPerformanceGuardian();
        this.outputChannel = vscode.window.createOutputChannel('Performance Manager');
    }

    /**
     * Initialisation complète du gestionnaire de performance
     */
    async initialize(): Promise<void> {
        this.outputChannel.appendLine('🚀 Initializing Performance Manager - Phase 0.2...');

        try {
            // Configuration des composants
            await this.setupResourceManager();
            await this.setupPerformanceGuardian();
            await this.setupEmergencyMode();
            await this.registerCommands();

            this.isActive = true;
            this.outputChannel.appendLine('✅ Performance Manager initialized successfully');

            // Démarrage du monitoring
            if (this.config.resourceManager.enableContinuousMonitoring) {
                await this.startIntegratedMonitoring();
            }

        } catch (error) {
            this.outputChannel.appendLine(`❌ Error initializing Performance Manager: ${error}`);
            throw error;
        }
    }

    /**
     * Génération d'un rapport de performance global
     */
    async generatePerformanceReport(): Promise<GlobalPerformanceReport> {
        try {
            this.outputChannel.appendLine('📊 Generating global performance report...');

            const systemMetrics = await this.resourceManager.monitorResourceUsage();
            const ideMetrics = await this.performanceGuardian.collectPerformanceMetrics();
            
            const overallHealth = this.calculateOverallHealth(systemMetrics, ideMetrics);
            const recommendations = this.generateRecommendations(systemMetrics, ideMetrics, overallHealth);
            const emergencyActions = this.checkEmergencyActions(systemMetrics, ideMetrics);

            const report: GlobalPerformanceReport = {
                timestamp: new Date(),
                system: systemMetrics,
                ide: ideMetrics,
                overallHealth,
                recommendations,
                emergencyActionsTriggered: emergencyActions
            };

            this.outputChannel.appendLine(`📈 Performance report generated - Health: ${overallHealth.toUpperCase()}`);
            return report;

        } catch (error) {
            this.outputChannel.appendLine(`❌ Error generating performance report: ${error}`);
            throw error;
        }
    }

    /**
     * Optimisation complète du système
     */
    async performCompleteOptimization(): Promise<void> {
        this.outputChannel.appendLine('⚡ Performing complete system optimization...');

        try {
            // Optimisation des ressources système
            await this.resourceManager.optimizeResourceAllocation({
                enableCpuThrottling: true,
                enableMemoryCleanup: true,
                enableProcessPrioritization: true,
                maxCpuUsage: this.config.resourceManager.maxCpuUsage,
                maxRamUsage: this.config.resourceManager.maxRamUsage
            });

            // Optimisation multiprocesseur
            await this.resourceManager.optimizeMultiprocessor();

            // Optimisation de la performance IDE
            await this.performanceGuardian.optimizeExtensionPerformance({
                enableLazyLoading: true,
                enableWorkerThreads: true,
                enableMemoryCleanup: true,
                enableAPICallDebouncing: true,
                workerThreadPoolSize: this.config.performanceGuardian.workerThreadPoolSize,
                memoryCleanupInterval: this.config.performanceGuardian.memoryCleanupInterval
            });

            // Configuration des failsafes
            await this.performanceGuardian.setupEmergencyFailsafeMechanisms();

            this.outputChannel.appendLine('✅ Complete optimization finished successfully');

            // Notification utilisateur
            vscode.window.showInformationMessage(
                '🎯 System optimization completed successfully!',
                'View Report', 'Performance Dashboard'
            ).then(selection => {
                if (selection === 'View Report') {
                    this.showPerformanceReport();
                } else if (selection === 'Performance Dashboard') {
                    this.openPerformanceDashboard();
                }
            });

        } catch (error) {
            this.outputChannel.appendLine(`❌ Error during complete optimization: ${error}`);
            vscode.window.showErrorMessage(`Optimization failed: ${error}`);
            throw error;
        }
    }

    /**
     * Mode d'urgence activé automatiquement
     */
    async activateEmergencyMode(reason: string): Promise<void> {
        this.outputChannel.appendLine(`🚨 ACTIVATING EMERGENCY MODE: ${reason}`);

        try {
            // Arrêt des opérations non critiques
            await this.performanceGuardian.setupEmergencyFailsafeMechanisms();

            // Optimisation agressive des ressources
            await this.resourceManager.optimizeResourceAllocation({
                enableCpuThrottling: true,
                enableMemoryCleanup: true,
                enableProcessPrioritization: true,
                enableSuspendNonCritical: true
            });

            // Prévention des freezes
            await this.performanceGuardian.preventFreeze({
                enableUIResponseMonitoring: true,
                enableAsyncTimeouts: true,
                enableEmergencyStop: true,
                enableGracefulDegradation: true
            });

            // Notification critique
            vscode.window.showErrorMessage(
                `🚨 Emergency Mode Activated: ${reason}`,
                'Optimize Now', 'View Status'
            ).then(selection => {
                if (selection === 'Optimize Now') {
                    this.performCompleteOptimization();
                } else if (selection === 'View Status') {
                    this.showPerformanceReport();
                }
            });

            this.outputChannel.appendLine('✅ Emergency mode activated successfully');

        } catch (error) {
            this.outputChannel.appendLine(`❌ Error activating emergency mode: ${error}`);
            throw error;
        }
    }

    /**
     * Démarrage du monitoring intégré
     */
    async startIntegratedMonitoring(): Promise<void> {
        this.outputChannel.appendLine('📊 Starting integrated performance monitoring...');

        try {
            // Démarrage du monitoring des ressources
            await this.resourceManager.startContinuousMonitoring(
                this.config.resourceManager.monitoringInterval
            );

            // Démarrage du monitoring de performance IDE
            await this.performanceGuardian.startPerformanceMonitoring(10000);

            // Démarrage du rapport périodique
            this.startPeriodicReporting();

            this.outputChannel.appendLine('✅ Integrated monitoring started successfully');

        } catch (error) {
            this.outputChannel.appendLine(`❌ Error starting integrated monitoring: ${error}`);
            throw error;
        }
    }

    /**
     * Arrêt du monitoring intégré
     */
    stopIntegratedMonitoring(): void {
        this.outputChannel.appendLine('🛑 Stopping integrated monitoring...');

        this.resourceManager.stopContinuousMonitoring();
        this.performanceGuardian.stopPerformanceMonitoring();

        if (this.reportingInterval) {
            clearInterval(this.reportingInterval);
            this.reportingInterval = null;
        }

        this.outputChannel.appendLine('✅ Integrated monitoring stopped');
    }

    // === MÉTHODES PRIVÉES ===

    /**
     * Configuration du gestionnaire de ressources
     */
    private async setupResourceManager(): Promise<void> {
        this.outputChannel.appendLine('⚙️ Setting up Resource Manager...');
        // Configuration déjà effectuée dans le constructeur
    }

    /**
     * Configuration du gardien de performance IDE
     */
    private async setupPerformanceGuardian(): Promise<void> {
        this.outputChannel.appendLine('🛡️ Setting up IDE Performance Guardian...');
        
        if (this.config.performanceGuardian.enableFreezePreventionlast) {
            await this.performanceGuardian.preventFreeze({
                maxUIResponseTime: this.config.performanceGuardian.maxUIResponseTime,
                maxAsyncOperationTime: this.config.performanceGuardian.maxAsyncOperationTime
            });
        }
    }

    /**
     * Configuration du mode d'urgence
     */
    private async setupEmergencyMode(): Promise<void> {
        if (!this.config.emergencyMode.enabled) {
            return;
        }

        this.outputChannel.appendLine('🚨 Setting up Emergency Mode...');
        // Configuration des seuils et actions automatiques
    }

    /**
     * Enregistrement des commandes VSCode
     */
    private async registerCommands(): Promise<void> {
        this.outputChannel.appendLine('📋 Registering Performance Manager commands...');

        // Commande d'optimisation complète
        vscode.commands.registerCommand('performance.optimizeComplete', async () => {
            await this.performCompleteOptimization();
        });

        // Commande de rapport de performance
        vscode.commands.registerCommand('performance.generateReport', async () => {
            await this.showPerformanceReport();
        });

        // Commande d'activation manuelle du mode d'urgence
        vscode.commands.registerCommand('performance.emergencyMode', async () => {
            await this.activateEmergencyMode('Manual activation');
        });

        // Commande de basculement du monitoring
        vscode.commands.registerCommand('performance.toggleMonitoring', () => {
            if (this.reportingInterval) {
                this.stopIntegratedMonitoring();
            } else {
                this.startIntegratedMonitoring();
            }
        });
    }

    /**
     * Calcul de la santé globale du système
     */
    private calculateOverallHealth(
        systemMetrics: ResourceMetrics, 
        ideMetrics: IDEPerformanceMetrics
    ): 'excellent' | 'good' | 'warning' | 'critical' {
        let score = 100;

        // Analyse système
        if (systemMetrics.cpu.usage > 80) score -= 30;
        else if (systemMetrics.cpu.usage > 60) score -= 15;

        if (systemMetrics.memory.usagePercent > 90) score -= 30;
        else if (systemMetrics.memory.usagePercent > 75) score -= 15;

        if (systemMetrics.prediction.saturationRisk === 'critical') score -= 40;
        else if (systemMetrics.prediction.saturationRisk === 'high') score -= 20;

        // Analyse IDE
        if (ideMetrics.responsiveness.freezeDetected) score -= 40;
        if (ideMetrics.responsiveness.uiResponseTime > 200) score -= 20;
        if (ideMetrics.memory.leakDetected) score -= 25;

        // Classification
        if (score >= 90) return 'excellent';
        if (score >= 70) return 'good';
        if (score >= 50) return 'warning';
        return 'critical';
    }

    /**
     * Génération des recommandations
     */
    private generateRecommendations(
        systemMetrics: ResourceMetrics,
        ideMetrics: IDEPerformanceMetrics,
        health: string
    ): string[] {
        const recommendations: string[] = [];

        if (health === 'critical') {
            recommendations.push('🚨 Immediate optimization required');
            recommendations.push('🛑 Consider emergency mode activation');
        }

        if (systemMetrics.cpu.usage > 70) {
            recommendations.push('⚡ Reduce CPU-intensive operations');
        }

        if (systemMetrics.memory.usagePercent > 80) {
            recommendations.push('🧹 Perform memory cleanup');
        }

        if (ideMetrics.responsiveness.uiResponseTime > 150) {
            recommendations.push('🔧 Optimize extension performance');
        }

        if (recommendations.length === 0) {
            recommendations.push('✅ System performance is optimal');
        }

        return recommendations;
    }

    /**
     * Vérification des actions d'urgence nécessaires
     */
    private checkEmergencyActions(
        systemMetrics: ResourceMetrics,
        ideMetrics: IDEPerformanceMetrics
    ): string[] {
        const actions: string[] = [];

        if (systemMetrics.cpu.usage > this.config.emergencyMode.cpuThreshold) {
            actions.push('CPU throttling activated');
        }

        if (systemMetrics.memory.usagePercent > this.config.emergencyMode.memoryThreshold) {
            actions.push('Emergency memory cleanup');
        }

        if (ideMetrics.responsiveness.freezeDetected) {
            actions.push('Freeze prevention measures');
        }

        return actions;
    }

    /**
     * Démarrage du rapport périodique
     */
    private startPeriodicReporting(): void {
        this.reportingInterval = setInterval(async () => {
            try {
                const report = await this.generatePerformanceReport();
                
                if (report.overallHealth === 'critical' && this.config.emergencyMode.autoOptimization) {
                    await this.activateEmergencyMode(`Critical health detected: ${report.recommendations[0]}`);
                }
                
            } catch (error) {
                this.outputChannel.appendLine(`Error in periodic reporting: ${error}`);
            }
        }, 60000); // Toutes les minutes
    }

    /**
     * Affichage du rapport de performance
     */
    private async showPerformanceReport(): Promise<void> {
        try {
            const report = await this.generatePerformanceReport();
            
            this.outputChannel.clear();
            this.outputChannel.appendLine('=== GLOBAL PERFORMANCE REPORT ===');
            this.outputChannel.appendLine(`Timestamp: ${report.timestamp.toISOString()}`);
            this.outputChannel.appendLine(`Overall Health: ${report.overallHealth.toUpperCase()}`);
            this.outputChannel.appendLine('');
            this.outputChannel.appendLine('=== SYSTEM METRICS ===');
            this.outputChannel.appendLine(`CPU Usage: ${report.system.cpu.usage}% (${report.system.cpu.cores} cores)`);
            this.outputChannel.appendLine(`Memory Usage: ${report.system.memory.used}GB / ${report.system.memory.total}GB (${report.system.memory.usagePercent}%)`);
            this.outputChannel.appendLine(`Risk Level: ${report.system.prediction.saturationRisk.toUpperCase()}`);
            this.outputChannel.appendLine('');
            this.outputChannel.appendLine('=== IDE METRICS ===');
            this.outputChannel.appendLine(`UI Response Time: ${report.ide.responsiveness.uiResponseTime}ms`);
            this.outputChannel.appendLine(`Active Extensions: ${report.ide.extensions.activeCount}`);
            this.outputChannel.appendLine(`Memory Usage: ${report.ide.memory.extensionMemory}MB`);
            this.outputChannel.appendLine('');
            this.outputChannel.appendLine('=== RECOMMENDATIONS ===');
            report.recommendations.forEach(rec => {
                this.outputChannel.appendLine(`- ${rec}`);
            });
            
            if (report.emergencyActionsTriggered.length > 0) {
                this.outputChannel.appendLine('');
                this.outputChannel.appendLine('=== EMERGENCY ACTIONS ===');
                report.emergencyActionsTriggered.forEach(action => {
                    this.outputChannel.appendLine(`- ${action}`);
                });
            }
            
            this.outputChannel.show();
            
        } catch (error) {
            this.outputChannel.appendLine(`Error showing performance report: ${error}`);
        }
    }

    /**
     * Ouverture du dashboard de performance
     */
    private async openPerformanceDashboard(): Promise<void> {
        // Implémentation future du dashboard web
        this.outputChannel.appendLine('📊 Performance dashboard (future implementation)');
        await this.showPerformanceReport(); // Fallback sur le rapport texte
    }

    /**
     * Nettoyage des ressources
     */
    dispose(): void {
        this.stopIntegratedMonitoring();
        this.resourceManager.dispose();
        this.performanceGuardian.dispose();
        this.outputChannel.dispose();
        this.isActive = false;
    }
}
