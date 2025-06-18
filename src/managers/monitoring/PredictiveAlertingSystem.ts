import * as vscode from 'vscode';
import { EventEmitter } from 'events';
import { Alert, SystemMetrics, AlertThresholds } from './ResourceDashboard';

/**
 * Interface pour les règles d'alerte prédictives
 */
export interface PredictiveRule {
    id: string;
    name: string;
    metric: string;
    algorithm: 'linear' | 'exponential' | 'polynomial';
    windowSize: number; // Nombre de points de données à analyser
    predictionWindow: number; // Horizon de prédiction en minutes
    threshold: number;
    enabled: boolean;
    sensitivity: 'low' | 'medium' | 'high';
}

/**
 * Interface pour les triggers d'atténuation automatique
 */
export interface MitigationTrigger {
    id: string;
    alertType: string;
    condition: string;
    action: 'cleanup' | 'restart' | 'scale' | 'notify' | 'emergency_stop';
    parameters: Record<string, any>;
    cooldown: number; // Minutes avant de pouvoir retrigguer
    lastTriggered?: number;
    enabled: boolean;
}

/**
 * Interface pour l'analyse de tendances
 */
export interface TrendAnalysis {
    metric: string;
    direction: 'increasing' | 'decreasing' | 'stable';
    slope: number;
    confidence: number;
    prediction: number;
    timeToThreshold?: number; // Minutes avant d'atteindre le seuil
    dataPoints: number;
}

/**
 * Système d'alerting prédictif avancé
 */
export class PredictiveAlertingSystem extends EventEmitter {
    private predictiveRules: Map<string, PredictiveRule> = new Map();
    private mitigationTriggers: Map<string, MitigationTrigger> = new Map();
    private metricsBuffer: Map<string, number[]> = new Map();
    private alertCooldowns: Map<string, number> = new Map();
    private isEnabled: boolean = true;

    constructor() {
        super();
        this.initializeDefaultRules();
        this.initializeDefaultTriggers();
    }

    /**
     * Initialise les règles prédictives par défaut
     */
    private initializeDefaultRules(): void {
        const defaultRules: PredictiveRule[] = [
            {
                id: 'cpu-linear-prediction',
                name: 'CPU Usage Linear Prediction',
                metric: 'cpu.usage',
                algorithm: 'linear',
                windowSize: 10,
                predictionWindow: 5,
                threshold: 80,
                enabled: true,
                sensitivity: 'medium'
            },
            {
                id: 'memory-exponential-prediction',
                name: 'Memory Usage Exponential Prediction',
                metric: 'memory.usage',
                algorithm: 'exponential',
                windowSize: 15,
                predictionWindow: 10,
                threshold: 85,
                enabled: true,
                sensitivity: 'high'
            },
            {
                id: 'disk-linear-prediction',
                name: 'Disk Usage Linear Prediction',
                metric: 'disk.usage',
                algorithm: 'linear',
                windowSize: 20,
                predictionWindow: 15,
                threshold: 90,
                enabled: true,
                sensitivity: 'low'
            },
            {
                id: 'temperature-polynomial-prediction',
                name: 'CPU Temperature Polynomial Prediction',
                metric: 'cpu.temperature',
                algorithm: 'polynomial',
                windowSize: 8,
                predictionWindow: 3,
                threshold: 75,
                enabled: true,
                sensitivity: 'high'
            }
        ];

        defaultRules.forEach(rule => {
            this.predictiveRules.set(rule.id, rule);
        });
    }

