#!/usr/bin/env python3
"""
Script to find duplicate unique_id values in Godot .tscn files.
Godot requires unique_id to be unique across the entire project.
"""

import re
import os
from collections import defaultdict
from pathlib import Path

def find_duplicate_unique_ids(root_dir="."):
    """Find all duplicate unique_id values in .tscn files."""
    ids = defaultdict(list)
    
    root_path = Path(root_dir)
    
    for tscn_file in root_path.rglob("*.tscn"):
        if ".git" in str(tscn_file) or "node_modules" in str(tscn_file):
            continue
            
        try:
            with open(tscn_file, 'r', encoding='utf-8') as f:
                for line_num, line in enumerate(f, 1):
                    matches = re.finditer(r'unique_id=(\d+)', line)
                    for m in matches:
                        unique_id = m.group(1)
                        node_match = re.search(r'\[node\s+name="([^"]+)"[^\]]*unique_id=' + unique_id, line)
                        node_name = node_match.group(1) if node_match else "unknown"
                        ids[unique_id].append({
                            'file': str(tscn_file.relative_to(root_path)),
                            'line': line_num,
                            'line_content': line.strip()[:100],
                            'node_name': node_name
                        })
        except Exception as e:
            print(f"Error reading {tscn_file}: {e}", file=os.sys.stderr)
    
    duplicates = {uid: locations for uid, locations in ids.items() if len(locations) > 1}
    return duplicates

def analyze_conflicts(duplicates):
    """Analyze which conflicts are most critical."""
    critical = []
    warnings = []
    
    for uid, locations in duplicates.items():
        files = [loc['file'] for loc in locations]
        unique_files = set(files)
        
        if len(unique_files) == 1:
            warnings.append({
                'uid': uid,
                'locations': locations,
                'reason': 'Same file, multiple nodes with same unique_id'
            })
        else:
            critical.append({
                'uid': uid,
                'locations': locations,
                'reason': 'Multiple files share the same unique_id'
            })
    
    return critical, warnings

def print_report(duplicates):
    """Print a formatted report of duplicate unique_ids."""
    if not duplicates:
        print("✓ No duplicate unique_id values found!")
        return
    
    critical, warnings = analyze_conflicts(duplicates)
    
    print(f"\n{'='*80}")
    print(f"Found {len(duplicates)} duplicate unique_id values")
    print(f"  - {len(critical)} critical conflicts (across multiple files)")
    print(f"  - {len(warnings)} warnings (same file)")
    print(f"{'='*80}\n")
    
    if critical:
        print("🚨 CRITICAL CONFLICTS (across multiple files):")
        print("-" * 80)
        for conflict in sorted(critical, key=lambda x: len(x['locations']), reverse=True):
            uid = conflict['uid']
            locations = conflict['locations']
            print(f"\nunique_id={uid} appears {len(locations)} times:")
            
            for loc in locations:
                print(f"  📄 {loc['file']}:{loc['line']}")
                print(f"     Node: {loc['node_name']}")
                print(f"     {loc['line_content']}")
    
    if warnings:
        print("\n⚠️  WARNINGS (same file, multiple nodes):")
        print("-" * 80)
        for warning in warnings:
            uid = warning['uid']
            locations = warning['locations']
            print(f"\nunique_id={uid} appears {len(locations)} times in {locations[0]['file']}:")
            for loc in locations:
                print(f"  Line {loc['line']}: {loc['node_name']} - {loc['line_content'][:60]}")
    
    print(f"\n{'='*80}")
    print("\n💡 RECOMMENDATIONS:")
    print("  1. Remove unique_id from instance nodes (nodes that instance other scenes)")
    print("  2. Let Godot auto-generate unique_ids for new nodes")
    print("  3. Only use unique_id when you need to reference a specific node")
    print(f"{'='*80}\n")

def main():
    print("Scanning for duplicate unique_id values...")
    duplicates = find_duplicate_unique_ids()
    print_report(duplicates)
    
    if duplicates:
        return 1
    return 0

if __name__ == "__main__":
    exit(main())
