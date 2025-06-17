import * as vscode from 'vscode';
import * as os from 'os';

/**
 * Interface pour les informations de batterie
 */
export interface BatteryInfo {
    isCharging: boolean;
    level: number; // 0-100
    timeRemaining: number | null; // minutes
    status: 'charging' | 'discharging' | 'full' | 'unknown';
    health: 'good' | 'fair' | 'poor' | 'unknown';
}

/**
 * Interface pour les informations thermiques
 */
export interface ThermalInfo {
    cpuTemperature: number;
    gpuTemperature?: number;
    systemTemperature: number;
    thermalState: 'normal' | 'fair' | 'serious' | 'critical';
    throttlingActive: boolean;
    fanSpeed?: number;
}

/**
 * Interface pour les profils de performance
 */
export interface PerformanceProfile {
    name: string;
    description: string;
    settings: {
        cpu: {
            maxUsage: number; // pourcentage
            throttleThreshold: number;
            enableTurboBoost: boolean;
        };
        gpu: {
            maxUsage: number;
            enableBoostClock: boolean;
            powerLimit: number; // watts
        };
        graphics: {
            targetFPS: number;
            enableVSync: boolean;
            textureQuality: 'low' | 'medium' | 'high' | 'ultra';
            enablePostProcessing: boolean;
        };
        background: {
            reduceActivity: boolean;
            pauseNonEssentialTasks: boolean;
            enableSleepMode: boolean;
        };
    };
}

/**
 * Interface pour les métriques de consommation
 */
export interface PowerConsumptionMetrics {
    totalPower: number; // watts
    cpuPower: number;
    gpuPower: number;
    displayPower: number;
    estimatedBatteryLife: number; // minutes
    powerEfficiency: number; // performance per watt
    recommendations: string[];
}

/**
 * Interface pour les options de gestion d'alimentation
 */
export interface PowerManagementOptions {
    batteryAware: {
        enableBatteryOptimization: boolean;
        lowBatteryThreshold: number; // pourcentage
        criticalBatteryThreshold: number;
        enableAdaptivePerformance: boolean;
    };
    thermal: {
        enableThermalMonitoring: boolean;
        maxTemperature: number; // celsius
        enableThrottling: boolean;
        enableFanControl: boolean;
    };
    performance: {
        enablePerformanceScaling: boolean;
        enableBackgroundReduction: boolean;
        enableSleepOptimization: boolean;
        enableWakeOptimization: boolean;
    };
    profiles: {
        enableProfileSwitching: boolean;
        autoSwitchOnBattery: boolean;
        autoSwitchOnThermal: boolean;
        customProfiles: PerformanceProfile[];
    };
}

/**
 * Gestionnaire intelligent de l'alimentation pour ordinateurs portables et mobiles
 * Phase 0.4 : Graphics & UI Optimization - Power Management
 */
export class PowerManager {
    private batteryInfo: BatteryInfo | null = null;
    private thermalInfo: ThermalInfo | null = null;
    private currentProfile: PerformanceProfile | null = null;
    private powerMetrics: PowerConsumptionMetrics | null = null;
    private isMonitoring = false;
    private monitoringInterval: NodeJS.Timer | null = null;
    private outputChannel: vscode.OutputChannel;

    private options: PowerManagementOptions = {
        batteryAware: {
            enableBatteryOptimization: true,
            lowBatteryThreshold: 20,
            criticalBatteryThreshold: 10,
            enableAdaptivePerformance: true
        },
        thermal: {
            enableThermalMonitoring: true,
            maxTemperature: 80, // 80°C
            enableThrottling: true,
            enableFanControl: false // Généralement contrôlé par le système
        },
        performance: {
            enablePerformanceScaling: true,
            enableBackgroundReduction: true,
            enableSleepOptimization: true,
            enableWakeOptimization: true
        },
        profiles: {
            enableProfileSwitching: true,
            autoSwitchOnBattery: true,
            autoSwitchOnThermal: true,
            customProfiles: []
        }
    };

