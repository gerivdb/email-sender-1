#!/usr/bin/env python3
"""
Jules Bot Integration Test
End-to-end test of the complete Jules Bot review and approval workflow
"""

import os
import sys
import json
import yaml
import tempfile
import shutil
import subprocess
from pathlib import Path
from typing import Dict, Any, List
import time

class JulesIntegrationTest:
    def __init__(self):
        """Initialize integration test"""
        self.script_dir = Path(__file__).parent
        self.project_root = self.script_dir.parent.parent
        self.config_path = self.project_root / '.github' / 'jules-config.yml'
        self.test_repo = None
        
    def setup_test_environment(self) -> str:
        """Create a test repository with all necessary files"""
        print("🔧 Setting up test environment...")
        
        # Create temporary directory
        test_dir = tempfile.mkdtemp(prefix='jules_integration_test_')
        self.test_repo = test_dir
        
        # Initialize git repository
        subprocess.run(['git', 'init'], cwd=test_dir, capture_output=True)
        subprocess.run(['git', 'config', 'user.email', 'test@example.com'], cwd=test_dir)
        subprocess.run(['git', 'config', 'user.name', 'Test User'], cwd=test_dir)
        
        # Copy scripts and config to test repo
        scripts_dir = Path(test_dir) / '.github' / 'scripts'
        scripts_dir.mkdir(parents=True, exist_ok=True)
        
        # Copy all Python scripts
        source_scripts = self.script_dir
        for script_file in source_scripts.glob('*.py'):
            if script_file.name != 'test_integration.py':  # Don't copy self
                shutil.copy2(script_file, scripts_dir)
        
        # Copy configuration
        config_dir = Path(test_dir) / '.github'
        shutil.copy2(self.config_path, config_dir)
        
        # Create initial project structure
        (Path(test_dir) / 'src').mkdir(exist_ok=True)
        (Path(test_dir) / 'docs').mkdir(exist_ok=True)
        (Path(test_dir) / 'tests').mkdir(exist_ok=True)
        
        # Create initial files
        with open(Path(test_dir) / 'README.md', 'w') as f:
            f.write('# Test Project\n\nThis is a test project for Jules Bot integration testing.\n')
        
        with open(Path(test_dir) / 'src' / 'main.py', 'w') as f:
            f.write('def main():\n    print("Hello, World!")\n\nif __name__ == "__main__":\n    main()\n')
        
        # Initial commit
        subprocess.run(['git', 'add', '.'], cwd=test_dir)
        subprocess.run(['git', 'commit', '-m', 'Initial commit'], cwd=test_dir)
        
        # Create dev branch
        subprocess.run(['git', 'checkout', '-b', 'dev'], cwd=test_dir)
        subprocess.run(['git', 'checkout', 'main'], cwd=test_dir)
        
        print(f"✅ Test environment created at: {test_dir}")
        return test_dir
    
    def create_jules_contribution(self, scenario: str) -> str:
        """Create a Jules Bot contribution branch with specified scenario"""
        print(f"📝 Creating Jules Bot contribution: {scenario}")
        
        # Checkout dev branch
        subprocess.run(['git', 'checkout', 'dev'], cwd=self.test_repo)
        
        # Create jules-google branch
        branch_name = f'jules-google/{scenario}'
        subprocess.run(['git', 'checkout', '-b', branch_name], cwd=self.test_repo)
        
        if scenario == 'high-quality':
            # High quality contribution
            changes = [
                {
                    'file': 'src/utils.py',
                    'content': '''"""Utility functions for the application."""

def calculate_sum(numbers: list[int]) -> int:
    """Calculate the sum of a list of numbers.
    
    Args:
        numbers: List of integers to sum
        
    Returns:
        The sum of all numbers in the list
        
    Example:
        >>> calculate_sum([1, 2, 3])
        6
    """
    return sum(numbers)

def validate_email(email: str) -> bool:
    """Validate email address format.
    
    Args:
        email: Email address to validate
        
    Returns:
        True if email format is valid, False otherwise
    """
    import re
    pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$'
    return bool(re.match(pattern, email))
''',
                    'commit_msg': 'feat: add utility functions with proper documentation and type hints'
                },
                {
                    'file': 'tests/test_utils.py',
                    'content': '''"""Tests for utility functions."""

import pytest
from src.utils import calculate_sum, validate_email

def test_calculate_sum():
    """Test the calculate_sum function."""
    assert calculate_sum([1, 2, 3]) == 6
    assert calculate_sum([]) == 0
    assert calculate_sum([-1, 1]) == 0

def test_validate_email():
    """Test the validate_email function."""
    assert validate_email('test@example.com') is True
    assert validate_email('invalid.email') is False
    assert validate_email('test@') is False
''',
                    'commit_msg': 'test: add comprehensive tests for utility functions'
                },
                {
                    'file': 'docs/utils.md',
                    'content': '''# Utility Functions

## Overview

This module provides utility functions for common operations.

## Functions

### `calculate_sum(numbers: list[int]) -> int`

Calculates the sum of a list of numbers.

**Parameters:**
- `numbers`: List of integers to sum

**Returns:**
- Integer sum of all numbers

### `validate_email(email: str) -> bool`

Validates email address format using regex.

**Parameters:**
- `email`: Email address string to validate

**Returns:**
- Boolean indicating if email format is valid
''',
                    'commit_msg': 'docs: add documentation for utility functions'
                }
            ]
        
        elif scenario == 'security-risk':
            # Security risk contribution
            changes = [
                {
                    'file': 'config/secrets.py',
                    'content': '''# Configuration with hardcoded secrets
API_KEY = "sk-1234567890abcdef"
DATABASE_PASSWORD = "admin123"
SECRET_TOKEN = "secret_token_here"

# AWS credentials
AWS_ACCESS_KEY = "AKIAIOSFODNN7EXAMPLE"
AWS_SECRET_KEY = "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"
''',
                    'commit_msg': 'add config'
                },
                {
                    'file': 'src/auth.py',
                    'content': '''import os
import subprocess

def authenticate_user(username, password):
    # Dangerous: SQL injection vulnerability
    query = f"SELECT * FROM users WHERE username='{username}' AND password='{password}'"
    
    # Dangerous: Command injection vulnerability
    result = subprocess.run(f"echo {password}", shell=True, capture_output=True)
    
    return True
''',
                    'commit_msg': 'add auth'
                }
            ]
        
        elif scenario == 'large-files':
            # Large files contribution
            changes = [
                {
                    'file': 'data/large_dataset.csv',
                    'content': 'id,data\n' + '\n'.join([f'{i},{"x" * 1000}' for i in range(10000)]),
                    'commit_msg': 'add large dataset'
                },
                {
                    'file': 'assets/video.mp4',
                    'content': 'x' * (5 * 1024 * 1024),  # 5MB file
                    'commit_msg': 'add video file'
                }
            ]
        
        else:
            # Standard quality contribution
            changes = [
                {
                    'file': 'src/helper.py',
                    'content': '''def process_data(data):
    result = []
    for item in data:
        if item > 0:
            result.append(item * 2)
    return result
''',
                    'commit_msg': 'add helper function'
                }
            ]
        
        # Apply changes
        for change in changes:
            file_path = Path(self.test_repo) / change['file']
            file_path.parent.mkdir(parents=True, exist_ok=True)
            
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(change['content'])
            
            subprocess.run(['git', 'add', change['file']], cwd=self.test_repo)
            subprocess.run(['git', 'commit', '-m', change['commit_msg']], cwd=self.test_repo)
        
        print(f"✅ Created {scenario} contribution on branch: {branch_name}")
        return branch_name
    
    def run_quality_assessment(self, branch_name: str) -> Dict[str, Any]:
        """Run quality assessment on the contribution"""
        print(f"🔍 Running quality assessment on {branch_name}...")
        
        scripts_dir = Path(self.test_repo) / '.github' / 'scripts'
        config_file = Path(self.test_repo) / '.github' / 'jules-config.yml'
        output_file = Path(self.test_repo) / 'quality_results.json'
        
        # Switch to the branch
        subprocess.run(['git', 'checkout', branch_name], cwd=self.test_repo)
        
        # Run quality assessment
        cmd = [
            'python', str(scripts_dir / 'quality_assessment.py'),
            '--config', str(config_file),
            '--base-ref', 'dev',
            '--output', str(output_file)
        ]
        
        result = subprocess.run(cmd, cwd=self.test_repo, capture_output=True, text=True)
        
        if result.returncode != 0:
            print(f"❌ Quality assessment failed: {result.stderr}")
            return {'error': result.stderr}
        
        # Read results
        with open(output_file, 'r') as f:
            quality_results = json.load(f)
        
        print(f"✅ Quality assessment completed. Score: {quality_results.get('overall_score', 'N/A')}")
        return quality_results
    
    def test_scenario(self, scenario: str) -> Dict[str, Any]:
        """Test a complete scenario"""
        print(f"\n{'='*60}")
        print(f"Testing Scenario: {scenario.upper()}")
        print(f"{'='*60}")
        
        try:
            # Create contribution
            branch_name = self.create_jules_contribution(scenario)
            
            # Run quality assessment
            quality_results = self.run_quality_assessment(branch_name)
            
            if 'error' in quality_results:
                return {
                    'scenario': scenario,
                    'status': 'FAIL',
                    'error': quality_results['error']
                }
            
            # Analyze results
            score = quality_results.get('overall_score', 0)
            review_type = quality_results.get('review_type', 'unknown')
            issues = quality_results.get('issues', [])
            
            # Validate expected outcomes
            validation = self.validate_scenario_results(scenario, score, review_type, issues)
            
            return {
                'scenario': scenario,
                'status': 'PASS' if validation['passed'] else 'FAIL',
                'score': score,
                'review_type': review_type,
                'issues_count': len(issues),
                'validation': validation,
                'details': quality_results
            }
            
        except Exception as e:
            return {
                'scenario': scenario,
                'status': 'ERROR',
                'error': str(e)
            }
    
    def validate_scenario_results(self, scenario: str, score: float, review_type: str, issues: List[Dict]) -> Dict[str, Any]:
        """Validate that results match expected outcomes for scenario"""
        validation = {'passed': True, 'messages': []}
        
        if scenario == 'high-quality':
            if score < 80:
                validation['passed'] = False
                validation['messages'].append(f'Expected high score (≥80), got {score}')
            
            if review_type != 'fast_track':
                validation['passed'] = False
                validation['messages'].append(f'Expected fast_track review, got {review_type}')
            
            if len(issues) > 0:
                validation['passed'] = False
                validation['messages'].append(f'Expected no issues, found {len(issues)}')
            
        elif scenario == 'security-risk':
            if score > 40:
                validation['passed'] = False
                validation['messages'].append(f'Expected low score (≤40), got {score}')
            
            security_issues = [i for i in issues if i.get('type') == 'security']
            if len(security_issues) == 0:
                validation['passed'] = False
                validation['messages'].append('Expected security issues, found none')
            
        elif scenario == 'large-files':
            file_size_issues = [i for i in issues if 'large file' in i.get('message', '').lower()]
            if len(file_size_issues) == 0:
                validation['passed'] = False
                validation['messages'].append('Expected large file issues, found none')
        
        if validation['passed']:
            validation['messages'].append('All validations passed')
        
        return validation
    
    def run_all_scenarios(self) -> Dict[str, Any]:
        """Run all integration test scenarios"""
        print("🚀 Jules Bot Integration Test Suite")
        print("Testing complete end-to-end workflow...")
        
        scenarios = [
            'high-quality',
            'security-risk', 
            'large-files',
            'standard'
        ]
        
        results = []
        
        for scenario in scenarios:
            result = self.test_scenario(scenario)
            results.append(result)
            
            status_emoji = "✅" if result['status'] == 'PASS' else "❌"
            print(f"\n{status_emoji} {scenario}: {result['status']}")
            
            if result['status'] == 'PASS':
                print(f"   Score: {result['score']:.1f}")
                print(f"   Review Type: {result['review_type']}")
                print(f"   Issues: {result['issues_count']}")
                for msg in result['validation']['messages']:
                    print(f"   ✓ {msg}")
            else:
                error_msg = result.get('error', 'Unknown error')
                print(f"   Error: {error_msg}")
        
        # Summary
        passed = sum(1 for r in results if r['status'] == 'PASS')
        total = len(results)
        
        print(f"\n{'='*60}")
        print(f"📊 Integration Test Summary: {passed}/{total} scenarios passed")
        
        if passed == total:
            print("🎉 All integration tests passed! The system is working correctly.")
        else:
            print("⚠️  Some integration tests failed. Review the issues above.")
        
        print(f"{'='*60}")
        
        return {
            'total_scenarios': total,
            'passed_scenarios': passed,
            'failed_scenarios': total - passed,
            'success_rate': (passed / total * 100) if total > 0 else 0,
            'results': results
        }
    
    def cleanup(self):
        """Clean up test environment"""
        if self.test_repo and os.path.exists(self.test_repo):
            try:
                shutil.rmtree(self.test_repo)
                print(f"🧹 Cleaned up test environment: {self.test_repo}")
            except Exception as e:
                print(f"⚠️  Could not clean up {self.test_repo}: {e}")

def main():
    """Main integration test runner"""
    test_runner = JulesIntegrationTest()
    
    try:
        # Setup test environment
        test_runner.setup_test_environment()
        
        # Run all scenarios
        results = test_runner.run_all_scenarios()
        
        # Return exit code based on results
        return 0 if results['failed_scenarios'] == 0 else 1
        
    finally:
        # Cleanup
        test_runner.cleanup()

if __name__ == '__main__':
    sys.exit(main())
