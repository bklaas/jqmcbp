#!/usr/bin/env -S uv run
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "pandas>=2.0.0",
#     "altair>=5.0.0",
#     "pymysql>=1.1.0",
#     "sqlalchemy>=2.0.0",
#     "python-dotenv>=1.0.0",
#     "vl-convert-python>=1.0.0",
# ]
# ///
"""
Modern Python replacement for entries_through_time.pl

Generates a line chart showing the rate of bracket entries over time
for multiple JQMCBP years. Produces PNG or SVG outputs.

Usage:
    uv run entries_through_time_modern.py [--format png|svg|both]
    
Or set up environment variables and run directly:
    ./entries_through_time_modern.py --format png
"""

import argparse
import base64
import os
import sys
from datetime import datetime, timezone
from pathlib import Path
from time import mktime
from typing import List, Dict, Optional

import pandas as pd
import altair as alt
from sqlalchemy import create_engine, text
from dotenv import load_dotenv


# ============================================================================
# CONFIGURATION VARIABLES - UPDATE THESE AS NEEDED
# ============================================================================

YEARS_OF_INTEREST = ['2026', '2025', '2024', '2017']
# YEARS_OF_INTEREST = ['2025', '2024', '2023', '2017']
# YEARS_OF_INTEREST = ['2022', '2020', '2019', '2018', '2017']

# Day of month when JQMCBP was announced (1-based)
START_TIMES = {
    '2005': 13, '2006': 12, '2007': 11, '2008': 16,
    '2009': 15, '2012': 11, '2013': 17, '2014': 16,
    '2015': 15, '2016': 13, '2017': 12, '2018': 11,
    '2019': 17, '2020': 17, '2021': 15, '2022': 13,
    '2023': 12, '2024': 17, '2025': 16, '2026': 15
}

CURRENT_YEAR = '2026'

# Time window: 91 hours = 327600 seconds
TIME_WINDOW_SECONDS = 327600
TIME_WINDOW_HOURS = 91

# Output configuration
OUTPUT_DIR = Path(__file__).parent
OUTPUT_PNG = OUTPUT_DIR / "entries_yeartoyear_modern.png"
OUTPUT_SVG = OUTPUT_DIR / "entries_yeartoyear_modern.svg"
LOGO_PATH = OUTPUT_DIR / "jq_graph_logo.png"

# Chart configuration
CHART_WIDTH = 800
CHART_HEIGHT = 600
Y_MAX = 900
COLORS = ['#1f77b4', '#2ca02c', '#d62728', '#000000', '#9467bd', '#00bfbf']

# ============================================================================
# DATABASE CONNECTION
# ============================================================================

def get_db_engine(database: str = "johnnyquest"):
    """Create SQLAlchemy engine for the specified database."""
    # Try to load from .env file first
    load_dotenv()
    
    # Get credentials from environment variables or use defaults
    user = os.getenv("JQMCBP_DB_USER", "root")
    password = os.getenv("JQMCBP_DB_PASS", "hoopoe")
    host = os.getenv("JQMCBP_DB_HOST", "localhost")
    port = os.getenv("JQMCBP_DB_PORT", "3306")
    
    connection_string = f"mysql+pymysql://{user}:{password}@{host}:{port}/{database}"
    return create_engine(connection_string, echo=False)


def get_timestamps_from_db(database: str) -> List[int]:
    """
    Fetch entry timestamps from the database for a specific year.
    
    Args:
        database: Database name (e.g., 'johnnyquest' or 'jq_2024')
    
    Returns:
        List of Unix timestamps sorted in ascending order
    """
    engine = get_db_engine(database)
    
    # Special handling for 2005 (no man_or_chimp field)
    if database == 'jq_2005':
        query = text("SELECT entry_time FROM player_info ORDER BY entry_time")
    else:
        query = text(
            "SELECT entry_time FROM player_info "
            "WHERE man_or_chimp = 'man' ORDER BY entry_time"
        )
    
    with engine.connect() as conn:
        result = conn.execute(query)
        timestamps = [row[0] for row in result]
    
    return timestamps