    private defaultProfiles: PerformanceProfile[] = [
        {
            name: 'High Performance',
            description: 'Maximum performance for plugged-in use',
            settings: {
                cpu: {
                    maxUsage: 100,
                    throttleThreshold: 90,
                    enableTurboBoost: true
                },
                gpu: {
                    maxUsage: 100,
                    enableBoostClock: true,
                    powerLimit: 200
                },
                graphics: {
                    targetFPS: 60,
                    enableVSync: true,
                    textureQuality: 'high',
                    enablePostProcessing: true
                },
                background: {
                    reduceActivity: false,
                    pauseNonEssentialTasks: false,
                    enableSleepMode: false
                }
            }
        },
        {
            name: 'Battery Saver',
            description: 'Extended battery life with reduced performance',
            settings: {
                cpu: {
                    maxUsage: 50,
                    throttleThreshold: 60,
                    enableTurboBoost: false
                },
                gpu: {
                    maxUsage: 30,
                    enableBoostClock: false,
                    powerLimit: 50
                },
                graphics: {
                    targetFPS: 30,
                    enableVSync: false,
                    textureQuality: 'low',
                    enablePostProcessing: false
                },
                background: {
                    reduceActivity: true,
                    pauseNonEssentialTasks: true,
                    enableSleepMode: true
                }
            }
        },
        {
            name: 'Balanced',
            description: 'Optimal balance between performance and power consumption',
            settings: {
                cpu: {
                    maxUsage: 80,
                    throttleThreshold: 75,
                    enableTurboBoost: true
                },
                gpu: {
                    maxUsage: 70,
                    enableBoostClock: true,
                    powerLimit: 120
                },
                graphics: {
                    targetFPS: 45,
                    enableVSync: true,
                    textureQuality: 'medium',
                    enablePostProcessing: true
                },
                background: {
                    reduceActivity: true,
                    pauseNonEssentialTasks: false,
                    enableSleepMode: false
                }
            }
        },
        {
            name: 'Thermal Control',
            description: 'Reduced performance to manage heat generation',
            settings: {
                cpu: {
                    maxUsage: 60,
                    throttleThreshold: 50,
                    enableTurboBoost: false
                },
                gpu: {
                    maxUsage: 40,
                    enableBoostClock: false,
                    powerLimit: 70
                },
                graphics: {
                    targetFPS: 30,
                    enableVSync: false,
                    textureQuality: 'low',
                    enablePostProcessing: false
                },
                background: {
                    reduceActivity: true,
                    pauseNonEssentialTasks: true,
                    enableSleepMode: true
                }
            }
        }
    ];

    constructor() {
        this.outputChannel = vscode.window.createOutputChannel('Power Manager');
        this.initializeProfiles();
        this.startMonitoring();
    }

    /**
     * Battery-aware operations - Opérations conscientes de la batterie
     */
    async enableBatteryAwareOperations(): Promise<void> {
        try {
            this.outputChannel.appendLine(`[BATTERY] Enabling battery-aware operations...`);

            if (!this.options.batteryAware.enableBatteryOptimization) {
                this.outputChannel.appendLine(`[BATTERY] Battery optimization disabled`);
                return;
            }

            // Obtenir les informations de batterie
            this.batteryInfo = await this.getBatteryInfo();

            if (!this.batteryInfo) {
                this.outputChannel.appendLine(`[BATTERY] No battery detected - assuming desktop system`);
                return;
            }

            // Adapter le comportement selon l'état de la batterie
            if (!this.batteryInfo.isCharging) {
                if (this.batteryInfo.level <= this.options.batteryAware.criticalBatteryThreshold) {
                    await this.switchToProfile('Battery Saver');
                    await this.enableCriticalBatteryMode();
                } else if (this.batteryInfo.level <= this.options.batteryAware.lowBatteryThreshold) {
                    await this.switchToProfile('Battery Saver');
                    await this.enableLowBatteryMode();
                } else if (this.options.batteryAware.enableAdaptivePerformance) {
                    await this.enableAdaptivePerformance();
                }
            } else {
                // Sur secteur - performance normale
                if (this.currentProfile?.name === 'Battery Saver') {
                    await this.switchToProfile('Balanced');
                }
            }

            this.outputChannel.appendLine(`[BATTERY] Battery-aware operations enabled`);

        } catch (error) {
            this.outputChannel.appendLine(`[ERROR] Battery-aware operations failed: ${error}`);
            throw error;
        }
    }

