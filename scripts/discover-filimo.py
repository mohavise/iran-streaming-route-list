#!/usr/bin/env python3
"""Compatibility wrapper after project rename/rebuild.
Use scripts/discover-iran-streaming.py for the real discovery logic.
"""
import runpy
from pathlib import Path

runpy.run_path(str(Path(__file__).with_name("discover-iran-streaming.py")), run_name="__main__")