# ============================================================================
# DATA PROCESSING
# ============================================================================

def get_start_timestamp(year: str) -> int:
    """Get Unix timestamp for 5pm on the announcement day."""
    day = START_TIMES[year]
    # March is month 2 (0-indexed), time is 5pm = 17:00
    dt = datetime(int(year), 3, day, 17, 0, 0)
    return int(mktime(dt.timetuple()))


def compile_data_for_year(year: str) -> pd.DataFrame:
    """
    Compile entry data for a specific year.
    
    Args:
        year: Year string (e.g., '2024')
    
    Returns:
        DataFrame with columns: hours_elapsed, num_entries, year
    """
    # Determine database name
    if year == CURRENT_YEAR:
        database = 'johnnyquest'
    else:
        database = f'jq_{year}'
    
    # Get timestamps from database
    timestamps = get_timestamps_from_db(database)
    
    if not timestamps:
        print(f"Warning: No entries found for {year}", file=sys.stderr)
        return pd.DataFrame(columns=['hours_elapsed', 'num_entries', 'year'])
    
    # Calculate time boundaries
    start_time = get_start_timestamp(year)
    
    # For current year, use current time or end of window
    if year == CURRENT_YEAR:
        now = int(datetime.now().timestamp())
        time_elapsed = now - start_time
        end_time = start_time + min(time_elapsed, TIME_WINDOW_SECONDS)
    else:
        end_time = start_time + TIME_WINDOW_SECONDS
    
    # Sample every minute for smooth curves
    data = []
    current_ts_idx = 0
    
    for elapsed_seconds in range(0, end_time - start_time, 60):
        current_time = start_time + elapsed_seconds
        hours_elapsed = elapsed_seconds / 3600
        
        # Count entries up to this time
        while (current_ts_idx < len(timestamps) and 
               timestamps[current_ts_idx] <= current_time):
            current_ts_idx += 1
        
        data.append({
            'hours_elapsed': hours_elapsed,
            'num_entries': current_ts_idx,
            'year': year
        })
    
    return pd.DataFrame(data)


def compile_all_data() -> pd.DataFrame:
    """Compile data for all years of interest."""
    all_dfs = []
    
    for year in YEARS_OF_INTEREST:
        print(f"Processing {year}...")
        df = compile_data_for_year(year)
        all_dfs.append(df)
    
    return pd.concat(all_dfs, ignore_index=True)


# ============================================================================
# VISUALIZATION
# ============================================================================

def get_logo_data_uri() -> str:
    """
    Load the logo image and convert it to a data URI for embedding.
    
    Returns:
        Data URI string for the logo image
    """
    logo_path = LOGO_PATH
    if not logo_path.exists():
        # Fallback to GIF if PNG doesn't exist
        logo_path = OUTPUT_DIR / "jq_graph_logo.gif"
    
    if not logo_path.exists():
        print(f"Warning: Logo not found at {logo_path}", file=sys.stderr)
        return ""
    
    with open(logo_path, 'rb') as f:
        image_data = f.read()
    
    # Determine MIME type
    mime_type = 'image/png' if logo_path.suffix == '.png' else 'image/gif'
    
    # Encode as base64 and create data URI
    encoded = base64.b64encode(image_data).decode('utf-8')
    return f"data:{mime_type};base64,{encoded}"


