"""Extract J2-factor and bracket performance data across multiple years.

Queries each jq_YYYY database, pulls human players' final j2_factor,
score, and rank, computes the "perfect bracket" j2 for that year,
and saves a combined CSV for downstream visualization.
"""

from pathlib import Path
import sys

import pandas as pd

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from db_config import get_connection

YEARS = list(range(2014, 2026))
OUTPUT = Path(__file__).resolve().parent / "j2_analysis_data.csv"


def compute_perfect_j2(cursor, db):
    """Compute the j2_factor a perfect bracket would have earned."""
    # sigma1: sum of seeds of actual first-round winners (games 1-32)
    game_list_r1 = ",".join(f"'game_{i}'" for i in range(1, 33))
    cursor.execute(
        f"SELECT SUM(t.seed) FROM {db}.games g "
        f"JOIN {db}.teams t ON g.winner = t.team "
        f"WHERE g.game IN ({game_list_r1})"
    )
    sigma1 = cursor.fetchone()[0]

    # sigma2: sum of seeds of actual Sweet-16 winners (games 49-56)
    game_list_s16 = ",".join(f"'game_{i}'" for i in range(49, 57))
    cursor.execute(
        f"SELECT SUM(t.seed) FROM {db}.games g "
        f"JOIN {db}.teams t ON g.winner = t.team "
        f"WHERE g.game IN ({game_list_s16})"
    )
    sigma2 = cursor.fetchone()[0]

    if sigma1 is None or sigma2 is None:
        return None

    j = (sigma1 - 144) / 256
    j2 = 20 * (j + 4 * ((sigma2 - 12) / 112))
    return min(j2, 99.99)


def extract_year(cursor, year):
    """Return a list of row dicts for one year."""
    db = f"jq_{year}"

    # Get final step
    cursor.execute(f"SELECT MAX(step) FROM {db}.scores")
    max_step = cursor.fetchone()[0]
    if max_step is None:
        print(f"  {year}: no scores data, skipping")
        return []

    # Get all human players at final step
    cursor.execute(
        f"SELECT pi.player_id, pi.name, pi.j2_factor, s.score, s.rank "
        f"FROM {db}.player_info pi "
        f"JOIN {db}.scores s ON pi.player_id = s.player_id "
        f"WHERE s.step = %s AND pi.man_or_chimp = 'man'",
        (max_step,),
    )
    rows = cursor.fetchall()
    if not rows:
        print(f"  {year}: no human players found, skipping")
        return []

    perfect_j2 = compute_perfect_j2(cursor, db)

    # Find minimum rank (winner)
    min_rank = min(r[4] for r in rows)

    # Collect scores for percentile calculation
    scores = [r[3] for r in rows]
    n = len(scores)

    result = []
    for player_id, name, j2_factor, score, rank in rows:
        # Percentile: fraction of players scoring below this player
        pct = sum(1 for s in scores if s < score) / n * 100 if n > 0 else 0
        result.append(
            {
                "year": year,
                "player_id": player_id,
                "name": name,
                "j2_factor": float(j2_factor) if j2_factor is not None else None,
                "score": int(score),
                "rank": int(rank),
                "is_winner": rank == min_rank,
                "perfect_j2": perfect_j2,
                "score_percentile": round(pct, 2),
            }
        )

    print(f"  {year}: {len(result)} players, winner rank={min_rank}, perfect_j2={perfect_j2:.2f}")
    return result


def extract_chimp_j2(cursor):
    """Extract j2_factor and score for all chimps across all years."""
    rows = []
    for year in YEARS:
        db = f"jq_{year}"
        # Get final step
        cursor.execute(f"SELECT MAX(step) FROM {db}.scores")
        max_step = cursor.fetchone()[0]
        if max_step is None:
            continue
        cursor.execute(
            f"SELECT pi.j2_factor, s.score "
            f"FROM {db}.player_info pi "
            f"JOIN {db}.scores s ON pi.player_id = s.player_id "
            f"WHERE s.step = %s AND pi.man_or_chimp = 'chimp' "
            f"AND pi.j2_factor IS NOT NULL",
            (max_step,),
        )
        for (j2, score) in cursor.fetchall():
            rows.append({"year": year, "j2_factor": float(j2), "score": int(score)})
    return rows


CHIMP_OUTPUT = Path(__file__).resolve().parent / "j2_chimp_data.csv"


def main():
    conn = get_connection()
    cursor = conn.cursor()

    all_rows = []
    for year in YEARS:
        try:
            all_rows.extend(extract_year(cursor, year))
        except Exception as e:
            print(f"  {year}: ERROR {e}")

    print("\nExtracting chimp J2 factors...")
    chimp_rows = extract_chimp_j2(cursor)

    cursor.close()
    conn.close()

    df = pd.DataFrame(all_rows)
    df.to_csv(OUTPUT, index=False)
    print(f"Saved {len(df)} rows to {OUTPUT}")

    chimp_df = pd.DataFrame(chimp_rows)
    chimp_df.to_csv(CHIMP_OUTPUT, index=False)
    print(f"Saved {len(chimp_df)} chimp rows to {CHIMP_OUTPUT}")


if __name__ == "__main__":
    main()
