#!/usr/bin/env python3
"""
Jules Bot Review System - Final Integration Test & Demo
Comprehensive end-to-end validation of the complete workflow.
"""

import json
import subprocess
import sys
from pathlib import Path
import time
from datetime import datetime

def run_command(cmd, description):
    """Run a command and return the result."""
    print(f"🔧 {description}...")
    try:
        result = subprocess.run(cmd, shell=True, capture_output=True, text=True, cwd=Path.cwd())
        if result.returncode == 0:
            print(f"   ✅ Success")
            return True, result.stdout
        else:
            print(f"   ❌ Failed: {result.stderr}")
            return False, result.stderr
    except Exception as e:
        print(f"   ❌ Error: {str(e)}")
        return False, str(e)

def validate_file_exists(file_path, description):
    """Validate that a file exists."""
    path = Path(file_path)
    if path.exists():
        print(f"   ✅ {description}: Found ({path.stat().st_size} bytes)")
        return True
    else:
        print(f"   ❌ {description}: Missing")
        return False

def main():
    print("🚀 Jules Bot Review & Approval System - Final Integration Test")
    print("=" * 70)
    print(f"🕐 Test Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    total_tests = 0
    passed_tests = 0
    
    # Test 1: Core Configuration Files
    print("📋 TEST 1: Core Configuration Files")
    print("-" * 35)
    
    config_files = [
        (".github/jules-config.yml", "Main configuration"),
        (".github/notification-config.yml", "Notification configuration"),
        (".github/workflows/jules-review-approval.yml", "Review workflow"),
        (".github/workflows/jules-integration.yml", "Integration workflow"),
        ("docs/JULES_BOT_PRODUCTION_DEPLOYMENT.md", "Production deployment guide")
    ]
    
    for file_path, description in config_files:
        total_tests += 1
        if validate_file_exists(file_path, description):
            passed_tests += 1
    
    print()
    
    # Test 2: Core Scripts Validation
    print("📋 TEST 2: Core Scripts Validation")
    print("-" * 32)
    
    scripts = [
        ".github/scripts/quality_assessment.py",
        ".github/scripts/notification_system.py", 
        ".github/scripts/integration_manager.py",
        ".github/scripts/metrics_collector.py",
        ".github/scripts/monitoring_dashboard.py"
    ]
    
    for script in scripts:
        total_tests += 1
        success, output = run_command(f"python -m py_compile {script}", f"Validate {Path(script).name}")
        if success:
            passed_tests += 1
    
    print()
    
    # Test 3: Quality Assessment Test
    print("📋 TEST 3: Quality Assessment System")
    print("-" * 35)
    
    total_tests += 1
    success, output = run_command(
        "python .github/scripts/quality_assessment.py --config .github/jules-config.yml --dry-run",
        "Quality assessment dry run"
    )
    if success:
        passed_tests += 1
    
    print()
    
    # Test 4: Monitoring System Test
    print("📋 TEST 4: Monitoring System")
    print("-" * 27)
    
    total_tests += 1
    success, output = run_command(
        "python .github/scripts/monitoring_dashboard.py --health-check",
        "System health check"
    )
    if success:
        passed_tests += 1
    
    print()
    
    # Test 5: Documentation Completeness
    print("📋 TEST 5: Documentation Completeness")
    print("-" * 36)
    
    docs = [
        ("docs/JULES_BOT_REVIEW_PROCESS.md", "Review process documentation"),
        ("docs/JULES_BOT_TESTING_GUIDE.md", "Testing guide"),
        ("docs/JULES_BOT_MONITORING.md", "Monitoring documentation"),
        ("docs/JULES_BOT_PRODUCTION_DEPLOYMENT.md", "Production deployment guide")
    ]
    
    for doc_path, description in docs:
        total_tests += 1
        if validate_file_exists(doc_path, description):
            passed_tests += 1
    
    print()
    
    # Test 6: GitHub Actions Workflow Validation
    print("📋 TEST 6: GitHub Actions Workflow Validation")
    print("-" * 43)
    
    workflows = [
        ".github/workflows/jules-review-approval.yml",
        ".github/workflows/jules-integration.yml"
    ]
    
    for workflow in workflows:
        total_tests += 1
        try:
            import yaml
            with open(workflow, 'r') as f:
                yaml.safe_load(f)
            print(f"   ✅ {Path(workflow).name}: Valid YAML")
            passed_tests += 1
        except Exception as e:
            print(f"   ❌ {Path(workflow).name}: Invalid YAML - {str(e)}")
    
    print()
    
    # Test 7: Integration Test Suite
    print("📋 TEST 7: Integration Test Suite")
    print("-" * 32)
    
    total_tests += 1
    success, output = run_command(
        "python .github/scripts/test_integration.py",
        "End-to-end integration tests"
    )
    if success:
        passed_tests += 1
    
    print()
    
    # Test 8: Production Readiness Check
    print("📋 TEST 8: Production Readiness Check")
    print("-" * 37)
    
    readiness_checks = [
        ("Git repository status", "git status --porcelain"),
        ("Python dependencies", "python -c \"import yaml, requests\""),
        ("GitHub CLI availability", "where gh")
    ]
    
    for description, command in readiness_checks:
        total_tests += 1
        success, output = run_command(command, description)
        if success or "nothing to commit" in output:
            passed_tests += 1
    
    print()
    
    # Summary Report
    print("📊 FINAL TEST RESULTS")
    print("=" * 22)
    
    success_rate = (passed_tests / total_tests) * 100
    
    print(f"🎯 Tests Passed: {passed_tests}/{total_tests} ({success_rate:.1f}%)")
    
    if success_rate >= 90:
        status = "🟢 EXCELLENT"
        recommendation = "System is ready for production deployment!"
    elif success_rate >= 80:
        status = "🟡 GOOD"
        recommendation = "System is mostly ready. Address failing tests before production."
    else:
        status = "🔴 NEEDS WORK"
        recommendation = "System needs significant fixes before production deployment."
    
    print(f"🏆 Overall Status: {status}")
    print(f"💡 Recommendation: {recommendation}")
    print()
    
    # Next Steps
    print("🚀 NEXT STEPS FOR PRODUCTION")
    print("-" * 30)
    
    if success_rate >= 90:
        print("✅ 1. Configure GitHub secrets (SLACK_WEBHOOK_URL, EMAIL_USER, EMAIL_PASSWORD)")
        print("✅ 2. Create Slack channels (#jules-bot-reviews, #code-quality, #dev-alerts)")
        print("✅ 3. Train review team on PR commands (/jules approve, /jules decline)")
        print("✅ 4. Monitor first Jules Bot contributions")
        print("✅ 5. Optimize quality thresholds based on initial data")
    else:
        print("🔧 1. Fix failing tests identified above")
        print("🔧 2. Re-run integration test until 90%+ pass rate")
        print("🔧 3. Then proceed with production deployment steps")
    
    print()
    print("📚 For detailed deployment instructions, see:")
    print("   docs/JULES_BOT_PRODUCTION_DEPLOYMENT.md")
    print()
    
    # Generate Test Report
    test_report = {
        "timestamp": datetime.now().isoformat(),
        "total_tests": total_tests,
        "passed_tests": passed_tests,
        "success_rate": success_rate,
        "status": status,
        "recommendation": recommendation,
        "production_ready": success_rate >= 90
    }
    
    with open("jules_integration_test_report.json", "w") as f:
        json.dump(test_report, f, indent=2)
    
    print(f"📋 Test report saved to: jules_integration_test_report.json")
    
    if success_rate >= 90:
        print("\n🎉 Jules Bot Review & Approval System is READY FOR PRODUCTION! 🚀")
        return 0
    else:
        print(f"\n⚠️  System needs work before production deployment (Success rate: {success_rate:.1f}%)")
        return 1

if __name__ == "__main__":
    exit_code = main()
    sys.exit(exit_code)
