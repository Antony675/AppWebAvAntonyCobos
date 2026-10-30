using System;
using System.Collections.Generic;
using System.Configuration;
using System.IO;
using System.Linq;
using System.Web;
using System.Web.Services;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WebAppPoliMusicV3
{
    public partial class Song : System.Web.UI.Page
    {
        string strConnString = ConfigurationManager.ConnectionStrings["BDD_PoliMusicConnectionString"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Page.IsPostBack)
            {
                LoadUserInformation();
                LoadSongs();
            }
        }

        /// <summary>
        /// Shows the logged user name and photo on the header of the page.
        /// </summary>
        private void LoadUserInformation()
        {
            EntityLayer.PoliMusicV3.User user = Session[EntityLayer.PoliMusicV3.Util.Constants.USER] as EntityLayer.PoliMusicV3.User;
            string userName = string.Empty;
            string userPhoto = string.Empty;

            if (user != null)
            {
                userName = user.UserName;
                userPhoto = user.Photo;
            }
            else if (Page.User != null && Page.User.Identity.IsAuthenticated)
            {
                userName = Page.User.Identity.Name;
            }
            if (string.IsNullOrWhiteSpace(userName))
            {
                userName = "invitado";
            }

            lblUserName.Text = Server.HtmlEncode(userName);
            imgUserPhoto.ImageUrl = ResolveUserPhoto(userPhoto);
        }

        /// <summary>
        /// Returns the url of the user photo, or the default avatar when the file does not exist.
        /// </summary>
        private string ResolveUserPhoto(string userPhoto)
        {
            if (!string.IsNullOrWhiteSpace(userPhoto))
            {
                try
                {
                    if (File.Exists(Server.MapPath(userPhoto)))
                    {
                        return ResolveUrl(userPhoto);
                    }
                }
                catch (Exception)
                {
                    // A malformed path just falls back to the default avatar.
                }
            }
            return ResolveUrl("~/UserImages/default.jpg");
        }

        /// <summary>
        /// Reads the song list from the business layer and binds it to the repeater.
        /// </summary>
        private void LoadSongs()
        {
            List<EntityLayer.PoliMusicV3.Song> songs = new List<EntityLayer.PoliMusicV3.Song>();
            try
            {
                songs = new BLL.PoliMusicV3.Song(strConnString).Read();
            }
            catch (Exception ex)
            {
                lblMessage.Text = "No se pudo cargar la biblioteca de canciones: " + Server.HtmlEncode(ex.Message);
                lblMessage.Visible = true;
            }

            rptSongs.DataSource = songs;
            rptSongs.DataBind();

            lblTotalSongs.Text = songs.Count.ToString();
            lblTotalPlays.Text = songs.Sum(song => song.Plays).ToString("N0");
            phEmpty.Visible = songs.Count == 0;
        }

        /// <summary>
        /// Tells if the mp3 file of a song really exists on the server.
        /// </summary>
        public bool IsAvailable(string songPath)
        {
            if (string.IsNullOrWhiteSpace(songPath))
            {
                return false;
            }
            try
            {
                return File.Exists(Server.MapPath(songPath));
            }
            catch (Exception)
            {
                return false;
            }
        }

        /// <summary>
        /// Decorative glyph used on the cover of every song (programming theme).
        /// </summary>
        public string GetGlyph(int index)
        {
            string[] glyphs = { "{ }", "</>", "&&", "=>", "[ ]" };
            return Server.HtmlEncode(glyphs[Math.Abs(index) % glyphs.Length]);
        }

        /// <summary>
        /// Called from javascript every time a song starts playing, to keep the PLAYS column updated.
        /// </summary>
        [WebMethod]
        public static int RegisterPlay(int idSong)
        {
            string strConn = ConfigurationManager.ConnectionStrings["BDD_PoliMusicConnectionString"].ConnectionString;
            return new BLL.PoliMusicV3.Song(strConn).RegisterPlay(idSong);
        }
    }

}
