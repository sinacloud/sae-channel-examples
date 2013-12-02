package game;

import java.io.IOException;

import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import net.sf.json.JSONObject;

import com.sina.sae.channel.SaeChannel;

/**
 * 玩家下棋时调用此接口post
 */
public class Move extends HttpServlet {
	private static final long serialVersionUID = 1L;
	
	SaeChannel channel = new SaeChannel();
	
	/**
	 * @see HttpServlet#doPost(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		String gameKey = request.getParameter("g");
		String u = request.getParameter("u");
		String i = request.getParameter("i");
		Game game = Game.getGameByKey(gameKey);
		if(game!=null){
			if("o".equals(u)){
				game.oMove(i);
			}else{
				game.xMove(i);
			}
			String gamejson = JSONObject.fromObject(game).toString();
			//将消息（游戏信息）推送到x和o玩家的channel中
			channel.sendMessage(game.getUserO()+gameKey, gamejson);
			channel.sendMessage(game.getUserX()+gameKey, gamejson);
		}
	}

}
