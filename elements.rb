require 'minigl'
include MiniGL

############################### classes abstratas ##############################

class TwoStateObject < GameObject
  def initialize(x, y, w, h, img, img_gap, sprite_cols, sprite_rows,
    change_interval, anim_interval, change_anim_interval, s1_indices, s2_indices, s1_s2_indices, s2_s1_indices, s2_first = false)
    super x, y, w, h, img, img_gap, sprite_cols, sprite_rows

    @timer = 0
    @changing = false
    @change_interval = change_interval
    @anim_interval = anim_interval
    @change_anim_interval = change_anim_interval
    @s1_indices = s1_indices
    @s2_indices = s2_indices
    @s1_s2_indices = s1_s2_indices
    @s2_s1_indices = s2_s1_indices
    @state2 = s2_first
    set_animation s2_indices[0] if s2_first
  end

  def update(section)
    @timer += 1
    if @timer == @change_interval
      @state2 = (not @state2)
      if @state2
        s1_to_s2 section
        set_animation @s1_s2_indices[0]
      else
        s2_to_s1 section
        set_animation @s2_s1_indices[0]
      end
      @changing = true
      @timer = 0
    end

    if @changing
      if @state2
        animate @s1_s2_indices, @change_anim_interval
        if @img_index == @s1_s2_indices[-1]
          set_animation @s1_s2_indices[-2]
          @changing = false
        end
      else
        animate @s2_s1_indices, @change_anim_interval
        if @img_index == @s2_s1_indices[-1]
          set_animation @s2_s1_indices[-2]
          @changing = false
        end
      end
    elsif @state2
      animate @s2_indices, @anim_interval if @anim_interval > 0
    else
      animate @s1_indices, @anim_interval if @anim_interval > 0
    end
  end
end

################################################################################

class Goal < GameObject
  def initialize(x, y, args, section)
    super x - 4, y - 118, 40, 150, :sprite_goal1, nil, 2, 2
    @active_bounds = Rectangle.new x - 4, y - 118, 40, 150
  end

  def update(section)
    animate [0, 1, 2, 3], 7
    section.finish if SB.player.bomb.collide? self
  end
end

class Bombie < GameObject
  def initialize(x, y, args, section)
    super x - 16, y, 64, 32, :sprite_Bombie, Vector.new(17, -2), 6, 1
    @msg_id = "msg#{args.to_i}".to_sym
    @pages = SB.text(@msg_id).split('/').size
    @balloon = Res.img :fx_Balloon1
    @facing_right = false
    @active = false
    @speaking = false
    @interval = 8

    @active_bounds = Rectangle.new x - 16, y, 64, 32
  end

  def update(section)
    if SB.player.bomb.collide? self
      if not @facing_right and SB.player.bomb.bounds.x > @x + @w / 2
        @facing_right = true
        @indices = [3, 4, 5]
        set_animation 3
      elsif @facing_right and SB.player.bomb.bounds.x < @x + @w / 2
        @facing_right = false
        @indices = [0, 1, 2]
        set_animation 0
      end
      if KB.key_pressed? SB.key[:up]
        @speaking = (not @speaking)
        if @speaking
          if @facing_right; @indices = [3, 4, 5]
          else; @indices = [0, 1, 2]; end
          @active = false
        else
          @page = 0
          if @facing_right; set_animation 3
          else; set_animation 0; end
        end
      elsif @speaking and KB.key_pressed? SB.key[:down]
        if @page < @pages - 1
          @page += 1
        else
          @page = 0
          @speaking = false
          if @facing_right; set_animation 3
          else; set_animation 0; end
        end
      end
      @active = (not @speaking)
    else
      @page = 0
      @active = false
      @speaking = false
      if @facing_right; set_animation 3
      else; set_animation 0; end
    end

    animate @indices, @interval if @speaking
  end

  def draw(map)
    super map
    @balloon.draw @x - map.cam.x + 16, @y - map.cam.y - 32, 0 if @active
    speak(@msg_id, @page) if @speaking
  end
end