    /**
     * Initialise les triggers d'atténuation par défaut
     */
    private initializeDefaultTriggers(): void {
        const defaultTriggers: MitigationTrigger[] = [
            {
                id: 'high-cpu-cleanup',
                alertType: 'cpu',
                condition: 'value > 90',
                action: 'cleanup',
                parameters: { 
                    processes: ['node', 'typescript', 'eslint'],
                    maxKill: 3 
                },
                cooldown: 5,
                enabled: true
            },
            {
                id: 'high-memory-cleanup',
                alertType: 'memory',
                condition: 'value > 95',
                action: 'cleanup',
                parameters: { 
                    clearCache: true,
                    gcTrigger: true 
                },
                cooldown: 3,
                enabled: true
            },
            {
                id: 'critical-temperature-emergency',
                alertType: 'temperature',
                condition: 'value > 85',
                action: 'emergency_stop',
                parameters: { 
                    gracefulShutdown: true,
                    saveState: true 
                },
                cooldown: 0,
                enabled: true
            },
            {
                id: 'disk-full-notification',
                alertType: 'disk',
                condition: 'value > 95',
                action: 'notify',
                parameters: { 
                    level: 'critical',
                    suggestion: 'Clean temporary files and caches' 
                },
                cooldown: 15,
                enabled: true
            }
        ];

        defaultTriggers.forEach(trigger => {
            this.mitigationTriggers.set(trigger.id, trigger);
        });
    }

    /**
     * Analyse les métriques pour les alertes prédictives
     */
    public analyzeMetrics(metrics: SystemMetrics): void {
        if (!this.isEnabled) {
            return;
        }

        // Mise à jour des buffers de métriques
        this.updateMetricsBuffers(metrics);

        // Analyse prédictive pour chaque règle
        this.predictiveRules.forEach(rule => {
            if (rule.enabled) {
                this.analyzePredictiveRule(rule, metrics);
            }
        });

        // Analyse des tendances globales
        this.analyzeTrends(metrics);
    }

    /**
     * Met à jour les buffers de métriques
     */
    private updateMetricsBuffers(metrics: SystemMetrics): void {
        const metricValues = {
            'cpu.usage': metrics.cpu.usage,
            'memory.usage': metrics.ram.usage,
            'disk.usage': metrics.disk.usage,
            'cpu.temperature': metrics.cpu.temperature || 0,
            'network.download': metrics.network.downloadSpeed,
            'network.upload': metrics.network.uploadSpeed
        };

        for (const [metricName, value] of Object.entries(metricValues)) {
            if (!this.metricsBuffer.has(metricName)) {
                this.metricsBuffer.set(metricName, []);
            }

            const buffer = this.metricsBuffer.get(metricName)!;
            buffer.push(value);

            // Limite la taille du buffer
            if (buffer.length > 100) {
                buffer.shift();
            }
        }
    }

    /**
     * Analyse une règle prédictive spécifique
     */
    private analyzePredictiveRule(rule: PredictiveRule, metrics: SystemMetrics): void {
        const buffer = this.metricsBuffer.get(rule.metric);
        
        if (!buffer || buffer.length < rule.windowSize) {
            return; // Pas assez de données
        }

        const recentData = buffer.slice(-rule.windowSize);
        const prediction = this.runPrediction(recentData, rule.algorithm, rule.predictionWindow);
        
        if (prediction === null) {
            return;
        }

        const confidence = this.calculateConfidence(recentData, rule.algorithm);
        const shouldAlert = this.shouldTriggerPredictiveAlert(rule, prediction, confidence);

        if (shouldAlert) {
            const alert = this.createPredictiveAlert(rule, prediction, confidence, metrics);
            this.emit('predictiveAlert', alert);
            
            // Déclencher les triggers d'atténuation si configurés
            this.triggerMitigation(alert);
        }
    }

    /**
     * Exécute une prédiction selon l'algorithme spécifié
     */
    private runPrediction(data: number[], algorithm: string, horizon: number): number | null {
        try {
            switch (algorithm) {
                case 'linear':
                    return this.linearPrediction(data, horizon);
                case 'exponential':
                    return this.exponentialPrediction(data, horizon);
                case 'polynomial':
                    return this.polynomialPrediction(data, horizon);
                default:
                    return this.linearPrediction(data, horizon);
            }
        } catch (error) {
            this.emit('predictionError', { algorithm, error: error.message });
            return null;
        }
    }

    /**
     * Prédiction linéaire
     */
    private linearPrediction(data: number[], horizon: number): number {
        const n = data.length;
        const x = Array.from({ length: n }, (_, i) => i);
        const y = data;

        const sumX = x.reduce((a, b) => a + b, 0);
        const sumY = y.reduce((a, b) => a + b, 0);
        const sumXY = x.reduce((sum, xi, i) => sum + xi * y[i], 0);
        const sumX2 = x.reduce((sum, xi) => sum + xi * xi, 0);

        const slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
        const intercept = (sumY - slope * sumX) / n;

        return slope * (n + horizon - 1) + intercept;
    }

