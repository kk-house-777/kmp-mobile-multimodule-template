#!/usr/bin/env python3
"""
Cookiecutter pre-generation hook for validating template variables.
"""
import re
import sys


def validate_project_name(project_name: str) -> bool:
    """
    Validate project name.
    - Must start with a letter (uppercase or lowercase)
    - Can contain alphanumeric characters, hyphens, and underscores
    - Cannot start or end with a hyphen or underscore
    """
    pattern = r'^[a-zA-Z][a-zA-Z0-9_-]*[a-zA-Z0-9]$|^[a-zA-Z]$'
    return bool(re.match(pattern, project_name))


def validate_bundle_id_prefix(bundle_id: str) -> bool:
    """
    Validate bundle ID prefix.
    - Must be in reverse domain format (e.g., com.example.app)
    - Each segment must start with a lowercase letter
    - Can only contain lowercase letters, numbers, and underscores
    """
    pattern = r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$'
    return bool(re.match(pattern, bundle_id))


def main():
    project_name = '{{ cookiecutter.project_name }}'
    bundle_id_prefix = '{{ cookiecutter.bundle_id_prefix }}'

    # Validate project name
    if not validate_project_name(project_name):
        print('ERROR: project_name must be a valid directory name.')
        print(f'       Given: "{project_name}"')
        print('       Rules:')
        print('         - Must start with a letter (a-z or A-Z)')
        print('         - Can contain letters, numbers, hyphens (-), and underscores (_)')
        print('         - Cannot start or end with a hyphen or underscore')
        print('       Examples: "MyApp", "my-app", "my_app", "kk-app"')
        sys.exit(1)

    # Validate bundle ID prefix
    if not validate_bundle_id_prefix(bundle_id_prefix):
        print('ERROR: bundle_id_prefix must be in reverse domain format.')
        print(f'       Given: "{bundle_id_prefix}"')
        print('       Example: "com.example.app", "jp.mycompany.myapp"')
        print('       Rules:')
        print('         - Each segment must start with a lowercase letter')
        print('         - Can only contain lowercase letters, numbers, and underscores')
        sys.exit(1)

    print(f'✓ Validation passed: {project_name} ({bundle_id_prefix})')


if __name__ == '__main__':
    main()
