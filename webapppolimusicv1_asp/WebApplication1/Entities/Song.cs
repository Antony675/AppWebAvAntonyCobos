using System;
using System.Collections.Generic;
using System.Web;

namespace WebApplication1.Entities
{
    /// <summary>
    /// Entity that maps the TBL_SONG table.
    /// </summary>
    public class Song
    {
        public Song()
        {
        }

        public Song(int id, string name, string path, int plays)
        {
            ID = id;
            Name = name;
            Path = path;
            Plays = plays;
        }

        /// <summary>ID_SONG (identity).</summary>
        public int ID { get; set; }

        /// <summary>SONG_NAME.</summary>
        public string Name { get; set; }

        /// <summary>SONG_PATH, stored as a web relative path (~/songFiles/file.mp3).</summary>
        public string Path { get; set; }

        /// <summary>PLAYS, number of times the song was played.</summary>
        public int Plays { get; set; }
    }
}
