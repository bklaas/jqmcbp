"""Generate J2-factor visualizations using Altair.

Reads j2_analysis_data.csv and produces 6 PNG charts exploring
how J2-factor correlates with bracket success.
"""

from pathlib import Path

import altair as alt
import pandas as pd

alt.data_transformers.disable_max_rows()

DATA_FILE = Path(__file__).resolve().parent / "j2_analysis_data.csv"
OUT_DIR = Path(__file__).resolve().parent
LOGO_PATH = Path(__file__).resolve().parents[2] / "web" / "2026" / "graphs" / "jq_graph_logo.gif"


def add_logo(image_path, logo_height=80, padding=10):
    """Overlay the JQ logo in the lower-right corner of a chart image."""
    if not LOGO_PATH.exists():
        return
    from PIL import Image
    chart_img = Image.open(image_path)
    logo = Image.open(LOGO_PATH).convert("RGBA")
    aspect = logo.width / logo.height
    logo = logo.resize((int(logo_height * aspect), logo_height))
    x = chart_img.width - logo.width - padding
    y = chart_img.height - logo.height - padding
    chart_img.paste(logo, (x, y), logo)
    chart_img.save(image_path)


def load_data():
    df = pd.read_csv(DATA_FILE)
    df["year"] = df["year"].astype(str)
    df = df.dropna(subset=["j2_factor"])
    df = df[df["j2_factor"] >= 0]
    df["year_label"] = df["year"].apply(
        lambda y: f"{y} (COVID)" if y == "2020" else y
    )
    return df


def assign_tiers(df):
    """Add a 'tier' column based on rank within each year."""
    tiers = []
    for _, group in df.groupby("year"):
        n = len(group)
        for _, row in group.iterrows():
            rank = row["rank"]
            if row["is_winner"]:
                tiers.append("Winner")
            elif rank <= 5:
                tiers.append("2nd–5th")
            elif rank <= 10:
                tiers.append("6th–10th")
            elif rank <= n * 0.25:
                tiers.append("11th–25%")
            elif rank <= n * 0.75:
                tiers.append("25%–75%")
            else:
                tiers.append("Bottom 25%")
    df["tier"] = tiers
    df["tier"] = pd.Categorical(
        df["tier"],
        categories=["Winner", "2nd–5th", "6th–10th", "11th–25%", "25%–75%", "Bottom 25%"],
        ordered=True,
    )
    return df


def chart1_scatter(df):
    """Scatter: J2-Factor vs Final Score (all years)."""
    base = alt.Chart(df[~df["is_winner"]]).mark_circle(size=30, opacity=0.5).encode(
        x=alt.X("j2_factor:Q", title="J-Factor"),
        y=alt.Y("score:Q", title="Final Score"),
        color=alt.Color("year:N", title="Year", legend=alt.Legend(columns=2)),
        tooltip=["name", "year", "j2_factor", "score", "rank"],
    )

    winners = alt.Chart(df[df["is_winner"]]).mark_point(
        shape="cross", size=200, filled=True, strokeWidth=1.5, stroke="black"
    ).encode(
        x="j2_factor:Q",
        y="score:Q",
        color=alt.Color("year:N", title="Year"),
        tooltip=["name", "year", "j2_factor", "score"],
    )

    reg = base.transform_regression("j2_factor", "score", method="linear").mark_line(
        color="red", strokeDash=[5, 3], strokeWidth=2
    )

    chart = (base + winners + reg).properties(
        width=700, height=450,
        title="J-Factor vs Final Score (2014–2025)"
    )
    out_path = OUT_DIR / "j2_vs_score_scatter.png"
    chart.save(str(out_path), scale_factor=2)
    add_logo(out_path)
    print("  j2_vs_score_scatter.png")


