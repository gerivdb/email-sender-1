// Infrastructure Manager Integration for VSCode Extension
// Phase 0.1 : Extension Integration with Diagnostic System

import { InfrastructureDiagnostic, DiagnosticReport, RepairResult } from './InfrastructureDiagnostic';
import * as vscode from 'vscode';

export interface ExtensionIntegrationConfig {
  diagnosticInterval: number; // ms
  autoRepairEnabled: boolean;
  notificationLevel: 'error' | 'warning' | 'info';
  enableBackgroundMonitoring: boolean;
}

export class InfrastructureExtensionManager {
  private diagnostic: InfrastructureDiagnostic;
  private outputChannel: vscode.OutputChannel;
  private statusBarItem: vscode.StatusBarItem;
  private diagnosticInterval: NodeJS.Timeout | undefined;
  private config: ExtensionIntegrationConfig;

  constructor(
    private context: vscode.ExtensionContext,
    config?: Partial<ExtensionIntegrationConfig>
  ) {
    this.diagnostic = new InfrastructureDiagnostic();
    this.outputChannel = vscode.window.createOutputChannel('Infrastructure Manager');
    this.statusBarItem = vscode.window.createStatusBarItem(
      vscode.StatusBarAlignment.Left,
      100
    );
    
    this.config = {
      diagnosticInterval: 30000, // 30 seconds
      autoRepairEnabled: true,
      notificationLevel: 'warning',
      enableBackgroundMonitoring: true,
      ...config
    };

    this.initialize();
  }

  private async initialize(): Promise<void> {
    this.log('🔧 Initializing Infrastructure Extension Manager...');
    
    // Register commands
    this.registerCommands();
    
    // Setup status bar
    this.setupStatusBar();
    
    // Start background monitoring if enabled
    if (this.config.enableBackgroundMonitoring) {
      this.startBackgroundMonitoring();
    }
    
    // Run initial diagnostic
    await this.runDiagnosticWithUI();
    
    this.log('✅ Infrastructure Extension Manager initialized');
  }

  private registerCommands(): void {
    const commands = [
      vscode.commands.registerCommand(
        'infrastructure.runDiagnostic',
        () => this.runDiagnosticWithUI()
      ),
      vscode.commands.registerCommand(
        'infrastructure.repairApiServer',
        () => this.repairApiServerWithUI()
      ),
      vscode.commands.registerCommand(
        'infrastructure.runEmergencyRepair',
        () => this.runEmergencyRepair()
      ),
      vscode.commands.registerCommand(
        'infrastructure.toggleMonitoring',
        () => this.toggleBackgroundMonitoring()
      ),
      vscode.commands.registerCommand(
        'infrastructure.showDetailedStatus',
        () => this.showDetailedStatus()
      ),
      vscode.commands.registerCommand(
        'infrastructure.auditScripts',
        () => this.auditInfrastructureScripts()
      )
    ];

    commands.forEach(cmd => this.context.subscriptions.push(cmd));
    this.context.subscriptions.push(this.outputChannel, this.statusBarItem);
  }

  private setupStatusBar(): void {
    this.statusBarItem.command = 'infrastructure.showDetailedStatus';
    this.statusBarItem.show();
    this.updateStatusBar('⏳', 'Initializing...', 'yellow');
  }

  private updateStatusBar(
    icon: string,
    text: string,
    color: 'green' | 'yellow' | 'red'
  ): void {
    this.statusBarItem.text = `${icon} Infrastructure: ${text}`;
    this.statusBarItem.backgroundColor = color === 'red' 
      ? new vscode.ThemeColor('statusBarItem.errorBackground')
      : color === 'yellow'
      ? new vscode.ThemeColor('statusBarItem.warningBackground')
      : undefined;
  }

  private startBackgroundMonitoring(): void {
    this.diagnosticInterval = setInterval(async () => {
      try {
        const report = await this.diagnostic.runCompleteDiagnostic();
        this.processBackgroundDiagnostic(report);
      } catch (error) {
        this.log(`Background diagnostic error: ${error}`);
      }
    }, this.config.diagnosticInterval);

    this.log(`🔄 Background monitoring started (interval: ${this.config.diagnosticInterval}ms)`);
  }

  private stopBackgroundMonitoring(): void {
    if (this.diagnosticInterval) {
      clearInterval(this.diagnosticInterval);
      this.diagnosticInterval = undefined;
      this.log('⏹️ Background monitoring stopped');
    }
  }

