<?php
require( dirname(__FILE__).'/game.php' );

$action_check = array('opened','move');
$action = $_GET['action'];
if (!in_array($action, $action_check)) {
	die('Illegal request');
}
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
