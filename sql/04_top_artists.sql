/* Artists with 8+ tracks: overall rank and rank within their main genre */
USE SpotifyDB;
GO

WITH artist_stats AS (
    SELECT
        track_artist,
        COUNT(*)                     AS tracks,
        AVG(track_popularity * 1.0)  AS avg_popularity,
        MAX(track_popularity)        AS best_track_popularity
    FROM dbo.spotify_tracks
    GROUP BY track_artist
    HAVING COUNT(*) >= 8                         -- 655 artists
),
artist_genre AS (                                -- genre where the artist has most tracks
    SELECT track_artist, playlist_genre,
           ROW_NUMBER() OVER (PARTITION BY track_artist
                              ORDER BY COUNT(*) DESC, playlist_genre) AS rn
    FROM dbo.spotify_tracks
    GROUP BY track_artist, playlist_genre
)
SELECT TOP 25
    RANK() OVER (ORDER BY s.avg_popularity DESC) AS overall_rank,
    s.track_artist,
    g.playlist_genre                             AS main_genre,
    RANK() OVER (PARTITION BY g.playlist_genre
                 ORDER BY s.avg_popularity DESC) AS rank_in_genre,
    s.tracks,
    ROUND(s.avg_popularity, 1)                   AS avg_popularity,
    s.best_track_popularity
FROM artist_stats s
JOIN artist_genre g ON g.track_artist = s.track_artist AND g.rn = 1
ORDER BY overall_rank;
GO