class Door < GameObject
  attr_reader :locked

  def initialize(x, y, args, section, switch)
    args = args.split(',')
    type = args[2]
    case type
    when '2' then x_g = -19; y_g = -89
    else          x_g = -10; y_g = -63
    end
    super x + 10, y + 63, 12, 1, "sprite_Door#{type}", Vector.new(x_g, y_g), 5, 1
    @entrance = args[0].to_i
    @locked = (switch[:state] != :taken and args[1] == '.')
    @open = false
    @active_bounds = Rectangle.new x, y, 32, 64
    @lock = Res.img(:sprite_Lock) if @locked
  end

  def update(section)
    collide = SB.player.bomb.collide? self
    if @locked and collide
      section.active_object = self
    elsif section.active_object == self
      section.active_object = nil
    end
    if not @locked and not @opening and collide
      if KB.key_pressed? SB.key[:up]
        set_animation 1
        @opening = true
      end
    end
    if @opening
      animate [1, 2, 3, 4, 0], 5
      if @img_index == 0
        section.warp = @entrance
        @opening = false
      end
    end
  end

  def unlock(section)
    @locked = false
    @lock = nil
    section.active_object = nil
    SB.stage.set_switch self
  end

  def draw(map)
    super map
    @lock.draw(@x + 9 - map.cam.x, @y - 38 - map.cam.y, 0) if @lock
  end
end

class GunPowder < GameObject
  def initialize(x, y, args, section, switch)
    return if switch && switch[:state] == :taken
    super x + 3, y + 19, 26, 13, :sprite_GunPowder, Vector.new(-2, -2)
    @switch = !switch.nil?
    @life = 10
    @counter = 0

    @active_bounds = Rectangle.new x + 1, y + 17, 30, 15
  end

  def update(section)
    b = SB.player.bomb
    if b.collide? self and not b.will_explode
      b.set_exploding
      SB.stage.set_switch self if @switch
      @dead = true
    end
  end
end

class Crack < GameObject
  def initialize(x, y, args, section, switch)
    super x + 32, y, 32, 32, :sprite_Crack
    @active_bounds = Rectangle.new x + 32, y, 32, 32
    @broken = switch[:state] == :taken
  end

  def update(section)
    if @broken or SB.player.bomb.explode? self
      i = (@x / C::TILE_SIZE).floor
      j = (@y / C::TILE_SIZE).floor
      section.tiles[i][j].broken = true
      SB.stage.set_switch self
      @dead = true
    end
  end
end

class Elevator < GameObject
  def initialize(x, y, args, section)
    a = args.split(':')
    type = a[0].to_i
    open = a[0][-1] == '!'
    case type
      when 1 then w = 32; cols = rows = nil
      when 2 then w = 64; cols = 4; rows = 1
      when 3 then w = 64; cols = rows = nil
      when 4 then w = 64; cols = rows = nil
    end
    super x, y, w, 1, "sprite_Elevator#{type}", Vector.new(0, 0), cols, rows
    @passable = true

    @speed_m = a[1].to_i
    @moving = false
    @points = []
    min_x = x; min_y = y
    max_x = x; max_y = y
    ps = a[2..-1]
    ps.each do |p|
      coords = p.split ','
      p_x = coords[0].to_i * C::TILE_SIZE; p_y = coords[1].to_i * C::TILE_SIZE

      min_x = p_x if p_x < min_x
      min_y = p_y if p_y < min_y
      max_x = p_x if p_x > max_x
      max_y = p_y if p_y > max_y

      @points << Vector.new(p_x, p_y)
    end
    if open
      (@points.length - 2).downto(0) do |i|
        @points << @points[i]
      end
    end
    @points << Vector.new(x, y)
    @indices = *(0...@img.size)
    @active_bounds = Rectangle.new min_x, min_y, (max_x - min_x + w), (max_y - min_y + @img[0].height)

    section.obstacles << self
  end

  def update(section)
    b = SB.player.bomb
    cycle @points, @speed_m, section.passengers, section.get_obstacles(b.x, b.y), section.ramps
    animate @indices, 8
  end

  def is_visible(map)
    true
  end
end

