using System;
using System.Configuration;
using System.Data;
using System.Web;
using System.Web.Security;
using System.Web.UI;
using System.Web.UI.WebControls;

namespace WebApplication1
{
    /// <summary>
    /// Song screen: lists the songs stored in TBL_SONG, shows the authenticated
    /// user and reproduces the audio files through the player of the page.
    /// </summary>
    public partial class Song : System.Web.UI.Page
    {
        private readonly string strConnString = ConfigurationManager.ConnectionStrings["BDD_PoliMusicConnectionString"].ConnectionString;

        protected void Page_Load(object sender, EventArgs e)
        {
            if (!Page.IsPostBack)
            {
                LoadAuthenticatedUser();
                BindSongs();
            }
        }

        /// <summary>
        /// Takes the user from the session (set in Login.aspx) or from the forms
        /// authentication ticket and paints the name in the sidebar, the top bar
        /// and the hero of the page.
        /// </summary>
        private void LoadAuthenticatedUser()
        {
            Entities.User user = Session[Util.Constants.USER] as Entities.User;
            string userName = string.Empty;
            string photo = string.Empty;

            if (user != null)
            {
                userName = user.UserName;
                photo = user.Photo;
            }
            if (string.IsNullOrEmpty(userName) && Context.User != null && Context.User.Identity != null)
            {
                userName = Context.User.Identity.Name;
            }
            if (string.IsNullOrEmpty(userName))
            {
                userName = "Invitado";
            }

            string safeUserName = Server.HtmlEncode(userName);
            lblUserName.Text = safeUserName;
            lblSideUserName.Text = safeUserName;
            lblHeroUser.Text = safeUserName;

            string avatarHtml = BuildAvatarHtml(photo, BuildInitials(userName), safeUserName);
            litUserAvatar.Text = avatarHtml;
            litSideAvatar.Text = avatarHtml;
        }

        /// <summary>
        /// Reads TBL_SONG through the BLL and binds the repeater of the page.
        /// </summary>
        private void BindSongs()
        {
            try
            {
                DataTable dtSongs = new BLL.Song(strConnString).Read();
                int count = dtSongs.Rows.Count;
                int totalPlays = 0;

                foreach (DataRow row in dtSongs.Rows)
                {
                    totalPlays += Convert.ToInt32(row["PLAYS"]);
                }

                rptSongs.DataSource = dtSongs;
                rptSongs.DataBind();

                lblSongCount.Text = count.ToString() + (count == 1 ? " canción" : " canciones");
                lblSideCount.Text = count.ToString() + " pistas";
                lblTotalPlays.Text = totalPlays.ToString() + (totalPlays == 1 ? " reproducción" : " reproducciones");
                pnlEmpty.Visible = count == 0;
                if (count == 0)
                {
                    lblEmptyText.Text = "La tabla TBL_SONG no tiene registros para mostrar.";
                }
            }
            catch (Exception ex)
            {
                rptSongs.DataSource = null;
                rptSongs.DataBind();
                lblSongCount.Text = "0 canciones";
                lblSideCount.Text = "0 pistas";
                lblTotalPlays.Text = "0 reproducciones";
                pnlEmpty.Visible = true;
                lblEmptyText.Text = "No se pudo leer la tabla TBL_SONG: " + Server.HtmlEncode(ex.Message);
            }
        }

        /// <summary>
        /// Builds the avatar: the user photo when it exists, the initials otherwise.
        /// If the image can not be loaded the browser removes it and the initials remain.
        /// </summary>
        private string BuildAvatarHtml(string photo, string initials, string safeUserName)
        {
            string html = "<span class=\"pm-avatar__initials\">" + initials + "</span>";
            if (!string.IsNullOrEmpty(photo))
            {
                html += "<img class=\"pm-avatar__img\" src=\"" + ResolveUrl(photo) + "\" alt=\"" +
                        safeUserName + "\" onerror=\"this.remove();\" />";
            }
            return html;
        }

        /// <summary>
        /// Returns up to two initials of the user name.
        /// </summary>
        private string BuildInitials(string userName)
        {
            string cleanName = (userName ?? string.Empty).Replace(".", " ").Replace("_", " ").Trim();
            string[] parts = cleanName.Split(new char[] { ' ' }, StringSplitOptions.RemoveEmptyEntries);
            string initials = string.Empty;
            if (parts.Length > 0 && parts[0].Length > 0)
            {
                initials += parts[0].Substring(0, 1);
            }
            if (parts.Length > 1 && parts[1].Length > 0)
            {
                initials += parts[1].Substring(0, 1);
            }
            if (initials.Length == 0)
            {
                initials = "PM";
            }
            return Server.HtmlEncode(initials.ToUpper());
        }
    }
}