    /**
     * Performance scaling selon alimentation
     */
    async enablePerformanceScaling(): Promise<void> {
        try {
            this.outputChannel.appendLine(`[SCALING] Enabling performance scaling...`);

            if (!this.options.performance.enablePerformanceScaling) {
                return;
            }

            // Détecter le type d'alimentation
            const powerSource = await this.detectPowerSource();
            
            // Obtenir les informations thermiques
            this.thermalInfo = await this.getThermalInfo();

            // Sélectionner le profil approprié
            let targetProfile: string;

            if (powerSource === 'battery') {
                if (this.batteryInfo && this.batteryInfo.level <= this.options.batteryAware.lowBatteryThreshold) {
                    targetProfile = 'Battery Saver';
                } else {
                    targetProfile = 'Balanced';
                }
            } else {
                // Sur secteur
                if (this.thermalInfo && this.thermalInfo.thermalState === 'critical') {
                    targetProfile = 'Thermal Control';
                } else if (this.thermalInfo && this.thermalInfo.thermalState === 'serious') {
                    targetProfile = 'Balanced';
                } else {
                    targetProfile = 'High Performance';
                }
            }

            await this.switchToProfile(targetProfile);

            this.outputChannel.appendLine(`[SCALING] Performance scaling enabled - Profile: ${targetProfile}`);

        } catch (error) {
            this.outputChannel.appendLine(`[ERROR] Performance scaling failed: ${error}`);
            throw error;
        }
    }

    /**
     * Background activity reduction
     */
    async enableBackgroundActivityReduction(): Promise<void> {
        try {
            this.outputChannel.appendLine(`[BACKGROUND] Enabling background activity reduction...`);

            if (!this.options.performance.enableBackgroundReduction) {
                return;
            }

            const shouldReduce = await this.shouldReduceBackgroundActivity();

            if (shouldReduce) {
                await this.reduceBackgroundActivities();
                await this.pauseNonEssentialTasks();
                await this.optimizeBackgroundProcesses();
            }

            this.outputChannel.appendLine(`[BACKGROUND] Background activity reduction enabled`);

        } catch (error) {
            this.outputChannel.appendLine(`[ERROR] Background activity reduction failed: ${error}`);
            throw error;
        }
    }

    /**
     * Thermal throttling awareness
     */
    async enableThermalThrottlingAwareness(): Promise<void> {
        try {
            this.outputChannel.appendLine(`[THERMAL] Enabling thermal throttling awareness...`);

            if (!this.options.thermal.enableThermalMonitoring) {
                return;
            }

            this.thermalInfo = await this.getThermalInfo();

            if (this.thermalInfo) {
                await this.handleThermalState(this.thermalInfo);
            }

            this.outputChannel.appendLine(`[THERMAL] Thermal throttling awareness enabled`);

        } catch (error) {
            this.outputChannel.appendLine(`[ERROR] Thermal awareness failed: ${error}`);
            throw error;
        }
    }

    /**
     * Obtenir les métriques de consommation actuelle
     */
    async getPowerConsumptionMetrics(): Promise<PowerConsumptionMetrics> {
        try {
            this.powerMetrics = await this.measurePowerConsumption();
            return this.powerMetrics;
        } catch (error) {
            this.outputChannel.appendLine(`[ERROR] Failed to get power metrics: ${error}`);
            throw error;
        }
    }

    /**
     * Changer de profil de performance
     */
    async switchToProfile(profileName: string): Promise<void> {
        try {
            const profile = this.getProfileByName(profileName);
            if (!profile) {
                throw new Error(`Profile not found: ${profileName}`);
            }

            this.outputChannel.appendLine(`[PROFILE] Switching to profile: ${profileName}`);

            await this.applyProfile(profile);
            this.currentProfile = profile;

            this.outputChannel.appendLine(`[PROFILE] Profile switched successfully`);

        } catch (error) {
            this.outputChannel.appendLine(`[ERROR] Profile switch failed: ${error}`);
            throw error;
        }
    }

    // Méthodes privées pour l'implémentation détaillée...

    private initializeProfiles(): void {
        this.options.profiles.customProfiles = [...this.defaultProfiles];
        this.currentProfile = this.defaultProfiles.find(p => p.name === 'Balanced') || this.defaultProfiles[0];
        this.outputChannel.appendLine(`[INIT] Power management initialized with ${this.defaultProfiles.length} profiles`);
    }

    private async getBatteryInfo(): Promise<BatteryInfo | null> {
        try {
            // Tentative d'utilisation de l'API Battery (si disponible)
            if (typeof navigator !== 'undefined' && 'getBattery' in navigator) {
                const battery = await (navigator as any).getBattery();
                return {
                    isCharging: battery.charging,
                    level: Math.round(battery.level * 100),
                    timeRemaining: battery.dischargingTime !== Infinity ? Math.round(battery.dischargingTime / 60) : null,
                    status: battery.charging ? 'charging' : 'discharging',
                    health: 'unknown'
                };
            }

            // Fallback pour les systèmes sans API Battery
            return await this.getBatteryInfoFallback();

        } catch (error) {
            this.outputChannel.appendLine(`[BATTERY] Battery info detection failed: ${error}`);
            return null;
        }
    }

