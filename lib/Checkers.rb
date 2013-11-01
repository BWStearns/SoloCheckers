# REV: I don't love the name Checker only because the name is so
#      close to Checkers. Piece seems more expressive and has
#      less potential for confusion. When I first saw this
#      class I thought it was a game class, not a piece class.
class Checker

  # REV: The way functionality is abstracted out between
  #      Checker and Board classes results in you needing
  #      to pass a lot between each with the accessor.
  #
  #      The really extreme example here is the fact that
  #      it's you have to pass a board variable from
  #      the Checker class to the Board class...
  attr_accessor :player, :king, :location, :board, :king_index

  def initialize(board, location, player = :r)
    # REV: Not really sure why you initialize the board's grid
    #      to this variable. Initializing an instance of the
    #      board class to this variable would be more typical.
    @board = board.grid
    @board[location[0]][location[1]] = self
    @player = player
    @location = location
    @king = false
    @king_index = { :r => 0 , :b => 7 }
  end

  def king_me?
    location[0] == self.king_index[player]
  end

  # REV: I think it might be easier to track what's going on here
  #      with piece movement if you abstracted jumps and slides
  #      into separate functions.

  def perform_moves(moves)
    begin
      # REV: Like Marshal for this. However, this might make more
      #      sense abstracted out to a clone function on the
      #      board class.
      fake_board = Marshal.dump(Marshal.load(board))
      fake_board[location[0]][location[1]].perform_moves!(moves)
    rescue
      raise "InvalidMoveError"
    end
  end

  def perform_moves!(moves)
    moves.reverse!
    while moves.length > 0
      perform_move(moves.pop)

      # REV: Don't love board.display here as the function isn't
      #      otherwise concerned with UI. Better to handle display
      #      on a high level function in your Board class or in a 
      #      Game class.
      board.display
    end
  end

  # REV: Not a great name. Maintenance is really general and gives
  #      me no sense what this function really does.
  def maintenance
    self.king = true if king_me?
  end

  # refactor this top half into a separate "remove_killed_piece function"
  # also figure out some way to pass attack or not instead of checking inline
  def perform_move(target)
    if get_allowed_moves.include? target
      if target.delta_math(location){ |x,y| x-y }.all? {|x| x.abs == 2}
        loc = target.delta_math(location){ |x,y| x-y }.map{|x| x/2}
        loc.delta_math!(location)
        self.board[loc[0]][loc[1]] = nil
      end
      board[location[0]][location[1]] = nil
      p location
      self.location = target
      self.board[target[0]][target[1]] = self
    end
    puts "Maintain!"
    maintenance if king != true   ## Add a maintenance method to check for kinging etc.
  end

  def get_allowed_moves
    # REV: unless determine_attacks.empty? is more expressive in this case.
    return determine_attacks if determine_attacks != []
    # REV: no need to call return here. Just implicit return.
    return default_moves
  end

  def default_moves
    direction = player == :r ? -1 : 1
    look =  [[1,1], [1,-1], [-1, 1], [-1,-1]]
    results = []
    look = look.keep_if{ |loc| loc[0] == direction } if king != true

    look.each{ |pos| results << location.delta_math(pos) if board[pos[0]][pos[1]] == nil}
    # REV: whtie space here
    results.keep_if {|pos| move_on_board?(pos)}
  end

  def determine_attacks
    possibles = default_moves # refactor a bit later
    # REV: Use 'do |mov|' and break this over multiple lines. It's just too long.
    attacks = possibles.keep_if{ |mov| board[mov[0]][mov[1]].class == Checker && board[mov[0]][mov[1]].player != player}
    attacks.keep_if do |attack|
      jump = attack.delta_math(offset(attack))
      board[jump[0]][jump[1]].nil?
    end
    # REV: white space here
    attacks.map!{|attack| attack.delta_math(offset(attack))}
  end

  def move_on_board?(coord)
    coord.all? { |x| (0..7).include? x }
  end

  def offset(tgt)
    location.delta_math(tgt){ |x,y| y-x }
  end

end


class Array

  def delta_math(delta, &prc)
    self.dup.delta_math!(delta, &prc)
  end

  def delta_math!(delta, &prc)
    prc = Proc.new{ |x,y| x + y } unless prc
    self.each_with_index { |item,index| self[index] = prc.call(item,delta[index]) }
  end
end
