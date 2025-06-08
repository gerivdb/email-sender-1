#!/usr/bin/env python3
"""
Jules Bot Metrics and Monitoring System
Tracks performance, quality trends, and system health
"""

import os
import json
import sqlite3
import yaml
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional, Tuple
import argparse
import subprocess

class MetricsCollector:
    def __init__(self, config_path: str = '.github/jules-config.yml', db_path: str = '.github/jules-metrics.db'):
        """Initialize metrics collector"""
        self.config = self._load_config(config_path)
        self.db_path = db_path
        self._init_database()
        
    def _load_config(self, config_path: str) -> Dict[str, Any]:
        """Load configuration from YAML file"""
        try:
            with open(config_path, 'r', encoding='utf-8') as f:
                return yaml.safe_load(f)
        except Exception as e:
            print(f"Warning: Could not load config {config_path}: {e}")
            return {}

    def _init_database(self) -> None:
        """Initialize SQLite database for metrics storage"""
        with sqlite3.connect(self.db_path) as conn:
            conn.executescript('''
                CREATE TABLE IF NOT EXISTS quality_assessments (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp TEXT NOT NULL,
                    branch_name TEXT NOT NULL,
                    overall_score INTEGER NOT NULL,
                    review_type TEXT NOT NULL,
                    file_count INTEGER,
                    security_score REAL,
                    commit_quality_score REAL,
                    configuration_score REAL,
                    documentation_score REAL,
                    issues_count INTEGER,
                    assessment_data TEXT
                );
                
                CREATE TABLE IF NOT EXISTS review_events (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp TEXT NOT NULL,
                    branch_name TEXT NOT NULL,
                    event_type TEXT NOT NULL,
                    reviewer TEXT,
                    pr_number INTEGER,
                    time_to_review INTEGER,
                    review_data TEXT
                );
                
                CREATE TABLE IF NOT EXISTS integration_events (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp TEXT NOT NULL,
                    source_branch TEXT NOT NULL,
                    target_branch TEXT NOT NULL,
                    merge_strategy TEXT,
                    success BOOLEAN NOT NULL,
                    integration_time INTEGER,
                    error_message TEXT,
                    integration_data TEXT
                );
                
                CREATE TABLE IF NOT EXISTS system_health (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp TEXT NOT NULL,
                    metric_name TEXT NOT NULL,
                    metric_value REAL NOT NULL,
                    metric_unit TEXT,
                    health_data TEXT
                );
                
                CREATE INDEX IF NOT EXISTS idx_quality_timestamp ON quality_assessments(timestamp);
                CREATE INDEX IF NOT EXISTS idx_review_timestamp ON review_events(timestamp);
                CREATE INDEX IF NOT EXISTS idx_integration_timestamp ON integration_events(timestamp);
                CREATE INDEX IF NOT EXISTS idx_health_timestamp ON system_health(timestamp);
            ''')

    def record_quality_assessment(self, assessment_data: Dict[str, Any]) -> None:
        """Record a quality assessment in the database"""
        timestamp = datetime.now().isoformat()
        
        with sqlite3.connect(self.db_path) as conn:
            conn.execute('''
                INSERT INTO quality_assessments (
                    timestamp, branch_name, overall_score, review_type,
                    file_count, security_score, commit_quality_score,
                    configuration_score, documentation_score, issues_count,
                    assessment_data
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                timestamp,
                assessment_data.get('branch_name', ''),
                assessment_data.get('overall_score', 0),
                assessment_data.get('review_type', ''),
                assessment_data.get('metrics', {}).get('file_count', 0),
                assessment_data.get('component_scores', {}).get('security', 0),
                assessment_data.get('component_scores', {}).get('commit_quality', 0),
                assessment_data.get('component_scores', {}).get('configuration', 0),
                assessment_data.get('component_scores', {}).get('documentation', 0),
                len(assessment_data.get('issues', [])),
                json.dumps(assessment_data)
            ))

    def record_review_event(self, event_data: Dict[str, Any]) -> None:
        """Record a review event in the database"""
        timestamp = datetime.now().isoformat()
        
        with sqlite3.connect(self.db_path) as conn:
            conn.execute('''
                INSERT INTO review_events (
                    timestamp, branch_name, event_type, reviewer,
                    pr_number, time_to_review, review_data
                ) VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', (
                timestamp,
                event_data.get('branch_name', ''),
                event_data.get('event_type', ''),
                event_data.get('reviewer', ''),
                event_data.get('pr_number'),
                event_data.get('time_to_review'),
                json.dumps(event_data)
            ))

    def record_integration_event(self, integration_data: Dict[str, Any]) -> None:
        """Record an integration event in the database"""
        timestamp = datetime.now().isoformat()
        
        with sqlite3.connect(self.db_path) as conn:
            conn.execute('''
                INSERT INTO integration_events (
                    timestamp, source_branch, target_branch, merge_strategy,
                    success, integration_time, error_message, integration_data
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ''', (
                timestamp,
                integration_data.get('source_branch', ''),
                integration_data.get('target_branch', ''),
                integration_data.get('strategy', ''),
                integration_data.get('success', False),
                integration_data.get('integration_time'),
                integration_data.get('error'),
                json.dumps(integration_data)
            ))

    def get_quality_trends(self, days: int = 30) -> Dict[str, Any]:
        """Get quality assessment trends over the specified period"""
        cutoff_date = (datetime.now() - timedelta(days=days)).isoformat()
        
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            
            # Overall score trends
            cursor = conn.execute('''
                SELECT 
                    DATE(timestamp) as date,
                    AVG(overall_score) as avg_score,
                    COUNT(*) as assessment_count,
                    AVG(issues_count) as avg_issues
                FROM quality_assessments 
                WHERE timestamp > ?
                GROUP BY DATE(timestamp)
                ORDER BY date
            ''', (cutoff_date,))
            
            daily_trends = [dict(row) for row in cursor.fetchall()]
            
            # Component score trends
            cursor = conn.execute('''
                SELECT 
                    AVG(security_score) as avg_security,
                    AVG(commit_quality_score) as avg_commit_quality,
                    AVG(configuration_score) as avg_configuration,
                    AVG(documentation_score) as avg_documentation,
                    COUNT(*) as total_assessments
                FROM quality_assessments 
                WHERE timestamp > ?
            ''', (cutoff_date,))
            
            component_averages = dict(cursor.fetchone())
            
            # Review type distribution
            cursor = conn.execute('''
                SELECT 
                    review_type,
                    COUNT(*) as count,
                    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM quality_assessments WHERE timestamp > ?), 2) as percentage
                FROM quality_assessments 
                WHERE timestamp > ?
                GROUP BY review_type
            ''', (cutoff_date, cutoff_date))
            
            review_distribution = [dict(row) for row in cursor.fetchall()]
        
        return {
            'period_days': days,
            'daily_trends': daily_trends,
            'component_averages': component_averages,
            'review_distribution': review_distribution
        }

    def get_review_performance(self, days: int = 30) -> Dict[str, Any]:
        """Get review performance metrics"""
        cutoff_date = (datetime.now() - timedelta(days=days)).isoformat()
        
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            
            # Review time metrics
            cursor = conn.execute('''
                SELECT 
                    AVG(time_to_review) as avg_review_time,
                    MIN(time_to_review) as min_review_time,
                    MAX(time_to_review) as max_review_time,
                    COUNT(*) as total_reviews
                FROM review_events 
                WHERE timestamp > ? AND time_to_review IS NOT NULL
            ''', (cutoff_date,))
            
            review_times = dict(cursor.fetchone())
            
            # Reviewer activity
            cursor = conn.execute('''
                SELECT 
                    reviewer,
                    COUNT(*) as review_count,
                    AVG(time_to_review) as avg_time
                FROM review_events 
                WHERE timestamp > ? AND reviewer IS NOT NULL
                GROUP BY reviewer
                ORDER BY review_count DESC
            ''', (cutoff_date,))
            
            reviewer_activity = [dict(row) for row in cursor.fetchall()]
            
            # Event type distribution
            cursor = conn.execute('''
                SELECT 
                    event_type,
                    COUNT(*) as count
                FROM review_events 
                WHERE timestamp > ?
                GROUP BY event_type
            ''', (cutoff_date,))
            
            event_distribution = [dict(row) for row in cursor.fetchall()]
        
        return {
            'period_days': days,
            'review_times': review_times,
            'reviewer_activity': reviewer_activity,
            'event_distribution': event_distribution
        }

    def get_integration_metrics(self, days: int = 30) -> Dict[str, Any]:
        """Get integration performance metrics"""
        cutoff_date = (datetime.now() - timedelta(days=days)).isoformat()
        
        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            
            # Success rate
            cursor = conn.execute('''
                SELECT 
                    COUNT(*) as total_integrations,
                    SUM(CASE WHEN success THEN 1 ELSE 0 END) as successful_integrations,
                    ROUND(SUM(CASE WHEN success THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as success_rate
                FROM integration_events 
                WHERE timestamp > ?
            ''', (cutoff_date,))
            
            success_metrics = dict(cursor.fetchone())
            
            # Integration times
            cursor = conn.execute('''
                SELECT 
                    AVG(integration_time) as avg_integration_time,
                    MIN(integration_time) as min_integration_time,
                    MAX(integration_time) as max_integration_time
                FROM integration_events 
                WHERE timestamp > ? AND success = 1 AND integration_time IS NOT NULL
            ''', (cutoff_date,))
            
            time_metrics = dict(cursor.fetchone())
            
            # Strategy usage
            cursor = conn.execute('''
                SELECT 
                    merge_strategy,
                    COUNT(*) as usage_count,
                    SUM(CASE WHEN success THEN 1 ELSE 0 END) as success_count
                FROM integration_events 
                WHERE timestamp > ?
                GROUP BY merge_strategy
            ''', (cutoff_date,))
            
            strategy_metrics = [dict(row) for row in cursor.fetchall()]
            
            # Error analysis
            cursor = conn.execute('''
                SELECT 
                    error_message,
                    COUNT(*) as error_count
                FROM integration_events 
                WHERE timestamp > ? AND success = 0 AND error_message IS NOT NULL
                GROUP BY error_message
                ORDER BY error_count DESC
                LIMIT 10
            ''', (cutoff_date,))
            
            error_analysis = [dict(row) for row in cursor.fetchall()]
        
        return {
            'period_days': days,
            'success_metrics': success_metrics,
            'time_metrics': time_metrics,
            'strategy_metrics': strategy_metrics,
            'error_analysis': error_analysis
        }

    def get_system_health(self) -> Dict[str, Any]:
        """Get current system health metrics"""
        health_data = {}
        
        try:
            # Git repository health
            result = subprocess.run(['git', 'status', '--porcelain'], capture_output=True, text=True)
            health_data['git_clean'] = len(result.stdout.strip()) == 0
            
            # Disk space check
            if os.name != 'nt':  # Unix-like systems
                result = subprocess.run(['df', '-h', '.'], capture_output=True, text=True)
                lines = result.stdout.strip().split('\n')
                if len(lines) >= 2:
                    fields = lines[1].split()
                    if len(fields) >= 5:
                        health_data['disk_usage'] = fields[4].rstrip('%')
            
            # Check recent error rates
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.execute('''
                    SELECT 
                        COUNT(*) as total_recent,
                        SUM(CASE WHEN success = 0 THEN 1 ELSE 0 END) as recent_failures
                    FROM integration_events 
                    WHERE timestamp > datetime('now', '-24 hours')
                ''')
                
                row = cursor.fetchone()
                if row[0] > 0:
                    health_data['recent_failure_rate'] = (row[1] / row[0]) * 100
                else:
                    health_data['recent_failure_rate'] = 0
            
            # Check average quality scores
            with sqlite3.connect(self.db_path) as conn:
                cursor = conn.execute('''
                    SELECT AVG(overall_score) as avg_score
                    FROM quality_assessments 
                    WHERE timestamp > datetime('now', '-7 days')
                ''')
                
                row = cursor.fetchone()
                health_data['recent_avg_quality'] = row[0] if row[0] else 0
            
        except Exception as e:
            health_data['health_check_error'] = str(e)
        
        return health_data

    def generate_dashboard_data(self, days: int = 30) -> Dict[str, Any]:
        """Generate comprehensive dashboard data"""
        return {
            'timestamp': datetime.now().isoformat(),
            'period_days': days,
            'quality_trends': self.get_quality_trends(days),
            'review_performance': self.get_review_performance(days),
            'integration_metrics': self.get_integration_metrics(days),
            'system_health': self.get_system_health()
        }

    def export_metrics(self, output_file: str, format: str = 'json', days: int = 30) -> None:
        """Export metrics to file"""
        data = self.generate_dashboard_data(days)
        
        if format.lower() == 'json':
            with open(output_file, 'w') as f:
                json.dump(data, f, indent=2)
        elif format.lower() == 'csv':
            # Export key metrics as CSV
            import csv
            with open(output_file, 'w', newline='') as f:
                writer = csv.writer(f)
                
                # Quality trends
                writer.writerow(['Date', 'Avg Score', 'Assessment Count', 'Avg Issues'])
                for trend in data['quality_trends']['daily_trends']:
                    writer.writerow([trend['date'], trend['avg_score'], trend['assessment_count'], trend['avg_issues']])
        else:
            raise ValueError(f"Unsupported format: {format}")