def chart2_dumbbell(df):
    """Dumbbell: Winner's J2 vs Perfect J2 by year."""
    winners = df[df["is_winner"]].copy()
    # If multiple winners per year, take the one with highest score
    winners = winners.sort_values("score", ascending=False).drop_duplicates("year", keep="first")
    perfect = df.drop_duplicates("year")[["year", "perfect_j2"]].copy()
    merged = winners.merge(perfect, on="year")

    merged["gap"] = abs(merged["j2_factor"] - merged["perfect_j2_y"])

    lines = alt.Chart(merged).mark_rule(strokeWidth=2).encode(
        y=alt.Y("year_label:N", title="Year", sort=sorted(merged["year_label"].unique())),
        x=alt.X("j2_factor:Q", title="J-Factor"),
        x2="perfect_j2_y:Q",
        color=alt.Color("gap:Q", scale=alt.Scale(scheme="redyellowgreen", reverse=True), title="Gap"),
    )

    winner_pts = alt.Chart(merged).mark_circle(size=120, color="#1f77b4").encode(
        y=alt.Y("year_label:N", sort=sorted(merged["year_label"].unique())),
        x="j2_factor:Q",
        tooltip=["name", "j2_factor"],
    )

    perfect_pts = alt.Chart(merged).mark_point(shape="diamond", size=120, color="#d62728", filled=True).encode(
        y=alt.Y("year_label:N", sort=sorted(merged["year_label"].unique())),
        x="perfect_j2_y:Q",
        tooltip=["perfect_j2_y"],
    )

    legend_data = pd.DataFrame({"label": ["Winner J-Factor", "Perfect Bracket J-Factor"], "x": [0, 0]})
    legend_winner = alt.Chart(legend_data[legend_data["label"] == "Winner J-Factor"]).mark_circle(
        size=120, color="#1f77b4"
    ).encode(y=alt.Y("label:N", title=None))
    legend_perfect = alt.Chart(legend_data[legend_data["label"] == "Perfect Bracket J-Factor"]).mark_point(
        shape="diamond", size=120, color="#d62728", filled=True
    ).encode(y=alt.Y("label:N", title=None))

    main = (lines + winner_pts + perfect_pts).properties(
        width=500, height=350,
        title="Winner's J-Factor vs Perfect Bracket J-Factor by Year",
    )
    legend = (legend_winner + legend_perfect).properties(width=20, height=60)

    chart = main | legend
    out_path = OUT_DIR / "winner_vs_perfect_j2.png"
    chart.save(str(out_path), scale_factor=2)
    add_logo(out_path)
    print("  winner_vs_perfect_j2.png")


def chart3_boxplot(df):
    """Box plots: J2-Factor by finish tier."""
    df = df[df["year"] != "2020"]
    tier_order = ["Winner", "2nd–5th", "6th–10th", "11th–25%", "25%–75%", "Bottom 25%", "All Chimps"]

    # Load chimp j2 data and add as a tier (excl. 2020 for this chart)
    chimp_df = pd.read_csv(DATA_FILE.parent / "j2_chimp_data.csv")
    chimp_df = chimp_df[chimp_df["year"] != 2020]
    chimp_df["tier"] = "All Chimps"
    chimp_df["year"] = ""
    chimp_df["name"] = "chimp"
    chimp_df["rank"] = 0

    # Use all data for boxplot stats
    box_data = pd.concat([df[["j2_factor", "tier"]],
                          chimp_df[["j2_factor", "tier"]]],
                         ignore_index=True)

    # Sample for strip plot overlay to keep SVG manageable
    chimp_sample = chimp_df.sample(n=500, random_state=42)
    point_data = pd.concat([df[["j2_factor", "tier", "year", "name", "rank"]],
                            chimp_sample[["j2_factor", "tier", "year", "name", "rank"]]],
                           ignore_index=True)

    boxes = alt.Chart(box_data).mark_boxplot(extent="min-max").encode(
        x=alt.X("tier:N", title="Finish Tier", sort=tier_order),
        y=alt.Y("j2_factor:Q", title="J-Factor"),
        color=alt.Color("tier:N", sort=tier_order, legend=None),
    )

    points = alt.Chart(point_data).mark_circle(size=15, opacity=0.3).encode(
        x=alt.X("tier:N", sort=tier_order),
        y=alt.Y("j2_factor:Q"),
        tooltip=["name", "year", "j2_factor", "rank"],
    )

    chart = (boxes + points).properties(
        width=650, height=400,
        title="J-Factor Distribution by Finish Tier (2014–2025, excl. 2020)",
    )
    out_path = OUT_DIR / "j2_by_finish_tier.png"
    chart.save(str(out_path), scale_factor=2)
    add_logo(out_path)
    print("  j2_by_finish_tier.png")


