import os
import sys
import base64
from pathlib import Path
import pandas as pd
import plotly.graph_objects as go

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

# Approximate lat/lon centers for state label placement
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

# Small states whose labels go out in the Atlantic with pointer lines
# (code) -> (label_lat, label_lon) in the ocean, stacked vertically
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

conn = get_connection(database=os.getenv("JQMCBP_DB", "johnnyquest"))
cursor = conn.cursor()
query = """
    SELECT location, COUNT(*) as players
    FROM player_info
    WHERE man_or_chimp = 'man'
    GROUP BY location
    ORDER BY players DESC
"""
cursor.execute(query)
df = pd.DataFrame(cursor.fetchall(), columns=["location", "players"])
cursor.close()
conn.close()

# Map state names to abbreviations, split US vs non-US
df["code"] = df["location"].map(STATE_TO_ABBREV)
non_us = df[df["code"].isna()].copy()
df = df.dropna(subset=["code"])

# Add rows for states with zero participants
present_codes = set(df["code"])
for code in ALL_US_CODES:
    if code not in present_codes:
        abbrev_to_name = {v: k for k, v in STATE_TO_ABBREV.items()}
        df = pd.concat([df, pd.DataFrame([{"location": abbrev_to_name[code], "players": 0, "code": code}])], ignore_index=True)

# Split into normal states and callout states
callout_codes = set(CALLOUT_STATES.keys())
df_normal = df[~df["code"].isin(callout_codes)].copy()
df_callout = df[df["code"].isin(callout_codes)].copy()

# Build bold text labels
df_normal["label"] = "<b>" + df_normal["code"] + "<br>" + df_normal["players"].astype(str) + "</b>"
df_callout["label"] = "<b>" + df_callout["code"] + " " + df_callout["players"].astype(str) + "</b>"

# Split data into zero and non-zero for different coloring
df_zero = df[df["players"] == 0]
df_nonzero = df[df["players"] > 0]

# Choropleth layer
fig = go.Figure()

# Gray layer for zero-participation states
if not df_zero.empty:
    fig.add_trace(go.Choropleth(
        locations=df_zero["code"],
        z=[0] * len(df_zero),
        locationmode="USA-states",
        colorscale=[[0, "#d9d9d9"], [1, "#d9d9d9"]],
        showscale=False,
        hovertemplate="<b>%{text}</b><br>Players: 0<extra></extra>",
        text=df_zero["location"],
    ))

# Colored layer for states with participants
fig.add_trace(go.Choropleth(
    locations=df_nonzero["code"],
    z=df_nonzero["players"],
    locationmode="USA-states",
    colorscale=[[0, "#ffffcc"], [0.25, "#a1dab4"], [0.5, "#41b6c4"], [0.75, "#2c7fb8"], [1, "#253494"]],
    colorbar=dict(title=dict(text="Players", font=dict(size=18)), tickfont=dict(size=14), x=0.02, xanchor="left"),
    hovertemplate="<b>%{text}</b><br>Players: %{z}<extra></extra>",
    text=df_nonzero["location"],
    zmin=1,
))

# Text labels on normal (large enough) states
# Use white text for dark (high-count) states
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

# Callout labels in the Atlantic
fig.add_trace(go.Scattergeo(
    lat=[CALLOUT_STATES[c][0] for c in df_callout["code"]],
    lon=[CALLOUT_STATES[c][1] for c in df_callout["code"]],
    text=df_callout["label"].tolist(),
    mode="text",
    textfont=dict(size=12, color="black", family="Arial Black"),
    hoverinfo="skip",
    showlegend=False,
))

# Pointer lines from callout labels to actual state centers
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

# Non-US annotation text
non_us_lines = []
for _, row in non_us.iterrows():
    non_us_lines.append(f"{row['location']}: {row['players']}")
non_us_text = " | ".join(non_us_lines)

fig.update_layout(
    title=dict(
        text="<b>JQMCBP 2026 Participation by State</b>",
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

# Add logo in lower right
logo_path = Path(__file__).resolve().parents[2] / "web" / "2026" / "graphs" / "jq_graph_logo.gif"
with open(logo_path, "rb") as f:
    logo_b64 = base64.b64encode(f.read()).decode()
fig.add_layout_image(
    source=f"data:image/gif;base64,{logo_b64}",
    xref="paper", yref="paper",
    x=1, y=0,
    xanchor="right", yanchor="bottom",
    sizex=0.12, sizey=0.12,
)

fig.write_html("choropleth.html")
print("Saved choropleth.html")

fig.write_image("choropleth.png", scale=2)
print("Saved choropleth.png")