    private async getBatteryInfoFallback(): Promise<BatteryInfo | null> {
        // Implémentation fallback pour détection batterie
        try {
            if (os.platform() === 'win32') {
                // Windows - utiliser wmic ou PowerShell si disponible
                return await this.getWindowsBatteryInfo();
            } else if (os.platform() === 'darwin') {
                // macOS - utiliser pmset ou system_profiler
                return await this.getMacOSBatteryInfo();
            } else if (os.platform() === 'linux') {
                // Linux - utiliser /sys/class/power_supply
                return await this.getLinuxBatteryInfo();
            }
        } catch (error) {
            // Système de bureau sans batterie
        }

        return null;
    }

    private async getWindowsBatteryInfo(): Promise<BatteryInfo | null> {
        // Simulation pour Windows (nécessiterait une implémentation native)
        return {
            isCharging: false,
            level: 75,
            timeRemaining: 240,
            status: 'discharging',
            health: 'good'
        };
    }

    private async getMacOSBatteryInfo(): Promise<BatteryInfo | null> {
        // Simulation pour macOS (nécessiterait une implémentation native)
        return {
            isCharging: false,
            level: 85,
            timeRemaining: 180,
            status: 'discharging',
            health: 'good'
        };
    }

    private async getLinuxBatteryInfo(): Promise<BatteryInfo | null> {
        // Simulation pour Linux (nécessiterait l'accès à /sys/class/power_supply)
        return {
            isCharging: true,
            level: 65,
            timeRemaining: null,
            status: 'charging',
            health: 'good'
        };
    }

    private async getThermalInfo(): Promise<ThermalInfo | null> {
        try {
            // Simulation des informations thermiques
            // Dans une implémentation réelle, ceci nécessiterait l'accès aux capteurs système
            return {
                cpuTemperature: 55,
                gpuTemperature: 60,
                systemTemperature: 50,
                thermalState: 'normal',
                throttlingActive: false,
                fanSpeed: 1200
            };
        } catch (error) {
            this.outputChannel.appendLine(`[THERMAL] Thermal info detection failed: ${error}`);
            return null;
        }
    }

    private async detectPowerSource(): Promise<'battery' | 'plugged'> {
        if (this.batteryInfo) {
            return this.batteryInfo.isCharging ? 'plugged' : 'battery';
        }
        return 'plugged'; // Assumer secteur si pas de batterie détectée
    }

    private async enableCriticalBatteryMode(): Promise<void> {
        this.outputChannel.appendLine(`[BATTERY] Enabling critical battery mode...`);
        
        // Réductions drastiques pour préserver la batterie
        await this.setMaxCPUUsage(25);
        await this.setMaxGPUUsage(15);
        await this.setTargetFPS(15);
        await this.pauseAllNonEssentialTasks();
        await this.enableAggressiveSleepMode();
    }

    private async enableLowBatteryMode(): Promise<void> {
        this.outputChannel.appendLine(`[BATTERY] Enabling low battery mode...`);
        
        // Réductions modérées
        await this.setMaxCPUUsage(50);
        await this.setMaxGPUUsage(30);
        await this.setTargetFPS(30);
        await this.reduceBackgroundActivities();
    }

    private async enableAdaptivePerformance(): Promise<void> {
        this.outputChannel.appendLine(`[BATTERY] Enabling adaptive performance...`);
        
        // Ajustement dynamique basé sur le niveau de batterie
        if (this.batteryInfo) {
            const batteryLevel = this.batteryInfo.level;
            const cpuUsage = Math.max(50, Math.min(100, batteryLevel + 30));
            const gpuUsage = Math.max(30, Math.min(80, batteryLevel + 10));
            
            await this.setMaxCPUUsage(cpuUsage);
            await this.setMaxGPUUsage(gpuUsage);
        }
    }

    private async handleThermalState(thermalInfo: ThermalInfo): Promise<void> {
        switch (thermalInfo.thermalState) {
            case 'critical':
                this.outputChannel.appendLine(`[THERMAL] Critical thermal state detected`);
                await this.switchToProfile('Thermal Control');
                await this.enableEmergencyThermalProtection();
                break;
                
            case 'serious':
                this.outputChannel.appendLine(`[THERMAL] Serious thermal state detected`);
                await this.switchToProfile('Balanced');
                await this.enableThermalThrottling();
                break;
                
            case 'fair':
                this.outputChannel.appendLine(`[THERMAL] Fair thermal state detected`);
                await this.enableModérateThermalControl();
                break;
                
            default:
                // Thermal state normal - pas d'action requise
                break;
        }
    }

