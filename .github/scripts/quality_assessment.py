#!/usr/bin/env python3
"""
Jules Bot Quality Assessment Script
Analyzes pull requests from jules-google/* branches for automated quality scoring
"""

import os
import re
import json
import yaml
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Tuple, Any
import argparse

class QualityAssessment:
    def __init__(self, config_path: str = '.github/jules-config.yml'):
        """Initialize quality assessment with configuration"""
        self.config = self._load_config(config_path)
        self.base_score = 100
        self.issues = []
        self.metrics = {}
        
    def _load_config(self, config_path: str) -> Dict[str, Any]:
        """Load configuration from YAML file"""
        try:
            with open(config_path, 'r', encoding='utf-8') as f:
                return yaml.safe_load(f)
        except Exception as e:
            print(f"Warning: Could not load config {config_path}: {e}")
            return self._default_config()
    
    def _default_config(self) -> Dict[str, Any]:
        """Return default configuration if config file is not available"""
        return {
            'quality_thresholds': {'fast_track': 80, 'standard': 60, 'enhanced': 0},
            'quality_weights': {
                'file_count': 0.15, 'file_size': 0.10, 'security': 0.25,
                'commit_quality': 0.20, 'configuration': 0.15, 'documentation': 0.15
            },
            'file_limits': {'max_files': 10, 'max_file_size_mb': 1, 'max_commits': 5},
            'security_patterns': {
                'sensitive_files': ['.env', '*.key', '*.pem'],
                'sensitive_content': ['password\\s*[=:]', 'api[_-]?key\\s*[=:]']
            }
        }

    def get_changed_files(self, base_ref: str = 'origin/dev') -> List[str]:
        """Get list of changed files in the current branch"""
        try:
            result = subprocess.run(
                ['git', 'diff', '--name-only', f'{base_ref}...HEAD'],
                capture_output=True, text=True, check=True
            )
            files = [f.strip() for f in result.stdout.strip().split('\n') if f.strip()]
            self.metrics['changed_files'] = files
            self.metrics['file_count'] = len(files)
            return files
        except subprocess.CalledProcessError as e:
            print(f"Error getting changed files: {e}")
            return []

    def assess_file_count(self, files: List[str]) -> float:
        """Assess score based on number of changed files"""
        max_files = self.config.get('file_limits', {}).get('max_files', 10)
        file_count = len(files)
        
        if file_count == 0:
            return 0
        elif file_count <= max_files:
            return 100
        else:
            # Exponential decay for large file counts
            penalty = min(50, (file_count - max_files) * 5)
            return max(50, 100 - penalty)

    def assess_file_sizes(self, files: List[str]) -> float:
        """Assess score based on file sizes"""
        max_size_mb = self.config.get('file_limits', {}).get('max_file_size_mb', 1)
        max_size_bytes = max_size_mb * 1024 * 1024
        
        large_files = []
        total_penalty = 0
        
        for file_path in files:
            if os.path.exists(file_path):
                size = os.path.getsize(file_path)
                if size > max_size_bytes:
                    large_files.append((file_path, size))
                    # Penalty based on how much larger the file is
                    penalty = min(20, (size / max_size_bytes - 1) * 10)
                    total_penalty += penalty
        
        if large_files:
            self.issues.append({
                'type': 'large_files',
                'severity': 'medium',
                'message': f"Large files detected: {[f[0] for f in large_files]}",
                'files': large_files
            })
        
        return max(0, 100 - total_penalty)

    def assess_security(self, files: List[str]) -> float:
        """Assess security risks in changed files"""
        sensitive_files = self.config.get('security_patterns', {}).get('sensitive_files', [])
        sensitive_content = self.config.get('security_patterns', {}).get('sensitive_content', [])
        
        security_score = 100
        security_issues = []
        
        # Check for sensitive file patterns
        for file_path in files:
            for pattern in sensitive_files:
                if self._matches_pattern(file_path, pattern):
                    security_issues.append(f"Sensitive file: {file_path}")
                    security_score -= 30
        
        # Check file contents for sensitive patterns
        for file_path in files:
            if os.path.exists(file_path) and self._is_text_file(file_path):
                try:
                    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                        content = f.read()
                        
                    for pattern in sensitive_content:
                        if re.search(pattern, content, re.IGNORECASE):
                            security_issues.append(f"Sensitive content in {file_path}: {pattern}")
                            security_score -= 25
                except Exception:
                    continue
        
        if security_issues:
            self.issues.append({
                'type': 'security',
                'severity': 'high',
                'message': 'Security issues detected',
                'details': security_issues
            })
        
        return max(0, security_score)

    def assess_commit_quality(self) -> float:
        """Assess quality of commit messages and commit count"""
        try:
            # Get commit messages since base branch
            result = subprocess.run(
                ['git', 'log', '--oneline', 'origin/dev..HEAD'],
                capture_output=True, text=True, check=True
            )
            commits = [line.strip() for line in result.stdout.strip().split('\n') if line.strip()]
            
            if not commits:
                return 100
            
            commit_count = len(commits)
            max_commits = self.config.get('file_limits', {}).get('max_commits', 5)
            
            # Score based on commit count
            count_score = 100 if commit_count <= max_commits else max(50, 100 - (commit_count - max_commits) * 10)
            
            # Score based on commit message quality
            quality_scores = []
            commit_quality = self.config.get('commit_quality', {})
            good_patterns = commit_quality.get('good_patterns', [])
            poor_patterns = commit_quality.get('poor_patterns', [])
            min_length = commit_quality.get('min_message_length', 10)
            
            for commit in commits:
                # Extract message (remove hash)
                message = ' '.join(commit.split()[1:]) if commit.split() else ''
                score = 70  # Base score
                
                # Length check
                if len(message) < min_length:
                    score -= 20
                
                # Good patterns
                for pattern in good_patterns:
                    if re.search(pattern, message, re.IGNORECASE):
                        score += 15
                        break
                
                # Poor patterns
                for pattern in poor_patterns:
                    if re.search(pattern, message, re.IGNORECASE):
                        score -= 20
                        break
                
                quality_scores.append(max(0, min(100, score)))
            
            message_score = sum(quality_scores) / len(quality_scores) if quality_scores else 70
            
            # Combined score
            combined_score = (count_score * 0.4) + (message_score * 0.6)
            
            self.metrics['commit_count'] = commit_count
            self.metrics['commit_quality_score'] = message_score
            
            return combined_score
            
        except subprocess.CalledProcessError:
            return 70  # Default score if git commands fail

    def assess_configuration_safety(self, files: List[str]) -> float:
        """Assess safety of configuration file changes"""
        critical_configs = self.config.get('config_files', {}).get('critical_configs', [])
        dangerous_patterns = self.config.get('config_files', {}).get('dangerous_patterns', [])
        
        config_score = 100
        config_issues = []
        
        # Check for critical config file changes
        critical_files_changed = []
        for file_path in files:
            for pattern in critical_configs:
                if self._matches_pattern(file_path, pattern):
                    critical_files_changed.append(file_path)
                    config_score -= 15
        
        if critical_files_changed:
            config_issues.append(f"Critical config files changed: {critical_files_changed}")
        
        # Check for dangerous patterns in changed files
        for file_path in files:
            if os.path.exists(file_path) and self._is_text_file(file_path):
                try:
                    with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                        content = f.read()
                        
                    for pattern in dangerous_patterns:
                        if re.search(pattern, content, re.IGNORECASE):
                            config_issues.append(f"Dangerous pattern '{pattern}' in {file_path}")
                            config_score -= 25
                except Exception:
                    continue
        
        if config_issues:
            self.issues.append({
                'type': 'configuration',
                'severity': 'high',
                'message': 'Configuration safety concerns',
                'details': config_issues
            })
        
        return max(0, config_score)

    def assess_documentation(self, files: List[str]) -> float:
        """Assess documentation completeness"""
        doc_patterns = self.config.get('documentation', {}).get('doc_patterns', ['*.md'])
        required_docs = self.config.get('documentation', {}).get('required_docs', {})
        
        # Check if documentation files are included
        doc_files = []
        code_files = []
        
        for file_path in files:
            is_doc = any(self._matches_pattern(file_path, pattern) for pattern in doc_patterns)
            if is_doc:
                doc_files.append(file_path)
            else:
                code_files.append(file_path)
        
        # Base score based on doc-to-code ratio
        if not code_files:
            return 100
        
        doc_ratio = len(doc_files) / len(code_files) if code_files else 1
        base_score = min(100, 70 + (doc_ratio * 30))
        
        # Check for required documentation based on file changes
        missing_docs = []
        for doc_type, requirements in required_docs.items():
            patterns = requirements.get('patterns', [])
            required_doc_files = requirements.get('docs', [])
            
            # Check if any changed files match the patterns
            matches_pattern = any(
                any(self._matches_pattern(file_path, pattern) for pattern in patterns)
                for file_path in code_files
            )
            
            if matches_pattern:
                # Check if required docs are present
                for required_doc in required_doc_files:
                    if not any(self._matches_pattern(doc_file, required_doc) for doc_file in doc_files):
                        missing_docs.append(f"{doc_type}: {required_doc}")
        
        penalty = len(missing_docs) * 15
        final_score = max(0, base_score - penalty)
        
        if missing_docs:
            self.issues.append({
                'type': 'documentation',
                'severity': 'medium',
                'message': 'Missing required documentation',
                'details': missing_docs
            })
        
        self.metrics['doc_files'] = len(doc_files)
        self.metrics['code_files'] = len(code_files)
        
        return final_score

    def _matches_pattern(self, file_path: str, pattern: str) -> bool:
        """Check if file path matches a glob-like pattern"""
        import fnmatch
        return fnmatch.fnmatch(file_path, pattern)

    def _is_text_file(self, file_path: str) -> bool:
        """Check if file is likely a text file"""
        try:
            with open(file_path, 'rb') as f:
                chunk = f.read(1024)
                return b'\0' not in chunk
        except Exception:
            return False

    def calculate_overall_score(self, files: List[str]) -> Tuple[int, str, Dict]:
        """Calculate overall quality score and determine review type"""
        weights = self.config.get('quality_weights', {})
        
        # Calculate individual scores
        scores = {
            'file_count': self.assess_file_count(files),
            'file_size': self.assess_file_sizes(files),
            'security': self.assess_security(files),
            'commit_quality': self.assess_commit_quality(),
            'configuration': self.assess_configuration_safety(files),
            'documentation': self.assess_documentation(files)
        }
        
        # Calculate weighted overall score
        overall_score = 0
        for component, score in scores.items():
            weight = weights.get(component, 0)
            overall_score += score * weight
        
        overall_score = int(round(overall_score))
        
        # Determine review type based on thresholds
        thresholds = self.config.get('quality_thresholds', {})
        if overall_score >= thresholds.get('fast_track', 80):
            review_type = 'fast_track'
        elif overall_score >= thresholds.get('standard', 60):
            review_type = 'standard'
        else:
            review_type = 'enhanced'
        
        # Prepare detailed results
        results = {
            'overall_score': overall_score,
            'review_type': review_type,
            'component_scores': scores,
            'metrics': self.metrics,
            'issues': self.issues,
            'weights_used': weights
        }
        
        return overall_score, review_type, results

