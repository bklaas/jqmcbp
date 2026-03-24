"""Extract data for additional visualizations across years 2014-2025.

Produces multiple CSVs:
  - extras_darwin.csv          (Darwin number analysis)
  - extras_upset_accuracy.csv  (Correct pick rate on upset games)
  - extras_elimination.csv     (Elimination curves by step)
  - extras_consistency.csv     (Year-over-year player consistency)
  - extras_geo_success.csv     (Geographic success by state)
"""

import collections
from pathlib import Path
import sys

import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from db_config import get_connection

YEARS = list(range(2014, 2026))
OUT_DIR = Path(__file__).resolve().parent

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


def extract_darwin(cursor):
    """Darwin number at final step for each human, plus chimp stats."""
    rows = []
    for year in YEARS:
        db = f"jq_{year}"
        cursor.execute(f"SELECT MAX(step) FROM {db}.scores")
        max_step = cursor.fetchone()[0]
        if not max_step:
            continue

        # Human darwin numbers
        cursor.execute(
            f"SELECT pi.player_id, pi.name, s.darwin, s.score, s.rank "
            f"FROM {db}.player_info pi JOIN {db}.scores s ON pi.player_id = s.player_id "
            f"WHERE s.step = %s AND pi.man_or_chimp = 'man'", (max_step,))
        for pid, name, darwin, score, rank in cursor.fetchall():
            rows.append({"year": year, "player_id": pid, "name": name,
                         "darwin": int(darwin), "score": int(score), "rank": int(rank)})

        # Chimp count and best chimp score
        cursor.execute(
            f"SELECT COUNT(*), MAX(s.score) FROM {db}.scores s "
            f"JOIN {db}.player_info pi ON s.player_id = pi.player_id "
            f"WHERE s.step = %s AND pi.man_or_chimp = 'chimp'", (max_step,))
        chimp_count, best_chimp = cursor.fetchone()
        print(f"  {year}: darwin extracted, {chimp_count} chimps, best chimp={best_chimp}")

    df = pd.DataFrame(rows)
    df.to_csv(OUT_DIR / "extras_darwin.csv", index=False)
    print(f"  Saved {len(df)} rows to extras_darwin.csv")


def extract_upset_accuracy(cursor):
    """For each player-year, compute how many first-round upsets they correctly predicted.

    An upset in R1 = winner seed > 8 (since matchups are 1v16, 2v15, ... 8v9).
    For R2+, an upset = winner had a higher seed than their opponent in that game.
    We focus on R1 upsets (games 1-32) since that's where most upsets happen.
    """
    rows = []
    for year in YEARS:
        db = f"jq_{year}"
        cursor.execute(f"SELECT MAX(step) FROM {db}.scores")
        max_step = cursor.fetchone()[0]
        if not max_step:
            continue

        # Find actual R1 upsets: games where winner seed > 8
        cursor.execute(
            f"SELECT g.game, g.winner, t.seed "
            f"FROM {db}.games g JOIN {db}.teams t ON g.winner = t.team "
            f"WHERE g.game REGEXP '^game_[0-9]+$' AND CAST(SUBSTRING(g.game, 6) AS UNSIGNED) <= 32 "
            f"AND t.seed > 8")
        upsets = {row[0]: (row[1], row[2]) for row in cursor.fetchall()}
        n_upsets = len(upsets)
        if n_upsets == 0:
            print(f"  {year}: no R1 upsets found, skipping upset accuracy")
            continue

        upset_games = list(upsets.keys())

        # For each human, count how many of these upset games they got right
        placeholders = ",".join(["%s"] * len(upset_games))
        cursor.execute(
            f"SELECT p.player_id, SUM(p.winner = g.winner) "
            f"FROM {db}.picks p JOIN {db}.games g ON p.game = g.game "
            f"JOIN {db}.player_info pi ON p.player_id = pi.player_id "
            f"WHERE pi.man_or_chimp = 'man' AND p.game IN ({placeholders}) "
            f"GROUP BY p.player_id", tuple(upset_games))

        player_upset_hits = dict(cursor.fetchall())

        # Get final scores/ranks
        cursor.execute(
            f"SELECT pi.player_id, pi.name, s.score, s.rank "
            f"FROM {db}.player_info pi JOIN {db}.scores s ON pi.player_id = s.player_id "
            f"WHERE s.step = %s AND pi.man_or_chimp = 'man'", (max_step,))

        for pid, name, score, rank in cursor.fetchall():
            hits = int(player_upset_hits.get(pid, 0))
            rows.append({
                "year": year, "player_id": pid, "name": name,
                "upset_hits": hits, "total_upsets": n_upsets,
                "upset_rate": round(hits / n_upsets * 100, 2),
                "score": int(score), "rank": int(rank),
            })

        print(f"  {year}: {n_upsets} R1 upsets, upset accuracy extracted")

    df = pd.DataFrame(rows)
    df.to_csv(OUT_DIR / "extras_upset_accuracy.csv", index=False)
    print(f"  Saved {len(df)} rows to extras_upset_accuracy.csv")


