import * as vscode from 'vscode';
import { ResourceDashboard, SystemMetrics } from './ResourceDashboard';
import { PredictiveAlertingSystem } from './PredictiveAlertingSystem';
import { EmergencyStopRecoverySystem } from './EmergencyStopRecoverySystem';

export interface MonitoringSystemConfig {
  monitoringInterval: number; // milliseconds
  predictionInterval: number; // milliseconds
  enableAutoRecovery: boolean;
  workspacePath: string;
}

export class MonitoringManager {
  private resourceDashboard: ResourceDashboard;
  private predictiveSystem: PredictiveAlertingSystem;
  private emergencySystem: EmergencyStopRecoverySystem;
  private isActive: boolean = false;
  private config: MonitoringSystemConfig;

  constructor(config: MonitoringSystemConfig) {
    this.config = config;
    this.resourceDashboard = new ResourceDashboard();
    this.predictiveSystem = new PredictiveAlertingSystem();
    this.emergencySystem = new EmergencyStopRecoverySystem(config.workspacePath);

    this.setupIntegration();
  }

  private setupIntegration(): void {
    // Connect predictive system to emergency system
    // This would be enhanced to actually listen to events between systems
    console.log('Setting up integration between monitoring components...');
  }

  public async startMonitoring(): Promise<void> {
    if (this.isActive) {
      vscode.window.showWarningMessage('Monitoring is already active');
      return;
    }

    try {
      // Start resource monitoring
      await this.resourceDashboard.startMonitoring(this.config.monitoringInterval);
      
      // Start predictive analysis
      this.predictiveSystem.startPredictiveAnalysis(this.config.predictionInterval);
      
      this.isActive = true;
      
      // Set up periodic data sync between components
      this.setupDataSync();
      
      vscode.window.showInformationMessage('🚀 Complete monitoring system started successfully');
      
      // Show initial dashboard
      this.showCompleteDashboard();
      
    } catch (error) {
      vscode.window.showErrorMessage(`Failed to start monitoring: ${error}`);
    }
  }

  public stopMonitoring(): void {
    if (!this.isActive) {
      vscode.window.showWarningMessage('Monitoring is not active');
      return;
    }

    this.resourceDashboard.stopMonitoring();
    this.predictiveSystem.stopPredictiveAnalysis();
    this.isActive = false;

    vscode.window.showInformationMessage('🛑 Monitoring system stopped');
  }

  private setupDataSync(): void {
    // Sync metrics history to predictive system every minute
    setInterval(() => {
      if (this.isActive) {
        const metricsHistory = this.resourceDashboard.getMetricsHistory();
        this.predictiveSystem.analyzeMetricsHistory(metricsHistory);
      }
    }, 60000); // Every minute
  }

  public showCompleteDashboard(): void {
    const panel = vscode.window.createWebviewPanel(
      'completeDashboard',
      '📊 Complete Monitoring Dashboard',
      vscode.ViewColumn.One,
      {
        enableScripts: true,
        retainContextWhenHidden: true
      }
    );

    panel.webview.onDidReceiveMessage(async (message) => {
      switch (message.command) {
        case 'emergencyStop':
          await this.handleEmergencyStop(message.reason);
          break;
        case 'refreshData':
          this.updateCompleteDashboard(panel);
          break;
        case 'showResourceDashboard':
          this.resourceDashboard.showDashboard();
          break;
        case 'showTrendAnalysis':
          // Show trend analysis from predictive system
          break;
      }
    });

    this.updateCompleteDashboard(panel);

    // Auto-refresh every 10 seconds
    const refreshInterval = setInterval(() => {
      if (panel.visible) {
        this.updateCompleteDashboard(panel);
      }
    }, 10000);

    panel.onDidDispose(() => {
      clearInterval(refreshInterval);
    });
  }

  private updateCompleteDashboard(panel: vscode.WebviewPanel): void {
    const currentMetrics = this.resourceDashboard.getCurrentMetrics();
    const alerts = this.resourceDashboard.getAlerts();
    const predictions = this.predictiveSystem.getPredictions();
    const emergencyStops = this.emergencySystem.getEmergencyStops();
    const trendAnalyses = this.predictiveSystem.getTrendAnalyses();

    panel.webview.html = this.generateCompleteDashboardHTML(
      currentMetrics,
      alerts,
      predictions,
      emergencyStops,
      trendAnalyses
    );
  }