  private async processBackgroundDiagnostic(report: DiagnosticReport): Promise<void> {
    // Update status bar based on overall health
    switch (report.overallHealth) {
      case 'healthy':
        this.updateStatusBar('✅', 'Running', 'green');
        break;
      case 'warning':
        this.updateStatusBar('⚠️', 'Issues Detected', 'yellow');
        if (this.config.notificationLevel !== 'error') {
          this.showNotification('warning', 'Infrastructure issues detected');
        }
        break;
      case 'critical':
        this.updateStatusBar('❌', 'Critical Issues', 'red');
        this.showNotification('error', 'Critical infrastructure issues detected');
        
        // Auto-repair if enabled
        if (this.config.autoRepairEnabled) {
          this.log('🔧 Auto-repair triggered for critical issues');
          await this.repairApiServerWithUI();
        }
        break;
    }

    // Log diagnostic summary
    this.log(`Diagnostic: ${report.overallHealth} - API: ${report.apiServer.status}, Memory: ${report.resourceUsage.memory}%, Conflicts: ${report.processConflicts.length}`);
  }

  async runDiagnosticWithUI(): Promise<DiagnosticReport> {
    this.log('🩺 Running infrastructure diagnostic...');
    this.updateStatusBar('⏳', 'Diagnosing...', 'yellow');

    try {
      const report = await vscode.window.withProgress(
        {
          location: vscode.ProgressLocation.Notification,
          title: 'Running Infrastructure Diagnostic',
          cancellable: false
        },
        async (progress) => {
          progress.report({ increment: 0, message: 'Checking API Server...' });
          const report = await this.diagnostic.runCompleteDiagnostic();
          progress.report({ increment: 100, message: 'Diagnostic complete' });
          return report;
        }
      );

      this.displayDiagnosticResults(report);
      this.processBackgroundDiagnostic(report); // Update UI
      
      return report;
    } catch (error) {
      this.log(`❌ Diagnostic failed: ${error}`);
      this.updateStatusBar('❌', 'Diagnostic Failed', 'red');
      this.showNotification('error', 'Infrastructure diagnostic failed');
      throw error;
    }
  }

  async repairApiServerWithUI(): Promise<RepairResult> {
    this.log('🔧 Repairing API Server...');
    this.updateStatusBar('⏳', 'Repairing...', 'yellow');

    try {
      const result = await vscode.window.withProgress(
        {
          location: vscode.ProgressLocation.Notification,
          title: 'Repairing API Server',
          cancellable: false
        },
        async (progress) => {
          progress.report({ increment: 0, message: 'Stopping existing processes...' });
          const result = await this.diagnostic.repairApiServer();
          progress.report({ increment: 100, message: 'Repair complete' });
          return result;
        }
      );

      if (result.success) {
        this.log(`✅ Repair successful: ${result.details}`);
        this.updateStatusBar('✅', 'Running', 'green');
        this.showNotification('info', 'API Server repair completed successfully');
      } else {
        this.log(`❌ Repair failed: ${result.details}`);
        this.updateStatusBar('❌', 'Repair Failed', 'red');
        this.showNotification('error', `API Server repair failed: ${result.details}`);
      }

      return result;
    } catch (error) {
      this.log(`❌ Repair error: ${error}`);
      this.updateStatusBar('❌', 'Repair Error', 'red');
      this.showNotification('error', 'API Server repair encountered an error');
      throw error;
    }
  }

  async runEmergencyRepair(): Promise<void> {
    this.log('🚨 Running emergency repair...');
    
    const terminal = vscode.window.createTerminal({
      name: 'Emergency Infrastructure Repair',
      cwd: vscode.workspace.workspaceFolders?.[0]?.uri.fsPath
    });

    terminal.sendText('powershell -ExecutionPolicy Bypass -File .\\scripts\\Emergency-Repair.ps1');
    terminal.show();

    this.showNotification('info', 'Emergency repair script launched in terminal');
  }

  async auditInfrastructureScripts(): Promise<void> {
    this.log('🔍 Auditing infrastructure scripts...');
    
    const terminal = vscode.window.createTerminal({
      name: 'Infrastructure Scripts Audit',
      cwd: vscode.workspace.workspaceFolders?.[0]?.uri.fsPath
    });

    terminal.sendText('powershell -ExecutionPolicy Bypass -File .\\scripts\\Infrastructure-Scripts-Audit.ps1');
    terminal.show();

    this.showNotification('info', 'Infrastructure scripts audit launched in terminal');
  }

  private toggleBackgroundMonitoring(): void {
    if (this.diagnosticInterval) {
      this.stopBackgroundMonitoring();
      this.config.enableBackgroundMonitoring = false;
      this.showNotification('info', 'Background monitoring disabled');
    } else {
      this.startBackgroundMonitoring();
      this.config.enableBackgroundMonitoring = true;
      this.showNotification('info', 'Background monitoring enabled');
    }
  }

  private async showDetailedStatus(): Promise<void> {
    try {
      const report = await this.diagnostic.runCompleteDiagnostic();
      
      const panel = vscode.window.createWebviewPanel(
        'infrastructureStatus',
        'Infrastructure Status',
        vscode.ViewColumn.One,
        { enableScripts: true }
      );

      panel.webview.html = this.generateStatusWebview(report);
    } catch (error) {
      this.showNotification('error', 'Failed to generate detailed status');
    }
  }

