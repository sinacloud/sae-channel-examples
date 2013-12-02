Sina App Engine Java channel 服务使用范例，基于channel服务实现了一个WebSocket的九宫格游戏(http://javachannel.sinaapp.com)



实现简要介绍


1.玩家1首次打开游戏页面为用户创建一个channel，同时实例化一个Game对象存储至缓存（Memcache）中，等待其他玩家加入;


    SaeChannel channel = new SaeChannel();
    String url1 = channel.createChannel(user1);//创建的channel作为WebSocket url
    Game game = new Game(gamekey,user1,url1);
    game.put();//game保存至缓存
 
 
 
2.有玩家2加入游戏时为玩家2创建另一个channel，同时更新缓存中的Game对象，同时向玩家1,2发送消息告知游戏开始;
 
     String url2 = channel.createChannel(user2);//创建的channel作为WebSocket url
    //向玩家发送消息告知游戏开始
    channel.sendMessage(user1, game);
    channel.sendMessage(user2, game);
 
 
 
3.游戏进行实时向玩家channel发送消息，更新游戏信息，使用JavaScript的sae.Channel对象的onmessage方法实时更新游戏状态。

    game.xMove(1);
    game.oMove(2);
    channel.sendMessage(user1, game);
    channel.sendMessage(user2, game);
    
    //JavaScript
    var channel = sae.Channel(url);
    channel.onmessage = function(message){
 	 updateGame(message);
    }
 
