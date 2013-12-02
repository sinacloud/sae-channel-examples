<%@page import="game.Game.GameStatus"%>
<%@page import="net.sf.json.JSONObject"%>
<%@page import="game.Game"%>
<%@page import="java.util.UUID"%>
<%@page import="com.sina.sae.channel.SaeChannel"%>
<%@ page language="java" contentType="text/html; charset=UTF-8"  pageEncoding="UTF-8"%>
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>Java Channel Example</title>
<script src='http://channel.sinaapp.com/api.js'></script>
      <style type='text/css'>
        body {
          font-family: 'Helvetica';
        }

        #board {
          width:152px; 
          height: 152px;
          margin: 20px auto;
        }
        
        #display-area {
          text-align: center;
        }
        
        #this-game {
          font-size: 9pt;
        }
        
        table {
          border-collapse: collapse;
        }
        
        td {
          width: 50px;
          height: 50px;
          font-family: "Helvetica";
          font-size: 16pt;
          text-align: center;
          vertical-align: middle;
          margin:0px;
          padding: 0px;
        }
        
        div.cell {
          float: left;
          width: 50px;
          height: 50px;
          border: none;
          margin: 0px;
          padding: 0px;
        }
        
        div.mark {
          position: absolute;
          top: 15px;          
        }
        
        div.l {
          border-right: 1pt solid black;
        }
        
        div.c {
        }
        
        div.r {
          border-left: 1pt solid black;
        }
        
        div.t {
          border-bottom: 1pt solid black;
        }
        
        div.m {
        }
        
        div.b {
          border-top: 1pt solid black;
          }
       </style>  
	    <%
    	String gameKey = request.getParameter("g");
    	String url = null; 
	   	boolean isX = true;//是否为先行玩家X
	   	Game game = null;
	 	String  user = (String)session.getAttribute("user");
    	if(user==null){
    		user = UUID.randomUUID().toString().replace("-", "");
    		session.setAttribute("user", user);
    	} 
	   	if(gameKey!=null){
	   		SaeChannel channel = new SaeChannel();
	   		game = Game.getGameByKey(gameKey);
	   		if(game==null){//首次进入游戏页 创建游戏对象，并定位为玩家X，同时把游戏对象存储至mc
	   			game = new Game(gameKey,user,null,true);
	   			game.setChannelX(channel.createChannel(user+gameKey));//创建X的channel
	   			game.put();
	   		}else{
	   			if(!user.equals(game.getUserX())&&game.getUserO()==null){//玩家O第一次登陆
	   				game.setUserO(user);
	   				game.setChannelO(channel.createChannel(user+gameKey));//创建O的Channel
	   				game.setStatus(GameStatus.STARTED);//玩家O进入 游戏进入开始状态
	        		game.put();
	   			}
		   		isX =  gameKey.equals(user);//判断玩家类型 X/O
	   		}
	   		url = isX?game.getChannelX():game.getChannelO();//根据用户指定相应的WebSocket url
	   	} else{
	   		String opt =  request.getParameter("opt");
	   		if("change".equals(opt)&&session.getAttribute("user")!=null){//更换用户操作
	   			user = UUID.randomUUID().toString().replace("-", "");
	    		session.setAttribute("user", user);
	   		}
	   	}
  %>
        </head>
  <body>  
 
	<div id='display-area'>
      <h2>Channel-based Tic Tac Toe</h2>
      <div id='message' style="height: 40px;" ></div>
        <%if(game!=null){ %>
	<script type='text/javascript'>
		
	  var game = eval("("+'<%=JSONObject.fromObject(game).toString()%>'+")");
	  var player = '<%=isX?"x":"o"%>';
	  var count = 1;
      updateGame = function() {//更新游戏，每次接到消息推送时调用
    	var xSquares = game.xSquares;
    	var oSquares = game.oSquares;
    	for(var i = 0; i < xSquares.length; i++){
    		document.getElementById(xSquares[i]).innerHTML = 'x';
    	}  
    	for(var i = 0; i < oSquares.length; i++){
    		document.getElementById(oSquares[i]).innerHTML = 'o';
    	}    
    	if(game.status=='XWIN'){
			  document.getElementById('message').innerHTML = "GAME OVER，玩家 X 赢得了游戏";
		 }else if(game.status=='XLOST'){
			  document.getElementById('message').innerHTML = "GAME OVER，玩家 O 赢得了游戏";
		 }else if(game.status=='DRAW'){
			  document.getElementById('message').innerHTML = "GAME OVER，平局";
		 }else if(game.status=='STARTED'){
			 document.getElementById('message').innerHTML = "游戏进行中";
		 }else{
			 document.getElementById('message').innerHTML = "等待玩家进入 (PS：复制链接给另一玩家打开加入游戏)";
		 }
      };
       
      //调用服务端post接口
      sendMessage = function(path, opt_param) {
        path += '?g=' + '<%=gameKey%>'+"&u="+player;
        if (opt_param) {
          path += '&' + opt_param;
        }
        var xhr = new XMLHttpRequest();
        xhr.open('POST', path, true);
        xhr.send();
      };

      moveInSquare = function(id) {
    	  if(game.status=='CREATED'){
    		  alert('等待玩家加入....');
    	  }else if(game.status=='STARTED'){
    		  if((game.xMove&&player=='x')||(!game.xMove&&player=='o')){
    			  if(document.getElementById(id).innerHTML==''){
    				  document.getElementById(id).innerHTML = player;
	    			  sendMessage('/move', 'i=' + id);
	    		  }else{
	    			  alert('这里不能下....');
	    		  }
    		  }else{
    			  alert('没轮到你呢 ....');
    		  }
    	  }else{
    		  alert('游戏已经结束了 ....');
    	  }
      };
      
      //Channel打开时候调用
      onOpened = function() {
        sendMessage('/opened');
      };
      
      //接到消息时候调用
      onMessage = function(m) {
        game = eval("("+m.data+")");
        updateGame();
      };
      
      openChannel = function() {
        socket = new sae.Channel('<%=url%>');
        socket.onopen = onOpened;
        socket.onmessage = onMessage;
      };
      
      initialize = function() {
        openChannel();
        var i;
        for (i = 1; i < 10; i++) {
        var square = document.getElementById(i);
	        square.onclick = new Function('moveInSquare(' + i + ')');
        }
        updateGame();
      };
      setTimeout(initialize, 100);
    </script>
	
      <div id='board' >
        <div class='t l cell'><table><tr><td id='1'></td></tr> </table></div>
        <div class='t c cell'><table><tr><td id='2'></td></tr> </table></div>
        <div class='t r cell'><table><tr><td id='3'></td></tr> </table></div>
        <div class='m l cell'><table><tr><td id='4'></td></tr> </table></div>
        <div class='m c cell'><table><tr><td id='5'></td></tr> </table></div>
        <div class='m r cell'><table><tr><td id='6'></td></tr> </table></div>
        <div class='b l cell'><table><tr><td id='7'></td></tr> </table></div>
        <div class='b c cell'><table><tr><td id='8'></td></tr> </table></div>
        <div class='b r cell'><table><tr><td id='9'></td></tr> </table></div>
      </div>
      <%} %>
      <div id='this-game' float='top'>
      <% if(game==null){ %>
                <span id='this-game-link'><b>Current user</b>:<%=user%><br><br><a href='/?opt=change'>Change user</a></span>
               <br><br><span id='this-game-link'><a href='/?g=<%=user%>'>Quick game</a></span>
      <% }else{ %>  
         <br><br>To index: <span id='this-game-link'><a href='/'>index</a></span>
      <% } %> 
      </div>
    </div>
	
</body>
</html>