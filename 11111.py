# -*- coding: utf-8 -*-
"""
Created on Sun May 18 10:19:41 2025

@author: hellpanderrr
"""

import os
import re
from datetime import datetime

def is_text_file(file_path):
    """Check if a file is a text file (heuristic, not foolproof)."""
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            file.read(1024)
        return True
    except (UnicodeDecodeError, IsADirectoryError, PermissionError, OSError):
        return False
    
def check_recovery_codes(file_path, max_size=1024):  # 100 MB
    """Check a single file for recovery codes (only if it has exactly 16 lines)."""
    if not is_text_file(file_path) or os.path.getsize(file_path) > max_size:
        return []

    # Count the number of lines in the file
    with open(file_path, 'r', encoding='utf-8', errors='ignore') as file:
        line_count = sum(1 for _ in file)

    # Proceed only if the file has exactly 16 lines
    if line_count != 16:
        return []

    pattern = r'\b[a-zA-Z0-9]{5}-[a-zA-Z0-9]{5}\b'
    matches = []
    with open(file_path, 'r', encoding='utf-8', errors='ignore') as file:
        for line in file:
            match = re.findall(pattern, line)
            if not match:
                return []
            matches.extend(match)
    return matches


def search_directory(root_dir, output_file):
    """Search for recovery codes in all files under root_dir (recursively)."""
    with open(output_file, 'w', encoding='utf-8') as outfile:
        for dirpath, _, filenames in os.walk(root_dir):
            for filename in filenames:
                file_path = os.path.join(dirpath, filename)
                matches = check_recovery_codes(file_path)
                if matches:
                    outfile.write(f"File: {file_path}\n")
                    outfile.write(f"Recovery Codes: {', '.join(matches)}\n\n")
                    print(f"Found recovery codes in: {file_path}")

if __name__ == "__main__":
    root_directory = input("Enter the root directory to search (e.g., C:\\): ") or 'C:\\'
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    output_filename = f"recovery_codes_{timestamp}.txt"

    print(f"Starting search in '{root_directory}'. Results will be saved to '{output_filename}'...")
    search_directory(root_directory, output_filename)
    print("Search completed.")
