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
CHART_HEIGHT = 800
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
    
    # Sample once per hour for highly visible smooth curve interpolation
    data = []
    current_ts_idx = 0
    
    for elapsed_seconds in range(0, end_time - start_time, 3600):
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


def get_current_year_status(df: pd.DataFrame) -> Dict:
    """
    Get current status information for the current year.
    
    Args:
        df: Complete data DataFrame
    
    Returns:
        Dict with current_hours, current_entries, and comparison data
    """
    # Get current year data
    current_df = df[df['year'] == CURRENT_YEAR]
    
    if current_df.empty:
        return None
    
    # Get the last (most recent) data point
    last_row = current_df.iloc[-1]
    current_hours = last_row['hours_elapsed']
    current_entries = last_row['num_entries']
    
    # Get all years' entry counts at approximately the same elapsed time
    comparisons = []
    for year in YEARS_OF_INTEREST:
        year_df = df[df['year'] == year]
        if not year_df.empty:
            # Find closest time point to current_hours
            closest_idx = (year_df['hours_elapsed'] - current_hours).abs().idxmin()
            closest_row = year_df.loc[closest_idx]
            comparisons.append({
                'year': year,
                'entries': int(closest_row['num_entries']),
                'hours': closest_row['hours_elapsed']
            })
    
    return {
        'current_hours': current_hours,
        'current_entries': int(current_entries),
        'comparisons': comparisons
    }


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


