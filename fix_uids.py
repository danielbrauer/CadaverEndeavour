#!/usr/bin/env python3
"""
Script to fix invalid UID references in .tscn files by removing UIDs
that don't match their corresponding .uid files, or by updating them.
"""

import re
import os
from pathlib import Path

def read_uid_file(resource_path):
    """Read the UID from a .uid file."""
    uid_path = Path(resource_path + ".uid")
    if uid_path.exists():
        try:
            with open(uid_path, 'r') as f:
                return f.read().strip()
        except:
            pass
    return None

def fix_tscn_file(tscn_path, dry_run=True):
    """Fix invalid UID references in a .tscn file."""
    with open(tscn_path, 'r', encoding='utf-8') as f:
        content = f.read()
        lines = content.split('\n')
    
    modified = False
    new_lines = []
    fixes = []
    
    for line in lines:
        # Match ext_resource lines with UIDs
        match = re.search(r'\[ext_resource.*uid="(uid://[^"]+)"[^]]*path="([^"]+)"', line)
        if match:
            uid_in_file = match.group(1)
            resource_path = match.group(2)
            
            # Get the actual UID from the .uid file
            actual_uid = read_uid_file(resource_path)
            
            if actual_uid and actual_uid != uid_in_file:
                # UID doesn't match - remove it and let Godot use the path
                new_line = re.sub(r' uid="uid://[^"]+"', '', line)
                if new_line != line:
                    modified = True
                    fixes.append(f"  Line {len(new_lines)+1}: Removed invalid UID '{uid_in_file}' for {resource_path}")
                    new_lines.append(new_line)
                else:
                    new_lines.append(line)
            elif not actual_uid:
                # No .uid file exists - remove the UID reference
                new_line = re.sub(r' uid="uid://[^"]+"', '', line)
                if new_line != line:
                    modified = True
                    fixes.append(f"  Line {len(new_lines)+1}: Removed UID (no .uid file) for {resource_path}")
                    new_lines.append(new_line)
                else:
                    new_lines.append(line)
            else:
                new_lines.append(line)
        else:
            new_lines.append(line)
    
    if modified and not dry_run:
        with open(tscn_path, 'w', encoding='utf-8') as f:
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
        
        modified, fixes = fix_tscn_file(tscn_file, dry_run=dry_run)
        
        if modified:
            fixed_count += 1
            print(f"📄 {tscn_file.relative_to(root_path)}")
            for fix in fixes:
                print(fix)
            print()
    
    if dry_run:
        print(f"\n✓ Found {fixed_count} files with invalid UID references")
        print("  Run with --fix to apply changes")
    else:
        print(f"\n✓ Fixed {fixed_count} files")
    
    return 0

if __name__ == "__main__":
    exit(main())
