/* =====================================================================
   Step 2 - Create database + table and load spotify_clean.csv
   Run in SSMS. Requires SQL Server 2017+ (for FORMAT = 'CSV').
   ===================================================================== */

-- 1. Database ----------------------------------------------------------
IF DB_ID('SpotifyDB') IS NULL
    CREATE DATABASE SpotifyDB;
GO
USE SpotifyDB;
GO

-- 2. Table (one row per unique track) ----------------------------------
DROP TABLE IF EXISTS dbo.spotify_tracks;
GO

CREATE TABLE dbo.spotify_tracks (
    track_id                  VARCHAR(22)    NOT NULL PRIMARY KEY,
    track_name                NVARCHAR(200)  NOT NULL,
    track_artist              NVARCHAR(100)  NOT NULL,
    track_popularity          TINYINT        NOT NULL,   -- 0-100
    track_album_id            VARCHAR(22)    NOT NULL,
    track_album_name          NVARCHAR(200)  NOT NULL,
    track_album_release_date  DATE           NOT NULL,   -- year-only dates stored as Jan 1
    playlist_name             NVARCHAR(150)  NOT NULL,
    playlist_id               VARCHAR(22)    NOT NULL,
    playlist_genre            VARCHAR(20)    NOT NULL,
    playlist_subgenre         VARCHAR(50)    NOT NULL,
    danceability              FLOAT          NOT NULL,
    energy                    FLOAT          NOT NULL,
    [key]                     TINYINT        NOT NULL,
    loudness                  FLOAT          NOT NULL,
    [mode]                    TINYINT        NOT NULL,
    speechiness               FLOAT          NOT NULL,
    acousticness              FLOAT          NOT NULL,
    instrumentalness          FLOAT          NOT NULL,
    liveness                  FLOAT          NOT NULL,
    valence                   FLOAT          NOT NULL,
    tempo                     FLOAT          NOT NULL,
    duration_ms               INT            NOT NULL,
    release_date_is_approx    BIT            NOT NULL,   -- 1 = original value was year only
    release_year              SMALLINT       NOT NULL,
    playlist_count            TINYINT        NOT NULL    -- number of playlists the track appears on
);
GO

-- 3. Load the CSV --------------------------------------------------------
-- !! Edit the path if your repo lives somewhere else !!
BULK INSERT dbo.spotify_tracks
FROM 'D:\projects\Spotify-Track-Popularity-Analysis\data\processed\spotify_clean.csv'
WITH (
    FORMAT          = 'CSV',
    FIRSTROW        = 2,              -- skip header
    FIELDQUOTE      = '"',
    FIELDTERMINATOR = ',',
    ROWTERMINATOR   = '0x0d0a',       -- Windows (CRLF) line endings
    CODEPAGE        = '65001',        -- UTF-8
    TABLOCK
);
GO

-- 4. Sanity checks (expected values in the comments) -------------------
SELECT COUNT(*)                         AS total_tracks            -- 28352
FROM dbo.spotify_tracks;

SELECT COUNT(DISTINCT playlist_genre)   AS genres                  -- 6
FROM dbo.spotify_tracks;

SELECT COUNT(*)                         AS artists_with_8_plus     -- 655
FROM (SELECT track_artist
      FROM dbo.spotify_tracks
      GROUP BY track_artist
      HAVING COUNT(*) >= 8) a;

SELECT CASE WHEN playlist_count >= 2 THEN '2+ playlists' ELSE '1 playlist' END AS grp,
       COUNT(*)                                  AS tracks,
       ROUND(AVG(CAST(track_popularity AS FLOAT)), 1) AS avg_popularity  -- 59.6 vs 37.1
FROM dbo.spotify_tracks
GROUP BY CASE WHEN playlist_count >= 2 THEN '2+ playlists' ELSE '1 playlist' END;
GO