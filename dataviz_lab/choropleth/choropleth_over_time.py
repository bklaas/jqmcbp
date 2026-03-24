import os
import sys
import base64
from pathlib import Path
import pandas as pd
import plotly.graph_objects as go
from PIL import Image
import io

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from db_config import get_connection

STATE_TO_ABBREV = {
    "Alabama": "AL", "Alaska": "AK", "Arizona": "AZ", "Arkansas": "AR",
    "California": "CA", "Colorado": "CO", "Connecticut": "CT", "Delaware": "DE",
    "District of Columbia": "DC", "Florida": "FL", "Georgia": "GA", "Hawaii": "HI",
    "Idaho": "ID", "Illinois": "IL", "Indiana": "IN", "Iowa": "IA", "Kansas": "KS",
    "Kentucky": "KY", "Louisiana": "LA", "Maine": "ME", "Maryland": "MD",
    "Massachusetts": "MA", "Michigan": "MI", "Minnesota": "MN", "Mississippi": "MS",
    "Missouri": "MO", "Montana": "MT", "Nebraska": "NE", "Nevada": "NV",
    "New Hampshire": "NH", "New Jersey": "NJ", "New Mexico": "NM", "New York": "NY",
    "North Carolina": "NC", "North Dakota": "ND", "Ohio": "OH", "Oklahoma": "OK",
    "Oregon": "OR", "Pennsylvania": "PA", "Rhode Island": "RI", "South Carolina": "SC",
    "South Dakota": "SD", "Tennessee": "TN", "Texas": "TX", "Utah": "UT",
    "Vermont": "VT", "Virginia": "VA", "Washington": "WA", "West Virginia": "WV",
    "Wisconsin": "WI", "Wyoming": "WY",
}

STATE_CENTERS = {
    "AL": (32.8, -86.8), "AK": (64.0, -153.0), "AZ": (34.2, -111.6),
    "AR": (34.8, -92.2), "CA": (37.0, -119.5), "CO": (39.0, -105.5),
    "CT": (41.6, -72.7), "DE": (39.0, -75.5), "DC": (38.9, -77.0),
    "FL": (27.8, -81.7), "GA": (32.7, -83.4), "HI": (20.5, -157.5),
    "ID": (44.4, -114.6), "IL": (40.0, -89.2), "IN": (39.8, -86.2),
    "IA": (42.0, -93.5), "KS": (38.5, -98.3), "KY": (37.5, -84.2),
    "LA": (31.0, -92.8), "ME": (45.4, -69.2), "MD": (39.0, -76.7),
    "MA": (42.2, -71.8), "MI": (43.6, -84.8), "MN": (46.3, -94.3),
    "MS": (32.6, -89.7), "MO": (38.4, -92.5), "MT": (47.0, -109.6),
    "NE": (41.5, -99.8), "NV": (39.3, -116.6), "NH": (43.7, -71.6),
    "NJ": (40.1, -74.7), "NM": (34.4, -106.1), "NY": (42.9, -75.5),
    "NC": (35.5, -79.8), "ND": (47.4, -100.5), "OH": (40.4, -82.8),
    "OK": (35.6, -97.4), "OR": (44.0, -120.5), "PA": (40.9, -77.8),
    "RI": (41.7, -71.5), "SC": (33.9, -80.9), "SD": (44.4, -100.2),
    "TN": (35.9, -86.4), "TX": (31.5, -99.3), "UT": (39.3, -111.7),
    "VT": (44.1, -72.6), "VA": (37.5, -78.8), "WA": (47.4, -120.5),
    "WV": (38.6, -80.6), "WI": (44.6, -89.7), "WY": (43.0, -107.5),
}

CALLOUT_STATES = {
    "VT": (47.2, -66.0),
    "NH": (46.1, -66.0),
    "MA": (45.0, -66.0),
    "CT": (43.9, -66.0),
    "RI": (42.8, -66.0),
    "NJ": (41.7, -66.0),
    "DE": (40.6, -66.0),
    "MD": (39.5, -66.0),
    "DC": (38.4, -66.0),
}