    /**
     * Prédiction exponentielle (lissage exponentiel simple)
     */
    private exponentialPrediction(data: number[], horizon: number): number {
        const alpha = 0.3; // Facteur de lissage
        let smoothed = data[0];

        for (let i = 1; i < data.length; i++) {
            smoothed = alpha * data[i] + (1 - alpha) * smoothed;
        }

        // Prédiction simple (peut être améliorée avec des tendances)
        return smoothed;
    }

    /**
     * Prédiction polynomiale (degré 2)
     */
    private polynomialPrediction(data: number[], horizon: number): number {
        const n = data.length;
        const x = Array.from({ length: n }, (_, i) => i);
        const y = data;

        // Régression polynomiale simple (degré 2)
        // Pour simplifier, utilisation d'une approximation
        const recentTrend = (y[n-1] - y[n-3]) / 2;
        const acceleration = (y[n-1] - 2*y[n-2] + y[n-3]);
        
        return y[n-1] + recentTrend * horizon + 0.5 * acceleration * horizon * horizon;
    }

    /**
     * Calcule la confiance de la prédiction
     */
    private calculateConfidence(data: number[], algorithm: string): number {
        const variance = this.calculateVariance(data);
        const stability = Math.max(0, 1 - variance / 100); // Normalisation
        
        // Facteur de confiance basé sur l'algorithme
        const algorithmFactor = {
            'linear': 0.8,
            'exponential': 0.7,
            'polynomial': 0.6
        }[algorithm] || 0.7;

        return Math.min(1, stability * algorithmFactor + 0.2);
    }

    /**
     * Calcule la variance d'un ensemble de données
     */
    private calculateVariance(data: number[]): number {
        const mean = data.reduce((a, b) => a + b, 0) / data.length;
        const squaredDiffs = data.map(value => Math.pow(value - mean, 2));
        return squaredDiffs.reduce((a, b) => a + b, 0) / data.length;
    }

    /**
     * Détermine si une alerte prédictive doit être déclenchée
     */
    private shouldTriggerPredictiveAlert(rule: PredictiveRule, prediction: number, confidence: number): boolean {
        // Seuils de confiance basés sur la sensibilité
        const confidenceThresholds = {
            'low': 0.4,
            'medium': 0.6,
            'high': 0.8
        };

        const minConfidence = confidenceThresholds[rule.sensitivity];
        
        // Vérification du cooldown
        const cooldownKey = `${rule.id}-predictive`;
        const lastAlert = this.alertCooldowns.get(cooldownKey) || 0;
        const cooldownPeriod = 2 * 60 * 1000; // 2 minutes
        
        if (Date.now() - lastAlert < cooldownPeriod) {
            return false;
        }

        return prediction > rule.threshold && confidence >= minConfidence;
    }

    /**
     * Crée une alerte prédictive
     */
    private createPredictiveAlert(rule: PredictiveRule, prediction: number, confidence: number, metrics: SystemMetrics): Alert {
        const currentValue = this.getCurrentMetricValue(rule.metric, metrics);
        
        this.alertCooldowns.set(`${rule.id}-predictive`, Date.now());

        return {
            id: `pred-${rule.id}-${Date.now()}`,
            type: prediction > rule.threshold * 1.2 ? 'error' : 'warning',
            metric: rule.metric,
            message: `${rule.name}: Predicted ${prediction.toFixed(1)}% in ${rule.predictionWindow} minutes (confidence: ${(confidence * 100).toFixed(1)}%)`,
            threshold: rule.threshold,
            currentValue,
            timestamp: Date.now(),
            predicted: true,
            severity: prediction > rule.threshold * 1.2 ? 4 : 3
        };
    }