class SaveBombie < GameObject
  def initialize(x, y, args, section, switch)
    super x - 16, y, 64, 32, :sprite_Bombie2, Vector.new(-16, -26), 4, 2
    @id = args.to_i
    @active_bounds = Rectangle.new x - 32, y - 26, 96, 58
    @saved = switch[:state] == :taken
    @indices = [1, 2, 3]
    set_animation 1 if @saved
  end

  def update(section)
    if not @saved and SB.player.bomb.collide? self
      section.save_check_point @id, self
      @saved = true
    end

    if @saved
      animate @indices, 8
    end
  end
end

class Pin < TwoStateObject
  def initialize(x, y, args, section)
    super x, y, 32, 32, :sprite_Pin, Vector.new(0, 0), 5, 1,
      60, 0, 3, [0], [4], [1, 2, 3, 4, 0], [3, 2, 1, 0, 4], (not args.nil?)

    @active_bounds = Rectangle.new x, y, 32, 32
    @obst = Block.new(x, y, 32, 32, true)
    section.obstacles << @obst if args
  end

  def s1_to_s2(section)
    section.obstacles << @obst
  end

  def s2_to_s1(section)
    section.obstacles.delete @obst
  end

  def is_visible(map)
    true
  end
end

class Spikes < TwoStateObject
  def initialize(x, y, args, section)
    @dir = args.to_i
    if @dir % 2 == 0
      x += 2; w = 28; h = 32
    else
      y += 2; w = 32; h = 28
    end
    super x, y, w, h, :sprite_Spikes, Vector.new(0, 0), 5, 1, 120, 0, 2, [0], [4], [1, 2, 3, 4, 0], [3, 2, 1, 0, 4]
    @active_bounds = Rectangle.new x, y, 32, 32
    @obst = Block.new(x + 2, y + 2, 28, 28)
  end

  def s1_to_s2(section)
    if SB.player.bomb.collide? @obst
      SB.player.bomb.hit
    else
      section.obstacles << @obst
    end
  end

  def s2_to_s1(section)
    section.obstacles.delete @obst
  end

  def update(section)
    super section

    b = SB.player.bomb
    if @state2 and b.collide? self
      if (@dir == 0 and b.y + b.h <= @y + 2) or
         (@dir == 1 and b.x >= @x + @w - 2) or
         (@dir == 2 and b.y >= @y + @h - 2) or
         (@dir == 3 and b.x + b.w <= @x + 2)
        SB.player.bomb.hit
      end
    end
  end

  def draw(map)
    angle = case @dir
              when 0 then 0
              when 1 then 90
              when 2 then 180
              when 3 then 270
            end
    @img[@img_index].draw_rot @x + @w/2 - map.cam.x, @y + @h/2 - map.cam.y, 0, angle
  end
end

class FixedSpikes < GameObject
  def initialize(x, y, args, section)
    @dir = args.to_i
    if @dir % 2 == 0
      super x + 2, y, 28, 32, :sprite_Spikes, Vector.new(0, 0), 5, 1
    else
      super x, y + 2, 32, 28, :sprite_Spikes, Vector.new(0, 0), 5, 1
    end
    @active_bounds = Rectangle.new x, y, 32, 32
    section.obstacles << Block.new(x + 2, y + 2, 28, 28)
  end

  def update(section)
    b = SB.player.bomb
    if b.collide? self
      if (@dir == 0 and b.y + b.h <= @y + 2) or
         (@dir == 1 and b.x >= @x + @w - 2) or
         (@dir == 2 and b.y >= @y + @h - 2) or
         (@dir == 3 and b.x + b.w <= @x + 2)
        SB.player.bomb.hit
      end
    end
  end

  def draw(map)
    angle = case @dir
              when 0 then 0
              when 1 then 90
              when 2 then 180
              when 3 then 270
            end
    @img[4].draw_rot @x + @w/2 - map.cam.x, @y + @h/2 - map.cam.y, 0, angle
  end
end