  private generateStatusWebview(report: DiagnosticReport): string {
    const healthColor = report.overallHealth === 'healthy' ? '#28a745' : 
                       report.overallHealth === 'warning' ? '#ffc107' : '#dc3545';

    return `
      <!DOCTYPE html>
      <html>
      <head>
        <title>Infrastructure Status</title>
        <style>
          body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; padding: 20px; }
          .header { color: ${healthColor}; border-bottom: 2px solid ${healthColor}; padding-bottom: 10px; }
          .section { margin: 20px 0; padding: 15px; border: 1px solid #ddd; border-radius: 5px; }
          .status-good { color: #28a745; }
          .status-warning { color: #ffc107; }
          .status-error { color: #dc3545; }
          .metric { display: flex; justify-content: space-between; margin: 5px 0; }
        </style>
      </head>
      <body>
        <h1 class="header">🏗️ Infrastructure Status - ${report.overallHealth.toUpperCase()}</h1>
        
        <div class="section">
          <h2>📡 API Server</h2>
          <div class="metric">
            <span>Status:</span>
            <span class="status-${report.apiServer.status === 'running' ? 'good' : 'error'}">${report.apiServer.status}</span>
          </div>
          <div class="metric">
            <span>Endpoint:</span>
            <span>${report.apiServer.endpoint}</span>
          </div>
          ${report.apiServer.responseTime ? `<div class="metric">
            <span>Response Time:</span>
            <span>${report.apiServer.responseTime}ms</span>
          </div>` : ''}
        </div>

        <div class="section">
          <h2>💻 System Resources</h2>
          <div class="metric">
            <span>CPU Usage:</span>
            <span class="status-${report.resourceUsage.cpu > 80 ? 'error' : report.resourceUsage.cpu > 60 ? 'warning' : 'good'}">${report.resourceUsage.cpu}%</span>
          </div>
          <div class="metric">
            <span>Memory Usage:</span>
            <span class="status-${report.resourceUsage.memory > 80 ? 'error' : report.resourceUsage.memory > 60 ? 'warning' : 'good'}">${report.resourceUsage.memory}%</span>
          </div>
          <div class="metric">
            <span>Disk Usage:</span>
            <span class="status-${report.resourceUsage.disk > 80 ? 'error' : report.resourceUsage.disk > 60 ? 'warning' : 'good'}">${report.resourceUsage.disk}%</span>
          </div>
        </div>

        <div class="section">
          <h2>🔌 Ports Status</h2>
          ${report.servicesPorts.map(port => `
            <div class="metric">
              <span>Port ${port.port} (${port.service}):</span>
              <span class="status-${port.status === 'available' ? 'good' : port.status === 'occupied' ? 'warning' : 'error'}">${port.status}</span>
            </div>
          `).join('')}
        </div>

        ${report.processConflicts.length > 0 ? `
        <div class="section">
          <h2>⚠️ Process Conflicts</h2>
          ${report.processConflicts.map(conflict => `
            <div class="metric">
              <span>${conflict.processName} (PID: ${conflict.pid}):</span>
              <span class="status-warning">${conflict.conflictType}</span>
            </div>
          `).join('')}
        </div>` : ''}

        <div class="section">
          <h2>ℹ️ Diagnostic Info</h2>
          <div class="metric">
            <span>Last Check:</span>
            <span>${new Date(report.timestamp).toLocaleString()}</span>
          </div>
        </div>
      </body>
      </html>
    `;
  }

  private displayDiagnosticResults(report: DiagnosticReport): void {
    this.log('\n📊 DIAGNOSTIC RESULTS:');
    this.log(`Overall Health: ${report.overallHealth.toUpperCase()}`);
    this.log(`API Server: ${report.apiServer.status} (${report.apiServer.endpoint})`);
    this.log(`Resource Usage: CPU ${report.resourceUsage.cpu}%, Memory ${report.resourceUsage.memory}%`);
    this.log(`Process Conflicts: ${report.processConflicts.length}`);
    this.log(`Ports Status: ${report.servicesPorts.map(p => `${p.port}:${p.status}`).join(', ')}`);
  }

  private showNotification(
    level: 'error' | 'warning' | 'info',
    message: string
  ): void {
    switch (level) {
      case 'error':
        vscode.window.showErrorMessage(`Infrastructure: ${message}`);
        break;
      case 'warning':
        vscode.window.showWarningMessage(`Infrastructure: ${message}`);
        break;
      case 'info':
        vscode.window.showInformationMessage(`Infrastructure: ${message}`);
        break;
    }
  }

  private log(message: string): void {
    const timestamp = new Date().toLocaleTimeString();
    this.outputChannel.appendLine(`[${timestamp}] ${message}`);
  }

  dispose(): void {
    this.stopBackgroundMonitoring();
    this.outputChannel.dispose();
    this.statusBarItem.dispose();
  }
}