    /**
     * Obtient la valeur actuelle d'une métrique
     */
    private getCurrentMetricValue(metricPath: string, metrics: SystemMetrics): number {
        const path = metricPath.split('.');
        let value: any = metrics;
        
        for (const key of path) {
            value = value?.[key];
        }
        
        return typeof value === 'number' ? value : 0;
    }

    /**
     * Analyse les tendances globales
     */
    private analyzeTrends(metrics: SystemMetrics): void {
        const trends: TrendAnalysis[] = [];

        // Analyse des tendances pour chaque métrique principale
        const metricsToAnalyze = ['cpu.usage', 'memory.usage', 'disk.usage'];
        
        for (const metricName of metricsToAnalyze) {
            const buffer = this.metricsBuffer.get(metricName);
            if (buffer && buffer.length >= 5) {
                const trend = this.calculateTrend(metricName, buffer.slice(-10));
                if (trend) {
                    trends.push(trend);
                }
            }
        }

        if (trends.length > 0) {
            this.emit('trendAnalysis', trends);
        }
    }

    /**
     * Calcule la tendance pour une métrique
     */
    private calculateTrend(metricName: string, data: number[]): TrendAnalysis | null {
        if (data.length < 3) {
            return null;
        }

        const n = data.length;
        const x = Array.from({ length: n }, (_, i) => i);
        const y = data;

        // Calcul de la régression linéaire
        const sumX = x.reduce((a, b) => a + b, 0);
        const sumY = y.reduce((a, b) => a + b, 0);
        const sumXY = x.reduce((sum, xi, i) => sum + xi * y[i], 0);
        const sumX2 = x.reduce((sum, xi) => sum + xi * xi, 0);

        const slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
        const intercept = (sumY - slope * sumX) / n;

        // Calcul du coefficient de corrélation (confiance)
        const meanY = sumY / n;
        const ss_tot = y.reduce((sum, yi) => sum + Math.pow(yi - meanY, 2), 0);
        const ss_res = y.reduce((sum, yi, i) => sum + Math.pow(yi - (slope * x[i] + intercept), 2), 0);
        const confidence = Math.max(0, 1 - ss_res / ss_tot);

        const direction = Math.abs(slope) < 0.1 ? 'stable' : slope > 0 ? 'increasing' : 'decreasing';
        const prediction = slope * n + intercept;

        return {
            metric: metricName,
            direction,
            slope,
            confidence,
            prediction: Math.max(0, prediction),
            dataPoints: n
        };
    }

    /**
     * Déclenche les actions d'atténuation automatique
     */
    private triggerMitigation(alert: Alert): void {
        for (const trigger of this.mitigationTriggers.values()) {
            if (!trigger.enabled) {
                continue;
            }

            if (this.shouldTriggerMitigation(trigger, alert)) {
                this.executeMitigation(trigger, alert);
            }
        }
    }

    /**
     * Détermine si un trigger d'atténuation doit être activé
     */
    private shouldTriggerMitigation(trigger: MitigationTrigger, alert: Alert): boolean {
        // Vérification du type d'alerte
        if (trigger.alertType !== alert.metric.split('.')[0]) {
            return false;
        }

        // Vérification du cooldown
        if (trigger.lastTriggered) {
            const cooldownMs = trigger.cooldown * 60 * 1000;
            if (Date.now() - trigger.lastTriggered < cooldownMs) {
                return false;
            }
        }

        // Évaluation de la condition
        return this.evaluateCondition(trigger.condition, alert.currentValue);
    }

    /**
     * Évalue une condition simple
     */
    private evaluateCondition(condition: string, value: number): boolean {
        try {
            // Remplacement simple pour évaluation
            const expression = condition.replace(/value/g, value.toString());
            return eval(expression);
        } catch {
            return false;
        }
    }

    /**
     * Exécute une action d'atténuation
     */
    private async executeMitigation(trigger: MitigationTrigger, alert: Alert): Promise<void> {
        trigger.lastTriggered = Date.now();

        try {
            switch (trigger.action) {
                case 'cleanup':
                    await this.executeCleanup(trigger.parameters);
                    break;
                case 'restart':
                    await this.executeRestart(trigger.parameters);
                    break;
                case 'scale':
                    await this.executeScale(trigger.parameters);
                    break;
                case 'notify':
                    await this.executeNotification(trigger.parameters, alert);
                    break;
                case 'emergency_stop':
                    await this.executeEmergencyStop(trigger.parameters);
                    break;
            }

            this.emit('mitigationExecuted', { trigger, alert, success: true });
            
        } catch (error) {
            this.emit('mitigationExecuted', { trigger, alert, success: false, error: error.message });
        }
    }