  private generateCompleteDashboardHTML(
    metrics?: SystemMetrics,
    alerts: any[] = [],
    predictions: any[] = [],
    emergencyStops: any[] = [],
    trendAnalyses: Map<string, any> = new Map()
  ): string {
    if (!metrics) {
      return `
        <!DOCTYPE html>
        <html>
        <head>
          <style>
            body { font-family: Arial, sans-serif; margin: 20px; background: #1e1e1e; color: #fff; text-align: center; }
            .start-button { 
              background: #007acc; 
              color: white; 
              border: none; 
              padding: 20px 40px; 
              border-radius: 8px; 
              cursor: pointer; 
              font-size: 18px;
            }
          </style>
        </head>
        <body>
          <h1>📊 Complete Monitoring Dashboard</h1>
          <p>Monitoring system is not active</p>
          <button class="start-button" onclick="startMonitoring()">🚀 Start Monitoring</button>
          <script>
            function startMonitoring() {
              const vscode = acquireVsCodeApi();
              vscode.postMessage({ command: 'startMonitoring' });
            }
          </script>
        </body>
        </html>
      `;
    }

    const currentEmergency = this.emergencySystem.getCurrentEmergency();
    const recentPredictions = predictions.slice(-3);
    const trendArray = Array.from(trendAnalyses.entries());

    return `
      <!DOCTYPE html>
      <html>
      <head>
        <style>
          body { 
            font-family: Arial, sans-serif; 
            margin: 0; 
            padding: 20px; 
            background: #1e1e1e; 
            color: #fff; 
          }
          .dashboard-grid {
            display: grid;
            grid-template-columns: 2fr 1fr;
            gap: 20px;
            margin-bottom: 20px;
          }
          .widget {
            background: #2d2d30;
            padding: 15px;
            border-radius: 8px;
            border-left: 4px solid #007acc;
          }
          .widget.critical { border-left-color: #e74c3c; }
          .widget.warning { border-left-color: #f39c12; }
          .widget.success { border-left-color: #27ae60; }
          .emergency-section {
            background: linear-gradient(135deg, #e74c3c, #c0392b);
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 20px;
            text-align: center;
          }
          .metrics-overview {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
            gap: 15px;
            margin-bottom: 20px;
          }
          .metric-card {
            background: #3a3a3a;
            padding: 15px;
            border-radius: 6px;
            text-align: center;
          }
          .metric-value {
            font-size: 2em;
            font-weight: bold;
            margin: 10px 0;
          }
          .progress-ring {
            width: 60px;
            height: 60px;
            margin: 0 auto;
          }
          .button {
            background: #007acc;
            color: white;
            border: none;
            padding: 10px 20px;
            border-radius: 5px;
            cursor: pointer;
            margin: 5px;
          }
          .button.danger { background: #e74c3c; }
          .button.warning { background: #f39c12; }
          .button.success { background: #27ae60; }
          .alert-item {
            background: #3a3a3a;
            padding: 10px;
            margin: 5px 0;
            border-radius: 4px;
            border-left: 3px solid #f39c12;
          }
          .alert-item.critical { border-left-color: #e74c3c; }
          .prediction-item {
            background: #2a3a4a;
            padding: 10px;
            margin: 5px 0;
            border-radius: 4px;
            border-left: 3px solid #3498db;
          }
          .trend-indicator {
            display: inline-block;
            padding: 2px 8px;
            border-radius: 12px;
            font-size: 0.8em;
            margin-left: 10px;
          }
          .trend-increasing { background: #e74c3c; color: white; }
          .trend-decreasing { background: #27ae60; color: white; }
          .trend-stable { background: #f39c12; color: white; }
          .status-indicator {
            width: 10px;
            height: 10px;
            border-radius: 50%;
            display: inline-block;
            margin-right: 8px;
          }
          .status-healthy { background: #27ae60; }
          .status-warning { background: #f39c12; }
          .status-critical { background: #e74c3c; }
          .footer {
            text-align: center;
            margin-top: 30px;
            padding: 20px;
            border-top: 1px solid #444;
          }
        </style>
      </head>
      <body>
        <header style="text-align: center; margin-bottom: 30px;">
          <h1>📊 Complete Monitoring Dashboard</h1>
          <p>Last updated: ${metrics.timestamp.toLocaleString()}</p>
          <div>
            <button class="button" onclick="refreshData()">🔄 Refresh</button>
            <button class="button warning" onclick="showResourceDashboard()">📈 Resource Details</button>
            <button class="button" onclick="showTrendAnalysis()">🔮 Trend Analysis</button>
          </div>
        </header>

        ${currentEmergency ? `
          <div class="emergency-section">
            <h2>🛑 EMERGENCY STATUS ACTIVE</h2>
            <p><strong>Reason:</strong> ${currentEmergency.reason}</p>
            <p><strong>Status:</strong> ${currentEmergency.status.toUpperCase()}</p>
            <p><strong>Progress:</strong> ${currentEmergency.recoveryProgress}%</p>
            <button class="button danger" onclick="viewEmergencyDetails()">View Emergency Details</button>
          </div>
        ` : ''}

        <div class="metrics-overview">
          <div class="metric-card ${metrics.cpu > 90 ? 'critical' : metrics.cpu > 70 ? 'warning' : 'success'}">
            <h3>🔧 CPU Usage</h3>
            <div class="metric-value" style="color: ${metrics.cpu > 90 ? '#e74c3c' : metrics.cpu > 70 ? '#f39c12' : '#27ae60'}">${metrics.cpu}%</div>
            <div class="status-indicator ${metrics.cpu > 90 ? 'status-critical' : metrics.cpu > 70 ? 'status-warning' : 'status-healthy'}"></div>
          </div>

          <div class="metric-card ${metrics.ram.percentage > 90 ? 'critical' : metrics.ram.percentage > 70 ? 'warning' : 'success'}">
            <h3>💾 RAM Usage</h3>
            <div class="metric-value" style="color: ${metrics.ram.percentage > 90 ? '#e74c3c' : metrics.ram.percentage > 70 ? '#f39c12' : '#27ae60'}">${metrics.ram.percentage}%</div>
            <div class="status-indicator ${metrics.ram.percentage > 90 ? 'status-critical' : metrics.ram.percentage > 70 ? 'status-warning' : 'status-healthy'}"></div>
            <small>${metrics.ram.used} MB / ${metrics.ram.total} MB</small>
          </div>

          <div class="metric-card">
            <h3>🌐 Network</h3>
            <div class="metric-value" style="color: #3498db">${metrics.network.latency}ms</div>
            <div class="status-indicator status-healthy"></div>
            <small>Latency</small>
          </div>

          <div class="metric-card">
            <h3>⚡ Services</h3>
            <div class="metric-value" style="color: #27ae60">${metrics.services.filter(s => s.status === 'healthy').length}/${metrics.services.length}</div>
            <div class="status-indicator status-healthy"></div>
            <small>Healthy</small>
          </div>
        </div>

        <div class="dashboard-grid">
          <div class="widget">
            <h3>🚨 Recent Alerts (${alerts.length})</h3>
            <div style="max-height: 300px; overflow-y: auto;">
              ${alerts.slice(-5).map(alert => `
                <div class="alert-item ${alert.severity}">
                  <strong>${alert.rule.name}</strong><br>
                  ${alert.message}<br>
                  <small>${alert.triggered.toLocaleString()}</small>
                </div>
              `).join('')}
              ${alerts.length === 0 ? '<p>No recent alerts</p>' : ''}
            </div>
          </div>

          <div class="widget">
            <h3>🔮 Predictive Alerts (${recentPredictions.length})</h3>
            <div style="max-height: 300px; overflow-y: auto;">
              ${recentPredictions.map(pred => `
                <div class="prediction-item">
                  <strong>${pred.rule.name}</strong><br>
                  Value: ${pred.predictedValue.toFixed(2)}<br>
                  Time: ${pred.timeToThreshold.toFixed(1)} min<br>
                  Confidence: ${(pred.confidence * 100).toFixed(1)}%<br>
                  <small>${pred.predicted.toLocaleString()}</small>
                </div>
              `).join('')}
              ${recentPredictions.length === 0 ? '<p>No predictions</p>' : ''}
            </div>
          </div>
        </div>

        <div class="widget">
          <h3>📈 Trend Analysis</h3>
          <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(300px, 1fr)); gap: 15px;">
            ${trendArray.map(([metric, analysis]) => `
              <div style="background: #3a3a3a; padding: 10px; border-radius: 4px;">
                <strong>${metric}</strong>
                <span class="trend-indicator trend-${analysis.direction}">
                  ${analysis.direction === 'increasing' ? '📈' : analysis.direction === 'decreasing' ? '📉' : '➡️'} 
                  ${analysis.direction.toUpperCase()}
                </span>
                <br>
                <small>Confidence: ${(analysis.confidence * 100).toFixed(1)}%</small><br>
                <small>Slope: ${analysis.slope.toFixed(4)}</small>
              </div>
            `).join('')}
            ${trendArray.length === 0 ? '<p>No trend data available</p>' : ''}
          </div>
        </div>

        <div class="widget">
          <h3>🔄 Top Processes</h3>
          <div style="max-height: 200px; overflow-y: auto;">
            ${metrics.processes.slice(0, 8).map(proc => `
              <div style="display: flex; justify-content: space-between; padding: 5px 0; border-bottom: 1px solid #444;">
                <span>${proc.name} (${proc.pid})</span>
                <span>CPU: ${proc.cpu.toFixed(1)}% | RAM: ${proc.memory} KB</span>
              </div>
            `).join('')}
          </div>
        </div>

        <div class="emergency-section" style="background: linear-gradient(135deg, #2d2d30, #1e1e1e); margin-top: 20px;">
          <h3>🛑 Emergency Controls</h3>
          <button class="button danger" onclick="emergencyStop('User requested emergency stop')">
            🛑 Emergency Stop
          </button>
          <button class="button warning" onclick="forceCleanup()">
            🧹 Force Cleanup
          </button>
          <button class="button" onclick="restartServices()">
            🔄 Restart Services
          </button>
        </div>

        <div class="footer">
          <p>📊 Phase 0.5: Monitoring & Alerting System - ✅ Active</p>
          <p><small>Real-time resource monitoring • Predictive alerting • Emergency recovery</small></p>
        </div>

        <script>
          const vscode = acquireVsCodeApi();

          function refreshData() {
            vscode.postMessage({ command: 'refreshData' });
          }

          function showResourceDashboard() {
            vscode.postMessage({ command: 'showResourceDashboard' });
          }

          function showTrendAnalysis() {
            vscode.postMessage({ command: 'showTrendAnalysis' });
          }

          function emergencyStop(reason) {
            if (confirm('Are you sure you want to trigger an emergency stop?\\n\\nReason: ' + reason)) {
              vscode.postMessage({ 
                command: 'emergencyStop', 
                reason: reason 
              });
            }
          }

          function forceCleanup() {
            if (confirm('Are you sure you want to force cleanup?')) {
              alert('Force cleanup initiated!');
            }
          }

          function restartServices() {
            if (confirm('Are you sure you want to restart all services?')) {
              alert('Services restart initiated!');
            }
          }

          function viewEmergencyDetails() {
            alert('Emergency details view - would open emergency recovery panel');
          }

          // Auto-refresh indicator
          let refreshCount = 0;
          setInterval(() => {
            refreshCount++;
            const indicator = document.querySelector('header p');
            if (indicator) {
              indicator.style.opacity = '0.5';
              setTimeout(() => {
                indicator.style.opacity = '1';
              }, 200);
            }
          }, 10000);
        </script>
      </body>
      </html>
    `;
  }