class MovingWall < GameObject
  attr_reader :id

  def initialize(x, y, args, section)
    super x + 2, y + C::TILE_SIZE, 28, 0, :sprite_MovingWall, Vector.new(0, 0), 1, 2
    args = args.split ','
    @id = args[0].to_i
    @closed = args[1].nil?
    if @closed
      until section.obstacle_at? @x, @y - 1
        @y -= C::TILE_SIZE
        @h += C::TILE_SIZE
      end
    else
      @max_size = C::TILE_SIZE * args[1].to_i
    end
    @active_bounds = Rectangle.new @x, @y, @w, @h
    section.obstacles << self
  end

  def update(section)
    if @active
      @timer += 1
      if @timer == 30
        @y += @closed ? 16 : -16
        @h += @closed ? -16 : 16
        @active_bounds = Rectangle.new @x, @y, @w, @h
        @timer = 0
        if @closed and @h == 0
          @dead = true
        elsif not @closed and @h == @max_size
          @active = false
        end
      end
    end
  end

  def activate
    @active = true
    @timer = 0
  end

  def draw(map)
    @img[0].draw @x - map.cam.x, @y - map.cam.y, 0 if @h > 0
    y = 16
    while y < @h
      @img[1].draw @x - map.cam.x, @y + y - map.cam.y, 0
      y += 16
    end
  end
end

class Ball < GameObject
  def initialize(x, y, args, section, switch)
    super x, y, 32, 32, :sprite_Ball
    @set = switch[:state] == :taken
    @start_x = x
    @rotation = 0
    @active_bounds = Rectangle.new @x, @y, @w, @h
    section.passengers << self
  end

  def update(section)
    if @set
      if @rec.nil?
        @rec = section.get_next_ball_receptor
        @x = @active_bounds.x = @rec.x
        @y = @active_bounds.y = @rec.y - 31
      end
      @x += (0.1 * (@rec.x - @x)) if @x.round(2) != @rec.x
    else
      forces = Vector.new 0, 0
      if SB.player.bomb.collide? self
        if SB.player.bomb.x <= @x; forces.x = (SB.player.bomb.x + SB.player.bomb.w - @x) * 0.15
        else; forces.x = -(@x + @w - SB.player.bomb.x) * 0.15; end
      end
      if @bottom
        if @speed.x != 0
          forces.x -= 0.15 * @speed.x
        end

        SB.stage.switches.each do |s|
          if s[:type] == BallReceptor and bounds.intersect? s[:obj].bounds
            next if s[:obj].is_set
            s[:obj].set section
            s2 = SB.stage.find_switch self
            s2[:extra] = @rec = s[:obj]
            s2[:state] = :temp_taken
            @active_bounds.x = @rec.x
            @active_bounds.y = @rec.y - 31
            @set = true
            return
          end
        end
      end
      move forces, section.get_obstacles(@x, @y), section.ramps

      @active_bounds = Rectangle.new @x, @y, @w, @h
      @rotation = 3 * (@x - @start_x)
    end
  end

  def draw(map)
    @img[0].draw_rot @x + (@w / 2) - map.cam.x, @y + (@h / 2) - map.cam.y, 0, @rotation
  end
end

class BallReceptor < GameObject
  attr_reader :id, :is_set

  def initialize(x, y, args, section, switch)
    super x, y + 31, 32, 1, :sprite_BallReceptor, Vector.new(0, -8), 1, 2
    @id = args.to_i
    @will_set = switch[:state] == :taken
    @active_bounds = Rectangle.new x, y + 23, 32, 13
  end

  def update(section)
    if @will_set
      section.activate_wall @id
      @is_set = true
      @img_index = 1
      @will_set = false
    end
  end

  def set(section)
    SB.stage.set_switch self
    section.activate_wall @id
    @is_set = true
    @img_index = 1
  end
end