ALL_US_CODES = list(STATE_TO_ABBREV.values())

# Database configs per year: (db_name, table, has_man_or_chimp)
YEAR_DBS = [
    (2000, "jq_2000", "players", False),
    (2001, "jq_2001", "player_info", False),
    (2002, "jq_2002", "player_info", False),
    (2003, "jq_2003", "player_info", False),
    (2004, "jq_2004", "player_info", False),
    (2005, "jq_2005", "player_info", False),
    (2006, "jq_2006", "player_info", True),
    (2007, "jq_2007", "player_info", True),
    (2008, "jq_2008", "player_info", True),
    (2009, "jq_2009", "player_info", True),
    (2012, "jq_2012", "player_info", True),
    (2013, "jq_2013", "player_info", True),
    (2014, "jq_2014", "player_info", True),
    (2015, "jq_2015", "player_info", True),
    (2016, "jq_2016", "player_info", True),
    (2017, "jq_2017", "player_info", True),
    (2018, "jq_2018", "player_info", True),
    (2019, "jq_2019", "player_info", True),
    (2020, "jq_2020", "player_info", True),
    (2021, "jq_2021", "player_info", True),
    (2022, "jq_2022", "player_info", True),
    (2023, "jq_2023", "player_info", True),
    (2024, "jq_2024", "player_info", True),
    (2025, "jq_2025", "player_info", True),
    (2026, "johnnyquest", "player_info", True),
]

# Fixed color scale max so all frames use the same scale
ZMAX = 200

# Logo
logo_path = Path(__file__).resolve().parents[2] / "web" / "2026" / "graphs" / "jq_graph_logo.gif"
with open(logo_path, "rb") as f:
    logo_b64 = base64.b64encode(f.read()).decode()


def fetch_year_data(cursor, db_name, table, has_man_or_chimp):
    if has_man_or_chimp:
        query = f"""
            SELECT location, COUNT(*) as players
            FROM {db_name}.{table}
            WHERE man_or_chimp = 'man'
              AND location IS NOT NULL AND location != ''
            GROUP BY location
            ORDER BY players DESC
        """
    else:
        query = f"""
            SELECT location, COUNT(*) as players
            FROM {db_name}.{table}
            WHERE location IS NOT NULL AND location != ''
            GROUP BY location
            ORDER BY players DESC
        """
    cursor.execute(query)
    df = pd.DataFrame(cursor.fetchall(), columns=["location", "players"])
    df["code"] = df["location"].map(STATE_TO_ABBREV)
    non_us = df[df["code"].isna()].copy()
    df = df.dropna(subset=["code"])

    # Fill missing states with zero
    present_codes = set(df["code"])
    abbrev_to_name = {v: k for k, v in STATE_TO_ABBREV.items()}
    for code in ALL_US_CODES:
        if code not in present_codes:
            df = pd.concat([df, pd.DataFrame([{"location": abbrev_to_name[code], "players": 0, "code": code}])], ignore_index=True)

    return df, non_us


