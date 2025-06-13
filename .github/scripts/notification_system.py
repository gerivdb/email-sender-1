#!/usr/bin/env python3
"""
Jules Bot Notification System
Handles notifications for review requests, approvals, and alerts
"""

import os
import json
import requests
import smtplib
import yaml
from email.mime.text import MimeText
from email.mime.multipart import MimeMultipart
from typing import Dict, List, Any, Optional
import argparse

class NotificationSystem:
    def __init__(self, config_path: str = '.github/jules-config.yml'):
        """Initialize notification system with configuration"""
        self.config = self._load_config(config_path)
        
    def _load_config(self, config_path: str) -> Dict[str, Any]:
        """Load configuration from YAML file"""
        try:
            with open(config_path, 'r', encoding='utf-8') as f:
                return yaml.safe_load(f)
        except Exception as e:
            print(f"Warning: Could not load config {config_path}: {e}")
            return {}

    def send_slack_notification(self, message: str, channel: Optional[str] = None, webhook_url: Optional[str] = None) -> bool:
        """Send notification to Slack"""
        webhook_url = webhook_url or os.environ.get('SLACK_WEBHOOK_URL') or self.config.get('notifications', {}).get('slack_webhook')
        
        if not webhook_url:
            print("No Slack webhook URL configured")
            return False
            
        payload = {
            'text': message,
            'username': 'Jules Bot',
            'icon_emoji': ':robot_face:'
        }
        
        if channel:
            payload['channel'] = channel
            
        try:
            response = requests.post(webhook_url, json=payload, timeout=10)
            response.raise_for_status()
            print("Slack notification sent successfully")
            return True        except Exception as e:
            print(f"Failed to send Slack notification: {e}")
            return False

    def send_email_notification(self, to_emails: List[str], subject: str, body: str, html_body: Optional[str] = None) -> bool:
        """Send email notification"""
        notifications_config = self.config.get('notifications', {})
        
        if not notifications_config.get('email_enabled', False):
            print("Email notifications are disabled")
            return False
            
        smtp_server = os.environ.get('SMTP_SERVER') or notifications_config.get('smtp_server')
        smtp_port = int(os.environ.get('SMTP_PORT', '587'))
        smtp_user = os.environ.get('SMTP_USER') or notifications_config.get('smtp_user')
        smtp_password = os.environ.get('SMTP_PASSWORD') or notifications_config.get('smtp_password')
        
        if not all([smtp_server, smtp_user, smtp_password]):
            print("Email configuration incomplete")
            return False
            
        try:
            msg = MimeMultipart('alternative')
            msg['Subject'] = subject
            msg['From'] = smtp_user
            msg['To'] = ', '.join(to_emails)
            
            # Add text part
            text_part = MimeText(body, 'plain')
            msg.attach(text_part)
            
            # Add HTML part if provided
            if html_body:
                html_part = MimeText(html_body, 'html')
                msg.attach(html_part)
            
            # Send email - ensure smtp_user and smtp_password are strings
            assert smtp_user is not None and smtp_password is not None
            with smtplib.SMTP(smtp_server, smtp_port) as server:
                server.starttls()
                server.login(smtp_user, smtp_password)
                server.send_message(msg)
                
            print(f"Email notification sent to {', '.join(to_emails)}")
            return True
            
        except Exception as e:
            print(f"Failed to send email notification: {e}")
            return False

    def format_quality_report(self, quality_results: Dict[str, Any], pr_info: Dict[str, Any]) -> str:
        """Format quality assessment results for notifications"""
        score = quality_results.get('overall_score', 0)
        review_type = quality_results.get('review_type', 'unknown')
        issues = quality_results.get('issues', [])
        component_scores = quality_results.get('component_scores', {})
        
        # Determine emoji based on score
        emoji = "🟢" if score >= 80 else "🟡" if score >= 60 else "🔴"
        
        message = f"""
{emoji} *Jules Bot Quality Assessment*

*Repository:* {pr_info.get('repository', 'Unknown')}
*Pull Request:* #{pr_info.get('number', 'N/A')} - {pr_info.get('title', 'Unknown')}
*Branch:* {pr_info.get('head_ref', 'Unknown')}
*Author:* {pr_info.get('author', 'Unknown')}

*Overall Score:* {score}/100
*Review Type:* {review_type.replace('_', ' ').title()}

*Component Scores:*
• File Count: {component_scores.get('file_count', 0):.0f}/100
• File Size: {component_scores.get('file_size', 0):.0f}/100
• Security: {component_scores.get('security', 0):.0f}/100
• Commit Quality: {component_scores.get('commit_quality', 0):.0f}/100
• Configuration: {component_scores.get('configuration', 0):.0f}/100
• Documentation: {component_scores.get('documentation', 0):.0f}/100
"""

        if issues:
            message += f"\n*Issues Found ({len(issues)}):*\n"
            for issue in issues[:5]:  # Limit to first 5 issues
                severity_emoji = "🚨" if issue['severity'] == 'high' else "⚠️" if issue['severity'] == 'medium' else "ℹ️"
                message += f"• {severity_emoji} {issue['type'].title()}: {issue['message']}\n"
            
            if len(issues) > 5:
                message += f"• ... and {len(issues) - 5} more issues\n"
        
        message += f"\n*Review Required:* {review_type.replace('_', ' ').title()}"
        
        return message

    def format_html_quality_report(self, quality_results: Dict[str, Any], pr_info: Dict[str, Any]) -> str:
        """Format quality assessment results as HTML for email"""
        score = quality_results.get('overall_score', 0)
        review_type = quality_results.get('review_type', 'unknown')
        issues = quality_results.get('issues', [])
        component_scores = quality_results.get('component_scores', {})
        
        # Color based on score
        color = "#28a745" if score >= 80 else "#ffc107" if score >= 60 else "#dc3545"
        
        html = f"""
<!DOCTYPE html>
<html>
<head>
    <style>
        body {{ font-family: Arial, sans-serif; margin: 20px; }}
        .header {{ background-color: {color}; color: white; padding: 15px; border-radius: 5px; }}
        .content {{ margin: 20px 0; }}
        .score {{ font-size: 24px; font-weight: bold; }}
        .component {{ margin: 10px 0; }}
        .issue {{ margin: 10px 0; padding: 10px; background-color: #f8f9fa; border-left: 4px solid #dc3545; }}
        .issue.medium {{ border-color: #ffc107; }}
        .issue.low {{ border-color: #28a745; }}
        .metrics {{ display: grid; grid-template-columns: repeat(2, 1fr); gap: 10px; }}
        .metric {{ padding: 10px; background-color: #e9ecef; border-radius: 3px; }}
    </style>
</head>
<body>
    <div class="header">
        <h2>🤖 Jules Bot Quality Assessment</h2>
        <div class="score">Score: {score}/100</div>
    </div>
    
    <div class="content">
        <h3>Pull Request Information</h3>
        <p><strong>Repository:</strong> {pr_info.get('repository', 'Unknown')}</p>
        <p><strong>Pull Request:</strong> #{pr_info.get('number', 'N/A')} - {pr_info.get('title', 'Unknown')}</p>
        <p><strong>Branch:</strong> {pr_info.get('head_ref', 'Unknown')}</p>
        <p><strong>Author:</strong> {pr_info.get('author', 'Unknown')}</p>
        <p><strong>Review Type:</strong> {review_type.replace('_', ' ').title()}</p>
        
        <h3>Component Scores</h3>
        <div class="metrics">
"""
        
        for component, score_val in component_scores.items():
            html += f"""
            <div class="metric">
                <strong>{component.replace('_', ' ').title()}:</strong> {score_val:.0f}/100
            </div>
"""
        
        html += """
        </div>
        
        <h3>Issues</h3>
"""
        
        if issues:
            for issue in issues:
                html += f"""
        <div class="issue {issue['severity']}">
            <strong>{issue['type'].title()} ({issue['severity'].title()}):</strong> {issue['message']}
        </div>
"""
        else:
            html += "<p>No issues found.</p>"
        
        html += """
    </div>
</body>
</html>
"""
        
        return html

    def get_reviewers_for_pr(self, pr_info: Dict[str, Any], quality_results: Dict[str, Any]) -> List[str]:
        """Get list of reviewers for the PR based on files changed and quality score"""
        changed_files = quality_results.get('metrics', {}).get('changed_files', [])
        review_type = quality_results.get('review_type', 'standard')
        
        reviewer_config = self.config.get('reviewer_assignment', {})
        
        # Get domain-specific reviewers
        domain_reviewers = set()
        domains = reviewer_config.get('domains', {})
        
        for domain, domain_config in domains.items():
            patterns = domain_config.get('patterns', [])
            reviewers = domain_config.get('reviewers', [])
            
            # Check if any changed files match this domain
            if any(self._matches_pattern(file_path, pattern) for file_path in changed_files for pattern in patterns):
                domain_reviewers.update(reviewers)
        
        # Get quality-based reviewers
        quality_reviewers = set()
        quality_assignment = reviewer_config.get('quality_based', {})
        
        if review_type in quality_assignment:
            primary = quality_assignment[review_type].get('primary', [])
            secondary = quality_assignment[review_type].get('secondary', [])
            quality_reviewers.update(primary)
            if len(domain_reviewers) == 0:  # Only add secondary if no domain experts
                quality_reviewers.update(secondary[:1])  # Add one secondary reviewer
        
        # Combine and clean up
        all_reviewers = list(domain_reviewers.union(quality_reviewers))
        
        # Replace placeholder reviewers with domain-specific ones
        final_reviewers = []
        for reviewer in all_reviewers:
            if reviewer == '@domain-expert' and domain_reviewers:
                final_reviewers.extend(list(domain_reviewers)[:1])  # Add first domain expert
            elif not reviewer.startswith('@domain-expert'):
                final_reviewers.append(reviewer)
        
        return list(set(final_reviewers))  # Remove duplicates

    def _matches_pattern(self, file_path: str, pattern: str) -> bool:
        """Check if file path matches a glob-like pattern"""
        import fnmatch
        return fnmatch.fnmatch(file_path, pattern)

    def notify_review_request(self, pr_info: Dict[str, Any], quality_results: Dict[str, Any]) -> bool:
        """Send notifications for review requests"""
        triggers = self.config.get('notifications', {}).get('triggers', {})
        score = quality_results.get('overall_score', 0)
        issues = quality_results.get('issues', [])
        
        # Check if we should send notifications
        should_notify = False
        
        if score < triggers.get('quality_score_low', 40):
            should_notify = True
        
        if any(issue['type'] == 'security' for issue in issues) and triggers.get('security_flag', True):
            should_notify = True
        
        if any(issue['type'] == 'configuration' for issue in issues) and triggers.get('config_changes', True):
            should_notify = True
        
        file_count = quality_results.get('metrics', {}).get('file_count', 0)
        if file_count > triggers.get('large_changes', 20):
            should_notify = True
        
        if not should_notify:
            print("No notification triggers met")
            return True
        
        # Format messages
        slack_message = self.format_quality_report(quality_results, pr_info)
        html_message = self.format_html_quality_report(quality_results, pr_info)
        
        # Get reviewers
        reviewers = self.get_reviewers_for_pr(pr_info, quality_results)
        
        # Send notifications
        success = True
        
        # Slack notification
        slack_channel = None
        if any(issue['severity'] == 'high' for issue in issues):
            slack_channel = '#security-alerts'
        
        if not self.send_slack_notification(slack_message, slack_channel):
            success = False
        
        # Email notification (extract email addresses from reviewer list if needed)
        reviewer_emails = [r.replace('@', '') + '@company.com' for r in reviewers if r.startswith('@')]
        if reviewer_emails:
            subject = f"Jules Bot Review Required: {pr_info.get('title', 'Unknown PR')}"
            if not self.send_email_notification(reviewer_emails, subject, slack_message, html_message):
                success = False
        
        return success