    /**
     * Exécute un nettoyage système
     */
    private async executeCleanup(parameters: any): Promise<void> {
        vscode.window.showInformationMessage('🧹 Automatic cleanup initiated...');
        
        // Simulation de nettoyage
        if (parameters.clearCache) {
            // Nettoyage du cache
        }
        
        if (parameters.gcTrigger) {
            // Déclenchement du garbage collector
            if (global.gc) {
                global.gc();
            }
        }
    }

    /**
     * Exécute un redémarrage de service
     */
    private async executeRestart(parameters: any): Promise<void> {
        vscode.window.showWarningMessage('🔄 Service restart initiated...');
        // Logique de redémarrage
    }

    /**
     * Exécute une mise à l'échelle
     */
    private async executeScale(parameters: any): Promise<void> {
        vscode.window.showInformationMessage('📈 Resource scaling initiated...');
        // Logique de scaling
    }

    /**
     * Exécute une notification
     */
    private async executeNotification(parameters: any, alert: Alert): Promise<void> {
        const message = `🔔 ${alert.message}${parameters.suggestion ? ` - ${parameters.suggestion}` : ''}`;
        
        if (parameters.level === 'critical') {
            vscode.window.showErrorMessage(message);
        } else {
            vscode.window.showWarningMessage(message);
        }
    }

    /**
     * Exécute un arrêt d'urgence
     */
    private async executeEmergencyStop(parameters: any): Promise<void> {
        vscode.window.showErrorMessage('🚨 Emergency stop triggered by predictive system!');
        this.emit('emergencyStopTriggered', parameters);
    }

    // Méthodes publiques de gestion

    public addPredictiveRule(rule: PredictiveRule): void {
        this.predictiveRules.set(rule.id, rule);
        this.emit('ruleAdded', rule);
    }

    public removePredictiveRule(ruleId: string): boolean {
        const removed = this.predictiveRules.delete(ruleId);
        if (removed) {
            this.emit('ruleRemoved', ruleId);
        }
        return removed;
    }

    public updatePredictiveRule(ruleId: string, updates: Partial<PredictiveRule>): boolean {
        const rule = this.predictiveRules.get(ruleId);
        if (rule) {
            const updatedRule = { ...rule, ...updates };
            this.predictiveRules.set(ruleId, updatedRule);
            this.emit('ruleUpdated', updatedRule);
            return true;
        }
        return false;
    }

    public addMitigationTrigger(trigger: MitigationTrigger): void {
        this.mitigationTriggers.set(trigger.id, trigger);
        this.emit('triggerAdded', trigger);
    }

    public removeMitigationTrigger(triggerId: string): boolean {
        const removed = this.mitigationTriggers.delete(triggerId);
        if (removed) {
            this.emit('triggerRemoved', triggerId);
        }
        return removed;
    }

    public getPredictiveRules(): PredictiveRule[] {
        return Array.from(this.predictiveRules.values());
    }

    public getMitigationTriggers(): MitigationTrigger[] {
        return Array.from(this.mitigationTriggers.values());
    }

    public enable(): void {
        this.isEnabled = true;
        this.emit('enabled');
    }

    public disable(): void {
        this.isEnabled = false;
        this.emit('disabled');
    }

    public clearMetricsBuffers(): void {
        this.metricsBuffer.clear();
        this.emit('buffersCleared');
    }

    public getMetricsBuffer(metric: string): number[] {
        return this.metricsBuffer.get(metric) || [];
    }

    public dispose(): void {
        this.predictiveRules.clear();
        this.mitigationTriggers.clear();
        this.metricsBuffer.clear();
        this.alertCooldowns.clear();
        this.removeAllListeners();
    }
}
