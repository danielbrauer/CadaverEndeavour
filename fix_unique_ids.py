#!/usr/bin/env python3
"""
Script to automatically fix duplicate unique_id conflicts by removing
unique_id from instance nodes (nodes that instance other scenes).
"""

import re
import os
from pathlib import Path
from collections import defaultdict

def find_instance_nodes_with_unique_ids(root_dir="."):
    """Find all instance nodes that have unique_id attributes."""
    issues = []
    
    root_path = Path(root_dir)
    
    for tscn_file in root_path.rglob("*.tscn"):
        if ".git" in str(tscn_file) or "node_modules" in str(tscn_file):
            continue
            
        try:
            with open(tscn_file, 'r', encoding='utf-8') as f:
                content = f.read()
                lines = content.split('\n')
                
                for line_num, line in enumerate(lines, 1):
                    if 'instance=' in line and 'unique_id=' in line:
                        issues.append({
                            'file': str(tscn_file.relative_to(root_path)),
                            'line_num': line_num,
                            'line': line
                        })
        except Exception as e:
            print(f"Error reading {tscn_file}: {e}", file=os.sys.stderr)
    
    return issues

def fix_instance_unique_ids(file_path, dry_run=True):
    """Remove unique_id from instance nodes in a file."""
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
        lines = content.split('\n')
    
    modified = False
    new_lines = []
    fixes = []
    
    for line in lines:
        if 'instance=' in line and 'unique_id=' in line:
            new_line = re.sub(r'\s+unique_id=\d+', '', line)
            if new_line != line:
                modified = True
                fixes.append(f"  Line {len(new_lines)+1}: Removed unique_id from instance node")
                new_lines.append(new_line)
            else:
                new_lines.append(line)
        else:
            new_lines.append(line)
    
    if modified and not dry_run:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write('\n'.join(new_lines))
    
    return modified, fixes

def main():
    import sys
    
    dry_run = '--fix' not in sys.argv
    
    if dry_run:
        print("🔍 DRY RUN MODE - No files will be modified")
        print("   Run with --fix to apply changes\n")
    else:
        print("🔧 FIX MODE - Files will be modified\n")
    
    root_path = Path(".")
    fixed_count = 0
    
    for tscn_file in root_path.rglob("*.tscn"):
        if ".git" in str(tscn_file) or "node_modules" in str(tscn_file):
            continue
        
        modified, fixes = fix_instance_unique_ids(tscn_file, dry_run=dry_run)
        
        if modified:
            fixed_count += 1
            print(f"📄 {tscn_file.relative_to(root_path)}")
            for fix in fixes:
                print(fix)
            print()
    
    if dry_run:
        print(f"\n✓ Found {fixed_count} files that would be fixed")
        print("  Run with --fix to apply changes")
    else:
        print(f"\n✓ Fixed {fixed_count} files")
    
    return 0

if __name__ == "__main__":
    exit(main())
