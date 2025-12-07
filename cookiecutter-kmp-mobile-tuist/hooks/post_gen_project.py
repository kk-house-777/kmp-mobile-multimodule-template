#!/usr/bin/env python3
"""
Cookiecutter post-generation hook for setting up the generated project.
"""
import os
import shutil
from pathlib import Path


def move_package_directories():
    """
    Move Kotlin package directories from template placeholder to actual package path.
    Example: kk/tuist/app -> com/example/myapp
    """
    project_root = Path.cwd()
    bundle_id_prefix = '{{ cookiecutter.bundle_id_prefix }}'
    package_path = bundle_id_prefix.replace('.', '/')

    # Source and destination base paths
    template_package_path = 'kk/tuist/app'

    # Directories to process
    kotlin_dirs = [
        project_root / 'android-app' / 'src' / 'androidMain' / 'kotlin',
        project_root / 'android-app' / 'src' / 'androidUnitTest' / 'kotlin',
        project_root / 'kmp-libraries' / 'feature' / 'src' / 'commonMain' / 'kotlin',
        project_root / 'kmp-libraries' / 'feature' / 'src' / 'commonTest' / 'kotlin',
        project_root / 'kmp-libraries' / 'feature' / 'src' / 'androidMain' / 'kotlin',
        project_root / 'kmp-libraries' / 'feature' / 'src' / 'iosMain' / 'kotlin',
    ]

    for kotlin_dir in kotlin_dirs:
        if not kotlin_dir.exists():
            continue

        src_dir = kotlin_dir / template_package_path
        if not src_dir.exists():
            continue

        # Create destination directory
        dest_dir = kotlin_dir / package_path
        dest_dir.parent.mkdir(parents=True, exist_ok=True)

        # Move the directory
        if src_dir.exists():
            shutil.move(str(src_dir), str(dest_dir))
            print(f'  Moved: {src_dir.relative_to(project_root)} -> {dest_dir.relative_to(project_root)}')

        # Clean up empty parent directories (kk/tuist/app -> remove kk/tuist/app, kk/tuist, kk)
        # Build the full path hierarchy and clean from deepest to shallowest
        parts = template_package_path.split('/')
        for i in range(len(parts), 0, -1):
            partial_path = '/'.join(parts[:i])
            cleanup_path = kotlin_dir / partial_path
            try:
                # Check if directory exists and is empty
                if cleanup_path.exists() and cleanup_path.is_dir():
                    # List directory contents
                    if not any(cleanup_path.iterdir()):
                        # Directory is empty, remove it
                        cleanup_path.rmdir()
                        print(f'  Cleaned up: {cleanup_path.relative_to(project_root)}')
                    else:
                        # Directory not empty, stop cleanup
                        break
            except (OSError, StopIteration):
                # Error occurred, stop cleanup
                break


def print_success_message():
    """Print success message with next steps."""
    project_name = '{{ cookiecutter.project_name }}'
    bundle_id = '{{ cookiecutter.bundle_id_prefix }}'

    print()
    print('=' * 60)
    print(f'✅ Project "{project_name}" has been successfully created!')
    print('=' * 60)
    print()
    print(f'📁 Project directory: {os.getcwd()}')
    print(f'📦 Bundle ID prefix: {bundle_id}')
    print()
    print('Next steps:')
    print(f'  1. cd {project_name}')
    print('  2. mise install              # Install Tuist and other tools')
    print('  3. ./gradlew build           # Build Android app')
    print('  4. cd ios && tuist generate  # Generate Xcode project')
    print()
    print('Happy coding!')
    print()


def main():
    print()
    print('Running post-generation hooks...')
    print()

    # Move package directories
    print('📦 Moving package directories...')
    move_package_directories()

    # Print success message
    print_success_message()


if __name__ == '__main__':
    main()
