#!/usr/bin/env python3
"""
Jules Bot System Test Runner
Simplified test runner to validate the system components
"""

import os
import sys
import json
import yaml
import tempfile
import shutil
from pathlib import Path
from typing import Dict, Any, List

class JulesTestRunner:
    def __init__(self):
        """Initialize test runner"""
        # Get project paths
        self.script_dir = Path(__file__).parent
        self.project_root = self.script_dir.parent.parent
        self.config_path = self.project_root / '.github' / 'jules-config.yml'
        
        print(f"Project root: {self.project_root}")
        print(f"Config path: {self.config_path}")
        print(f"Scripts dir: {self.script_dir}")

    def test_config_validation(self) -> Dict[str, Any]:
        """Test configuration file validation"""
        print("\n🔧 Testing Configuration Validation...")
        
        try:
            # Check if config exists
            if not self.config_path.exists():
                return {'status': 'FAIL', 'message': f'Config file not found: {self.config_path}'}
            
            # Load and validate YAML
            with open(self.config_path, 'r', encoding='utf-8') as f:
                config = yaml.safe_load(f)
            
            # Check required sections
            required_sections = [
                'quality_thresholds', 'quality_weights', 'file_limits',
                'security_patterns', 'reviewer_assignment', 'timeouts', 'notifications'
            ]
            
            missing = [s for s in required_sections if s not in config]
            if missing:
                return {'status': 'FAIL', 'message': f'Missing sections: {missing}'}
            
            # Check quality weights sum to 1.0
            weights = config['quality_weights']
            total = sum(weights.values())
            if abs(total - 1.0) > 0.01:
                return {'status': 'FAIL', 'message': f'Weights sum to {total}, not 1.0'}
            
            return {'status': 'PASS', 'message': 'Configuration is valid'}
            
        except Exception as e:
            return {'status': 'FAIL', 'message': f'Error: {str(e)}'}

    def test_script_imports(self) -> Dict[str, Any]:
        """Test that all Python scripts can be imported/parsed"""
        print("\n📦 Testing Script Imports...")
        
        script_files = [
            'quality_assessment.py',
            'notification_system.py', 
            'integration_manager.py',
            'metrics_collector.py'
        ]
        
        results = []
        
        for script in script_files:
            script_path = self.script_dir / script
            
            if not script_path.exists():
                results.append(f'❌ Missing: {script}')
                continue
            
            try:
                # Try to compile the script
                with open(script_path, 'r', encoding='utf-8') as f:
                    code = f.read()
                
                compile(code, str(script_path), 'exec')
                results.append(f'✅ Valid: {script}')
                
            except SyntaxError as e:
                results.append(f'❌ Syntax error in {script}: {e}')
            except Exception as e:
                results.append(f'❌ Error in {script}: {e}')
        
        errors = [r for r in results if '❌' in r]
        if errors:
            return {'status': 'FAIL', 'message': '; '.join(errors)}
        else:
            return {'status': 'PASS', 'message': 'All scripts are valid'}

    def test_workflow_files(self) -> Dict[str, Any]:
        """Test GitHub Actions workflow files"""
        print("\n⚙️  Testing Workflow Files...")
        
        workflow_files = [
            'jules-review-approval.yml',
            'jules-integration.yml'
        ]
        
        workflow_dir = self.project_root / '.github' / 'workflows'
        results = []
        
        for workflow in workflow_files:
            workflow_path = workflow_dir / workflow
            
            if not workflow_path.exists():
                results.append(f'❌ Missing: {workflow}')
                continue
            
            try:
                with open(workflow_path, 'r', encoding='utf-8') as f:
                    workflow_data = yaml.safe_load(f)
                  # Basic validation
                if 'on' not in workflow_data and True not in workflow_data:
                    results.append(f'❌ No triggers in {workflow}')
                elif 'jobs' not in workflow_data:
                    results.append(f'❌ No jobs in {workflow}')
                else:
                    results.append(f'✅ Valid: {workflow}')
                    
            except yaml.YAMLError as e:
                results.append(f'❌ YAML error in {workflow}: {e}')
            except Exception as e:
                results.append(f'❌ Error in {workflow}: {e}')
        
        errors = [r for r in results if '❌' in r]
        if errors:
            return {'status': 'FAIL', 'message': '; '.join(errors)}
        else:
            return {'status': 'PASS', 'message': 'All workflows are valid'}

    def test_quality_assessment_basic(self) -> Dict[str, Any]:
        """Basic test of quality assessment script"""
        print("\n🔍 Testing Quality Assessment (Basic)...")
        
        try:
            quality_script = self.script_dir / 'quality_assessment.py'
            if not quality_script.exists():
                return {'status': 'FAIL', 'message': 'quality_assessment.py not found'}
            
            # Check if script has required functions
            with open(quality_script, 'r', encoding='utf-8') as f:
                content = f.read()
            
            required_classes = ['QualityAssessment']
            required_methods = ['assess_file_count', 'assess_security', 'assess_commit_quality']
            
            missing = []
            for cls in required_classes:
                if f'class {cls}' not in content:
                    missing.append(f'class {cls}')
            
            for method in required_methods:
                if f'def {method}' not in content:
                    missing.append(f'method {method}')
            
            if missing:
                return {'status': 'FAIL', 'message': f'Missing: {missing}'}
            
            return {'status': 'PASS', 'message': 'Quality assessment script structure is valid'}
            
        except Exception as e:
            return {'status': 'FAIL', 'message': f'Error: {str(e)}'}

    def test_documentation(self) -> Dict[str, Any]:
        """Test documentation files"""
        print("\n📚 Testing Documentation...")
        
        doc_files = [
            'docs/JULES_BOT_REVIEW_PROCESS.md',
            'docs/JULES_BOT_TESTING_GUIDE.md',
            'docs/JULES_BOT_MONITORING.md'
        ]
        
        results = []
        
        for doc in doc_files:
            doc_path = self.project_root / doc
            
            if not doc_path.exists():
                results.append(f'❌ Missing: {doc}')
                continue
            
            try:
                with open(doc_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                if len(content.strip()) < 100:
                    results.append(f'❌ Too short: {doc}')
                else:
                    results.append(f'✅ Valid: {doc}')
                    
            except Exception as e:
                results.append(f'❌ Error reading {doc}: {e}')
        
        errors = [r for r in results if '❌' in r]
        if errors:
            return {'status': 'FAIL', 'message': '; '.join(errors)}
        else:
            return {'status': 'PASS', 'message': 'All documentation files exist'}

    def test_pr_templates(self) -> Dict[str, Any]:
        """Test PR template files"""
        print("\n📋 Testing PR Templates...")
        
        template_files = [
            '.github/pull_request_template.md',
            '.github/PULL_REQUEST_TEMPLATE/jules-bot-contribution.md'
        ]
        
        results = []
        
        for template in template_files:
            template_path = self.project_root / template
            
            if not template_path.exists():
                results.append(f'❌ Missing: {template}')
                continue
            
            try:
                with open(template_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Check for basic template structure
                if '##' not in content or 'checklist' not in content.lower():
                    results.append(f'❌ Invalid structure: {template}')
                else:
                    results.append(f'✅ Valid: {template}')
                    
            except Exception as e:
                results.append(f'❌ Error reading {template}: {e}')
        
        errors = [r for r in results if '❌' in r]
        if errors:
            return {'status': 'FAIL', 'message': '; '.join(errors)}
        else:
            return {'status': 'PASS', 'message': 'All PR templates are valid'}

    def run_all_tests(self) -> Dict[str, Any]:
        """Run all tests and return summary"""
        print("🚀 Jules Bot System Validation")
        print("=" * 60)
        
        tests = [
            ('Configuration', self.test_config_validation),
            ('Script Imports', self.test_script_imports),
            ('Workflow Files', self.test_workflow_files),
            ('Quality Assessment', self.test_quality_assessment_basic),
            ('Documentation', self.test_documentation),
            ('PR Templates', self.test_pr_templates)
        ]
        
        results = []
        
        for test_name, test_func in tests:
            try:
                result = test_func()
                result['test_name'] = test_name
                results.append(result)
                
                status_emoji = "✅" if result['status'] == 'PASS' else "❌"
                print(f"{status_emoji} {test_name}: {result['status']}")
                print(f"   {result['message']}")
                
            except Exception as e:
                result = {
                    'test_name': test_name,
                    'status': 'ERROR',
                    'message': f'Test execution failed: {str(e)}'
                }
                results.append(result)
                print(f"❌ {test_name}: ERROR")
                print(f"   {result['message']}")
        
        # Summary
        passed = sum(1 for r in results if r['status'] == 'PASS')
        total = len(results)
        
        print("\n" + "=" * 60)
        print(f"📊 Summary: {passed}/{total} tests passed")
        
        if passed == total:
            print("🎉 All tests passed! The Jules Bot system is ready.")
        else:
            print("⚠️  Some tests failed. Review the issues above.")
        
        print("=" * 60)
        
        return {
            'total_tests': total,
            'passed_tests': passed,
            'failed_tests': total - passed,
            'success_rate': (passed / total * 100) if total > 0 else 0,
            'results': results
        }

def main():
    """Main test runner"""
    runner = JulesTestRunner()
    results = runner.run_all_tests()
    
    # Return exit code based on results
    return 0 if results['failed_tests'] == 0 else 1

if __name__ == '__main__':
    sys.exit(main())