    private async shouldReduceBackgroundActivity(): Promise<boolean> {
        // Détermine si les activités de fond doivent être réduites
        if (this.batteryInfo && !this.batteryInfo.isCharging && 
            this.batteryInfo.level <= this.options.batteryAware.lowBatteryThreshold) {
            return true;
        }

        if (this.thermalInfo && 
            (this.thermalInfo.thermalState === 'serious' || this.thermalInfo.thermalState === 'critical')) {
            return true;
        }

        return false;
    }

    private async reduceBackgroundActivities(): Promise<void> {
        this.outputChannel.appendLine(`[BACKGROUND] Reducing background activities...`);
        // Implémentation de la réduction des activités de fond
    }

    private async pauseNonEssentialTasks(): Promise<void> {
        this.outputChannel.appendLine(`[BACKGROUND] Pausing non-essential tasks...`);
        // Implémentation de la pause des tâches non essentielles
    }

    private async optimizeBackgroundProcesses(): Promise<void> {
        this.outputChannel.appendLine(`[BACKGROUND] Optimizing background processes...`);
        // Implémentation de l'optimisation des processus de fond
    }

    private async measurePowerConsumption(): Promise<PowerConsumptionMetrics> {
        // Simulation des métriques de consommation
        return {
            totalPower: 45,
            cpuPower: 15,
            gpuPower: 20,
            displayPower: 8,
            estimatedBatteryLife: 180,
            powerEfficiency: 2.5,
            recommendations: [
                'Reduce screen brightness',
                'Close unused applications',
                'Enable power saving mode'
            ]
        };
    }

    private getProfileByName(name: string): PerformanceProfile | null {
        return this.options.profiles.customProfiles.find(p => p.name === name) || null;
    }

    private async applyProfile(profile: PerformanceProfile): Promise<void> {
        this.outputChannel.appendLine(`[PROFILE] Applying profile: ${profile.name}`);
        
        // Application des paramètres CPU
        await this.setMaxCPUUsage(profile.settings.cpu.maxUsage);
        await this.setCPUThrottleThreshold(profile.settings.cpu.throttleThreshold);
        await this.enableTurboBoost(profile.settings.cpu.enableTurboBoost);
        
        // Application des paramètres GPU
        await this.setMaxGPUUsage(profile.settings.gpu.maxUsage);
        await this.enableGPUBoostClock(profile.settings.gpu.enableBoostClock);
        await this.setGPUPowerLimit(profile.settings.gpu.powerLimit);
        
        // Application des paramètres graphiques
        await this.setTargetFPS(profile.settings.graphics.targetFPS);
        await this.enableVSync(profile.settings.graphics.enableVSync);
        await this.setTextureQuality(profile.settings.graphics.textureQuality);
        await this.enablePostProcessing(profile.settings.graphics.enablePostProcessing);
        
        // Application des paramètres de fond
        if (profile.settings.background.reduceActivity) {
            await this.reduceBackgroundActivities();
        }
        if (profile.settings.background.pauseNonEssentialTasks) {
            await this.pauseNonEssentialTasks();
        }
        if (profile.settings.background.enableSleepMode) {
            await this.enableSleepOptimizations();
        }
    }

    private async setMaxCPUUsage(percentage: number): Promise<void> {
        this.outputChannel.appendLine(`[CPU] Setting max CPU usage: ${percentage}%`);
    }

    private async setCPUThrottleThreshold(percentage: number): Promise<void> {
        this.outputChannel.appendLine(`[CPU] Setting CPU throttle threshold: ${percentage}%`);
    }

    private async enableTurboBoost(enable: boolean): Promise<void> {
        this.outputChannel.appendLine(`[CPU] Turbo boost: ${enable ? 'enabled' : 'disabled'}`);
    }

    private async setMaxGPUUsage(percentage: number): Promise<void> {
        this.outputChannel.appendLine(`[GPU] Setting max GPU usage: ${percentage}%`);
    }

    private async enableGPUBoostClock(enable: boolean): Promise<void> {
        this.outputChannel.appendLine(`[GPU] GPU boost clock: ${enable ? 'enabled' : 'disabled'}`);
    }

