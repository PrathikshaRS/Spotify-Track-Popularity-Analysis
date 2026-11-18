/* Popularity by release year, with year-over-year change (LAG).
   Year-only dates (release_date_is_approx = 1) are excluded because their
   month/day is a placeholder; years with fewer than 50 tracks are skipped
   so tiny samples don't distort the trend. */
USE SpotifyDB;
GO

WITH yearly AS (
    SELECT
        release_year,
        COUNT(*)                          AS tracks,
        AVG(track_popularity * 1.0)       AS avg_popularity
    FROM dbo.spotify_tracks
    WHERE release_date_is_approx = 0
    GROUP BY release_year
    HAVING COUNT(*) >= 50
)
SELECT
    release_year,
    tracks,
    ROUND(avg_popularity, 1) AS avg_popularity,
    ROUND(avg_popularity - LAG(avg_popularity) OVER (ORDER BY release_year), 1) AS yoy_change
FROM yearly
ORDER BY release_year;
GO