class HideTile
  def initialize(i, j, group, tiles, num)
    @state = 0
    @alpha = 0xff
    @color = 0xffffffff

    @group = group
    @points = []
    check_tile i, j, tiles, 4

    @img = Res.imgs "sprite_ForeWall#{num}".to_sym, 5, 1
  end

  def check_tile(i, j, tiles, dir)
    return -1 if tiles[i].nil? or tiles[i][j].nil?
    return tiles[i][j].wall if tiles[i][j].hide < 0
    return 0 if tiles[i][j].hide == @group

    tiles[i][j].hide = @group
    t = 0; r = 0; b = 0; l = 0
    t = check_tile i, j-1, tiles, 0 if dir != 2
    r = check_tile i+1, j, tiles, 1 if dir != 3
    b = check_tile i, j+1, tiles, 2 if dir != 0
    l = check_tile i-1, j, tiles, 3 if dir != 1
    if t < 0 and r >= 0 and b >= 0 and l >= 0; img = 1
    elsif t >= 0 and r < 0 and b >= 0 and l >= 0; img = 2
    elsif t >= 0 and r >= 0 and b < 0 and l >= 0; img = 3
    elsif t >= 0 and r >= 0 and b >= 0 and l < 0; img = 4
    else; img = 0; end

    @points << {x: i * C::TILE_SIZE, y: j * C::TILE_SIZE, img: img}
    0
  end

  def update(section)
    will_show = false
    @points.each do |p|
      rect = Rectangle.new p[:x], p[:y], C::TILE_SIZE, C::TILE_SIZE
      if SB.player.bomb.bounds.intersect? rect
        will_show = true
        break
      end
    end
    if will_show; show
    else; hide; end
  end

  def show
    if @state != 2
      @alpha -= 17
      if @alpha == 51
        @state = 2
      else
        @state = 1
      end
      @color = 0x00ffffff | (@alpha << 24)
    end
  end

  def hide
    if @state != 0
      @alpha += 17
      if @alpha == 0xff
        @state = 0
      else
        @state = 1
      end
      @color = 0x00ffffff | (@alpha << 24)
    end
  end

  def is_visible(map)
    true
  end

  def draw(map)
    @points.each do |p|
      @img[p[:img]].draw p[:x] - map.cam.x, p[:y] - map.cam.y, 0, 1, 1, @color
    end
  end
end

class Projectile < GameObject
  attr_reader :owner

  def initialize(x, y, type, angle, owner)
    case type
    when 1 then w = 20; h = 12; x_g = -2; y_g = -2; cols = 3; rows = 1; indices = [0, 1, 0, 2]; @speed_m = 3
    when 2 then w = 8; h = 8; x_g = -2; y_g = -2; cols = 4; rows = 2; indices = [0, 1, 2, 3, 4, 5, 6, 7]; @speed_m = 2.5
    when 3 then w = 4; h = 40; x_g = 0; y_g = 0; cols = 1; rows = 1; indices = [0]; @speed_m = 6
    when 4 then w = 16; h = 22; x_g = -2; y_g = 0; cols = 1; rows = 1; indices = [0]; @speed_m = 5
    end

    super x - x_g, y - y_g, w, h, "sprite_Projectile#{type}", Vector.new(x_g, y_g), cols, rows
    # rads = angle * Math::PI / 180
    # @aim = Vector.new @x + (1000000 * Math.cos(rads)), @y + (1000000 * Math.sin(rads))
    @active_bounds = Rectangle.new @x + @img_gap.x, @y + @img_gap.y, @img[0].width, @img[0].height
    @angle = angle
    @owner = owner
    @indices = indices
  end

  def update(section)
    move_free(@angle, @speed_m)

    t = (@y + @img_gap.y).floor
    r = (@x + @img_gap.x + @img[0].width).ceil
    b = (@y + @img_gap.y + @img[0].height).ceil
    l = (@x + @img_gap.x).floor
    if t > section.size.y || r < 0 || b < C::TOP_MARGIN || l > section.size.x
      @dead = true
    end

    unless @dead
      animate @indices, 5
      @active_bounds = Rectangle.new @x + @img_gap.x, @y + @img_gap.y, @img[0].width, @img[0].height
    end
  end

  def draw(map)
    @img[@img_index].draw_rot @x + (@w / 2) - map.cam.x, @y + (@h / 2) - map.cam.y, 0, @angle
  end
end

class Poison < GameObject
  def initialize(x, y, args, section)
    super x, y + 31, 32, 1, :sprite_poison, Vector.new(0, -19), 3, 1
    @active_bounds = Rectangle.new(x, y - 19, 32, 28)
  end

  def update(section)
    animate [0, 1, 2], 8
    if SB.player.bomb.collide? self
      SB.player.bomb.hit
    end
  end
