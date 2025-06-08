#!/usr/bin/env python3
"""
Jules Bot System Test Suite
Comprehensive testing for the review and approval workflow
"""

import os
import json
import subprocess
import tempfile
import shutil
import yaml
from typing import Dict, List, Any, Optional
import argparse
import sys
from pathlib import Path

class JulesBotTestSuite:
    def __init__(self, config_path: str = None):
        """Initialize test suite"""
        # Find the project root directory (contains .github folder)
        current_dir = Path(__file__).parent
        project_root = current_dir.parent.parent
        
        if config_path is None:
            config_path = project_root / '.github' / 'jules-config.yml'
        
        self.project_root = project_root
        self.scripts_dir = current_dir
        self.config_path = config_path
        self.config = self._load_config(str(config_path))
        self.test_results = []
        self.temp_dirs = []
        
    def _load_config(self, config_path: str) -> Dict[str, Any]:
        """Load configuration from YAML file"""
        try:
            with open(config_path, 'r', encoding='utf-8') as f:
                return yaml.safe_load(f)
        except Exception as e:
            print(f"Warning: Could not load config {config_path}: {e}")
            return {}

    def _run_command(self, command: List[str], cwd: Optional[str] = None) -> subprocess.CompletedProcess:
        """Run a command and return the result"""
        return subprocess.run(command, capture_output=True, text=True, cwd=cwd)

    def _create_test_repo(self) -> str:
        """Create a temporary git repository for testing"""
        temp_dir = tempfile.mkdtemp(prefix='jules_test_')
        self.temp_dirs.append(temp_dir)
        
        # Initialize git repository
        self._run_command(['git', 'init'], cwd=temp_dir)
        self._run_command(['git', 'config', 'user.email', 'test@example.com'], cwd=temp_dir)
        self._run_command(['git', 'config', 'user.name', 'Test User'], cwd=temp_dir)
        
        # Create initial files
        with open(os.path.join(temp_dir, 'README.md'), 'w') as f:
            f.write('# Test Repository\n\nThis is a test repository for Jules Bot testing.')
        
        with open(os.path.join(temp_dir, 'src', 'main.py'), 'w') as f:
            os.makedirs(os.path.dirname(f.name), exist_ok=True)
            f.write('print("Hello, World!")\n')
        
        # Initial commit
        self._run_command(['git', 'add', '.'], cwd=temp_dir)
        self._run_command(['git', 'commit', '-m', 'Initial commit'], cwd=temp_dir)
        
        # Create dev branch
        self._run_command(['git', 'checkout', '-b', 'dev'], cwd=temp_dir)
        self._run_command(['git', 'checkout', 'main'], cwd=temp_dir)
        
        return temp_dir

    def _create_jules_branch(self, repo_dir: str, branch_name: str, changes: List[Dict[str, Any]]) -> None:
        """Create a jules-google branch with specified changes"""
        # Checkout dev and create jules branch
        self._run_command(['git', 'checkout', 'dev'], cwd=repo_dir)
        self._run_command(['git', 'checkout', '-b', branch_name], cwd=repo_dir)
        
        # Apply changes
        for change in changes:
            file_path = os.path.join(repo_dir, change['file'])
            os.makedirs(os.path.dirname(file_path), exist_ok=True)
            
            with open(file_path, 'w') as f:
                f.write(change['content'])
            
            self._run_command(['git', 'add', change['file']], cwd=repo_dir)
            self._run_command(['git', 'commit', '-m', change.get('commit_message', f'Update {change["file"]}')], cwd=repo_dir)

    def test_quality_assessment_script(self) -> Dict[str, Any]:
        """Test the quality assessment script with various scenarios"""
        test_name = "Quality Assessment Script"
        print(f"Running test: {test_name}")
        
        results = {'test_name': test_name, 'passed': True, 'details': []}
        
        try:
            # Test 1: High quality contribution
            repo_dir = self._create_test_repo()
            
            # Copy scripts to test repo
            scripts_dir = os.path.join(repo_dir, '.github', 'scripts')
            os.makedirs(scripts_dir, exist_ok=True)
            
            # Copy quality assessment script
            shutil.copy('.github/scripts/quality_assessment.py', scripts_dir)
            
            # Copy config
            config_dir = os.path.join(repo_dir, '.github')
            shutil.copy('.github/jules-config.yml', config_dir)
            
            # Create high-quality branch
            high_quality_changes = [
                {
                    'file': 'src/utils.py',
                    'content': 'def add_numbers(a: int, b: int) -> int:\n    """Add two numbers together."""\n    return a + b\n',
                    'commit_message': 'feat: add utility function for number addition'
                },
                {
                    'file': 'docs/api.md',
                    'content': '# API Documentation\n\n## Utils Module\n\n### add_numbers\n\nAdds two numbers together.\n',
                    'commit_message': 'docs: add API documentation for utils module'
                }
            ]
            
            self._create_jules_branch(repo_dir, 'jules-google/feature-utils', high_quality_changes)
            
            # Run quality assessment
            result = self._run_command([
                'python', os.path.join(scripts_dir, 'quality_assessment.py'),
                '--config', os.path.join(config_dir, 'jules-config.yml'),
                '--base-ref', 'dev',
                '--output', os.path.join(repo_dir, 'quality_results.json')
            ], cwd=repo_dir)
            
            if result.returncode == 0:
                results['details'].append('✓ High quality assessment completed successfully')
                
                # Check results
                with open(os.path.join(repo_dir, 'quality_results.json'), 'r') as f:
                    quality_data = json.load(f)
                
                score = quality_data.get('overall_score', 0)
                if score >= 80:
                    results['details'].append(f'✓ High quality score achieved: {score}')
                else:
                    results['details'].append(f'✗ Expected high score, got: {score}')
                    results['passed'] = False
            else:
                results['details'].append(f'✗ Quality assessment failed: {result.stderr}')
                results['passed'] = False
            
            # Test 2: Low quality contribution
            low_quality_changes = [
                {
                    'file': 'temp.txt',
                    'content': 'temporary file\npassword=secret123\napi_key=abc123def\n',
                    'commit_message': 'temp'
                },
                {
                    'file': 'large_file.zip',
                    'content': 'x' * 2000000,  # 2MB file
                    'commit_message': 'add large file'
                }
            ]
            
            self._create_jules_branch(repo_dir, 'jules-google/bad-feature', low_quality_changes)
            
            result = self._run_command([
                'python', os.path.join(scripts_dir, 'quality_assessment.py'),
                '--config', os.path.join(config_dir, 'jules-config.yml'),
                '--base-ref', 'dev',
                '--output', os.path.join(repo_dir, 'quality_results_low.json')
            ], cwd=repo_dir)
            
            if result.returncode == 0:
                with open(os.path.join(repo_dir, 'quality_results_low.json'), 'r') as f:
                    quality_data = json.load(f)
                
                score = quality_data.get('overall_score', 100)
                issues = quality_data.get('issues', [])
                
                if score < 60 and len(issues) > 0:
                    results['details'].append(f'✓ Low quality correctly detected: score={score}, issues={len(issues)}')
                else:
                    results['details'].append(f'✗ Failed to detect low quality: score={score}, issues={len(issues)}')
                    results['passed'] = False
            else:
                results['details'].append(f'✗ Low quality assessment failed: {result.stderr}')
                results['passed'] = False
                
        except Exception as e:
            results['passed'] = False
            results['details'].append(f'✗ Test exception: {str(e)}')
        
        return results

    def test_notification_system(self) -> Dict[str, Any]:
        """Test the notification system"""
        test_name = "Notification System"
        print(f"Running test: {test_name}")
        
        results = {'test_name': test_name, 'passed': True, 'details': []}
        
        try:
            # Test notification formatting
            from .github.scripts.notification_system import NotificationSystem
            
            notifier = NotificationSystem()
            
            # Test data
            quality_results = {
                'overall_score': 75,
                'review_type': 'standard',
                'component_scores': {
                    'security': 80,
                    'commit_quality': 70,
                    'documentation': 75
                },
                'issues': [
                    {'type': 'security', 'severity': 'medium', 'message': 'Test security issue'}
                ],
                'metrics': {'file_count': 3}
            }
            
            pr_info = {
                'repository': 'test/repo',
                'number': 123,
                'title': 'Test PR',
                'head_ref': 'jules-google/test',
                'author': 'jules-bot'
            }
            
            # Test message formatting
            message = notifier.format_quality_report(quality_results, pr_info)
            
            if 'Quality Assessment' in message and '75/100' in message:
                results['details'].append('✓ Quality report formatting works')
            else:
                results['details'].append('✗ Quality report formatting failed')
                results['passed'] = False
            
            # Test HTML formatting
            html_message = notifier.format_html_quality_report(quality_results, pr_info)
            
            if '<html>' in html_message and 'Jules Bot' in html_message:
                results['details'].append('✓ HTML report formatting works')
            else:
                results['details'].append('✗ HTML report formatting failed')
                results['passed'] = False
                
        except ImportError:
            results['details'].append('✗ Could not import notification system')
            results['passed'] = False
        except Exception as e:
            results['passed'] = False
            results['details'].append(f'✗ Test exception: {str(e)}')
        
        return results

    def test_integration_manager(self) -> Dict[str, Any]:
        """Test the integration manager"""
        test_name = "Integration Manager"
        print(f"Running test: {test_name}")
        
        results = {'test_name': test_name, 'passed': True, 'details': []}
        
        try:
            # Create test repository
            repo_dir = self._create_test_repo()
            
            # Copy integration script
            scripts_dir = os.path.join(repo_dir, '.github', 'scripts')
            os.makedirs(scripts_dir, exist_ok=True)
            shutil.copy('.github/scripts/integration_manager.py', scripts_dir)
            
            # Copy config
            config_dir = os.path.join(repo_dir, '.github')
            shutil.copy('.github/jules-config.yml', config_dir)
            
            # Create test branch
            test_changes = [
                {
                    'file': 'src/feature.py',
                    'content': 'def new_feature():\n    return "Hello from new feature"\n',
                    'commit_message': 'feat: add new feature'
                }
            ]
            
            self._create_jules_branch(repo_dir, 'jules-google/test-integration', test_changes)
            
            # Test dry run
            result = self._run_command([
                'python', os.path.join(scripts_dir, 'integration_manager.py'),
                '--config', os.path.join(config_dir, 'jules-config.yml'),
                '--source-branch', 'jules-google/test-integration',
                '--target-branch', 'dev',
                '--dry-run'
            ], cwd=repo_dir)
            
            if result.returncode == 0:
                results['details'].append('✓ Integration dry run completed successfully')
            else:
                results['details'].append(f'✗ Integration dry run failed: {result.stderr}')
                results['passed'] = False
                
        except Exception as e:
            results['passed'] = False
            results['details'].append(f'✗ Test exception: {str(e)}')
        
        return results

    def test_metrics_collector(self) -> Dict[str, Any]:
        """Test the metrics collection system"""
        test_name = "Metrics Collector"
        print(f"Running test: {test_name}")
        
        results = {'test_name': test_name, 'passed': True, 'details': []}
        
        try:
            from .github.scripts.metrics_collector import MetricsCollector
            
            # Create temporary database
            temp_db = tempfile.mktemp(suffix='.db')
            collector = MetricsCollector(db_path=temp_db)
            
            # Test recording quality assessment
            quality_data = {
                'branch_name': 'jules-google/test',
                'overall_score': 85,
                'review_type': 'fast_track',
                'component_scores': {
                    'security': 90,
                    'commit_quality': 80
                },
                'issues': [],
                'metrics': {'file_count': 2}
            }
            
            collector.record_quality_assessment(quality_data)
            results['details'].append('✓ Quality assessment recording works')
            
            # Test getting trends
            trends = collector.get_quality_trends(days=7)
            
            if 'daily_trends' in trends and 'component_averages' in trends:
                results['details'].append('✓ Quality trends retrieval works')
            else:
                results['details'].append('✗ Quality trends retrieval failed')
                results['passed'] = False
            
            # Test dashboard generation
            dashboard = collector.generate_dashboard_data(days=7)
            
            required_sections = ['quality_trends', 'review_performance', 'integration_metrics', 'system_health']
            missing_sections = [s for s in required_sections if s not in dashboard]
            
            if not missing_sections:
                results['details'].append('✓ Dashboard generation works')
            else:
                results['details'].append(f'✗ Dashboard missing sections: {missing_sections}')
                results['passed'] = False
            
            # Cleanup
            os.unlink(temp_db)
                
        except ImportError:
            results['details'].append('✗ Could not import metrics collector')
            results['passed'] = False
        except Exception as e:
            results['passed'] = False
            results['details'].append(f'✗ Test exception: {str(e)}')
        
        return results

    def test_configuration_validation(self) -> Dict[str, Any]:
        """Test configuration file validation"""
        test_name = "Configuration Validation"
        print(f"Running test: {test_name}")
        
        results = {'test_name': test_name, 'passed': True, 'details': []}
        
        try:
            # Check if config file exists and is valid YAML
            config_path = '.github/jules-config.yml'
            
            if not os.path.exists(config_path):
                results['details'].append('✗ Configuration file does not exist')
                results['passed'] = False
                return results
            
            with open(config_path, 'r') as f:
                config = yaml.safe_load(f)
            
            results['details'].append('✓ Configuration file is valid YAML')
            
            # Check required sections
            required_sections = [
                'quality_thresholds',
                'quality_weights',
                'file_limits',
                'security_patterns',
                'reviewer_assignment'
            ]
            
            missing_sections = [s for s in required_sections if s not in config]
            
            if not missing_sections:
                results['details'].append('✓ All required configuration sections present')
            else:
                results['details'].append(f'✗ Missing configuration sections: {missing_sections}')
                results['passed'] = False
            
            # Validate quality weights sum to 1.0
            weights = config.get('quality_weights', {})
            total_weight = sum(weights.values())
            
            if abs(total_weight - 1.0) < 0.01:  # Allow small floating point errors
                results['details'].append('✓ Quality weights sum correctly')
            else:
                results['details'].append(f'✗ Quality weights sum to {total_weight}, should be 1.0')
                results['passed'] = False
            
            # Check threshold values
            thresholds = config.get('quality_thresholds', {})
            
            if (thresholds.get('fast_track', 0) > thresholds.get('standard', 0) > 
                thresholds.get('enhanced', 0)):
                results['details'].append('✓ Quality thresholds are properly ordered')
            else:
                results['details'].append('✗ Quality thresholds are not properly ordered')
                results['passed'] = False
                
        except yaml.YAMLError as e:
            results['passed'] = False
            results['details'].append(f'✗ Configuration YAML error: {str(e)}')
        except Exception as e:
            results['passed'] = False
            results['details'].append(f'✗ Test exception: {str(e)}')
        
        return results

    def run_all_tests(self) -> Dict[str, Any]:
        """Run all test suites"""
        print("=" * 60)
        print("Jules Bot System Test Suite")
        print("=" * 60)
        
        test_methods = [
            self.test_configuration_validation,
            self.test_quality_assessment_script,
            self.test_notification_system,
            self.test_integration_manager,
            self.test_metrics_collector
        ]
        
        all_results = []
        
        for test_method in test_methods:
            try:
                result = test_method()
                all_results.append(result)
                
                print(f"\n{result['test_name']}: {'PASS' if result['passed'] else 'FAIL'}")
                for detail in result['details']:
                    print(f"  {detail}")
                    
            except Exception as e:
                error_result = {
                    'test_name': test_method.__name__,
                    'passed': False,
                    'details': [f'✗ Test execution failed: {str(e)}']
                }
                all_results.append(error_result)
                print(f"\n{error_result['test_name']}: FAIL")
                print(f"  ✗ Test execution failed: {str(e)}")
        
        # Summary
        passed_tests = [r for r in all_results if r['passed']]
        failed_tests = [r for r in all_results if not r['passed']]
        
        print("\n" + "=" * 60)
        print(f"Test Summary: {len(passed_tests)}/{len(all_results)} tests passed")
        
        if failed_tests:
            print("\nFailed tests:")
            for test in failed_tests:
                print(f"  - {test['test_name']}")
        
        print("=" * 60)
        
        return {
            'total_tests': len(all_results),
            'passed_tests': len(passed_tests),
            'failed_tests': len(failed_tests),
            'success_rate': len(passed_tests) / len(all_results) * 100 if all_results else 0,
            'results': all_results
        }

    def cleanup(self) -> None:
        """Clean up temporary directories"""
        for temp_dir in self.temp_dirs:
            try:
                shutil.rmtree(temp_dir)
            except Exception as e:
                print(f"Warning: Could not clean up {temp_dir}: {e}")

