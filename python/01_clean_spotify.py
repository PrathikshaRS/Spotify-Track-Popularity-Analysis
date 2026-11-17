"""
Step 1 - Clean the Spotify dataset
Input : spotify_songs.xlsx  (32,833 rows x 23 cols)
Output: spotify_clean.csv   (one row per unique track)
"""
import datetime as dt
import sys
from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parent.parent
SRC = sys.argv[1] if len(sys.argv) > 1 else ROOT / "data" / "raw" / "spotify_songs.xlsx"
OUT = sys.argv[2] if len(sys.argv) > 2 else ROOT / "data" / "processed" / "spotify_clean.csv"
Path(OUT).parent.mkdir(parents=True, exist_ok=True)

df = pd.read_excel(SRC)
print(f"Raw rows: {len(df):,}")

# 1. Drop rows with missing track names ---------------------------------
before = len(df)
df = df.dropna(subset=["track_name"]).copy()
print(f"Dropped {before - len(df)} rows with missing track_name")

# 2. Repair text values Excel auto-converted ----------------------------
TEXT_COLS = ["track_name", "track_artist", "track_album_name"]


def restore_text(v):
    """Turn a value Excel converted (number/date/time/bool) back into text."""
    if isinstance(v, str) or pd.isna(v):
        return v, False
    if isinstance(v, bool):
        return str(v).upper(), True
    if isinstance(v, dt.datetime):            # e.g. title '9-2' -> 2005-09-02
        return f"{v.month}/{v.day}/{v.year % 100:02d}", True
    if isinstance(v, dt.time):                # e.g. title '12:51'
        return f"{v.hour}:{v.minute:02d}", True
    if isinstance(v, dt.timedelta):           # durations like 75:28
        mins = int(v.total_seconds() // 60)
        return f"{mins // 60}:{mins % 60:02d}", True
    if isinstance(v, float) and v.is_integer():
        return str(int(v)), True
    return str(v), True                       # ints, floats


fixed_cells = 0
for col in TEXT_COLS:
    res = df[col].map(restore_text)
    df[col] = res.map(lambda t: t[0])
    n = int(res.map(lambda t: t[1]).sum())
    fixed_cells += n
    print(f"  {col}: corrected {n} values")
print(f"Corrected {fixed_cells} text values in total")

# 3. Reconcile year-only release dates ----------------------------------
raw_date = df["track_album_release_date"]
year_only = raw_date.map(lambda v: isinstance(v, (int, float)) and not pd.isna(v))
df["release_date_is_approx"] = year_only.astype(int)


def to_date(v):
    if isinstance(v, (int, float)) and not pd.isna(v):
        return pd.Timestamp(year=int(v), month=1, day=1)   # year-only -> Jan 1
    return pd.to_datetime(v, errors="coerce")


df["track_album_release_date"] = raw_date.map(to_date)
df["release_year"] = df["track_album_release_date"].dt.year
print(f"Reconciled {int(year_only.sum()):,} year-only release dates (set to Jan 1, flagged)")

# 4. playlist_count BEFORE dedup ----------------------------------------
pl = df.groupby("track_id")["playlist_id"].nunique().rename("playlist_count")
df = df.merge(pl, on="track_id", how="left")

# 5. Deduplicate to unique tracks ---------------------------------------
before = len(df)
df = df.drop_duplicates(subset="track_id", keep="first").reset_index(drop=True)
print(f"Deduplicated {before:,} -> {len(df):,} unique tracks")

df["track_album_release_date"] = df["track_album_release_date"].dt.strftime("%Y-%m-%d")
df.to_csv(OUT, index=False, encoding="utf-8-sig")
print(f"Saved {OUT}  shape={df.shape}")