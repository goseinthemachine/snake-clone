GRID_SIZE = 20
SPEED = 10

def render_grid args
  (0..@state.field.x).each do |x|
    args.outputs.lines << [x * GRID_SIZE, 0, x * GRID_SIZE, args.grid.h]
  end
  (0..@state.field.y).each do |y|
    args.outputs.lines << [0, y * GRID_SIZE, args.grid.w, y * GRID_SIZE]
  end
end

def render_boundaries args
  args.outputs.solids << [@left_wall, @right_wall, @top_wall, @bottom_wall]
end

def render_collectable args
  args.outputs.solids << @state.collectable
end

def render_player args
  args.outputs.solids << [@state.player, *@state.body]
end

def render_score args
  args.outputs.labels << [args.grid.left + 24, args.grid.top - 24, "Score: #{@state.score}"]
end

def render_game_over args
  args.outputs.labels << {x: args.grid.w / 2, y: (args.grid.h / 2).shift_up(16), text: "GAME OVER!", size_enum: 10, alignment_enum: 1 }
  args.outputs.labels << {x: args.grid.w / 2, y: (args.grid.h / 2).shift_down(24), text: "Final Score was #{@state.score} points!", size_enum: 1, alignment_enum: 1 }
  args.outputs.labels << {x: args.grid.w / 2, y: (args.grid.h / 2).shift_down(48), text: "Press Escape to try again", size_enum: 0, alignment_enum: 1}
end

def move_segments args
  @state.body.each_with_index do |segment, index|
    if index == 0
      @state.body[index].direction = @state.player.previous_direction
    else
      @state.body[index].direction = @state.body[index - 1].previous_direction
    end
  end

  snake = [@state.player, *@state.body]

  snake.each_with_index do |segment, index|
    segment.previous_direction = segment.direction
    vector = {x: 0, y: 0}
    if args.tick_count.mod_zero? SPEED
      case segment.direction
      when :right
        vector.x = 1
      when :left
        vector.x = -1
      when :down
        vector.y = -1
      when :up
        vector.y = 1
      end

      segment.x += (GRID_SIZE * vector.x) 
      segment.y += (GRID_SIZE * vector.y)
      
    end
  end
end

def spawn_collectable args
  if @state.collectable.nil? && args.tick_count.mod_zero?(SPEED)
    random_x = (GRID_SIZE * rand(args.grid.w / GRID_SIZE)).clamp(GRID_SIZE, @right_wall.x - GRID_SIZE)
    random_y = (GRID_SIZE * rand(args.grid.h / GRID_SIZE)).clamp(GRID_SIZE, @top_wall.y - GRID_SIZE)
    @state.collectable = {x: random_x, y: random_y, w: GRID_SIZE, h: GRID_SIZE, r: 234, g: 32, b: 3 }
  end
end

def new_segment
  vector = {x: 0, y:0 }
  segment = @state.body.last.clone || @state.player.clone
  if segment.direction == :right
    vector.x = -1
  elsif segment.direction == :left
    vector.x = 1
  elsif segment.direction == :down
    vector.y = 1
  elsif segment.direction == :up
    vector.y = -1
  end

  segment.x += (GRID_SIZE * vector.x)
  segment.y += (GRID_SIZE * vector.y)
  segment.x = segment.x.clamp(GRID_SIZE, @right_wall.x - GRID_SIZE)
  segment.y = segment.y.clamp(GRID_SIZE, @top_wall.y - GRID_SIZE)
  segment
end

def player_collects args
  unless @state.collectable.nil?
    if @state.player.inside_rect? @state.collectable
      @state.score += 1
      args.audio[:bite] = {
        input: 'sounds/bite.wav',  # Filename
        x: 0.0, y: 0.0, z: 0.0,   # Relative position to the listener, x, y, z from -1.0 to 1.0
        gain: 1.0,                # Volume (0.0 to 1.0)
        pitch: 1.0,               # Pitch of the sound (1.0 = original pitch)
        paused: false,            # Set to true to pause the sound at the current playback position
        looping: false,           # Set to true to loop the sound/music until you stop it
      }
      @state.body << new_segment
      @state.collectable = nil
    end
  end
