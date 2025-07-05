#!/usr/bin/env python3
"""
Convert tags from space-separated strings to YAML inline lists.
Also replace underscores with spaces in tag values.
"""
import os
import re
import glob

def convert_tags_in_file(file_path):
    """Convert tags in a single file from string to YAML list format."""
    print(f"Processing {file_path}")
    
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Find the tags line using regex
    tags_pattern = r'^tags:\s*"([^"]+)"'
    match = re.search(tags_pattern, content, re.MULTILINE)
    
    if not match:
        print(f"  No tags found in {file_path}")
        return False
    
    tags_string = match.group(1)
    print(f"  Found tags: {tags_string}")
    
    # Split by spaces and clean up
    tag_items = tags_string.split()
    
    # Process each tag: replace underscores with spaces
    processed_tags = []
    for tag in tag_items:
        # Replace underscores with spaces
        clean_tag = tag.replace('_', ' ')
        processed_tags.append(clean_tag)
    
    # Create YAML inline list format
    yaml_list = '[' + ', '.join(processed_tags) + ']'
    
    # Replace the old tags line with the new one
    new_content = re.sub(tags_pattern, f'tags: {yaml_list}', content, flags=re.MULTILINE)
    
    # Write back to file
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    print(f"  Updated to: tags: {yaml_list}")
    return True

def main():
    """Convert tags in all markdown files."""
    # Find all markdown files with tags
    files_to_process = []
    
    for pattern in ['_news/*.md', '_posts/*.md']:
        files_to_process.extend(glob.glob(pattern))
    
    converted_count = 0
    
    for file_path in files_to_process:
        if os.path.exists(file_path):
            if convert_tags_in_file(file_path):
                converted_count += 1
    
    print(f"\nConversion complete! Updated {converted_count} files.")

if __name__ == '__main__':
    main()
