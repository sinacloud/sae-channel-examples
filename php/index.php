<?php
require( dirname(__FILE__).'/render.php' );
require( dirname(__FILE__).'/game.php' );

$user = $_COOKIE['u'];
if (!$user) {
	$user = uniqid();
	setcookie("u",$user);
}

$game_key = $_REQUEST['g'];
if (!$game_key) {
	$game_key = $user;
	$stor_mess = array(
			'userX' => $user,
			'userO' => null,
			'board' => str_repeat(" ",9),
			'moveX' => true,
			'winner' => null,
			'winning_board'=>null,
			);
	$game = new Game($game_key,$stor_mess);
	$game->put();
} else {
	$game = Game::get_by_key_name($game_key);
	if (!$game->userO) {
		$game ->userO = $user;
		$game->put();
	}
}

$game_link = '/?g='.$game_key;
if ( $game ) {
	$channel_instance = new SaeChannel();
	$token = $channel_instance->create_channel($user.$game_key);
	$game_update_instance = new GameUpdater($game);
	$initial_message = $game_update_instance->get_game_message();
} else {
	die('No such game');
}

$render_message = array(
	'token' => $token,
	'me' => $user,
	'game_key' => $game_key,
	'game_link' => $game_link,
	'initial_message' => $initial_message,
	);
$template_file = 'index.tpl';
$ret = render_template($template_file, $render_message);
echo($ret);
