using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;

namespace WebApplication1.DAL
{
    /// <summary>
    /// Data access layer for the TBL_SONG table (CRUD operations).
    /// </summary>
    public class Song
    {
        private readonly string strConnectionString;

        public Song(string strConnString)
        {
            strConnectionString = strConnString;
        }

        #region CRUD

        /// <summary>
        /// Inserts a new song and returns the generated ID_SONG.
        /// </summary>
        public int Save(Entities.Song song)
        {
            const string strSql = "INSERT INTO TBL_SONG (SONG_NAME, SONG_PATH, PLAYS) " +
                                  "VALUES (@SONG_NAME, @SONG_PATH, @PLAYS); " +
                                  "SELECT CAST(SCOPE_IDENTITY() AS INT);";
            using (SqlConnection cn = new SqlConnection(strConnectionString))
            {
                using (SqlCommand cmd = new SqlCommand(strSql, cn))
                {
                    cmd.Parameters.Add("@SONG_NAME", SqlDbType.VarChar, 50).Value = song.Name;
                    cmd.Parameters.Add("@SONG_PATH", SqlDbType.VarChar, 255).Value = song.Path;
                    cmd.Parameters.Add("@PLAYS", SqlDbType.Int).Value = song.Plays;
                    cn.Open();
                    object newId = cmd.ExecuteScalar();
                    return newId == null ? 0 : Convert.ToInt32(newId);
                }
            }
        }

        /// <summary>
        /// Returns every song ordered by name.
        /// </summary>
        public DataTable Read()
        {
            const string strSql = "SELECT ID_SONG, SONG_NAME, SONG_PATH, ISNULL(PLAYS, 0) AS PLAYS " +
                                  "FROM TBL_SONG ORDER BY SONG_NAME";
            using (SqlConnection cn = new SqlConnection(strConnectionString))
            {
                using (SqlCommand cmd = new SqlCommand(strSql, cn))
                {
                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        DataTable dt = new DataTable();
                        da.Fill(dt);
                        return dt;
                    }
                }
            }
        }

        /// <summary>
        /// Returns a single song by its identifier.
        /// </summary>
        public DataTable ReadById(int id)
        {
            const string strSql = "SELECT ID_SONG, SONG_NAME, SONG_PATH, ISNULL(PLAYS, 0) AS PLAYS " +
                                  "FROM TBL_SONG WHERE ID_SONG = @ID_SONG";
            using (SqlConnection cn = new SqlConnection(strConnectionString))
            {
                using (SqlCommand cmd = new SqlCommand(strSql, cn))
                {
                    cmd.Parameters.Add("@ID_SONG", SqlDbType.Int).Value = id;
                    using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                    {
                        DataTable dt = new DataTable();
                        da.Fill(dt);
                        return dt;
                    }
                }
            }
        }

        /// <summary>
        /// Updates the editable fields of a song. Returns the affected rows.
        /// </summary>
        public int Update(Entities.Song song)
        {
            const string strSql = "UPDATE TBL_SONG SET SONG_NAME = @SONG_NAME, SONG_PATH = @SONG_PATH, " +
                                  "PLAYS = @PLAYS WHERE ID_SONG = @ID_SONG";
            using (SqlConnection cn = new SqlConnection(strConnectionString))
            {
                using (SqlCommand cmd = new SqlCommand(strSql, cn))
                {
                    cmd.Parameters.Add("@SONG_NAME", SqlDbType.VarChar, 50).Value = song.Name;
                    cmd.Parameters.Add("@SONG_PATH", SqlDbType.VarChar, 255).Value = song.Path;
                    cmd.Parameters.Add("@PLAYS", SqlDbType.Int).Value = song.Plays;
                    cmd.Parameters.Add("@ID_SONG", SqlDbType.Int).Value = song.ID;
                    cn.Open();
                    return cmd.ExecuteNonQuery();
                }
            }
        }

        /// <summary>
        /// Deletes a song by its identifier. Returns the affected rows.
        /// </summary>
        public int Delete(int id)
        {
            const string strSql = "DELETE FROM TBL_SONG WHERE ID_SONG = @ID_SONG";
            using (SqlConnection cn = new SqlConnection(strConnectionString))
            {
                using (SqlCommand cmd = new SqlCommand(strSql, cn))
                {
                    cmd.Parameters.Add("@ID_SONG", SqlDbType.Int).Value = id;
                    cn.Open();
                    return cmd.ExecuteNonQuery();
                }
            }
        }

        #endregion

        #region Extra queries

        /// <summary>
        /// Increments PLAYS by one and returns the new counter value.
        /// </summary>
        public int UpdatePlays(int id)
        {
            const string strSql = "UPDATE TBL_SONG SET PLAYS = ISNULL(PLAYS, 0) + 1 " +
                                  "OUTPUT INSERTED.PLAYS WHERE ID_SONG = @ID_SONG";
            using (SqlConnection cn = new SqlConnection(strConnectionString))
            {
                using (SqlCommand cmd = new SqlCommand(strSql, cn))
                {
                    cmd.Parameters.Add("@ID_SONG", SqlDbType.Int).Value = id;
                    cn.Open();
                    object plays = cmd.ExecuteScalar();
                    return plays == null ? 0 : Convert.ToInt32(plays);
                }
            }
        }

        /// <summary>
        /// Counts how many songs already use the given name.
        /// </summary>
        public int CheckExistSong(string songName)
        {
            const string strSql = "SELECT COUNT(1) FROM TBL_SONG WHERE SONG_NAME = @SONG_NAME";
            using (SqlConnection cn = new SqlConnection(strConnectionString))
            {
                using (SqlCommand cmd = new SqlCommand(strSql, cn))
                {
                    cmd.Parameters.Add("@SONG_NAME", SqlDbType.VarChar, 50).Value = songName;
                    cn.Open();
                    return Convert.ToInt32(cmd.ExecuteScalar());
                }
            }
        }

        #endregion
    }
}