def extract_elimination(cursor):
    """Elimination curves: at each step, what % of human brackets are mathematically eliminated."""
    rows = []
    for year in YEARS:
        db = f"jq_{year}"

        # Fetch all step/score/rtt for humans in one query
        cursor.execute(
            f"SELECT s.step, s.score, s.rtt "
            f"FROM {db}.scores s JOIN {db}.player_info pi ON s.player_id = pi.player_id "
            f"WHERE pi.man_or_chimp = 'man' ORDER BY s.step")
        by_step = collections.defaultdict(list)
        for step, score, rtt in cursor.fetchall():
            by_step[step].append((int(score), int(rtt)))

        for step in sorted(by_step.keys()):
            data = by_step[step]
            leader_score = max(d[0] for d in data)
            total = len(data)
            eliminated = sum(1 for d in data if d[1] < leader_score)
            rows.append({
                "year": year, "step": step, "total": total,
                "eliminated": eliminated,
                "pct_eliminated": round(eliminated / total * 100, 2) if total else 0,
            })

        print(f"  {year}: elimination curves extracted ({len(by_step)} steps)")

    df = pd.DataFrame(rows)
    df.to_csv(OUT_DIR / "extras_elimination.csv", index=False)
    print(f"  Saved {len(df)} rows to extras_elimination.csv")


def extract_consistency(cursor):
    """Year-over-year player consistency: track individuals across years by name."""
    # Collect name -> [(year, rank, total_players, score)] across all years
    name_data = collections.defaultdict(list)

    for year in YEARS:
        db = f"jq_{year}"
        cursor.execute(f"SELECT MAX(step) FROM {db}.scores")
        max_step = cursor.fetchone()[0]
        if not max_step:
            continue

        cursor.execute(
            f"SELECT pi.name, s.rank, s.score "
            f"FROM {db}.player_info pi JOIN {db}.scores s ON pi.player_id = s.player_id "
            f"WHERE s.step = %s AND pi.man_or_chimp = 'man'", (max_step,))
        results = cursor.fetchall()
        n = len(results)
        for name, rank, score in results:
            pct = round((1 - rank / n) * 100, 2) if n > 0 else 0
            name_data[name].append({
                "year": year, "rank": int(rank), "score": int(score),
                "total_players": n, "rank_percentile": pct,
            })

    # Only keep players with 4+ years
    rows = []
    for name, entries in name_data.items():
        if len(entries) >= 4:
            for e in entries:
                rows.append({"name": name, **e})

    df = pd.DataFrame(rows)
    df["years_played"] = df.groupby("name")["year"].transform("count")
    df.to_csv(OUT_DIR / "extras_consistency.csv", index=False)
    unique = df["name"].nunique()
    print(f"  Consistency: {unique} repeat players (4+ years), {len(df)} rows")


def extract_geo_success(cursor):
    """Geographic success: median rank percentile by US state."""
    rows = []
    for year in YEARS:
        db = f"jq_{year}"
        cursor.execute(f"SELECT MAX(step) FROM {db}.scores")
        max_step = cursor.fetchone()[0]
        if not max_step:
            continue

        cursor.execute(
            f"SELECT pi.location, s.rank, s.score "
            f"FROM {db}.player_info pi JOIN {db}.scores s ON pi.player_id = s.player_id "
            f"WHERE s.step = %s AND pi.man_or_chimp = 'man' "
            f"AND pi.location IS NOT NULL AND pi.location != ''",
            (max_step,))
        results = cursor.fetchall()
        n_total = len(results)
        for location, rank, score in results:
            code = STATE_TO_ABBREV.get(location)
            if code:
                pct = round((1 - rank / n_total) * 100, 2) if n_total else 0
                rows.append({
                    "year": year, "state": location, "code": code,
                    "rank": int(rank), "score": int(score),
                    "rank_percentile": pct,
                })

    df = pd.DataFrame(rows)
    df.to_csv(OUT_DIR / "extras_geo_success.csv", index=False)
    states = df["code"].nunique()
    print(f"  Geo success: {states} states, {len(df)} rows")


def main():
    conn = get_connection()
    cursor = conn.cursor()

    print("Extracting Darwin numbers...")
    extract_darwin(cursor)
    print("\nExtracting upset accuracy...")
    extract_upset_accuracy(cursor)
    print("\nExtracting elimination curves...")
    extract_elimination(cursor)
    print("\nExtracting year-over-year consistency...")
    extract_consistency(cursor)
    print("\nExtracting geographic success...")
    extract_geo_success(cursor)

    cursor.close()
    conn.close()
    print("\nAll extractions complete.")


if __name__ == "__main__":
    main()
