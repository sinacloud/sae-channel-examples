#!/usr/bin/python2.4
#
# pylint: disable-msg=C6310

"""Channel Tic Tac Toe

This module demonstrates Sina App Engine Channel API by implementing a
simple tic-tac-toe game.
"""

import datetime
import logging
import os
import random
import re
import json
import uuid

import tornado.web
import tornado.wsgi

import pylibmc as memcache
from sae import channel

mc = memcache.Client()

class Game:
  """All the data we store for a game"""
  def __init__(self, key_name, **args):
    self.key_name = key_name
    self.userX = args.get('userX')
    self.userO = args.get('userO')
    self.board = args.get('board')
    self.moveX = args.get('moveX')
    self.winner = args.get('winner')
    self.winning_board = args.get('winning_board')

  @classmethod
  def get_by_key_name(cls, key_name):
    if isinstance(key_name, unicode):
        key_name = key_name.encode('utf8')
    data = mc.get(key_name)
    if data:
        return cls(key_name, **data)

  def put(self):
    mc.set(self.key_name, {
        'userX': self.userX,
        'userO': self.userO,
        'board': self.board,
        'moveX': self.moveX,
        'winner': self.winner,
        'winning_board': self.winning_board,})
  
class Wins():
  x_win_patterns = ['XXX......',
                    '...XXX...',
                    '......XXX',
                    'X..X..X..',
                    '.X..X..X.',
                    '..X..X..X',
                    'X...X...X',
                    '..X.X.X..']

  o_win_patterns = map(lambda s: s.replace('X','O'), x_win_patterns)
  
  x_wins = map(lambda s: re.compile(s), x_win_patterns)
  o_wins = map(lambda s: re.compile(s), o_win_patterns)


class GameUpdater():
  game = None

  def __init__(self, game):
    self.game = game

  def get_game_message(self):
    gameUpdate = {
      'board': self.game.board,
      'userX': self.game.userX,
      'userO': '' if not self.game.userO else self.game.userO,
      'moveX': self.game.moveX,
      'winner': self.game.winner,
      'winningBoard': self.game.winning_board
    }
    return json.dumps(gameUpdate)

  def send_update(self):
    message = self.get_game_message()
    channel.send_message(self.game.userX + self.game.key_name, message)
    if self.game.userO:
      channel.send_message(self.game.userO + self.game.key_name, message)

  def check_win(self):
    if self.game.moveX:
      # O just moved, check for O wins
      wins = Wins().o_wins
      potential_winner = self.game.userO
    else:
      # X just moved, check for X wins
      wins = Wins().x_wins
      potential_winner = self.game.userX
      
    for win in wins:
      if win.match(self.game.board):
        self.game.winner = potential_winner
        self.game.winning_board = win.pattern
        return

  def make_move(self, position, user):
    if position >= 0 and user == self.game.userX or user == self.game.userO:
      if self.game.moveX == (user == self.game.userX):
        boardList = list(self.game.board)
        if (boardList[position] == ' '):
          boardList[position] = 'X' if self.game.moveX else 'O'
          self.game.board = "".join(boardList)
          self.game.moveX = not self.game.moveX
          self.check_win()
          self.game.put()
          self.send_update()
          return


class MovePage(tornado.web.RequestHandler):

  def post(self):
    game_key = self.get_argument('g')
    game = Game.get_by_key_name(game_key)
    user = self.get_secure_cookie('u')
    if game and user:
      id = int(self.get_argument('i'))
      GameUpdater(game).make_move(id, user)


class OpenedPage(tornado.web.RequestHandler):

  def post(self):
    game_key = self.get_argument('g')
    game = Game.get_by_key_name(game_key)
    GameUpdater(game).send_update()


class MainPage(tornado.web.RequestHandler):
  """The main UI page, renders the 'index.html' template."""

  def get(self):
    """Renders the main page. When this page is shown, we create a new
    channel to push asynchronous updates to the client."""
    user = self.get_secure_cookie('u')
    if user is None:
      user = uuid.uuid4().hex
      self.set_secure_cookie('u', user)
    game_key = self.get_argument('g', None)
    if game_key is None:
      game_key = user
      game = Game(key_name = game_key,
                  userX = user,
                  moveX = True,
                  board = '         ')
      game.put()
    else:
      game = Game.get_by_key_name(game_key)
      if not game.userO:
        game.userO = user
        game.put()

    game_link = '/?g=' + game_key

    if game:
      url = channel.create_channel(user + game_key)
      template_values = {'url': token,
                         'me': user,
                         'game_key': game_key,
                         'game_link': game_link,
                         'initial_message': GameUpdater(game).get_game_message()
                        }
      path = os.path.join(os.path.dirname(__file__), 'index.html')
      self.render(path, **template_values)
    else:
      self.write('No such game')

application = tornado.wsgi.WSGIApplication([
  ('/', MainPage),
  ('/opened', OpenedPage),
  ('/move', MovePage)
], debug=True, cookie_secret='0xcafebabe')

if __name__ == '__main__':
  import wsgiref.simple_server
  httpd = wsgiref.simple_server.make_server('', 8080, application)
  httpd.serve_forever()
