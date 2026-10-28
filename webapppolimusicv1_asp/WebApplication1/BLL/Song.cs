using System;
using System.Collections.Generic;
using System.Data;

namespace WebApplication1.BLL
{
    /// <summary>
    /// Business layer for the songs. It only delegates the persistence to the DAL
    /// and keeps the business validations here.
    /// </summary>
    public class Song
    {
        private readonly string strConnectionString;

        public Song(string strConnString)
        {
            strConnectionString = strConnString;
        }

        public int Save(Entities.Song song)
        {
            return new DAL.Song(strConnectionString).Save(song);
        }

        public DataTable Read()
        {
            return new DAL.Song(strConnectionString).Read();
        }

        public DataTable ReadById(int id)
        {
            return new DAL.Song(strConnectionString).ReadById(id);
        }

        public int Update(Entities.Song song)
        {
            return new DAL.Song(strConnectionString).Update(song);
        }

        public int Delete(int id)
        {
            return new DAL.Song(strConnectionString).Delete(id);
        }

        /// <summary>
        /// Registers one reproduction of the song and returns the new PLAYS counter.
        /// </summary>
        public int UpdatePlays(int id)
        {
            if (id <= 0)
            {
                return 0;
            }
            return new DAL.Song(strConnectionString).UpdatePlays(id);
        }

        public int CheckExistSong(string songName)
        {
            return new DAL.Song(strConnectionString).CheckExistSong(songName);
        }

        /// <summary>
        /// Returns an empty string when the song is valid or the error message otherwise.
        /// </summary>
        public string ValidationsSong(Entities.Song song)
        {
            if (song == null)
            {
                return "The song is required!";
            }
            if (string.IsNullOrEmpty(song.Name) || song.Name.Trim() == string.Empty)
            {
                return "The song name is required!";
            }
            if (song.Name.Length > 50)
            {
                return "The song name can not be longer than 50 characters!";
            }
            if (string.IsNullOrEmpty(song.Path) || song.Path.Trim() == string.Empty)
            {
                return "The song path is required!";
            }
            if (song.Path.Length > 255)
            {
                return "The song path can not be longer than 255 characters!";
            }
            return string.Empty;
        }
    }
}
