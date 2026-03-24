"""Generate additional visualizations using Altair.

Reads extras CSV files and produces 5 PNG charts:
  1. Darwin Number Analysis (Man vs Chimp)
  2. Upset Prediction Accuracy vs Score
  3. Elimination Curves by Year
  4. Year-over-Year Consistency (repeat players)
  5. Geographic Success by State
"""

from pathlib import Path

import altair as alt
import pandas as pd

OUT_DIR = Path(__file__).resolve().parent
DATA_DIR = OUT_DIR


def chart1_darwin():
    """Darwin Number Analysis: histogram + what fraction of humans are beaten by chimps."""
    df = pd.read_csv(DATA_DIR / "extras_darwin.csv")
    df = df[df["year"] != 2020]

    hist = alt.Chart(df).mark_bar(opacity=0.7, color="steelblue").encode(
        x=alt.X("darwin:Q", bin=alt.Bin(step=50), title="Darwin Number (chimps scoring at or above you)"),
        y=alt.Y("count()", title="Number of Human Players"),
    )

    zero_line = alt.Chart(
        pd.DataFrame({"x": [0], "label": ["Darwin=0: beat all chimps"]})
    ).mark_rule(color="green", strokeWidth=2, strokeDash=[6, 3]).encode(x="x:Q")

    zero_text = alt.Chart(
        pd.DataFrame({"x": [5], "label": ["Darwin=0"]})
    ).mark_text(align="left", dy=-10, color="green", fontSize=11, fontWeight="bold").encode(
        x="x:Q", text="label:N",
    )

    # Stat annotations
    total = len(df)
    beaten_by_any = len(df[df["darwin"] > 0])
    pct = beaten_by_any / total * 100

    stat_text = alt.Chart(pd.DataFrame({
        "x": [df["darwin"].max() * 0.6],
        "y": [df.groupby(pd.cut(df["darwin"], bins=20)).size().max() * 0.8],
        "label": [f"{pct:.0f}% of humans beaten\nby at least one chimp"],
    })).mark_text(fontSize=14, fontWeight="bold", color="firebrick").encode(
        x="x:Q", y="y:Q", text="label:N",
    )

    chart = (hist + zero_line + zero_text + stat_text).properties(
        width=650, height=400,
        title="Darwin Number: How Many Chimps Beat You? (2014–2025, excl. 2020)",
    )
    chart.save(str(OUT_DIR / "altair_darwin.png"), scale_factor=2)
    print("  altair_darwin.png")


def chart2_upset_accuracy():
    """Scatter: Upset prediction accuracy vs final score."""
    df = pd.read_csv(DATA_DIR / "extras_upset_accuracy.csv")
    df = df[df["year"] != 2020]
    df["year"] = df["year"].astype(str)

    dots = alt.Chart(df).mark_circle(size=15, opacity=0.3).encode(
        x=alt.X("upset_rate:Q", title="R1 Upset Prediction Accuracy (%)"),
        y=alt.Y("score:Q", title="Final Score"),
        color=alt.Color("year:N", title="Year", legend=alt.Legend(columns=2)),
        tooltip=["name", "year", "upset_rate", "upset_hits", "total_upsets", "score"],
    )

    # Highlight rank=1 winners
    winners = df[df["rank"] == 1]
    winner_pts = alt.Chart(winners).mark_point(
        shape="cross", size=200, filled=True, strokeWidth=1.5, stroke="black",
    ).encode(
        x="upset_rate:Q", y="score:Q",
        color=alt.Color("year:N", title="Year"),
        tooltip=["name", "year", "upset_rate", "score"],
    )

    chart = (dots + winner_pts).properties(
        width=700, height=450,
        title="Does Predicting Upsets Correctly Help You Win? (2014–2025, excl. 2020)",
    )
    chart.save(str(OUT_DIR / "altair_upset_accuracy.png"), scale_factor=2)
    print("  altair_upset_accuracy.png")


