package game;

import java.io.IOException;
import java.io.PrintWriter;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.sina.sae.channel.SaeChannel;

import net.sf.json.JSONObject;
/**
 * WebSocket（页面）打开时调用此接口post
 */
public class Opened extends HttpServlet {
	private static final long serialVersionUID = 1L;

	SaeChannel channel = new SaeChannel();
	
	/**
	 * @see HttpServlet#doPost(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		String gameKey = request.getParameter("g");
		String u = request.getParameter("u");
		//当玩家o加入时将消息（游戏信息）推送到x玩家的channel中
		if("o".equals(u)){
			Game game = Game.getGameByKey(gameKey);
			String gamejson = JSONObject.fromObject(game).toString();
			channel.sendMessage(game.getUserX()+gameKey, gamejson);
		}
	}
	
	
}
