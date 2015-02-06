<?php
/*
* Game class
*/
class Game
{
	public $key_name;
	public $userX;
	public $userO;
	public $board;
	public $moveX;
	public $winner;
	public $winning_board;
	public $link;

	function __construct( $key_name, $params )
	{
		$this->key_name = $key_name;
		$this->userX = $params['userX'];
		$this->userO = $params['userO'];
		$this->board = $params['board'];
		$this->moveX = $params['moveX'];
		$this->winner = $params['winner'];
		$this->winning_board = $params['winning_board'];
		$this->link = memcache_init();
	}

	public static function get_by_key_name($key_name)
	{
            $link = memcache_init();
            if (!$key_name) {
                return false;
            }
            $data = memcache_get($link,$key_name);
		$new_obj = new Game($key_name,$data);
		return $new_obj;
	}

	public function put()
	{
		$stor_mess = array(
			'userX' => $this->userX,
			'userO' => $this->userO,
			'board' => $this->board,
			'moveX' => $this->moveX,
			'winner' => $this->winner,
			'winning_board' => $this->winning_board,
			);
		$ret = memcache_set($this->link, $this->key_name,$stor_mess);
		return $ret;
	}
}

class Wins
{
	public static $x_win_patterns = array(
		'XXX......',
		'...XXX...',
		'......XXX',
		'X..X..X..',
		'.X..X..X.',
		'..X..X..X',
		'X...X...X',
		'..X.X.X..');
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

	private function check_regual( $now_stat, $regual)
	{
		$after = str_repeat(" ",9);;
		$after_array = $this->str2array($after);
		for ( $i = 0; $i < 9; $i++ ) {
			if($regual[$i] == '.') {
				$after_array[$i] = '.';
			} else {
				$after_array[$i] = $now_stat[$i];
			}
		}
		$after = implode("", $after_array);
		return($after == $regual);
	}

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

	private function str2array($str)
	{
		$ret = array();
		for ( $i = 0; $i < strlen($str); $i++) {
			$ret[$i] = $str[$i];
		}
		return $ret;
	}

}