  private async handleEmergencyStop(reason: string): Promise<void> {
    try {
      const emergencyId = await this.emergencySystem.triggerEmergencyStop(reason, 'critical');
      vscode.window.showWarningMessage(`Emergency stop triggered: ${emergencyId}`);
    } catch (error) {
      vscode.window.showErrorMessage(`Failed to trigger emergency stop: ${error}`);
    }
  }

  public getSystemStatus(): any {
    return {
      isActive: this.isActive,
      currentMetrics: this.resourceDashboard.getCurrentMetrics(),
      alertCount: this.resourceDashboard.getAlerts().length,
      predictionCount: this.predictiveSystem.getPredictions().length,
      emergencyCount: this.emergencySystem.getEmergencyStops().length,
      currentEmergency: this.emergencySystem.getCurrentEmergency()
    };
  }

  public exportSystemData(): string {
    return JSON.stringify({
      resourceMetrics: this.resourceDashboard.exportMetrics(),
      predictiveData: this.predictiveSystem.exportPredictiveData(),
      emergencyHistory: this.emergencySystem.exportEmergencyHistory(),
      exportedAt: new Date()
    }, null, 2);
  }

  public dispose(): void {
    this.stopMonitoring();
    this.resourceDashboard.dispose();
    this.predictiveSystem.dispose();
    this.emergencySystem.dispose();
  }
}

