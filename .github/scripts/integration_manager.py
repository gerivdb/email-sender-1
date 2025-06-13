#!/usr/bin/env python3
"""
Jules Bot Integration Manager
Handles the actual merging of approved Jules Bot contributions to dev branch
"""

import os
import json
import subprocess
import yaml
from typing import Dict, Any, Optional
import argparse
import sys

class IntegrationManager:
    def __init__(self, config_path: str = '.github/jules-config.yml'):
        """Initialize integration manager with configuration"""
        self.config = self._load_config(config_path)
        
    def _load_config(self, config_path: str) -> Dict[str, Any]:
        """Load configuration from YAML file"""
        try:
            with open(config_path, 'r', encoding='utf-8') as f:
                return yaml.safe_load(f)
        except Exception as e:
            print(f"Warning: Could not load config {config_path}: {e}")
            return {}

    def _run_command(self, command: list, check: bool = True) -> subprocess.CompletedProcess:
        """Run a shell command and return the result"""
        print(f"Running: {' '.join(command)}")
        result = subprocess.run(command, capture_output=True, text=True, check=False)
        
        if result.returncode != 0 and check:
            print(f"Command failed with return code {result.returncode}")
            print(f"STDOUT: {result.stdout}")
            print(f"STDERR: {result.stderr}")
            raise subprocess.CalledProcessError(result.returncode, command, result.stdout, result.stderr)
        
        return result

    def validate_branch_state(self, source_branch: str, target_branch: str = 'dev') -> bool:
        """Validate that branches are in a good state for merging"""
        print(f"Validating branch state: {source_branch} -> {target_branch}")
        
        try:
            # Fetch latest changes
            self._run_command(['git', 'fetch', 'origin'])
            
            # Check if source branch exists
            result = self._run_command(['git', 'rev-parse', '--verify', f'origin/{source_branch}'], check=False)
            if result.returncode != 0:
                print(f"Source branch {source_branch} does not exist")
                return False
            
            # Check if target branch exists
            result = self._run_command(['git', 'rev-parse', '--verify', f'origin/{target_branch}'], check=False)
            if result.returncode != 0:
                print(f"Target branch {target_branch} does not exist")
                return False
            
            # Check if source branch is ahead of target
            result = self._run_command(['git', 'rev-list', '--count', f'origin/{target_branch}..origin/{source_branch}'])
            commits_ahead = int(result.stdout.strip())
            
            if commits_ahead == 0:
                print(f"Source branch {source_branch} is not ahead of {target_branch}")
                return False
            
            print(f"Branch validation passed: {commits_ahead} commits ahead")
            return True
            
        except Exception as e:
            print(f"Branch validation failed: {e}")
            return False

    def create_integration_branch(self, source_branch: str, target_branch: str = 'dev') -> str:
        """Create an integration branch for safe merging"""
        integration_branch = f"integration/{source_branch.replace('jules-google/', '')}"
        
        try:
            # Switch to target branch and create integration branch
            self._run_command(['git', 'checkout', f'origin/{target_branch}'])
            self._run_command(['git', 'checkout', '-b', integration_branch])
            
            print(f"Created integration branch: {integration_branch}")
            return integration_branch
            
        except Exception as e:
            print(f"Failed to create integration branch: {e}")
            raise

    def merge_with_strategy(self, source_branch: str, integration_branch: str, strategy: str = 'squash') -> bool:
        """Merge source branch into integration branch with specified strategy"""
        print(f"Merging {source_branch} -> {integration_branch} using {strategy} strategy")
        
        try:
            if strategy == 'squash':
                # Squash merge
                self._run_command(['git', 'merge', '--squash', f'origin/{source_branch}'])
                
                # Create a meaningful commit message
                commit_message = self._generate_squash_commit_message(source_branch)
                self._run_command(['git', 'commit', '-m', commit_message])
                
            elif strategy == 'merge':
                # Regular merge
                commit_message = f"Merge Jules Bot contribution from {source_branch}"
                self._run_command(['git', 'merge', f'origin/{source_branch}', '-m', commit_message])
                
            elif strategy == 'rebase':
                # Rebase and fast-forward
                self._run_command(['git', 'rebase', f'origin/{source_branch}'])
                
            else:
                raise ValueError(f"Unknown merge strategy: {strategy}")
            
            print(f"Merge completed successfully using {strategy} strategy")
            return True
            
        except Exception as e:
            print(f"Merge failed: {e}")
            return False

    def _generate_squash_commit_message(self, source_branch: str) -> str:
        """Generate a meaningful commit message for squash merges"""
        try:
            # Get the commit messages from the source branch
            result = self._run_command(['git', 'log', '--oneline', f'origin/dev..origin/{source_branch}'])
            commits = [line.strip() for line in result.stdout.strip().split('\n') if line.strip()]
            
            if not commits:
                return f"Jules Bot: Merge contribution from {source_branch}"
            
            # Extract the main purpose from commit messages
            first_commit = commits[-1] if commits else ""  # First commit chronologically
            
            # Clean up the commit message
            if ' ' in first_commit:
                main_message = ' '.join(first_commit.split()[1:])  # Remove hash
            else:
                main_message = f"Contribution from {source_branch}"
            
            # Create comprehensive commit message
            commit_message = f"Jules Bot: {main_message}\n\n"
            commit_message += f"Source: {source_branch}\n"
            commit_message += f"Commits: {len(commits)}\n\n"
            
            if len(commits) > 1:
                commit_message += "Squashed commits:\n"
                for commit in commits:
                    commit_message += f"  - {commit}\n"
            
            return commit_message
            
        except Exception as e:
            print(f"Error generating commit message: {e}")
            return f"Jules Bot: Merge contribution from {source_branch}"

    def run_integration_tests(self, integration_branch: str) -> bool:
        """Run integration tests on the merged code"""
        print("Running integration tests...")
        
        # This would typically run the project's test suite
        # For now, we'll do basic checks
        
        try:
            # Check if common files are still valid
            common_files = ['package.json', 'requirements.txt', 'composer.json']
            
            for file_path in common_files:
                if os.path.exists(file_path):
                    print(f"Validating {file_path}...")
                    
                    # Basic JSON validation for package.json
                    if file_path.endswith('.json'):
                        try:
                            with open(file_path, 'r') as f:
                                json.load(f)
                            print(f"✓ {file_path} is valid JSON")
                        except json.JSONDecodeError as e:
                            print(f"✗ {file_path} is invalid JSON: {e}")
                            return False
            
            # Run project-specific tests if configured
            test_commands = self.config.get('integration', {}).get('test_commands', [])
            
            for command in test_commands:
                print(f"Running test command: {command}")
                result = self._run_command(command.split(), check=False)
                
                if result.returncode != 0:
                    print(f"Test command failed: {command}")
                    print(f"Output: {result.stdout}")
                    print(f"Error: {result.stderr}")
                    return False
            
            print("All integration tests passed")
            return True
            
        except Exception as e:
            print(f"Integration tests failed: {e}")
            return False

    def finalize_merge(self, integration_branch: str, target_branch: str = 'dev') -> bool:
        """Finalize the merge by pushing to target branch"""
        print(f"Finalizing merge: {integration_branch} -> {target_branch}")
        
        try:
            # Switch to target branch and merge integration branch
            self._run_command(['git', 'checkout', f'origin/{target_branch}'])
            self._run_command(['git', 'checkout', '-b', f'temp-{target_branch}'])
            self._run_command(['git', 'merge', '--ff-only', integration_branch])
            
            # Push to remote
            self._run_command(['git', 'push', 'origin', f'temp-{target_branch}:{target_branch}'])
            
            print(f"Successfully merged to {target_branch}")
            return True
            
        except Exception as e:
            print(f"Failed to finalize merge: {e}")
            return False

    def cleanup_branches(self, integration_branch: str, source_branch: str) -> None:
        """Clean up temporary branches after successful merge"""
        print("Cleaning up temporary branches...")
        
        try:
            # Delete local integration branch
            self._run_command(['git', 'branch', '-D', integration_branch], check=False)
            
            # Optionally delete the source branch (jules-google/*)
            # This might be handled by a separate cleanup process
            delete_source = self.config.get('integration', {}).get('delete_source_branch', False)
            
            if delete_source:
                self._run_command(['git', 'push', 'origin', '--delete', source_branch], check=False)
                print(f"Deleted source branch: {source_branch}")
            
            print("Cleanup completed")
            
        except Exception as e:
            print(f"Cleanup failed (non-critical): {e}")

    def update_contextual_memory(self, source_branch: str, merge_result: Dict[str, Any]) -> None:
        """Update Jules Bot's contextual memory with merge results"""
        print("Updating contextual memory...")
        
        try:
            # This would integrate with the contextual memory system
            # For now, we'll create a simple log entry
            
            memory_entry = {
                'timestamp': subprocess.run(['date', '-Iseconds'], capture_output=True, text=True).stdout.strip(),
                'event': 'integration_completed',
                'source_branch': source_branch,
                'target_branch': merge_result.get('target_branch', 'dev'),
                'merge_strategy': merge_result.get('strategy', 'unknown'),
                'success': merge_result.get('success', False),
                'tests_passed': merge_result.get('tests_passed', False),
                'integration_score': merge_result.get('integration_score', 0)
            }
            
            # Append to memory log
            memory_file = '.github/jules-memory.jsonl'
            with open(memory_file, 'a') as f:
                f.write(json.dumps(memory_entry) + '\n')
            
            print("Contextual memory updated")
            
        except Exception as e:
            print(f"Failed to update contextual memory: {e}")

    def integrate_contribution(self, source_branch: str, target_branch: str = 'dev', strategy: str = 'squash') -> Dict[str, Any]:
        """Main integration workflow"""
        result = {
            'success': False,
            'source_branch': source_branch,
            'target_branch': target_branch,
            'strategy': strategy,
            'integration_branch': None,
            'tests_passed': False,
            'error': None
        }
        
        try:
            print(f"Starting integration: {source_branch} -> {target_branch}")
            
            # Step 1: Validate branch state
            if not self.validate_branch_state(source_branch, target_branch):
                result['error'] = "Branch validation failed"
                return result
            
            # Step 2: Create integration branch
            integration_branch = self.create_integration_branch(source_branch, target_branch)
            result['integration_branch'] = integration_branch
            
            # Step 3: Merge with specified strategy
            if not self.merge_with_strategy(source_branch, integration_branch, strategy):
                result['error'] = "Merge failed"
                return result
            
            # Step 4: Run integration tests
            tests_passed = self.run_integration_tests(integration_branch)
            result['tests_passed'] = tests_passed
            
            if not tests_passed:
                result['error'] = "Integration tests failed"
                return result
            
            # Step 5: Finalize merge
            if not self.finalize_merge(integration_branch, target_branch):
                result['error'] = "Failed to finalize merge"
                return result
            
            # Step 6: Cleanup
            self.cleanup_branches(integration_branch, source_branch)
            
            # Step 7: Update contextual memory
            result['success'] = True
            self.update_contextual_memory(source_branch, result)
            
            print("Integration completed successfully!")
            return result
            
        except Exception as e:
            result['error'] = str(e)
            print(f"Integration failed: {e}")
            return result

def main():
    parser = argparse.ArgumentParser(description='Jules Bot Integration Manager')
    parser.add_argument('--config', default='.github/jules-config.yml', help='Configuration file path')
    parser.add_argument('--source-branch', required=True, help='Source branch to merge (e.g., jules-google/feature-123)')
    parser.add_argument('--target-branch', default='dev', help='Target branch to merge into')
    parser.add_argument('--strategy', choices=['squash', 'merge', 'rebase'], default='squash', help='Merge strategy')
    parser.add_argument('--dry-run', action='store_true', help='Validate only, do not actually merge')
    args = parser.parse_args()
    
    manager = IntegrationManager(args.config)
    
    if args.dry_run:
        print("Running in dry-run mode - validation only")
        success = manager.validate_branch_state(args.source_branch, args.target_branch)
        return 0 if success else 1
    
    result = manager.integrate_contribution(
        args.source_branch,
        args.target_branch,
        args.strategy
    )
    
    # Output result for GitHub Actions
    print(f"INTEGRATION_SUCCESS={result['success']}")
    print(f"INTEGRATION_ERROR={result.get('error', '')}")
    
    return 0 if result['success'] else 1

if __name__ == '__main__':
    sys.exit(main())