end

class Vortex < GameObject
  def initialize(x, y, args, section)
    super x - 11, y - 11, 54, 54, :sprite_vortex, Vector.new(-5, -5), 2, 2
    @active_bounds = Rectangle.new(@x, @y, @w, @h)
    @angle = 0
    @entrance = args.to_i
  end

  def update(section)
    animate [0, 1, 2, 3, 2, 1], 5
    @angle += 5
    @angle = 0 if @angle == 360

    b = SB.player.bomb
    if @transporting
      b.move_free @aim, 1.5
      @timer += 1
      if @timer == 32
        section.add_effect(Effect.new(@x - 3, @y - 3, :fx_transport, 2, 2, 7, [0, 1, 2, 3], 28))
      elsif @timer == 60
        section.warp = @entrance
        @transporting = false
        b.active = true
      end
    else
      if b.collide? self
        b.active = false
        @aim = Vector.new(@x + (@w - b.w) / 2, @y + (@h - b.h) / 2 + 3)
        @transporting = true
        @timer = 0
      end
    end
  end

  def draw(map)
    @img[@img_index].draw_rot @x + @w / 2 - map.cam.x, @y + @h/2 - map.cam.y, 0, @angle
  end
end

class AirMattress < GameObject
  def initialize(x, y, args, section)
    super x + 2, y + 16, 60, 1, :sprite_airMattress, Vector.new(-2, -2), 1, 3
    @active_bounds = Rectangle.new(x, y + 15, 64, 32)
    @color = (args || 'ffffff').to_i(16)
    @timer = 0
    @points = [
      Vector.new(@x, @y),
      Vector.new(@x, @y + 16)
    ]
    @speed_m = 0.16
    @passable = true
    @state = :normal
    section.obstacles << self
  end

  def update(section)
    b = SB.player.bomb
    if @state == :normal
      if b.bottom == self
        @state = :down
        @timer = 0
        set_animation 0
      else
        x = @timer + 0.5
        @speed_m = -0.0001875 * x**2 + 0.015 * x
        cycle @points, @speed_m, [b]
        @timer += 1
        if @timer == 80
          @timer = 0
        end
      end
    elsif @state == :down
      animate [0, 1, 2], 8 if @img_index != 2
      if b.bottom == self
        move_carrying Vector.new(@x, @y + 1), 0.3, [b], section.get_obstacles(b.x, b.y), section.ramps
      else
        @state = :up
        set_animation 2
      end
    elsif @state == :up
      animate [2, 1, 0], 8 if @img_index != 0
      move_carrying Vector.new(@x, @y - 1), 0.3, [b], section.get_obstacles(b.x, b.y), section.ramps
      if SB.player.bomb.bottom == self
        @state = :down
      elsif @y.round == @points[0].y
        @y = @points[0].y
        @state = :normal
      end
    end
  end

  def draw(map)
    super map, 1, 1, 255, @color
  end
end

class Branch < GameObject
  def initialize(x, y, args, section)
    a = args ? args.split(',') : []
    size = a[0] ? a[0].to_i : 2
    super x, y, size * C::TILE_SIZE, 1, :sprite_branch, Vector.new(0, 0)
    @passable = true
    @active_bounds = Rectangle.new(@x, @y, @w, @img[0].height)
    @left = a[1].nil?
    @scale = size.to_f / 2
    section.obstacles << self
  end

  def update(section); end

  def draw(map)
    w = @w
    @w = @img[0].width
    super(map, @scale, 1, 255, 0xffffff, nil, @left ? nil : :horiz)
    @w = w
  end
end

class Water
  attr_reader :x, :y, :w, :h, :bounds

  def initialize(x, y, args, section)
    a = args.split ':'
    @x = x
    @y = y + 5
    @w = C::TILE_SIZE * a[0].to_i
    @h = C::TILE_SIZE * a[1].to_i - 5
    @bounds = Rectangle.new(@x, @y, @w, @h)
    section.add_interacting_element(self)
  end

  def update(section)
    b = SB.player.bomb
    if b.collide? self
      b.stored_forces.y -= 1
      unless SB.player.dead?
        SB.player.die
        section.add_effect(Effect.new(b.x + b.w / 2 - 32, @y - 19, :fx_water, 1, 4, 8))
      end
    end
  end

  def dead?
    false
  end

  def is_visible(map)
    map.cam.intersect? @bounds
  end

  def draw(map); end