def chart3_elimination():
    """Elimination curves: % of brackets eliminated at each step, by year."""
    df = pd.read_csv(DATA_DIR / "extras_elimination.csv")
    df["year"] = df["year"].astype(str)
    df["year_label"] = df["year"].apply(lambda y: f"{y} (COVID)" if y == "2020" else y)

    # Only plot every-other step to reduce clutter, plus key milestones
    round_labels = {1: "R1 Start", 32: "R1 End", 48: "R2 End",
                    56: "S16 End", 60: "E8 End", 63: "Final"}

    chart = alt.Chart(df).mark_line(strokeWidth=2).encode(
        x=alt.X("step:Q", title="Game Step (1–63)", scale=alt.Scale(domain=[1, 65])),
        y=alt.Y("pct_eliminated:Q", title="% Brackets Eliminated"),
        color=alt.Color("year_label:N", title="Year"),
        strokeDash=alt.condition(
            alt.datum.year == "2020",
            alt.value([5, 3]),
            alt.value([0]),
        ),
        tooltip=["year_label", "step", "pct_eliminated", "eliminated", "total"],
    ).properties(
        width=700, height=400,
        title="Elimination Curves: When Do Brackets Die? (2014–2025)",
    )

    # Add round boundary markers
    boundaries = pd.DataFrame([
        {"step": 32, "label": "R2"},
        {"step": 48, "label": "S16"},
        {"step": 56, "label": "E8"},
        {"step": 60, "label": "F4"},
    ])
    rules = alt.Chart(boundaries).mark_rule(
        color="gray", strokeDash=[3, 3], opacity=0.5
    ).encode(x="step:Q")
    labels = alt.Chart(boundaries).mark_text(
        dy=-10, color="gray", fontSize=10
    ).encode(x="step:Q", text="label:N")

    full = (chart + rules + labels)
    full.save(str(OUT_DIR / "altair_elimination_curves.png"), scale_factor=2)
    print("  altair_elimination_curves.png")


def chart4_consistency():
    """Year-over-year consistency: bump chart of repeat players' rank percentile."""
    df = pd.read_csv(DATA_DIR / "extras_consistency.csv")
    df["year"] = df["year"].astype(str)

    # Pick top 20 most-frequent players, then among those show their trajectories
    top_players = (df.groupby("name")["years_played"].first()
                   .sort_values(ascending=False).head(20).index.tolist())
    subset = df[df["name"].isin(top_players)].copy()

    lines = alt.Chart(subset).mark_line(strokeWidth=1.5, opacity=0.7).encode(
        x=alt.X("year:N", title="Year"),
        y=alt.Y("rank_percentile:Q", title="Rank Percentile (higher = better)",
                 scale=alt.Scale(domain=[0, 100])),
        color=alt.Color("name:N", title="Player", legend=None),
        tooltip=["name", "year", "rank_percentile", "rank", "score"],
    )

    points = alt.Chart(subset).mark_circle(size=40).encode(
        x="year:N",
        y="rank_percentile:Q",
        color=alt.Color("name:N", legend=None),
        tooltip=["name", "year", "rank_percentile", "rank"],
    )

    # Overlay: average line
    avg = subset.groupby("year")["rank_percentile"].mean().reset_index()
    avg_line = alt.Chart(avg).mark_line(
        color="red", strokeWidth=3, strokeDash=[5, 3]
    ).encode(x="year:N", y="rank_percentile:Q")

    avg_label = alt.Chart(pd.DataFrame({
        "x": [avg["year"].iloc[-1]], "y": [avg["rank_percentile"].iloc[-1]],
        "label": ["Avg of repeat players"],
    })).mark_text(align="left", dx=5, color="red", fontSize=11).encode(
        x="x:N", y="y:Q", text="label:N",
    )

    chart = (lines + points + avg_line + avg_label).properties(
        width=700, height=450,
        title=f"Year-over-Year Performance: Top 20 Most Frequent Players (2014–2025)",
    )
    chart.save(str(OUT_DIR / "altair_consistency.png"), scale_factor=2)
    print("  altair_consistency.png")


def chart5_geo_success():
    """Geographic success: median rank percentile by state."""
    df = pd.read_csv(DATA_DIR / "extras_geo_success.csv")
    df = df[df["year"] != 2020]

    # Compute median rank percentile per state, require 10+ entries
    state_stats = (df.groupby(["state", "code"])
                   .agg(median_pct=("rank_percentile", "median"),
                        entries=("rank_percentile", "count"))
                   .reset_index())
    state_stats = state_stats[state_stats["entries"] >= 10]

    bars = alt.Chart(state_stats).mark_bar().encode(
        x=alt.X("median_pct:Q", title="Median Rank Percentile (higher = better)",
                 scale=alt.Scale(domain=[30, 70])),
        y=alt.Y("code:N", title="State", sort="-x"),
        color=alt.Color("median_pct:Q",
                         scale=alt.Scale(scheme="redyellowgreen", domain=[40, 60]),
                         title="Percentile"),
        tooltip=["state", "code", "median_pct", "entries"],
    ).properties(
        width=500,
        height=alt.Step(14),
        title="Geographic Success: Which States Pick Best? (2014–2025 excl. 2020, min 10 entries)",
    )
    bars.save(str(OUT_DIR / "altair_geo_success.png"), scale_factor=2)
    print("  altair_geo_success.png")


def main():
    print("Generating Altair extras charts...")
    chart1_darwin()
    chart2_upset_accuracy()
    chart3_elimination()
    chart4_consistency()
    chart5_geo_success()
    print("Done.")


if __name__ == "__main__":
    main()