def main():
    parser = argparse.ArgumentParser(description='Jules Bot Metrics and Monitoring')
    parser.add_argument('--config', default='.github/jules-config.yml', help='Configuration file path')
    parser.add_argument('--db', default='.github/jules-metrics.db', help='Metrics database path')
    parser.add_argument('--action', required=True, choices=['record-quality', 'record-review', 'record-integration', 'export', 'dashboard'], help='Action to perform')
    parser.add_argument('--data', help='JSON data for recording (required for record-* actions)')
    parser.add_argument('--output', help='Output file for export/dashboard')
    parser.add_argument('--format', choices=['json', 'csv'], default='json', help='Export format')
    parser.add_argument('--days', type=int, default=30, help='Number of days for metrics')
    args = parser.parse_args()
    
    collector = MetricsCollector(args.config, args.db)
    
    if args.action.startswith('record-'):
        if not args.data:
            print("--data is required for record actions")
            return 1
        
        try:
            data = json.loads(args.data)
        except json.JSONDecodeError as e:
            print(f"Invalid JSON data: {e}")
            return 1
        
        if args.action == 'record-quality':
            collector.record_quality_assessment(data)
            print("Quality assessment recorded")
        elif args.action == 'record-review':
            collector.record_review_event(data)
            print("Review event recorded")
        elif args.action == 'record-integration':
            collector.record_integration_event(data)
            print("Integration event recorded")
    
    elif args.action == 'export':
        if not args.output:
            print("--output is required for export")
            return 1
        
        collector.export_metrics(args.output, args.format, args.days)
        print(f"Metrics exported to {args.output}")
    
    elif args.action == 'dashboard':
        dashboard_data = collector.generate_dashboard_data(args.days)
        
        if args.output:
            with open(args.output, 'w') as f:
                json.dump(dashboard_data, f, indent=2)
            print(f"Dashboard data saved to {args.output}")
        else:
            print(json.dumps(dashboard_data, indent=2))
    
    return 0

if __name__ == '__main__':
    import sys
    sys.exit(main())