end

class ForceField < GameObject
  def initialize(x, y, args, section, switch)
    return if switch[:state] == :taken
    super x, y, 32, 32, :sprite_ForceField, Vector.new(-14, -14), 3, 1
    @active_bounds = Rectangle.new(x - 14, y - 14, 60, 60)
    @alpha = 255
  end

  def update(section)
    animate [0, 1, 2, 1], 10
    b = SB.player.bomb
    if @taken
      @x = b.x + b.w / 2 - 16; @y = b.y + b.h / 2 - 16
      @timer += 1
      @dead = true if @timer == 1200
      if @timer >= 1080
        if @timer % 5 == 0
          @alpha = @alpha == 0 ? 255 : 0
        end
      end
    elsif b.collide? self
      b.set_invulnerable 1200
      SB.stage.set_switch self
      @taken = true
      @timer = 0
    end
  end

  def draw(map)
    super map, 1, 1, @alpha
  end
end

class Stalactite < GameObject
  def initialize(x, y, args, section)
    super x + 11, y - 16, 10, 48, :sprite_stalactite, Vector.new(-9, 0), 3, 2
    @active_bounds = Rectangle.new(x + 2, y, 28, 48)
    @normal = args.nil?
  end

  def update(section)
    if @dying
      animate [0, 1, 2, 3, 4, 5, 5, 5, 5, 5, 5, 5], 5
      @timer += 1
      @dead = true if @timer == 60
    elsif @moving
      move Vector.new(0, 0), section.get_obstacles(@x, @y), section.ramps
      SB.player.bomb.hit if SB.player.bomb.collide?(self)
      obj = section.active_object
      if obj.is_a? Sahiss and obj.bounds.intersect?(self)
        obj.hit(section)
      end
      if @bottom
        @dying = true
        @moving = false
        @timer = 0
      end
    elsif @will_move
      if @timer % 4 == 0
        if @x % 2 == 0; @x += 1
        else; @x -= 1; end
      end
      @timer += 1
      @moving = true if @timer == 30
    else
      b = SB.player.bomb
      if (@normal && b.x + b.w > @x - 80 && b.x < @x + 90 && b.y > @y && b.y < @y + 256) ||
         (!@normal && b.x + b.w > @x && b.x < @x + @w && b.y + b.h > @y - C::TILE_SIZE && b.y + b.h < @y)
        @will_move = true
        @timer = 0
      end
    end
  end
end

class Board < GameObject
  def initialize(x, y, facing_right, section, switch)
    super x, y, 50, 4, :sprite_board, Vector.new(0, -1)
    @facing_right = facing_right
    @passable = true
    @active_bounds = Rectangle.new(x, y - 1, 50, 5)
    section.obstacles << self
    @switch = switch
  end

  def update(section)
    b = SB.player.bomb
    if b.collide? self and b.y + b.h <= @y + @h
      b.y = @y - b.h
    elsif b.bottom == self
      section.active_object = self
    elsif section.active_object == self
      section.active_object = nil
    end
  end

  def take(section)
    SB.player.add_item @switch
    @switch[:state] = :temp_taken
    section.obstacles.delete self
    section.active_object = nil
    @dead = true
  end

  def draw(map)
    super(map, 1, 1, 255, 0xffffff, nil, @facing_right ? nil : :horiz)
  end
end

class Rock < GameObject
  def initialize(x, y, args, section)
    case args
      when '1' then
        objs = [['l', 0, 0, 26, 96], [26, 0, 32, 96], [58, 27, 31, 69], ['r', 89, 27, 18, 35], [89, 62, 30, 34]]
        w = 120; h = 96; x -= 44; y -= 64
      else
        objs = []; w = h = 0
    end
    objs.each do |o|
      if o[0].is_a? String
        section.ramps << Ramp.new(x + o[1], y + o[2], o[3], o[4], o[0] == 'l')
      else
        section.obstacles << Block.new(x + o[0], y + o[1], o[2], o[3])
      end
    end
    super x, y, w, h, "sprite_rock#{args}", Vector.new(0, 0)
    @active_bounds = Rectangle.new(x, y, w, h)
  end

  def update(section); end
