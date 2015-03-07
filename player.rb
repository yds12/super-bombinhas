require_relative 'bomb'

class Player
  attr_reader :name, :bomb, :items, :cur_item_type
  attr_accessor :lives, :score

  def initialize(name = nil, bomb = :azul, lives = 5, score = 0)
    @name = name
    @bomb = Bomb.new bomb
    @lives = lives
    @score = score
    @items = {}
  end

  def dead?
    @dead
  end

  def die
    unless @dead
      @lives -= 1
      @dead = true
      @bomb.reset
    end
  end

  def add_item(item)
    @items[item[:type]] = [] if @items[item[:type]].nil?
    @items[item[:type]] << item
    @cur_item_type = item[:type] if @cur_item_type.nil?
  end

  def use_item(section)
    return if @cur_item_type.nil?
    item_set = @items[@cur_item_type]
    item = item_set[0]
    if item[:obj].use section
      if item[:state] == :temp_taken
        item[:state] = :temp_taken_used
      else
        item[:state] = :temp_used
      end

      item_set.delete item
      if item_set.length == 0
        @items.delete @cur_item_type
        @item_index = 0 if @item_index >= @items.length
        @cur_item_type = @items.keys[@item_index]
      end
    end
  end

  def change_item
    @item_index += 1
    @item_index = 0 if @item_index >= @items.length
    @cur_item_type = @items.keys[@item_index]
  end

  def reset
    @items.clear
    @bomb.reset
    @cur_item_type = nil
    @item_index = 0
    @dead = false
  end
end