def main():
    parser = argparse.ArgumentParser(description='Jules Bot Quality Assessment')
    parser.add_argument('--config', default='.github/jules-config.yml', help='Configuration file path')
    parser.add_argument('--base-ref', default='origin/dev', help='Base reference for comparison')
    parser.add_argument('--output', help='Output file for results (JSON)')
    parser.add_argument('--github-output', action='store_true', help='Output for GitHub Actions')
    args = parser.parse_args()
    
    # Initialize assessment
    assessment = QualityAssessment(args.config)
    
    # Get changed files
    changed_files = assessment.get_changed_files(args.base_ref)
    
    if not changed_files:
        print("No changed files detected")
        if args.github_output:
            print("score=100")
            print("type=fast_track")
        return
    
    # Calculate quality score
    score, review_type, results = assessment.calculate_overall_score(changed_files)
    
    # Output results
    if args.github_output:
        print(f"score={score}")
        print(f"type={review_type}")
        print(f"issues={len(results['issues'])}")
        
        # Export detailed results as environment variable for later steps
        results_json = json.dumps(results, indent=2)
        with open(os.environ.get('GITHUB_ENV', '/dev/null'), 'a') as f:
            f.write(f"QUALITY_RESULTS<<EOF\n{results_json}\nEOF\n")
    else:
        print(f"Quality Score: {score}/100")
        print(f"Review Type: {review_type}")
        print(f"Files Changed: {len(changed_files)}")
        print(f"Issues Found: {len(results['issues'])}")
        
        if results['issues']:
            print("\nIssues:")
            for issue in results['issues']:
                print(f"  - {issue['type']} ({issue['severity']}): {issue['message']}")
    
    # Save detailed results if requested
    if args.output:
        with open(args.output, 'w') as f:
            json.dump(results, f, indent=2)
    
    return score

if __name__ == '__main__':
    sys.exit(0 if main() >= 60 else 1)  # Exit with error if score is too low