def create_chart(df: pd.DataFrame) -> alt.Chart:
    """
    Create an Altair line chart from the data with logo in lower right.
    
    Args:
        df: DataFrame with columns: hours_elapsed, num_entries, year
    
    Returns:
        Altair Chart object
    """
    # Base line chart
    lines = alt.Chart(df).mark_line(
        strokeWidth=2,
        point=False
    ).encode(
        x=alt.X(
            'hours_elapsed:Q',
            title='Hours from JQMCBP Announcement',
            scale=alt.Scale(domain=[0, TIME_WINDOW_HOURS])
        ),
        y=alt.Y(
            'num_entries:Q',
            title='Number of Entries',
            scale=alt.Scale(domain=[0, Y_MAX])
        ),
        color=alt.Color(
            'year:N',
            title='Year',
            scale=alt.Scale(
                domain=YEARS_OF_INTEREST,
                range=COLORS[:len(YEARS_OF_INTEREST)]
            ),
            legend=alt.Legend(orient='right')
        ),
        tooltip=[
            alt.Tooltip('year:N', title='Year'),
            alt.Tooltip('hours_elapsed:Q', title='Hours', format='.1f'),
            alt.Tooltip('num_entries:Q', title='Entries')
        ]
    )
    
    # Logo in lower right corner
    # Position it at approximately 75 hours and 75 entries from bottom
    logo_uri = get_logo_data_uri()
    
    if logo_uri:
        logo_data = pd.DataFrame([{
            'x': TIME_WINDOW_HOURS - 15,  # 15 hours from right edge
            'y': 75,  # 75 entries from bottom
            'img': logo_uri
        }])
        
        logo = alt.Chart(logo_data).mark_image(
            width=100,
            height=100,
            opacity=0.8
        ).encode(
            x=alt.X('x:Q', scale=alt.Scale(domain=[0, TIME_WINDOW_HOURS])),
            y=alt.Y('y:Q', scale=alt.Scale(domain=[0, Y_MAX])),
            url='img:N'
        )
        
        # Layer the logo on top of the lines
        chart = alt.layer(lines, logo)
    else:
        # No logo available, just use the lines
        chart = lines
    
    # Apply common properties
    chart = chart.properties(
        width=CHART_WIDTH,
        height=CHART_HEIGHT,
        title={
            "text": "Rate of Entries",
            "fontSize": 18,
            "fontWeight": "bold"
        }
    ).configure_axis(
        labelFontSize=12,
        titleFontSize=14
    ).configure_legend(
        titleFontSize=13,
        labelFontSize=12
    )
    
    return chart


def save_chart(chart: alt.Chart, format: str = 'png'):
    """
    Save the chart in the specified format(s).
    
    Args:
        chart: Altair Chart object
        format: 'png', 'svg', or 'both'
    """
    if format in ('png', 'both'):
        # Save as PNG using vl-convert
        chart.save(str(OUTPUT_PNG), scale_factor=2.0)
        print(f"✓ Saved PNG to: {OUTPUT_PNG}")
    
    if format in ('svg', 'both'):
        # Save as SVG (vector format, scales perfectly)
        chart.save(str(OUTPUT_SVG))
        print(f"✓ Saved SVG to: {OUTPUT_SVG}")


# ============================================================================
# MAIN
# ============================================================================

def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Generate JQMCBP entry rate visualization"
    )
    parser.add_argument(
        '--format',
        choices=['png', 'svg', 'both'],
        default='png',
        help='Output format (default: png)'
    )
    
    args = parser.parse_args()
    
    print("=" * 60)
    print("JQMCBP Entry Rate Visualization (Modern Python Edition)")
    print("=" * 60)
    print(f"Years: {', '.join(YEARS_OF_INTEREST)}")
    print(f"Current year: {CURRENT_YEAR}")
    print()
    
    # Compile data from all years
    print("Fetching data from database...")
    df = compile_all_data()
    
    if df.empty:
        print("Error: No data found!", file=sys.stderr)
        sys.exit(1)
    
    print(f"✓ Collected {len(df)} data points")
    print()
    
    # Create visualization
    print("Creating visualization...")
    chart = create_chart(df)
    
    # Save outputs
    print(f"Saving chart ({args.format})...")
    save_chart(chart, format=args.format)
    
    print()
    print("=" * 60)
    print("Done! 🎉")
    print("=" * 60)


if __name__ == '__main__':
    main()
