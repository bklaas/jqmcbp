#!/usr/bin/env python3
"""UCOW = Unweighted Chance Of Winning

Rewrite of UCOW.pl — calculates the unweighted chance of winning
for all remaining tournament outcomes at 16, 8, or 4 teams remaining.
Uses numpy for vectorized scoring across all outcomes.
"""

import sys
import numpy as np


CONFIGS = {
    16: {"n": 15, "points": [4]*8 + [6]*4 + [8]*2 + [16], "start": 33, "end": 48},
    8:  {"n": 7,  "points": [6]*4 + [8]*2 + [16],          "start": 49, "end": 56},
    4:  {"n": 3,  "points": [8]*2 + [16],                   "start": 57, "end": 60},
}

COLUMN_PREFIX = {16: "sixteen", 8: "eight", 4: "four"}


def get_db_connection():
    import pymysql
    return pymysql.connect(
        host="localhost", port=3306,
        user="root", password="hoopoe",
        database="johnnyquest",
        cursorclass=pymysql.cursors.DictCursor,
    )


def fetch_all_db_data(remaining_teams, start_game, end_game):
    """Single DB session: fetch step, team codes, player info, picks, scores."""
    conn = get_db_connection()
    cur = conn.cursor()

    # Current step
    cur.execute("SELECT step FROM scores ORDER BY step DESC LIMIT 1")
    step = cur.fetchone()["step"]

    # Team hex codes from game winners (start_game..end_game)
    games_list = [f"game_{i}" for i in range(start_game, end_game + 1)]
    ph = ",".join(["%s"] * len(games_list))
    cur.execute(f"SELECT game, winner FROM games WHERE game IN ({ph})", games_list)
    rows = sorted(cur.fetchall(), key=lambda r: int(r["game"].split("_")[1]))
    team_codes = {row["winner"]: i for i, row in enumerate(rows)}

    if remaining_teams == 4:
        for team, code in team_codes.items():
            print(f"{team}\t{code:x}")

    # Player info (both man and chimp)
    cur.execute(
        "SELECT pi.player_id, pi.name, pi.man_or_chimp, s.score "
        "FROM player_info pi "
        "JOIN scores s ON pi.player_id = s.player_id AND s.step = %s "
        "ORDER BY pi.player_id",
        (step,),
    )
    player_rows = cur.fetchall()

    # All picks for remaining games
    pick_start = end_game + 1
    pick_games = [f"game_{i}" for i in range(pick_start, 64)]
    ph2 = ",".join(["%s"] * len(pick_games))
    cur.execute(
        f"SELECT player_id, game, winner FROM picks WHERE game IN ({ph2})",
        pick_games,
    )
    picks_lookup = {}
    for p in cur.fetchall():
        picks_lookup[(p["player_id"], p["game"])] = p["winner"]

    conn.close()

    # Build per-player structures
    player_ids = []
    info = {}
    picks_encoded = {}

    for row in player_rows:
        pid = row["player_id"]
        player_ids.append(pid)
        info[pid] = {
            "name": row["name"],
            "man_or_chimp": row["man_or_chimp"],
        }
        encoded = []
        for g in pick_games:
            w = picks_lookup.get((pid, g))
            encoded.append(team_codes[w] if w and w in team_codes else -1)
        picks_encoded[pid] = {"picks": encoded, "score": row["score"]}

    return player_ids, info, picks_encoded


def _next_round(flips, codes, start, end):
    a, b = 0, 1
    newcodes = []
    for i in range(start, end + 1):
        if flips[i] == 0:
            flips[i] = codes[a]
            newcodes.append(codes[a])
        else:
            flips[i] = codes[b]
            newcodes.append(codes[b])
        a += 2
        b += 2
    return flips, newcodes


def encode_all_outcomes(n, remaining_teams):
    """Generate all 2^n possible tournament outcomes as an (2^n, n) int8 array."""
    total = 1 << n
    outcomes = np.empty((total, n), dtype=np.int8)
    half = remaining_teams // 2

    for idx in range(total):
        flips = list(map(int, format(idx, f"0{n}b")))
        codes = []

        # First round: pair up adjacent teams
        for i in range(half):
            winner = i * 2 + flips[i]
            flips[i] = winner
            codes.append(winner)

        end = half - 1
        if remaining_teams == 16:
            flips, codes = _next_round(flips, codes, 8, 11)
            end = 11
        if remaining_teams > 4:
            flips, codes = _next_round(flips, codes, end + 1, end + 2)
            end += 2
        flips, codes = _next_round(flips, codes, end + 1, end + 1)

        outcomes[idx] = flips

    return outcomes