def create_chart(df: pd.DataFrame, status: Optional[Dict] = None) -> alt.Chart:
    """
    Create an Altair line chart from the data with logo in lower right.
    
    Args:
        df: DataFrame with columns: hours_elapsed, num_entries, year
        status: Optional dict with current year status information
    
    Returns:
        Altair Chart object
    """
    # Base line chart
    lines = alt.Chart(df).mark_line(
        strokeWidth=2,
        point=False,
        interpolate='monotone'
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
    
    layers = [lines]
    
    # Add current year enhancements if we have status info
    if status and status['current_hours'] < TIME_WINDOW_HOURS:
        current_hours = status['current_hours']
        current_entries = status['current_entries']
        
        # 1. Add a vertical line at current time
        vline_data = pd.DataFrame([{
            'x': current_hours,
            'y': 0,
            'y2': Y_MAX
        }])
        
        vline = alt.Chart(vline_data).mark_rule(
            strokeDash=[5, 5],
            opacity=0.7,
            color='#666666',
            strokeWidth=1.5
        ).encode(
            x=alt.X('x:Q', scale=alt.Scale(domain=[0, TIME_WINDOW_HOURS])),
            y=alt.Y('y:Q', scale=alt.Scale(domain=[0, Y_MAX])),
            y2='y2:Q'
        )
        layers.append(vline)
        
        # 2. Add a marker point at the end of current year line
        marker_data = pd.DataFrame([{
            'hours': current_hours,
            'entries': current_entries,
            'year': CURRENT_YEAR
        }])
        
        marker = alt.Chart(marker_data).mark_point(
            size=225,
            filled=True,
            color=COLORS[YEARS_OF_INTEREST.index(CURRENT_YEAR)]
        ).encode(
            x=alt.X('hours:Q', scale=alt.Scale(domain=[0, TIME_WINDOW_HOURS])),
            y=alt.Y('entries:Q', scale=alt.Scale(domain=[0, Y_MAX])),
            tooltip=[
                alt.Tooltip('year:N', title='Year'),
                alt.Tooltip('hours:Q', title='Hours', format='.1f'),
                alt.Tooltip('entries:Q', title='Current Entries')
            ]
        )
        layers.append(marker)
        
        # 3. Create comparison table as text annotations
        # Position in upper left area
        table_x = 5
        table_y = Y_MAX - 50
        line_spacing = 38
        
        # Table header
        table_texts = []
        table_texts.append({
            'x': table_x,
            'y': table_y,
            'text': f'Entries at {current_hours:.1f} hours:',
            'size': 12,
            'bold': True
        })
        
        # Table rows - one per year
        for i, comp in enumerate(status['comparisons']):
            y_pos = table_y - (i + 1) * line_spacing
            is_current = comp['year'] == CURRENT_YEAR
            year_color_idx = YEARS_OF_INTEREST.index(comp['year'])
            
            # Year name and entry count
            prefix = '► ' if is_current else '   '
            text = f"{prefix}{comp['year']}: {comp['entries']:,}"
            
            table_texts.append({
                'x': table_x,
                'y': y_pos,
                'text': text,
                'size': 11,
                'bold': is_current
            })
        
        # Create text annotations for table
        table_df = pd.DataFrame(table_texts)
        
        # Split into bold and normal text for different mark properties
        bold_df = table_df[table_df['bold']]
        normal_df = table_df[~table_df['bold']]
        
        # Create separate text marks for bold and normal
        table_layers = []
        
        if not bold_df.empty:
            # Header text - size 12
            header_df = bold_df[bold_df['size'] == 12]
            if not header_df.empty:
                table_header = alt.Chart(header_df).mark_text(
                    align='left',
                    baseline='top',
                    dx=5,
                    dy=-5,
                    fontWeight='bold',
                    fontSize=12
                ).encode(
                    x=alt.X('x:Q', scale=alt.Scale(domain=[0, TIME_WINDOW_HOURS])),
                    y=alt.Y('y:Q', scale=alt.Scale(domain=[0, Y_MAX])),
                    text='text:N'
                )
                table_layers.append(table_header)
            
            # Bold row text (current year) - size 11
            bold_row_df = bold_df[bold_df['size'] == 11]
            if not bold_row_df.empty:
                table_bold_row = alt.Chart(bold_row_df).mark_text(
                    align='left',
                    baseline='top',
                    dx=5,
                    dy=-5,
                    fontWeight='bold',
                    fontSize=11
                ).encode(
                    x=alt.X('x:Q', scale=alt.Scale(domain=[0, TIME_WINDOW_HOURS])),
                    y=alt.Y('y:Q', scale=alt.Scale(domain=[0, Y_MAX])),
                    text='text:N'
                )
                table_layers.append(table_bold_row)
        
        if not normal_df.empty:
            # Normal row text - size 11
            table_normal = alt.Chart(normal_df).mark_text(
                align='left',
                baseline='top',
                dx=5,
                dy=-5,
                fontSize=11
            ).encode(
                x=alt.X('x:Q', scale=alt.Scale(domain=[0, TIME_WINDOW_HOURS])),
                y=alt.Y('y:Q', scale=alt.Scale(domain=[0, Y_MAX])),
                text='text:N'
            )
            table_layers.append(table_normal)
        
        if table_layers:
            table = alt.layer(*table_layers)
            layers.append(table)
        
        # Add semi-transparent background for table
        table_bg_data = pd.DataFrame([{
            'x': table_x - 2,
            'y': table_y + 20,
            'x2': table_x + 22,
            'y2': table_y - len(status['comparisons']) * line_spacing - 10
        }])
        
        table_bg = alt.Chart(table_bg_data).mark_rect(
            opacity=0.85,
            color='white',
            stroke='lightgray',
            strokeWidth=1
        ).encode(
            x=alt.X('x:Q', scale=alt.Scale(domain=[0, TIME_WINDOW_HOURS])),
            y=alt.Y('y:Q', scale=alt.Scale(domain=[0, Y_MAX])),
            x2='x2:Q',
            y2='y2:Q'
        )
        # Insert background before table text
        layers.insert(-1, table_bg)
    
    # Logo in lower right corner
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
        layers.append(logo)
    
    # Layer all components
    chart = alt.layer(*layers).properties(
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
        # Save as PNG to match Perl output dimensions (no upscaling)
        chart.save(str(OUTPUT_PNG))
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
    
    # Get current year status for annotations
    status = get_current_year_status(df)
    if status:
        print(f"✓ Current year ({CURRENT_YEAR}) status: {status['current_entries']} entries at {status['current_hours']:.1f} hours")
        print()
    
    # Create visualization
    print("Creating visualization...")
    chart = create_chart(df, status=status)
    
    # Save outputs
    print(f"Saving chart ({args.format})...")
    save_chart(chart, format=args.format)
    
    print()
    print("=" * 60)
    print("Done! 🎉")
    print("=" * 60)


if __name__ == '__main__':
    main()