def main():
    parser = argparse.ArgumentParser(description='Jules Bot Notification System')
    parser.add_argument('--config', default='.github/jules-config.yml', help='Configuration file path')
    parser.add_argument('--action', required=True, choices=['review-request', 'approval', 'rejection', 'timeout'], help='Notification type')
    parser.add_argument('--quality-results', help='Quality assessment results JSON file')
    parser.add_argument('--pr-info', help='Pull request information JSON file')
    parser.add_argument('--message', help='Custom message to send')
    parser.add_argument('--channel', help='Slack channel override')
    args = parser.parse_args()
    
    notifier = NotificationSystem(args.config)
    
    if args.action == 'review-request':
        if not args.quality_results or not args.pr_info:
            print("Quality results and PR info required for review-request")
            return 1
            
        try:
            with open(args.quality_results, 'r') as f:
                quality_results = json.load(f)
            with open(args.pr_info, 'r') as f:
                pr_info = json.load(f)
                
            success = notifier.notify_review_request(pr_info, quality_results)
            return 0 if success else 1
            
        except Exception as e:
            print(f"Error processing review request notification: {e}")
            return 1
    
    elif args.message:
        success = notifier.send_slack_notification(args.message, args.channel)
        return 0 if success else 1
    
    else:
        print("No action taken")
        return 0

if __name__ == '__main__':
    import sys
    sys.exit(main())