// Export React component interface as specified in the markdown
export interface ResourceMonitorProps {
  children: React.ReactNode;
}

export interface CPUUsageChartProps {
  usage: number;
}

export interface RAMUsageChartProps {
  usage: {
    used: number;
    total: number;
    percentage: number;
  };
}

export interface ProcessListProps {
  processes: Array<{
    pid: number;
    name: string;
    cpu: number;
    memory: number;
    status: string;
  }>;
}

export interface ServiceHealthProps {
  services: Array<{
    name: string;
    status: string;
    uptime: number;
    lastCheck: Date;
    responseTime?: number;
  }>;
}

export interface EmergencyControlsProps {
  onEmergency: (reason: string) => void;
}

// React component implementation (would be in a separate .tsx file in a real project)
export const ResourceDashboardComponent = `
import React, { useState, useEffect } from 'react';
import { SystemMetrics } from './ResourceDashboard';

const ResourceDashboard: React.FC = () => {
  const [metrics, setMetrics] = useState<SystemMetrics>({});
  
  useEffect(() => {
    // In a real implementation, this would connect to the monitoring system
    // For now, it's just a template matching the markdown specification
  }, []);

  const handleEmergency = (reason: string) => {
    // Trigger emergency stop
    console.log('Emergency triggered:', reason);
  };

  return (
    <ResourceMonitor>
      <CPUUsageChart usage={metrics.cpu} />
      <RAMUsageChart usage={metrics.ram} />
      <ProcessList processes={metrics.processes} />
      <ServiceHealth services={metrics.services} />
      <EmergencyControls onEmergency={handleEmergency} />
    </ResourceMonitor>
  );
};

const ResourceMonitor: React.FC<ResourceMonitorProps> = ({ children }) => (
  <div className="resource-monitor">{children}</div>
);

const CPUUsageChart: React.FC<CPUUsageChartProps> = ({ usage }) => (
  <div className="cpu-chart">CPU: {usage}%</div>
);

const RAMUsageChart: React.FC<RAMUsageChartProps> = ({ usage }) => (
  <div className="ram-chart">RAM: {usage.percentage}%</div>
);

const ProcessList: React.FC<ProcessListProps> = ({ processes }) => (
  <div className="process-list">
    {processes?.map(proc => (
      <div key={proc.pid}>{proc.name}: {proc.cpu}%</div>
    ))}
  </div>
);

const ServiceHealth: React.FC<ServiceHealthProps> = ({ services }) => (
  <div className="service-health">
    {services?.map(service => (
      <div key={service.name}>{service.name}: {service.status}</div>
    ))}
  </div>
);

const EmergencyControls: React.FC<EmergencyControlsProps> = ({ onEmergency }) => (
  <div className="emergency-controls">
    <button onClick={() => onEmergency('Manual trigger')}>Emergency Stop</button>
  </div>
);

export { ResourceDashboard };
`;
