/* Popularity across the 6 genres (CTE + window functions) */
USE SpotifyDB;
GO

WITH genre_stats AS (
    SELECT DISTINCT
        playlist_genre,
        COUNT(*)                 OVER (PARTITION BY playlist_genre) AS tracks,
        AVG(track_popularity * 1.0) OVER (PARTITION BY playlist_genre) AS avg_popularity,
        PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY track_popularity)
                                 OVER (PARTITION BY playlist_genre) AS median_popularity
    FROM dbo.spotify_tracks
)
SELECT
    RANK() OVER (ORDER BY avg_popularity DESC) AS popularity_rank,
    playlist_genre,
    tracks,
    ROUND(avg_popularity, 1)    AS avg_popularity,
    median_popularity,
    ROUND(avg_popularity - AVG(avg_popularity) OVER (), 1) AS vs_genre_average
FROM genre_stats
ORDER BY popularity_rank;
GO