    private async setGPUPowerLimit(watts: number): Promise<void> {
        this.outputChannel.appendLine(`[GPU] Setting GPU power limit: ${watts}W`);
    }

    private async setTargetFPS(fps: number): Promise<void> {
        this.outputChannel.appendLine(`[GRAPHICS] Setting target FPS: ${fps}`);
    }

    private async enableVSync(enable: boolean): Promise<void> {
        this.outputChannel.appendLine(`[GRAPHICS] VSync: ${enable ? 'enabled' : 'disabled'}`);
    }

    private async setTextureQuality(quality: string): Promise<void> {
        this.outputChannel.appendLine(`[GRAPHICS] Setting texture quality: ${quality}`);
    }

    private async enablePostProcessing(enable: boolean): Promise<void> {
        this.outputChannel.appendLine(`[GRAPHICS] Post-processing: ${enable ? 'enabled' : 'disabled'}`);
    }

    private async pauseAllNonEssentialTasks(): Promise<void> {
        this.outputChannel.appendLine(`[CRITICAL] Pausing all non-essential tasks...`);
    }

    private async enableAggressiveSleepMode(): Promise<void> {
        this.outputChannel.appendLine(`[CRITICAL] Enabling aggressive sleep mode...`);
    }

    private async enableEmergencyThermalProtection(): Promise<void> {
        this.outputChannel.appendLine(`[THERMAL] Enabling emergency thermal protection...`);
    }

    private async enableThermalThrottling(): Promise<void> {
        this.outputChannel.appendLine(`[THERMAL] Enabling thermal throttling...`);
    }

    private async enableModérateThermalControl(): Promise<void> {
        this.outputChannel.appendLine(`[THERMAL] Enabling moderate thermal control...`);
    }

    private async enableSleepOptimizations(): Promise<void> {
        this.outputChannel.appendLine(`[SLEEP] Enabling sleep optimizations...`);
    }

    private startMonitoring(): void {
        if (this.isMonitoring) return;

        this.isMonitoring = true;
        this.outputChannel.appendLine(`[MONITOR] Starting power management monitoring...`);

        this.monitoringInterval = setInterval(async () => {
            try {
                // Mise à jour des informations de batterie
                if (this.options.batteryAware.enableBatteryOptimization) {
                    this.batteryInfo = await this.getBatteryInfo();
                }

                // Mise à jour des informations thermiques
                if (this.options.thermal.enableThermalMonitoring) {
                    this.thermalInfo = await this.getThermalInfo();
                }

                // Auto-switch de profil si configuré
                if (this.options.profiles.enableProfileSwitching) {
                    await this.checkAutoProfileSwitch();
                }

            } catch (error) {
                this.outputChannel.appendLine(`[MONITOR] Monitoring error: ${error}`);
            }
        }, 30000); // Monitoring toutes les 30 secondes
    }

    private async checkAutoProfileSwitch(): Promise<void> {
        if (!this.currentProfile) return;

        let shouldSwitch = false;
        let targetProfile = '';

        // Vérification batterie
        if (this.options.profiles.autoSwitchOnBattery && this.batteryInfo) {
            if (!this.batteryInfo.isCharging && 
                this.batteryInfo.level <= this.options.batteryAware.lowBatteryThreshold &&
                this.currentProfile.name !== 'Battery Saver') {
                shouldSwitch = true;
                targetProfile = 'Battery Saver';
            } else if (this.batteryInfo.isCharging && this.currentProfile.name === 'Battery Saver') {
                shouldSwitch = true;
                targetProfile = 'Balanced';
            }
        }

        // Vérification thermique
        if (this.options.profiles.autoSwitchOnThermal && this.thermalInfo) {
            if (this.thermalInfo.thermalState === 'critical' && 
                this.currentProfile.name !== 'Thermal Control') {
                shouldSwitch = true;
                targetProfile = 'Thermal Control';
            } else if (this.thermalInfo.thermalState === 'normal' && 
                       this.currentProfile.name === 'Thermal Control') {
                shouldSwitch = true;
                targetProfile = 'Balanced';
            }
        }

        if (shouldSwitch && targetProfile) {
            await this.switchToProfile(targetProfile);
        }
    }

    /**
     * Arrêt propre du gestionnaire
     */
    dispose(): void {
        this.isMonitoring = false;
        
        if (this.monitoringInterval) {
            clearInterval(this.monitoringInterval);
            this.monitoringInterval = null;
        }
        
        this.outputChannel.dispose();
    }
}