def main():
    parser = argparse.ArgumentParser(description='Jules Bot System Test Suite')
    parser.add_argument('--config', default='.github/jules-config.yml', help='Configuration file path')
    parser.add_argument('--test', choices=['config', 'quality', 'notification', 'integration', 'metrics', 'all'], 
                       default='all', help='Specific test to run')
    parser.add_argument('--output', help='Output file for test results (JSON)')
    args = parser.parse_args()
    
    test_suite = JulesBotTestSuite(args.config)
    
    try:
        if args.test == 'all':
            results = test_suite.run_all_tests()
        else:
            # Run specific test
            test_map = {
                'config': test_suite.test_configuration_validation,
                'quality': test_suite.test_quality_assessment_script,
                'notification': test_suite.test_notification_system,
                'integration': test_suite.test_integration_manager,
                'metrics': test_suite.test_metrics_collector
            }
            
            result = test_map[args.test]()
            results = {
                'total_tests': 1,
                'passed_tests': 1 if result['passed'] else 0,
                'failed_tests': 0 if result['passed'] else 1,
                'success_rate': 100 if result['passed'] else 0,
                'results': [result]
            }
            
            print(f"{result['test_name']}: {'PASS' if result['passed'] else 'FAIL'}")
            for detail in result['details']:
                print(f"  {detail}")
        
        # Save results if requested
        if args.output:
            with open(args.output, 'w') as f:
                json.dump(results, f, indent=2)
            print(f"\nTest results saved to {args.output}")
        
        # Return appropriate exit code
        return 0 if results['failed_tests'] == 0 else 1
        
    finally:
        test_suite.cleanup()

if __name__ == '__main__':
    sys.exit(main())