end

def check_player_collision args
  if @state.body.any? { |segment| segment.intersect_rect? @state.player } ||
    [@top_wall,@right_wall,@bottom_wall,@left_wall].any? { |wall| wall.intersect_rect? @state.player }
    @state.game_state = :game_over
  end
end
def clamp_entities args
  snake = [@state.player, *@state.body]
  snake.each do |segment|
    segment.x = segment.x.clamp(GRID_SIZE, @right_wall.x - GRID_SIZE)
    segment.y = segment.y.clamp(GRID_SIZE, @top_wall.y - GRID_SIZE)
  end
end
def defaults args
  @state ||= args.state
  @inputs ||= args.inputs
  @state.field ||= { x: args.grid.w / GRID_SIZE, y: args.grid.h / GRID_SIZE }
  @state.player ||= { x: @state.field.x / 2 * GRID_SIZE, y: @state.field.y / 2 * GRID_SIZE, w: GRID_SIZE, h: GRID_SIZE, r: 12, g: 255, b: 33 }
  @state.player.direction ||= :right
  @state.score ||= 0
  @state.collectable ||= nil
  @state.body ||= []
  @left_wall ||= {x: args.grid.left, y: args.grid.bottom, h: args.grid.h, w: GRID_SIZE, r: 12, g: 33, b: 245 }
  @right_wall ||= {x: args.grid.right - GRID_SIZE, y: args.grid.bottom, h: args.grid.h, w: GRID_SIZE, r: 12, g: 33, b: 245 }
  @top_wall ||= {x: args.grid.left, y: args.grid.top - GRID_SIZE, h: GRID_SIZE, w: args.grid.w, r: 12, g: 33, b: 245 }
  @bottom_wall ||= {x: args.grid.left, y: args.grid.bottom, h: GRID_SIZE, w: args.grid.w, r: 12, g: 33, b: 245 }
  args.audio[:main] ||= {
      input: 'sounds/snake.ogg',  # Filename
      x: 0.0, y: 0.0, z: 0.0,   # Relative position to the listener, x, y, z from -1.0 to 1.0
      gain: 0.25,                # Volume (0.0 to 1.0)
      pitch: 1.0,               # Pitch of the sound (1.0 = original pitch)
      paused: false,            # Set to true to pause the sound at the current playback position
      looping: true   
  }
end

def reset_game args
  @state.player = { x: @state.field.x / 2 * GRID_SIZE, y: @state.field.y / 2 * GRID_SIZE, w: GRID_SIZE, h: GRID_SIZE, r: 12, g: 255, b: 33 }
  @state.player.direction = :right
  @state.score = 0
  @state.collectable = nil
  @state.body = [] 
  @state.game_state = :playing
end

def handle_input args
  if @state.game_state == :game_over
    if @inputs.keyboard.key_down.escape
      reset_game args
    end
  else 
    if args.tick_count.mod_zero? SPEED
      if @inputs.left && @state.player.previous_direction != :right
        @state.player.previous_direction = @state.player.direction
        @state.player.direction = :left
      elsif @inputs.right && @state.player.previous_direction != :left
        @state.player.previous_direction = @state.player.direction
        @state.player.direction = :right
      elsif @inputs.down && @state.player.previous_direction != :up
        @state.player.previous_direction = @state.player.direction
        @state.player.direction = :down
      elsif @inputs.up && @state.player.previous_direction != :down
        @state.player.previous_direction = @state.player.direction
        @state.player.direction = :up
      end
    end
  end
end

def update args
  if args.tick_count.mod_zero? SPEED
    move_segments args
    spawn_collectable args
    player_collects args
    check_player_collision args
    clamp_entities args
  end
end

def render args
  # render_grid args
  if @state.game_state == :game_over
    render_game_over args
  else
    render_collectable args
    render_player args
    render_boundaries args
    render_score args
  end
end


def tick args
  defaults args
  handle_input args 
  update args
  render args
end
