#!/usr/bin/env python3
"""
Jules Bot Monitoring Dashboard
Real-time monitoring and performance analytics for the Jules Bot Review System
"""

import json
import sqlite3
import time
from datetime import datetime, timedelta
from pathlib import Path
import os
import sys

class JulesBotMonitor:
    def __init__(self, db_path=None):
        """Initialize the monitoring dashboard."""
        if db_path is None:
            self.db_path = Path(__file__).parent / "jules_metrics.db"
        else:
            self.db_path = Path(db_path)
        
        self.init_database()
        self.seed_sample_data()
    
    def init_database(self):
        """Initialize the metrics database."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Create tables for metrics storage
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS system_health (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp TEXT,
                component TEXT,
                status TEXT,
                response_time REAL,
                details TEXT
            )
        """)
        
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS performance_metrics (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp TEXT,
                metric_name TEXT,
                value REAL,
                unit TEXT,
                tags TEXT
            )
        """)
        
        cursor.execute("""
            CREATE TABLE IF NOT EXISTS quality_assessments (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp TEXT,
                pr_number INTEGER,
                quality_score REAL,
                review_type TEXT,
                files_count INTEGER,
                issues_count INTEGER,
                approval_status TEXT
            )
        """)
        
        conn.commit()
        conn.close()
    
    def seed_sample_data(self):
        """Seed database with sample data for demonstration."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        # Check if data already exists
        cursor.execute("SELECT COUNT(*) FROM system_health")
        if cursor.fetchone()[0] > 0:
            conn.close()
            return
        
        # Sample system health data
        now = datetime.now()
        components = [
            ("Quality Assessment", "healthy", 187.5),
            ("Notification System", "healthy", 102.3),
            ("Integration Manager", "healthy", 252.1),
            ("Metrics Collection", "healthy", 101.7),
            ("GitHub Workflows", "healthy", 119.4)
        ]
        
        for component, status, response_time in components:
            cursor.execute("""
                INSERT INTO system_health (timestamp, component, status, response_time, details)
                VALUES (?, ?, ?, ?, ?)
            """, (now.isoformat(), component, status, response_time, f"{component} operating normally"))
        
        # Sample performance metrics
        for i in range(24):  # 24 hours of sample data
            timestamp = (now - timedelta(hours=i)).isoformat()
            
            # Review cycle time (hours)
            cycle_time = 12.5 + (i * 0.1)  # Varying from 12.5 to 14.8 hours
            cursor.execute("""
                INSERT INTO performance_metrics (timestamp, metric_name, value, unit, tags)
                VALUES (?, ?, ?, ?, ?)
            """, (timestamp, "review_cycle_time", cycle_time, "hours", '{}'))
            
            # Auto-approval rate (percentage)
            approval_rate = 65 + (i % 10)  # Varying from 65% to 75%
            cursor.execute("""
                INSERT INTO performance_metrics (timestamp, metric_name, value, unit, tags)
                VALUES (?, ?, ?, ?, ?)
            """, (timestamp, "auto_approval_rate", approval_rate, "percent", '{}'))
            
            # Quality score
            quality_score = 75 + (i % 20)  # Varying quality scores
            cursor.execute("""
                INSERT INTO performance_metrics (timestamp, metric_name, value, unit, tags)
                VALUES (?, ?, ?, ?, ?)
            """, (timestamp, "quality_score", quality_score, "score", '{}'))
        
        # Sample quality assessments
        for i in range(10):
            timestamp = (now - timedelta(hours=i*2)).isoformat()
            quality_score = 70 + (i * 3)  # Scores from 70 to 97
            review_type = "enhanced" if quality_score >= 85 else "standard" if quality_score >= 70 else "thorough"
            
            cursor.execute("""
                INSERT INTO quality_assessments (timestamp, pr_number, quality_score, review_type, files_count, issues_count, approval_status)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            """, (timestamp, 1000+i, quality_score, review_type, 3+i, max(0, 5-i), "approved" if quality_score >= 75 else "pending"))
        
        conn.commit()
        conn.close()
    
    def get_system_health_summary(self, hours=24):
        """Get system health summary for the last N hours."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        since = (datetime.now() - timedelta(hours=hours)).isoformat()
        
        cursor.execute("""
            SELECT component, status, response_time, MAX(timestamp) as latest
            FROM system_health 
            WHERE timestamp > ?
            GROUP BY component
            ORDER BY component
        """, (since,))
        
        results = cursor.fetchall()
        conn.close()
        
        return [{
            "component": row[0],
            "status": row[1],
            "response_time": row[2],
            "latest_check": row[3]
        } for row in results]
    
    def get_performance_trends(self, metric_name, hours=24):
        """Get performance trends for a specific metric."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        since = (datetime.now() - timedelta(hours=hours)).isoformat()
        
        cursor.execute("""
            SELECT timestamp, value, unit, tags
            FROM performance_metrics 
            WHERE metric_name = ? AND timestamp > ?
            ORDER BY timestamp
        """, (metric_name, since))
        
        results = cursor.fetchall()
        conn.close()
        
        return [{
            "timestamp": row[0],
            "value": row[1],
            "unit": row[2],
            "tags": json.loads(row[3])
        } for row in results]
    
    def get_quality_score_distribution(self, days=7):
        """Get distribution of quality scores over time."""
        trends = self.get_performance_trends("quality_score", hours=days*24)
        
        if not trends:
            return {"high": 0, "standard": 0, "low": 0}
        
        distribution = {"high": 0, "standard": 0, "low": 0}
        
        for trend in trends:
            score = trend["value"]
            if score >= 80:
                distribution["high"] += 1
            elif score >= 60:
                distribution["standard"] += 1
            else:
                distribution["low"] += 1
        
        return distribution
    
    def generate_dashboard_report(self, hours=24):
        """Generate a comprehensive dashboard report."""
        print("Jules Bot Review System - Performance Dashboard")
        print("=" * 60)
        print(f"Report Period: Last {hours} hours")
        print(f"Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print()
        
        # System Health Overview
        health_summary = self.get_system_health_summary(hours)
        print("SYSTEM HEALTH OVERVIEW")
        print("-" * 30)
        
        if not health_summary:
            print("No health data available")
        else:
            overall_status = "HEALTHY" if all(h["status"] == "healthy" for h in health_summary) else "DEGRADED"
            print(f"Overall Status: {overall_status}")
            print()
            
            for health in health_summary:
                status_icon = "✓" if health["status"] == "healthy" else "✗"
                print(f"{status_icon} {health['component']:<25} {health['status']:<10} ({health['response_time']:.1f}ms)")
        
        print()
        
        # Performance Metrics
        print("PERFORMANCE METRICS")
        print("-" * 30)
        
        # Review cycle time
        cycle_trends = self.get_performance_trends("review_cycle_time", hours)
        if cycle_trends:
            avg_cycle_time = sum(t["value"] for t in cycle_trends) / len(cycle_trends)
            print(f"Average Review Cycle Time: {avg_cycle_time:.1f} hours")
        else:
            print("Average Review Cycle Time: No data")
        
        # Auto-approval rate
        approval_trends = self.get_performance_trends("auto_approval_rate", hours)
        if approval_trends:
            avg_approval_rate = sum(t["value"] for t in approval_trends) / len(approval_trends)
            print(f"Auto-Approval Rate: {avg_approval_rate:.1f}%")
        else:
            print("Auto-Approval Rate: No data")
        
        print()
        
        # Quality Score Distribution
        print("QUALITY SCORE DISTRIBUTION")
        print("-" * 30)
        
        distribution = self.get_quality_score_distribution(days=7)
        total_scores = sum(distribution.values())
        
        if total_scores > 0:
            for category, count in distribution.items():
                percentage = (count / total_scores) * 100
                print(f"{category.title():<10} ({count:>2}): {percentage:>5.1f}%")
        else:
            print("No quality score data available")
        
        print()
        
        # Recent Quality Assessments
        print("RECENT QUALITY ASSESSMENTS")
        print("-" * 30)
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        since = (datetime.now() - timedelta(hours=hours)).isoformat()
        cursor.execute("""
            SELECT timestamp, pr_number, quality_score, review_type, files_count, issues_count, approval_status
            FROM quality_assessments 
            WHERE timestamp > ?
            ORDER BY timestamp DESC
            LIMIT 5
        """, (since,))
        
        assessments = cursor.fetchall()
        conn.close()
        
        if assessments:
            print("PR#    Score  Type       Files  Issues  Status")
            print("-" * 45)
            for assessment in assessments:
                pr_num = assessment[1]
                score = assessment[2]
                review_type = assessment[3]
                files = assessment[4]
                issues = assessment[5]
                status = assessment[6]
                print(f"{pr_num:<6} {score:<6.0f} {review_type:<10} {files:<6} {issues:<7} {status}")
        else:
            print("No recent assessments available")
        
        print()
        print("=" * 60)
    
    def log_system_health(self, component, status, response_time, details=""):
        """Log system health check result."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute("""
            INSERT INTO system_health (timestamp, component, status, response_time, details)
            VALUES (?, ?, ?, ?, ?)
        """, (datetime.now().isoformat(), component, status, response_time, details))
        
        conn.commit()
        conn.close()
    
    def log_performance_metric(self, metric_name, value, unit, tags=None):
        """Log a performance metric."""
        if tags is None:
            tags = {}
        
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute("""
            INSERT INTO performance_metrics (timestamp, metric_name, value, unit, tags)
            VALUES (?, ?, ?, ?, ?)
        """, (datetime.now().isoformat(), metric_name, value, unit, json.dumps(tags)))
        
        conn.commit()
        conn.close()
    
    def log_quality_assessment(self, pr_number, quality_score, review_type, files_count, issues_count, approval_status):
        """Log a quality assessment result."""
        conn = sqlite3.connect(self.db_path)
        cursor = conn.cursor()
        
        cursor.execute("""
            INSERT INTO quality_assessments (timestamp, pr_number, quality_score, review_type, files_count, issues_count, approval_status)
            VALUES (?, ?, ?, ?, ?, ?, ?)
        """, (datetime.now().isoformat(), pr_number, quality_score, review_type, files_count, issues_count, approval_status))
        
        conn.commit()
        conn.close()

def main():
    """Main function to run the monitoring dashboard."""
    monitor = JulesBotMonitor()
    
    if len(sys.argv) > 1:
        if sys.argv[1] == "--continuous":
            print("Starting continuous monitoring mode...")
            try:
                while True:
                    os.system('cls' if os.name == 'nt' else 'clear')  # Clear screen
                    monitor.generate_dashboard_report()
                    print("\nPress Ctrl+C to exit...")
                    time.sleep(30)  # Update every 30 seconds
            except KeyboardInterrupt:
                print("\nMonitoring stopped.")
        elif sys.argv[1] == "--health-check":
            # Perform health checks
            start_time = time.time()
            
            # Simulate health checks
            components = [
                "Quality Assessment",
                "Notification System", 
                "Integration Manager",
                "Metrics Collection",
                "GitHub Workflows"
            ]
            
            for component in components:
                response_time = (time.time() - start_time) * 1000  # Convert to ms
                monitor.log_system_health(component, "healthy", response_time, f"{component} health check passed")
                time.sleep(0.1)  # Small delay between checks
            
            print("Health check completed and logged.")
        else:
            print("Usage: python monitoring_dashboard.py [--continuous|--health-check]")
    else:
        # Generate single report
        monitor.generate_dashboard_report()

if __name__ == "__main__":
    main()
