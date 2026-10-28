using System;
using System.Configuration;
using System.Web;

namespace WebApplication1.Handlers
{
    /// <summary>
    /// Increases the PLAYS counter of a song each time it starts playing.
    /// The page calls it through an asynchronous request so the audio never stops.
    /// GET Handlers/SongPlay.ashx?id=1 -> {"id":1,"plays":5}
    /// </summary>
    public class SongPlay : IHttpHandler
    {
        public void ProcessRequest(HttpContext context)
        {
            context.Response.ContentType = "application/json";
            context.Response.Cache.SetCacheability(HttpCacheability.NoCache);

            int idSong;
            if (!int.TryParse(context.Request.QueryString["id"], out idSong) || idSong <= 0)
            {
                context.Response.StatusCode = 400;
                context.Response.Write("{\"error\":\"invalid song id\"}");
                return;
            }

            try
            {
                string strConnString = ConfigurationManager.ConnectionStrings["BDD_PoliMusicConnectionString"].ConnectionString;
                int plays = new BLL.Song(strConnString).UpdatePlays(idSong);
                context.Response.Write(string.Format("{{\"id\":{0},\"plays\":{1}}}", idSong, plays));
            }
            catch (Exception ex)
            {
                context.Response.StatusCode = 500;
                context.Response.Write("{\"error\":\"" + ex.Message.Replace("\"", "'") + "\"}");
            }
        }

        public bool IsReusable
        {
            get { return false; }
        }
    }
}
