#!/usr/bin/env python3
"""
Simple configuration validation for SOC components.
"""

import os
import sys
import json
import yaml
from pathlib import Path

def validate_yaml(file_path):
    """Validate YAML file syntax."""
    try:
        with open(file_path, 'r') as f:
            yaml.safe_load(f)
        return True, ""
    except yaml.YAMLError as e:
        return False, f"Invalid YAML: {str(e)}"

def validate_json(file_path):
    """Validate JSON file syntax."""
    try:
        with open(file_path, 'r') as f:
            json.load(f)
        return True, ""
    except json.JSONDecodeError as e:
        return False, f"Invalid JSON: {str(e)}"

def validate_docker_compose(file_path):
    """Basic Docker Compose validation."""
    try:
        with open(file_path, 'r') as f:
            content = yaml.safe_load(f)
        
        if not content or 'services' not in content:
            return False, "Missing 'services' section"
            
        for service_name, service in content['services'].items():
            if 'image' not in service and 'build' not in service:
                return False, f"Service '{service_name}' needs 'image' or 'build'"
                
        return True, ""
    except Exception as e:
        return False, f"Validation error: {str(e)}"

def validate_file(file_path):
    """Validate a configuration file."""
    if not os.path.exists(file_path):
        return False, "File not found"
    
    if file_path.endswith(('.yaml', '.yml')):
        if 'docker-compose' in file_path:
            return validate_docker_compose(file_path)
        return validate_yaml(file_path)
    elif file_path.endswith('.json'):
        return validate_json(file_path)
    
    return True, "Skipped (unsupported file type)"

def main():
    if len(sys.argv) < 2:
        print("Usage: python validate_configs.py <path_to_validate>")
        sys.exit(1)
    
    path = Path(sys.argv[1])
    if not path.exists():
        print(f"Error: Path '{path}' does not exist")
        sys.exit(1)
    
    print(f"Validating configurations in: {path}\n")
    
    success = True
    
    for root, _, files in os.walk(path):
        for file in files:
            if file.endswith(('.yaml', '.yml', '.json')):
                file_path = Path(root) / file
                is_valid, message = validate_file(file_path)
                status = "PASS" if is_valid else "FAIL"
                print(f"[{status}] {file_path}")
                if message:
                    print(f"  -> {message}")
                if not is_valid:
                    success = False
    
    if success:
        print("\nAll configurations are valid!")
        sys.exit(0)
    else:
        print("\nValidation failed. Please check the errors above.")
        sys.exit(1)

if __name__ == "__main__":
    main()