def chart4_small_multiples(df):
    """Small multiples: J2 vs Score by year."""
    # Load chimp j2 data for yellow overlay (sampled for SVG performance)
    chimp_all = pd.read_csv(DATA_FILE.parent / "j2_chimp_data.csv")
    chimp_all["year"] = chimp_all["year"].astype(str)
    chimp_all["year_label"] = chimp_all["year"].apply(
        lambda y: f"{y} (COVID)" if y == "2020" else y
    )
    # Sample 50 per year to keep rendering fast
    chimp_sampled = pd.concat([
        g.sample(n=min(50, len(g)), random_state=42)
        for _, g in chimp_all.groupby("year")
    ], ignore_index=True)
    chimp_sampled["is_winner"] = False
    chimp_sampled["player_type"] = "chimp"
    chimp_sampled["name"] = "chimp"
    chimp_sampled["rank"] = 0

    combined = df.copy()
    combined["player_type"] = "human"
    # Get perfect_j2 mapping for chimps
    pj2_map = combined.drop_duplicates("year").set_index("year")["perfect_j2"].to_dict()
    chimp_sampled["perfect_j2"] = chimp_sampled["year"].map(pj2_map)

    combined = pd.concat([combined, chimp_sampled], ignore_index=True)

    # Compute color and size columns in pandas to avoid nested conditions
    combined["pt_color"] = combined.apply(
        lambda r: "limegreen" if r.get("player_type") == "chimp"
                  else ("red" if r.get("is_winner") else "steelblue"), axis=1)
    combined["pt_size"] = combined.apply(
        lambda r: 12 if r.get("player_type") == "chimp"
                  else (80 if r.get("is_winner") else 15), axis=1)
    # Label column for legend
    combined["legend_label"] = combined.apply(
        lambda r: "Chimps" if r.get("player_type") == "chimp"
                  else ("Winner(s)" if r.get("is_winner") else "Humans"), axis=1)

    # Add a dummy row for the Perfect Bracket legend entry
    legend_row = combined.iloc[[0]].copy()
    legend_row["legend_label"] = "Perfect Bracket J-Factor"
    legend_row["j2_factor"] = None  # won't render visually
    combined = pd.concat([combined, legend_row], ignore_index=True)

    base = alt.Chart(combined).mark_circle(opacity=0.4).encode(
        x=alt.X("j2_factor:Q", title="J-Factor"),
        y=alt.Y("score:Q", title="Score"),
        color=alt.Color("legend_label:N",
                        scale=alt.Scale(
                            domain=["Humans", "Chimps", "Winner(s)", "Perfect Bracket J-Factor"],
                            range=["steelblue", "limegreen", "red", "orange"]),
                        legend=alt.Legend(title=None)),
        size=alt.Size("pt_size:Q", scale=None, legend=None),
        tooltip=["name", "j2_factor", "score", "rank"],
    )

    rules = alt.Chart(combined).mark_rule(
        color="orange", strokeDash=[4, 2], strokeWidth=1.5
    ).encode(
        x="perfect_j2:Q",
    )

    chart = alt.layer(base, rules, data=combined).properties(
        width=160, height=130,
    ).facet(
        facet=alt.Facet("year_label:N", title="Year"),
        columns=4,
    ).properties(
        title="J-Factor vs Score by Year",
    ).configure_legend(
        orient="bottom", direction="horizontal",
        symbolStrokeWidth=0, symbolSize=80,
    )
    out_path = OUT_DIR / "j2_vs_score_by_year.png"
    chart.save(str(out_path), scale_factor=2)
    add_logo(out_path)
    print("  j2_vs_score_by_year.png")


