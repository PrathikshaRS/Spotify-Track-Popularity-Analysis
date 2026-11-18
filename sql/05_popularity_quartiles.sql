/* Top vs bottom popularity quartile (NTILE).
   Ties on popularity are broken by track_id so the split is repeatable. */
USE SpotifyDB;
GO

WITH ranked AS (
    SELECT *,
           NTILE(4) OVER (ORDER BY track_popularity, track_id) AS quartile  -- 1 = least popular, 4 = most
    FROM dbo.spotify_tracks
)
SELECT
    quartile,
    COUNT(*)                          AS tracks,
    MIN(track_popularity)             AS min_popularity,
    MAX(track_popularity)             AS max_popularity,
    ROUND(AVG(playlist_count * 1.0), 2) AS avg_playlists,
    ROUND(AVG(danceability), 3)       AS danceability,
    ROUND(AVG(energy), 3)             AS energy,
    ROUND(AVG(acousticness), 3)       AS acousticness,
    ROUND(AVG(instrumentalness), 3)   AS instrumentalness,
    ROUND(AVG(duration_ms) / 60000.0, 2) AS avg_minutes
FROM ranked
GROUP BY quartile
ORDER BY quartile;
GO