def render_frame(df, non_us, year):
    """Render a single year's choropleth as a PNG image bytes."""
    callout_codes = set(CALLOUT_STATES.keys())
    df_normal = df[~df["code"].isin(callout_codes)].copy()
    df_callout = df[df["code"].isin(callout_codes)].copy()

    df_normal["label"] = "<b>" + df_normal["code"] + "<br>" + df_normal["players"].astype(str) + "</b>"
    df_callout["label"] = "<b>" + df_callout["code"] + " " + df_callout["players"].astype(str) + "</b>"

    df_zero = df[df["players"] == 0]
    df_nonzero = df[df["players"] > 0]

    fig = go.Figure()

    if not df_zero.empty:
        fig.add_trace(go.Choropleth(
            locations=df_zero["code"],
            z=[0] * len(df_zero),
            locationmode="USA-states",
            colorscale=[[0, "#d9d9d9"], [1, "#d9d9d9"]],
            showscale=False,
            hoverinfo="skip",
        ))

    fig.add_trace(go.Choropleth(
        locations=df_nonzero["code"],
        z=df_nonzero["players"],
        locationmode="USA-states",
        colorscale=[[0, "#ffffcc"], [0.25, "#a1dab4"], [0.5, "#41b6c4"], [0.75, "#2c7fb8"], [1, "#253494"]],
        colorbar=dict(title=dict(text="Players", font=dict(size=18)), tickfont=dict(size=14), x=0.02, xanchor="left"),
        zmin=1,
        zmax=ZMAX,
        hoverinfo="skip",
    ))

    label_colors = ["white" if p >= 70 else "black" for p in df_normal["players"]]
    fig.add_trace(go.Scattergeo(
        lat=[STATE_CENTERS[c][0] for c in df_normal["code"]],
        lon=[STATE_CENTERS[c][1] for c in df_normal["code"]],
        text=df_normal["label"].tolist(),
        mode="text",
        textfont=dict(size=11, color=label_colors, family="Arial Black"),
        hoverinfo="skip",
        showlegend=False,
    ))

    fig.add_trace(go.Scattergeo(
        lat=[CALLOUT_STATES[c][0] for c in df_callout["code"]],
        lon=[CALLOUT_STATES[c][1] for c in df_callout["code"]],
        text=df_callout["label"].tolist(),
        mode="text",
        textfont=dict(size=12, color="black", family="Arial Black"),
        hoverinfo="skip",
        showlegend=False,
    ))

    for code in df_callout["code"]:
        state_lat, state_lon = STATE_CENTERS[code]
        label_lat, label_lon = CALLOUT_STATES[code]
        fig.add_trace(go.Scattergeo(
            lat=[state_lat, label_lat],
            lon=[state_lon, label_lon],
            mode="lines",
            line=dict(width=1, color="gray"),
            hoverinfo="skip",
            showlegend=False,
        ))

    non_us_lines = [f"{row['location']}: {row['players']}" for _, row in non_us.iterrows()]
    non_us_text = " | ".join(non_us_lines) if non_us_lines else "None"

    fig.update_layout(
        title=dict(
            text=f"<b>JQMCBP {year} Participation by State</b>",
            font=dict(size=30),
            x=0.5,
        ),
        geo=dict(
            scope="usa",
            lakecolor="rgb(255, 255, 255)",
            bgcolor="rgba(0,0,0,0)",
        ),
        annotations=[dict(
            x=0.5, y=-0.05,
            xref="paper", yref="paper",
            text=f"<b>Outside US:</b> {non_us_text}",
            showarrow=False,
            font=dict(size=16),
        )],
        margin=dict(l=0, r=0, t=80, b=60),
        width=1200,
        height=750,
    )

    fig.add_layout_image(
        source=f"data:image/gif;base64,{logo_b64}",
        xref="paper", yref="paper",
        x=1, y=0,
        xanchor="right", yanchor="bottom",
        sizex=0.12, sizey=0.12,
    )

    img_bytes = fig.to_image(format="png", scale=2)
    return Image.open(io.BytesIO(img_bytes))


# Main
conn = get_connection()
cursor = conn.cursor()

frames = []
for year, db_name, table, has_moc in YEAR_DBS:
    print(f"Rendering {year}...")
    try:
        df, non_us = fetch_year_data(cursor, db_name, table, has_moc)
        frame = render_frame(df, non_us, year)
        frames.append(frame)
    except Exception as e:
        print(f"  Skipping {year}: {e}")

cursor.close()
conn.close()

if frames:
    out = "choropleth_over_time.gif"
    # 2s per frame, 10s on the last (current year)
    durations = [2000] * (len(frames) - 1) + [10000]
    frames[0].save(
        out,
        save_all=True,
        append_images=frames[1:],
        duration=durations,
        loop=0,
    )
    print(f"Saved {out} ({len(frames)} frames)")
else:
    print("No frames generated!")
