using System;
using System.Collections.Generic;
using System.Data;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace BLL.PoliMusicV3
{
    public class Song
    {
        private string strConnectionString;
        public Song(string strConnString)
        {
            strConnectionString = strConnString;
        }

        public int Save(EntityLayer.PoliMusicV3.Song song)
        {
            if (song.Plays < 0)
            {
                song.Plays = 0;
            }
            return new DAL.PoliMusicV3.Song(strConnectionString).Save(song);
        }

        public List<EntityLayer.PoliMusicV3.Song> Read()
        {
            DataTable dtSong = new DAL.PoliMusicV3.Song(strConnectionString).Read();
            return ConvertToSongList(dtSong);
        }

        public EntityLayer.PoliMusicV3.Song GetById(int idSong)
        {
            DataTable dtSong = new DAL.PoliMusicV3.Song(strConnectionString).GetById(idSong);
            List<EntityLayer.PoliMusicV3.Song> songs = ConvertToSongList(dtSong);
            return songs.Count > 0 ? songs[0] : null;
        }

        public int Update(EntityLayer.PoliMusicV3.Song song)
        {
            if (song.Plays < 0)
            {
                song.Plays = 0;
            }
            return new DAL.PoliMusicV3.Song(strConnectionString).Update(song);
        }

        public int Delete(int idSong)
        {
            return new DAL.PoliMusicV3.Song(strConnectionString).Delete(idSong);
        }

        public int RegisterPlay(int idSong)
        {
            if (idSong <= 0)
            {
                return 0;
            }
            return new DAL.PoliMusicV3.Song(strConnectionString).RegisterPlay(idSong);
        }

        public int CheckExistSong(string songName)
        {
            return new DAL.PoliMusicV3.Song(strConnectionString).CheckExistSong(songName);
        }

        /// <summary>
        /// Business rules that a song must satisfy before being stored.
        /// </summary>
        /// <returns>An empty string if the song is valid, otherwise the error message.</returns>
        public string ValidationsRequired(EntityLayer.PoliMusicV3.Song song)
        {
            if (song == null)
            {
                return "The song is required!";
            }
            if (string.IsNullOrWhiteSpace(song.SongName))
            {
                return "Song name is required!";
            }
            if (song.SongName.Trim().Length > 50)
            {
                return "Song name can not exceed 50 characters!";
            }
            if (string.IsNullOrWhiteSpace(song.SongPath))
            {
                return "Song path is required!";
            }
            if (!song.SongPath.ToLower().EndsWith(".mp3"))
            {
                return "Only .mp3 files are allowed!";
            }
            if (song.SongPath.Length > 255)
            {
                return "Song path can not exceed 255 characters!";
            }
            return string.Empty;
        }

        /// <summary>
        /// Business rule: the song name must be unique inside the library.
        /// </summary>
        /// <returns>An empty string if the name is free, otherwise the error message.</returns>
        public string ValidationsDuplicated(EntityLayer.PoliMusicV3.Song song)
        {
            if (song == null || string.IsNullOrWhiteSpace(song.SongName))
            {
                return string.Empty;
            }
            if (CheckExistSong(song.SongName.Trim()) != 0)
            {
                return "Song name already registered!";
            }
            return string.Empty;
        }

        /// <summary>
        /// Maps the DataTable returned by the DAL into a list of entities.
        /// </summary>
        private List<EntityLayer.PoliMusicV3.Song> ConvertToSongList(DataTable dtSong)
        {
            List<EntityLayer.PoliMusicV3.Song> songs = new List<EntityLayer.PoliMusicV3.Song>();
            if (dtSong == null)
            {
                return songs;
            }
            foreach (DataRow row in dtSong.Rows)
            {
                songs.Add(new EntityLayer.PoliMusicV3.Song(
                    Convert.ToInt32(row["ID_SONG"]),
                    row["SONG_NAME"].ToString(),
                    row["SONG_PATH"].ToString(),
                    Convert.ToInt32(row["PLAYS"])));
            }
            return songs;
        }
    }

}
