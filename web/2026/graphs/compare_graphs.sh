#!/bin/bash
# Quick comparison script to run both old (Perl) and new (Python) versions
# and compare their outputs

echo "======================================"
echo "JQMCBP Entry Graph Comparison"
echo "======================================"
echo

# Run legacy Perl version
echo "Running legacy Perl version..."
time perl entries_through_time.pl
echo "✓ Legacy output: entries_yeartoyear.png"
echo

# Run modern Python version
echo "Running modern Python version..."
time uv run ./entries_through_time_modern.py --format both
echo "✓ Modern outputs: entries_yeartoyear_modern.{png,svg}"
echo

# Compare file sizes
echo "======================================"
echo "File Size Comparison:"
echo "======================================"
ls -lh entries_yeartoyear.png entries_yeartoyear_modern.png entries_yeartoyear_modern.svg 2>/dev/null | awk '{print $9, "\t", $5}'
echo

echo "======================================"
echo "View outputs at:"
echo "  Legacy:     file://$(pwd)/entries_yeartoyear.png"
echo "  Modern PNG: file://$(pwd)/entries_yeartoyear_modern.png"
echo "  Modern SVG: file://$(pwd)/entries_yeartoyear_modern.svg"
echo "======================================"