def chart5_histogram(df):
    """Histogram of all J2 values with winner overlay."""
    winners = df[df["is_winner"]]
    avg_perfect = df.drop_duplicates("year")["perfect_j2"].mean()

    hist = alt.Chart(df).mark_bar(opacity=0.6, color="steelblue").encode(
        x=alt.X("j2_factor:Q", bin=alt.Bin(step=5), title="J-Factor"),
        y=alt.Y("count()", title="Number of Players"),
    )

    winner_rules = alt.Chart(winners).mark_rule(color="red", strokeWidth=2).encode(
        x="j2_factor:Q",
        tooltip=["name", "year", "j2_factor"],
    )

    perfect_rule = alt.Chart(
        pd.DataFrame({"x": [avg_perfect], "label": ["Avg Perfect J-Factor"]})
    ).mark_rule(color="orange", strokeWidth=2, strokeDash=[6, 3]).encode(
        x="x:Q",
    )

    perfect_text = alt.Chart(
        pd.DataFrame({"x": [avg_perfect], "label": [f"Avg Perfect J-Factor = {avg_perfect:.1f}"]})
    ).mark_text(align="left", dx=5, dy=-10, color="orange", fontSize=11).encode(
        x="x:Q",
        text="label:N",
    )

    chart = (hist + winner_rules + perfect_rule + perfect_text).properties(
        width=650, height=400,
        title="J-Factor Distribution: All Players (2014–2025) — Red lines = Winners",
    )
    out_path = OUT_DIR / "j2_histogram_winners.png"
    chart.save(str(out_path), scale_factor=2)
    add_logo(out_path)
    print("  j2_histogram_winners.png")


def chart6_heatmap(df):
    """Heatmap: J2-Factor bucket vs Score bucket."""
    df = df.copy()
    j2_bins = [-60, 0, 10, 20, 30, 40, 50, 100]
    j2_labels = ["<0", "0–10", "10–20", "20–30", "30–40", "40–50", "50+"]
    df["j2_bin"] = pd.cut(df["j2_factor"], bins=j2_bins, labels=j2_labels, right=False)

    score_bins = [0, 40, 60, 80, 100, 200]
    score_labels = ["0–39", "40–59", "60–79", "80–99", "100+"]
    df["score_bin"] = pd.cut(df["score"], bins=score_bins, labels=score_labels, right=False)

    df = df.dropna(subset=["j2_bin", "score_bin"])

    chart = alt.Chart(df).mark_rect().encode(
        x=alt.X("j2_bin:O", title="J-Factor Range", sort=j2_labels),
        y=alt.Y("score_bin:O", title="Score Range", sort=list(reversed(score_labels))),
        color=alt.Color("count():Q", title="Players", scale=alt.Scale(scheme="blues")),
        tooltip=["j2_bin", "score_bin", "count()"],
    ).properties(
        width=500, height=350,
        title="J-Factor vs Score Heatmap (2014–2025)",
    )
    out_path = OUT_DIR / "j2_score_heatmap.png"
    chart.save(str(out_path), scale_factor=2)
    add_logo(out_path)
    print("  j2_score_heatmap.png")


def main():
    df = load_data()
    df = assign_tiers(df)
    print("Generating Altair charts...")
    chart1_scatter(df)
    chart2_dumbbell(df)
    chart3_boxplot(df)
    chart4_small_multiples(df)
    chart5_histogram(df)
    chart6_heatmap(df)
    print("Done.")


if __name__ == "__main__":
    main()