def main():
    remaining_teams = int(sys.argv[1]) if len(sys.argv) > 1 else 16
    if remaining_teams not in CONFIGS:
        print(f"Error: remaining_teams must be 4, 8, or 16", file=sys.stderr)
        sys.exit(1)

    cfg = CONFIGS[remaining_teams]
    n = cfg["n"]
    points_arr = np.array(cfg["points"], dtype=np.int32)
    total_outcomes = 1 << n

    # --- DB fetch ---
    player_ids, info, picks_data = fetch_all_db_data(
        remaining_teams, cfg["start"], cfg["end"]
    )
    num_players = len(player_ids)

    # --- Build numpy arrays ---
    picks_matrix = np.empty((num_players, n), dtype=np.int8)
    current_scores = np.empty(num_players, dtype=np.int32)
    for i, pid in enumerate(player_ids):
        picks_matrix[i] = picks_data[pid]["picks"]
        current_scores[i] = picks_data[pid]["score"]

    # --- Generate all outcomes ---
    outcomes = encode_all_outcomes(n, remaining_teams)

    # --- Vectorized scoring ---
    # For each game slot, broadcast-compare outcomes vs picks and accumulate points
    added_scores = np.zeros((total_outcomes, num_players), dtype=np.int32)
    for i in range(n):
        # outcomes[:, i:i+1] is (total_outcomes, 1); picks_matrix[:, i] is (num_players,)
        # broadcast → (total_outcomes, num_players)
        added_scores += (outcomes[:, i:i + 1] == picks_matrix[:, i]) * points_arr[i]

    total_scores = added_scores + current_scores  # broadcast current_scores across rows

    # --- Determine winners per outcome ---
    max_scores = total_scores.max(axis=1, keepdims=True)  # (total_outcomes, 1)
    is_winner = total_scores == max_scores                 # (total_outcomes, num_players)

    # Per-player win count
    by_player = is_winner.sum(axis=0)  # (num_players,)

    # Winner-count tally
    num_winners_per = is_winner.sum(axis=1)
    unique_counts, tally_counts = np.unique(num_winners_per, return_counts=True)
    winners_tally = dict(zip(unique_counts.tolist(), tally_counts.tolist()))

    # Man vs chimp outcome wins
    is_man = np.array([info[pid]["man_or_chimp"] == "man" for pid in player_ids])
    is_chimp = np.array([info[pid]["man_or_chimp"] == "chimp" for pid in player_ids])
    man_wins = int((is_winner & is_man).any(axis=1).sum())
    chimp_wins = int((is_winner & is_chimp).any(axis=1).sum())

    # --- Final Four detail output ---
    if remaining_teams == 4:
        for oidx in range(total_outcomes):
            winner_indices = np.where(is_winner[oidx])[0]
            outcome_str = "".join(format(x, "x") for x in outcomes[oidx])
            for widx in winner_indices:
                pid = player_ids[widx]
                name = info[pid]["name"]
                if info[pid]["man_or_chimp"] == "chimp":
                    name += " the Chimp"
                print(f"{name}\t{outcome_str}")

    # --- Print results ---
    print("===== WINNERS ====")
    print("Name\tNumber of Winning Brackets\tPercentage of Winning Brackets")

    sorted_indices = np.argsort(-by_player)
    for idx in sorted_indices:
        wins = int(by_player[idx])
        if wins == 0:
            break
        pid = player_ids[idx]
        name = info[pid]["name"]
        if info[pid]["man_or_chimp"] == "chimp":
            name += " the Chimp"
        pct = f"{wins / total_outcomes * 100:.3f}"
        print(f"{name}\t{wins}\t{pct}")

    print("==== HUMAN WINS, CHIMP WINS ====")
    print(f"Human Wins: {man_wins}")
    print(f"Chimp Wins: {chimp_wins}")

    print("==== NUMBER OF WINNERS/OUTCOME TALLY ====")
    for num in sorted(winners_tally):
        print(f"{num}\t{winners_tally[num]}")

    # --- Write results to ucow table ---
    col_brackets = f"ucow_{COLUMN_PREFIX[remaining_teams]}_brackets"
    col_percent = f"ucow_{COLUMN_PREFIX[remaining_teams]}_percent"

    conn = get_db_connection()
    cur = conn.cursor()
    upsert_sql = (
        f"INSERT INTO ucow (player_id, {col_brackets}, {col_percent}) "
        f"VALUES (%s, %s, %s) "
        f"ON DUPLICATE KEY UPDATE {col_brackets} = VALUES({col_brackets}), "
        f"{col_percent} = VALUES({col_percent})"
    )
    rows_to_insert = []
    for i, pid in enumerate(player_ids):
        wins = int(by_player[i])
        pct = round(wins / total_outcomes * 100, 2)
        rows_to_insert.append((pid, wins, pct))
    cur.executemany(upsert_sql, rows_to_insert)
    conn.commit()
    conn.close()
    print(f"\nInserted/updated {len(rows_to_insert)} rows in ucow table ({col_brackets}, {col_percent})")


if __name__ == "__main__":
    main()
