# 服务使用示例

下面我们使用[TicTacToe(井字棋)](http://zh.wikipedia.org/wiki/%E4%BA%95%E5%AD%97%E6%A3%8B)游戏来示范channel服务的使用方法：

![game-screenshot](https://github.com/sinacloud/sae-channel-examples/raw/master/python/screenshot.png)

**channel的创建和连接**

当用户A打开TicTacToe游戏的主页时，服务端的程序会：

+ 调用`create_channel`创建为用户A创建一个channel，并将该channel的url嵌入到返回给用户的html页面代码中。
+ 生成一个加入游戏的连接，用户通过将此连接发送给其它用户B，其它用户B可以通过此连接加入用户A创建的游戏。

每个页面对应的channel的name应该是独一无二的，比如可以使用用户id的字符串作为channel的name。

游戏的主页的html代码模板大致如下所示，其中`<?=url?>`和`<?=game_link?>`分别为上面生成的channel url和游戏加入连接。

    <head>
    ...
    <script src="http://channel.sinaapp.com/api.js"></script>
    </head>
    <body>
      <script>
        channel = new sae.Channel('{{ url }}');
        socket.onopen = onOpened;
        socket.onmessage = onMessage;
        socket.onerror = onError;
        socket.onclose = onClose;
      </script>

      ...

      <div id='other-player' style='display:none'>
        Waiting for another player to join.<br>
        Send them this link to play:<br>
        <div id='game-link'><a href='{{ game_link }}'>{{ game_link }}</a></div>
      </div>

    </body>

游戏的js客户端使用 `sae.Channel` 来创建一条channel连接，并且设置channel的onopen/onmessage/onerror/onclose的callback函数。

**使用channel来推送游戏状态信息**

当用户B点击用户A发过来的连接打开了游戏页面时，游戏的javascript客户端通过 `sendMessage` 函数通知服务端。

    onOpened = function() {
      connected = true;
      sendMessage('opened');
      updateBoard();
    };

    sendMessage = function(path, opt_param) {
      path += '?g=' + state.game_key;
      if (opt_param) {
        path += '&' + opt_param;
      }
      var xhr = new XMLHttpRequest();
      xhr.open('POST', path, true);
      xhr.send();
    };

服务端更新当前游戏的状态，并且通过channel的`sendMessage`将游戏的新的状态发送给用户A和用户B的channel客户端。客户端接受到消息后更新游戏页面。此后用户A和用户B交替走棋，客户端通过`sendMessage`将用户的走法发送给服务端。

    moveInSquare = function(id) {
      if (isMyMove() && state.board[id] == ' ') {
        sendMessage('/move', 'i=' + id);
      }
    }

服务收到消息后更新游戏的状态，再通过`sendMessage`将更新后的状态发送给用户A和B，如此往复直到游戏结束为止。

    switch($action) {
      case 'opened':
        $game_key = $_REQUEST['g'];
        $game = Game::get_by_key_name($game_key);
        $game_updater_instance = new GameUpdater($game);
        $game_updater_instance->send_update();
        break;
      case 'move':
        $game_key = $_REQUEST['g'];
        $game = Game::get_by_key_name($game_key);
        $user = $_COOKIE['u'];
        if ($game and $user) {
          $id = $_REQUEST['i'];
          $game_updater_instance = new GameUpdater($game);
          $game_updater_instance->make_move($id,$user);
        }
        break;
      default:
        die('Illegal request');
    }

    class GameUpdater
    {
        public $game;
        function __construct($game) 
        {
          $this->game = $game;
          $this->channel = new SaeChannel();
        }

        function get_game_message()
        {
          $GameUpdater = array(
            'board' => $this->game->board,
            'userX' => $this->game->userX,
            'userO' => $this->game->userO,
            'moveX' => $this->game->moveX,
            'winner' => $this->game->winner,
            'winningBoard' => $this->game->winning_board,
            );
          return json_encode($GameUpdater);
        }

        function send_update()
        {
          $message = $this->get_game_message();
          $this->channel->sendMessage($this->game->userX.$this->game->key_name,$message);
          if ($this->game->userO) {
            $this->channel->sendMessage($this->game->userO.$this->game->key_name,$message);
          }
        }

        function check_win()
        {
          if ($this->game->moveX) {
              # O just moved, check for O wins
                          $potential_winner = $this->game->userO;
                          $wins = array_map(function($a){return str_replace('X','O',$a);},Wins::$x_win_patterns);
              //$wins = Wins::$o_win_patterns;
          } else {
                          $potential_winner = $this->game->userX;
              $wins = Wins::$x_win_patterns;
          }
          foreach ($wins as $small) {
            if ( $this->check_regual( $this->game->board, $small) ) {
              $this->game->winner = $potential_winner;
              $this->game->winning_board = $small;
              return true;
            }
          }
          return false;
        }

        ...

        function make_move( $position, $user )
        {
          if ($user>0 and $user == $this->game->userX or $user == $this->game->userO) {
            if($this->game->moveX == ($user == $this->game->moveX)) {
              $boardList = $this->str2array($this->game->board);
              if ($boardList[$position] == ' ') {
                $boardList[$position] = $this->game->moveX ? 'X' : 'O';
                $this->game->board = implode("", $boardList);
                $this->game->moveX = !$this->game->moveX;
                $this->check_win();
                $this->game->put();
                $this->send_update();
                return true;          
              }
            }
          }
          return false; 
        }

        ...
    }

GameUpdater类检查move的请求是否合法，如果合法则更新游戏的状态并且通知游戏双方新的游戏状态。

注意事项：

1. 每个html页面最多可以建立1个channel连接。
2. 每个创建的channel只允许一个channel客户端连接。
