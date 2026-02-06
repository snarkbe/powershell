#!/usr/bin/env python3
"""
VideoRenamer - Automatically rename video files based on naming patterns.
Supports TV series and movie formats with logging capabilities.
"""

import argparse
import os
import re
import sys
from datetime import datetime
from pathlib import Path
from typing import Optional, List


class VideoRenamer:
    """Renames video files based on detected patterns (series or movies)."""
    
    # Supported video extensions
    VIDEO_EXTENSIONS = {'.mkv', '.mp4', '.avi'}
    
    # Regex patterns (case-insensitive)
    # Supports: S01E01, S1E1, Season 01 Episode 01, Ep01, Episode 01
    SERIES_PATTERN = re.compile(
        r'(?i)^(?P<title>.+?)[\s\.]+(?:S(?P<season>\d{1,2})E(?P<episode>\d{1,2})|'
        r'Season\s+\d{1,2}\s+Episode\s+\d{1,2}|'
        r'Ep(?:isode)?\s+\d{1,2})\b.*\.(?P<ext>mkv|mp4|avi)$'
    )
    
    # Movie pattern: title with 4-digit year
    MOVIE_PATTERN = re.compile(
        r'(?i)^(?P<title>.+?)[\s\.](?P<year>\d{4})\b.*\.(?P<ext>mkv|mp4|avi)$'
    )
    
    def __init__(self, directory: str, enable_logging: bool = False):
        """
        Initialize VideoRenamer.
        
        Args:
            directory: Path to the directory containing video files
            enable_logging: Whether to create a log file
        """
        self.directory = Path(directory)
        self.enable_logging = enable_logging
        self.log_entries: List[str] = []
        self.log_file: Optional[Path] = None
        
        if not self.directory.exists():
            self.log_message(f"Directory '{directory}' does not exist.", "ERROR")
            sys.exit(1)
        
        if enable_logging:
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            self.log_file = self.directory / f"VideoRenamer_{timestamp}.log"
    
    def log_message(self, message: str, level: str = "INFO") -> None:
        """
        Log a message with timestamp and level.
        
        Args:
            message: The message to log
            level: Log level (INFO, WARN, SUCCESS, ERROR)
        """
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        log_entry = f"[{timestamp}] [{level}] {message}"
        
        print(log_entry)
        
        # Only store in log_entries if logging is enabled
        if self.enable_logging:
            self.log_entries.append(log_entry)
    
    def get_video_files(self) -> List[Path]:
        """
        Get all video files in the directory (non-recursive).
        
        Returns:
            List of Path objects for video files
        """
        video_files = []
        for file in self.directory.iterdir():
            if file.is_file() and file.suffix.lower() in self.VIDEO_EXTENSIONS:
                video_files.append(file)
        return sorted(video_files)
    
    def clean_title(self, title: str) -> str:
        """
        Clean title by replacing dots with spaces.
        
        Args:
            title: The title to clean
            
        Returns:
            Cleaned title
        """
        return title.replace('.', ' ')
    
    def process_series_file(self, file: Path) -> bool:
        """
        Process a series file and rename it if it matches the pattern.
        
        Args:
            file: Path to the file to process
            
        Returns:
            True if file was renamed, False otherwise
        """
        match = self.SERIES_PATTERN.match(file.name)
        if not match:
            return False
        
        title = self.clean_title(match.group('title'))
        season = int(match.group('season'))
        episode = int(match.group('episode'))
        ext = match.group('ext')
        
        new_name = f"{title} S{season:02d}E{episode:02d}.{ext}"
        new_path = file.parent / new_name
        
        if new_path.exists():
            self.log_message(
                f"File '{new_name}' already exists in directory.",
                "WARN"
            )
            return False
        
        try:
            file.rename(new_path)
            self.log_message(
                f"Renamed: '{file.name}' -> '{new_name}'",
                "SUCCESS"
            )
            return True
        except Exception as e:
            self.log_message(
                f"Failed to rename '{file.name}': {e}",
                "ERROR"
            )
            return False
    
    def process_movie_file(self, file: Path) -> bool:
        """
        Process a movie file and rename it if it matches the pattern.
        
        Args:
            file: Path to the file to process
            
        Returns:
            True if file was renamed, False otherwise
        """
        match = self.MOVIE_PATTERN.match(file.name)
        if not match:
            return False
        
        title = self.clean_title(match.group('title'))
        year = match.group('year')
        ext = match.group('ext')
        
        new_name = f"{title} ({year}).{ext}"
        new_path = file.parent / new_name
        
        if new_path.exists():
            self.log_message(
                f"File '{new_name}' already exists in directory.",
                "WARN"
            )
            return False
        
        try:
            file.rename(new_path)
            self.log_message(
                f"Renamed: '{file.name}' -> '{new_name}'",
                "SUCCESS"
            )
            return True
        except Exception as e:
            self.log_message(
                f"Failed to rename '{file.name}': {e}",
                "ERROR"
            )
            return False
    
    def process_file(self, file: Path) -> None:
        """
        Process a single video file, attempting to match series or movie patterns.
        
        Args:
            file: Path to the file to process
        """
        if self.process_series_file(file):
            return
        
        if self.process_movie_file(file):
            return
        
        self.log_message(
            f"File '{file.name}' does not match expected patterns (series or movie).",
            "WARN"
        )
    
    def run(self) -> None:
        """Main processing method."""
        video_files = self.get_video_files()
        
        if not video_files:
            self.log_message(f"No video files found in '{self.directory}'.", "INFO")
            return
        
        self.log_message(f"Found {len(video_files)} video file(s) to process.", "INFO")
        
        for file in video_files:
            self.process_file(file)
        
        self.log_message("Processing complete.", "INFO")
        
        # Save log file if logging is enabled
        if self.enable_logging and self.log_file:
            try:
                with open(self.log_file, 'w', encoding='utf-8') as f:
                    f.write('\n'.join(self.log_entries))
                print(f"\nLog saved to: {self.log_file}", flush=True)
            except Exception as e:
                print(f"Warning: Could not save log file: {e}", file=sys.stderr)


def main():
    """Entry point for the script."""
    parser = argparse.ArgumentParser(
        description='Automatically rename video files based on naming patterns.',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  python VideoRenamer.py "C:\\Videos"
  python VideoRenamer.py "C:\\Videos" --log
        """
    )
    
    parser.add_argument(
        'directory',
        help='Path to the directory containing video files'
    )
    
    parser.add_argument(
        '--log',
        action='store_true',
        help='Enable logging to a timestamped file in the target directory'
    )
    
    args = parser.parse_args()
    
    renamer = VideoRenamer(args.directory, enable_logging=args.log)
    renamer.run()


if __name__ == '__main__':
    main()