end

class Monep < GameObject
  def initialize(x, y, args, section, switch)
    super x, y, 62, 224, :sprite_monep, Vector.new(0, 0), 3, 2
    @active_bounds = Rectangle.new(x, y, 62, 224)
    @blocking = switch[:state] != :taken
    @state = :normal
    @balloon = Res.img :fx_Balloon3
  end

  def update(section)
    if @blocking
      b = SB.player.bomb
      if b.collide? self
        if @state == :normal
          section.set_fixed_camera(@x + @w / 2 - C::SCREEN_WIDTH / 2, @y + 50 - C::SCREEN_HEIGHT / 2)
          section.active_object = self
          set_animation 3
          @state = :speaking
          @timer = 0
        elsif @state == :speaking
          @timer += 1
          if @timer == 600 or KB.key_pressed? Gosu::KbReturn or KB.key_pressed? SB.key[:up]
            section.unset_fixed_camera
            set_animation 0
            @state = :waiting
          end
        elsif b.x > @x + @w / 2 - b.w / 2
          b.x = @x + @w / 2 - b.w / 2
        end
      else
        if section.active_object == self
          section.active_object = nil
          @state = :normal
        end
      end
    end
    if @state == :speaking; animate [3, 4, 5, 4, 5, 3, 5], 10
    else; animate [0, 1, 0, 2], 10; end
  end

  def activate(section)
    @blocking = false
    @state = :normal
    section.active_object = nil
    SB.stage.set_switch(self)
  end

  def draw(map)
    super map
    @balloon.draw @x - map.cam.x, @y + 30 - map.cam.y, 0 if @state == :waiting
    speak(:msg_monep) if @state == :speaking
  end
end

class StalactiteGenerator < GameObject
  def initialize(x, y, args, section)
    super x, y, 96, 32, :sprite_stalacGen, Vector.new(0, 0)
    @active_bounds = Rectangle.new(@x, @y, @w, @h)
    @active = true
    @limit = args.to_i * C::TILE_SIZE
  end

  def update(section)
    if @active and SB.player.bomb.collide?(self)
      section.add(Stalactite.new(@x + 96 + rand(@limit), @y + C::TILE_SIZE, '!', section))
      @active = false
      @timer = 0
    elsif not @active
      @timer += 1
      if @timer == 60
        @active = true
      end
    end
  end
end

class SpecGate < GameObject
  def initialize(x, y, args, section)
    super x, y, 32, 32, :sprite_SpecGate
    @active_bounds = Rectangle.new(x, y, 32, 32)
  end

  def update(section)
    if SB.player.bomb.collide? self
      SB.prepare_special_world
    end
  end
end

class Graphic < Sprite
  def initialize(x, y, args, section)
    type = args.to_i
    cols = 1; rows = 1
    case type
    when 1 then @w = 32; @h = 64
    when 2 then x += 16; y += 16; @w = 64; @h = 64; cols = 2; rows = 2; @rot = -5
    when 3..5 then x -= 16; @w = 64; @h = 32
    when 6 then x -= 134; y -= 208; @w = 300; @h = 240
    end
    super x, y, "sprite_graphic#{type}", cols, rows
    @active_bounds = Rectangle.new(x, y, @w, @h)
    @indices = *(0...(cols * rows)) if cols * rows > 1
    @angle = 0 if @rot
  end

  def update(section)
    animate @indices, 7 if @indices
    @angle += @rot if @rot
  end

  def draw(map)
    @rot ?
      (@img[@img_index].draw_rot @x + @w / 2 - map.cam.x, @y + @h/2 - map.cam.y, -1, @angle) :
      super(map, 1, 1, 255, 0xffffff, nil, nil, -1)
  end

  def is_visible(map)
    map.cam.intersect? @active_bounds
  end

  def dead?
    false
  end
end