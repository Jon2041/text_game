class Game

end

module Rollable
  def roll(die)
    rand(1..die)
  end
end

module Effectable

  def determine_effect(type)
    return @effect if @effect || roll(20) <= @sp_def
    case type
    when :fire   then @effect = :burned
    when :cold   then become_frozen
    when :shock  then become_paralyzed
    when :sleep  then become_asleep
    end
    display_effect
  end

  def become_poisoned
    @effect = :poisoned
    @fx_turns = roll(6) + 4
    display_effect
  end

  def become_burned
    @effect = :burned
  end

  def become_frozen
    @effect = :frozen
    @fx_turns = roll(4) + 2
  end

  def become_paralyzed
    @effect = :paralyzed
    @fx_turns = roll(6)
  end

  def become_asleep
    @effect = :asleep
    @fx_turns = roll(4)
  end

  def display_effect
    puts ''
    puts "#{@name} is #{@effect.to_s}!"
    puts ''
  end

  def resolve_effect
    case @effect
    when :poisoned    then poison_damage
    when :frozen      then can_attack?(21)
    when :paralyzed   then can_attack?(14)
    when :asleep      then can_attack?(21)
    when nil          then can_attack?(0)
    end
  end
end


module Fightable
# This module includes the mechanics for both the player and creatures to make
# attacks and deal damage.

  def can_attack?(difficulty=0)
    @fx_turns -= 1
    if fx_turns == 0
      puts "#{name} is no longer #{@effect.to_s}!"
      @effect = nil
      true
    elsif roll(20) > difficulty
      true
    else
      false
    end
  end

  def attack(target)
    if hit?(target)
      damage(target)
      if @equipped.poisoned && target.effect == nil
        target.become_poisoned
        @equipped.poisoned = false
      end
    else
      puts "#{name} takes a shot at #{target.name}, but misses!"
    end
  end

  def hit?(target)
    roll(20) + to_hit + equipped.to_hit >= target.armor
  end

  def damage(target)
    total = roll(@equipped.die) + @equipped.bonus
    target.health -= total
    puts "#{name} attacks #{target.name} with #{equipped.name} for #{total} points."
  end

  def magic_damage(target=self, damage, type)
    total = damage
    total *= 2 if target.effect == :burned && type == :fire
    target.health -= total
    puts "#{target.name} takes #{total} #{type.to_s} damage!"
    target.determine_effect(type)
  end

  def poison_damage
    if fx_turns > 0
      @fx_turns -= 1
      total = roll(1) + 1
      @health -= total
      puts "#{name} takes #{total} poison damage."
    else
      @effect = nil
      puts "#{name} is no longer poisoned."
    end
    true
  end
end

module XPable
  def update_xp(amount)
    @experience += amount
    level_up if level_up?
  end

  def level_up?
    @experience >= @xp_to_next_lvl
  end

  def level_up
    puts "#{name} levels up!"
    @level += 1
    @experience = @experience % @xp_to_next_lvl
    @xp_to_next_lvl = 20 + @level ** 2
    @armor += @level / 2
    @to_hit += @level / 2
    @max_health = 12 + @level
    heal(@level)
    display_stats
  end
end

module Healable
  def initialize
  end

  def heal(amount)
    if @health + amount > @max_health
      amount = @max_health - @health
    end
    @health += amount
    puts "You recovered #{amount} HP."
    puts "#{@name}: #{health} HP"
  end
end

module Searchable
  ITEMS = {(1..2) => 'FireballScroll.new', (3..4) => 'FreezeRayScroll.new',
           (5..6) => 'LightningScroll.new', (7..8) => 'SleepScroll.new',
           (9..12) => 'HealthPotion.new(:cloudy)', (13..15) => 'Dagger.new(:rusty)',
           (16..18) => 'Sword.new(:rusty)', (19..20) => 'Axe.new(:rusty)',
           (21..22) => 'FireballScroll.new', (23..24) => 'FreezeRayScroll.new',
           (25..26) => 'LightningScroll.new', (27..28) => 'SleepScroll.new',
           (29..32) => 'HealthPotion.new(:standard)', (33..35) => 'Dagger.new(:standard)',
           (36..38) => 'Sword.new(:standard)', (39..40) => 'Axe.new(:standard)',
           (41..42) => 'FireballScroll.new', (43..44) => 'FreezeRayScroll.new',
           (45..46) => 'LightningScroll.new', (47..48) => 'SleepScroll.new',
           (49..56) => 'HealthPotion.new(:good)', (57..60) => 'Dagger.new(:good)',
           (61..66) => 'Sword.new(:good)', (67..70) => 'Axe.new(:good)',
           (71..72) => 'FireballScroll.new', (73..74) => 'FreezeRayScroll.new',
           (75..76) => 'LightningScroll.new', (77..78) => 'SleepScroll.new',
           (79..86) => 'HealthPotion.new(:advanced)', (87..90) => 'Dagger.new(:gleaming)',
           (91..96) => 'Sword.new(:gleaming)', (97..100) => 'Axe.new(:gleaming)'}

  def search_yourself
    loop do
      display_items
      puts "Would you like to 'EQUIP', 'USE' or 'DROP' an item? Enter 'X' to exit."
      break unless manage
    end
  end

  def search_something(target)
    loop do
      system 'clear'
      target.display_items
      break if target.inventory.empty?
      display_items
      puts "Would you like to 'EQUIP', 'TAKE' or 'GIVE' an item? Enter 'X' to exit."
      break unless manage(target)
    end
    target.name = target.name + " (searched)"
  end

  def display_items
    if inventory.empty?
      puts "It is empty!"
    else
      puts "#{name}: #{inventory.map {|item| item.name }.to_s}"
    end
  end

  def manage(target=self)
    case gets.chomp.downcase
    when 'take'  then take(target)
    when 'give'  then give(target)
    when 'equip' then equip(target)
    when 'use'   then use(target)
    when 'drop'  then drop(target)
    when 'x'     then return false
    else         p "Invalid entry."
    end
  end

  def numbered_list(action, target=self)
    puts "Which item would you like to #{action}? (Enter the number)"
    target.inventory.each_with_index do |item, index|
      puts "#{index} - #{item.name}"
    end
  end

  def take(target, action='take')
      numbered_list(action, target)
      item_index = gets.chomp.to_i
    if item_index >= target.inventory.size
      puts "Not a valid entry."
      puts ''
    else
      inventory << target.inventory.slice!(item_index)
    end
  end

  def give(target)
    numbered_list('give')
    item_index = gets.chomp.to_i
    if item_index >= inventory.size
      puts "Not a valid entry."
      puts ''
      give(target)
    else
      target.inventory << inventory.slice!(item_index)
    end
  end

  def equip(target=self)
    loop do
      take(target, 'equip')
      if self.inventory.last.is_a?(Weapon)
        self.equipped = self.inventory.last
        break
      else
        puts "You can't equip that item."
      end
    end
    true
  end

  def drop(target)
    numbered_list('drop')
    item_index = gets.chomp.to_i
    inventory.slice!(item_index)
  end

  def use(target=self)
    numbered_list('use')
    item_index = gets.chomp.to_i
    begin
      inventory[item_index].use(target)
      inventory.slice!(item_index)
    rescue
    puts "You can't use this item now."
    end
  end

  def generate_contents(die)
    items = []
    (roll(3) - 1).times do
      item = ITEMS.select { |k,v| k.include?(roll(die)) }
      unless item.empty?
        items << eval(item.values[0])
      end
    end
    items
  end
end

module Usable
  def use(target)
    puts "You used #{name}!"

    case @type
    when :potion then use_potion(target)
    when :poison then use_poison(target)
    when :spell  then use_spell(target)
    end
  end

  def use_potion(target)
    eval(@effect)
  end

  def use_spell(target)
    eval(@effect)
  end

  def use_poison(target)
    target.equipped.poisoned = true
    puts "#{target.name} applies #{@name} to #{target.equipped.name}..."
    begin
      target.attack(target.opponent)
    rescue
    end
  end
end

class Container
  include Rollable
  include Searchable

  attr_accessor :name, :inventory

  CONTAINERS = %w(chest bag box desk)

  def initialize(level)
    @name = "a " + CONTAINERS.sample
    @die = determine_die(level)
    @inventory = generate_contents(@die)
  end

  def determine_die(level)
    case level
    when (0..1) then 20
    when (2..4) then 40
    when (5..9) then 70
    else             100
    end
  end
end

class Item
  def initialize
  end
end

class Scroll < Item
  include Rollable
  include Usable

  attr_reader :name, :type, :effect

  def initialize(name, type, effect)
    @name = name
    @type = type
    @effect = effect
  end
end

class FireballScroll < Scroll
  def initialize
    super('scroll of fireball', :spell, "target.magic_damage(target.opponent, roll(4) + 1, :fire)")
    @damage_type = :fire
  end
end

class FreezeRayScroll < Scroll
  def initialize
    super('scroll of freeze ray', :spell, "target.magic_damage(target.opponent, roll(2) + 1, :cold)")
    @damage_type = :fire
  end
end

class LightningScroll < Scroll
  def initialize
    super('scroll of lightning', :spell, "target.magic_damage(target.opponent, roll(6) + 1, :shock)")
    @damage_type = :fire
  end
end

class SleepScroll < Scroll
  def initialize
    super('scroll of sleep', :spell, "target.magic_damage(target.opponent, 0, :sleep)")
    @damage_type = :fire
  end
end

class Potion < Item
  RANKS = [:cloudy, :standard, :good, :gleaming]

  include Rollable
  include Usable

  attr_reader :name, :type, :effect

  def initialize (name, potion_poison, effect)
    @name = name
    @type = potion_poison
    @effect = effect
  end
end

class HealthPotion < Potion
  def initialize(quality)
    case quality
    when :cloudy   then super('a cloudy health potion', :potion, 'target.heal(roll(4) + 2)')
    when :standard then super('a health potion', :potion, 'target.heal(roll(6) + 4)')
    when :good     then super('a strong health potion', :potion, 'target.heal(roll(6) + 6)')
    when :advanced   then super('an advanced health potion', :potion, 'target.heal(roll(8) + 8)')
    end
  end
end

class Poison < Potion
  def initialize
    super('a venomous poison', :poison, nil)
  end
end

class Weapon < Item
  attr_reader :name, :die, :bonus, :to_hit
  attr_accessor :poisoned

  def initialize(name, die, bonus, to_hit)
    @name = name
    @die = die
    @bonus = bonus
    @to_hit = to_hit
    @poisoned = false
  end

  def use
    puts "You can't use this right now."
  end
end

class Fangs < Weapon
  def initialize
    super("its slavering fangs", 3, 0, 0)
  end
end

class Dagger < Weapon
  def initialize(quality)
    case quality
    when :rusty then super('a rusty dagger', 4, 1, 2)
    when :standard then super('a dagger', 6, 1, 2)
    when :good then super('a sharpened dagger', 8, 1, 3)
    when :gleaming then super('a gleaming dagger', 8, 3, 3)
    end
  end
end

class Sword < Weapon
  def initialize(quality)
    case quality
    when :rusty then super('a rusty sword', 6, 1, 1)
    when :standard then super('a sword', 8, 1, 1)
    when :good then super('a sharpened sword', 8, 2, 2)
    when :gleaming then super('a gleaming sword', 10, 3, 2)
    end
  end
end

class Axe < Weapon
  def initialize(quality)
    case quality
    when :rusty then super('a rusty axe', 6, 2, 0)
    when :standard then super('an axe', 8, 2, 1)
    when :good then super('a sharpened axe', 8, 3, 2)
    when :gleaming then super('a gleaming axe', 10, 4, 2)
    end
  end
end

class Player
  include Searchable
  include Healable
  include XPable
  include Rollable
  include Effectable
  include Fightable

  attr_reader :name, :inventory, :to_hit, :weapon, :level
  attr_accessor :health, :equipped, :armor, :sneak, :opponent, :effect, :fx_turns

  def initialize
    @name = get_name
    @level = 0
    @experience = 0
    @xp_to_next_lvl = 20
    @equipped = Dagger.new(:rusty)
    @armor = 10
    @to_hit = 0
    @max_health = 12
    @health = 12
    @inventory = [@equipped]
    @sneak = false
    @opponent = nil
    @effect = nil
    @fx_turns = 0
  end

  def get_name
    puts "What is your name?"
    answer = gets.chomp
  end

  def display_stats
    puts ''
    puts "----- #{name} -----"
    puts "Level:       #{@level}"
    puts "Current XP:  #{@experience} XP"
    puts "Next Level:  #{@xp_to_next_lvl} XP"
    puts "-------------------"
    puts "Armor Class: #{@armor}"
    puts "Hit Bonus:   #{@to_hit}"
    puts "Max Health:  #{@max_health} HP"
    puts "Current HP:  #{@health} HP"
    puts ''
  end

end

class Creature
  include Rollable
  include Effectable
  include Fightable
  include Searchable

  attr_reader :to_hit, :armor, :equipped, :xp, :weapon
  attr_accessor :name, :health, :inventory, :effect, :fx_turns, :opponent

  def initialize(name, health, armor, sp_def, to_hit, weapon, xp)
    @name = name.capitalize
    @health = health
    @armor = armor
    @sp_def = sp_def
    @equipped = weapon
    @to_hit = to_hit
    @xp = xp
    @inventory = [@equipped]
    @opponent = nil
    @effect = nil
    @fx_turns = 0
  end
end

class Spider < Creature
  def initialize
    super('spider', 9, 8, 8, 0, Fangs.new, 4)
    @inventory = [Poison.new]
  end
end

class Skeleton < Creature

  def initialize(player_level)
    rank = case player_level
    when 0..1 then :squishy
    when 2..3 then :normal
    when 4..5 then :tough
    else           :toughest
    end

    case rank
    when :squishy then super('skeleton', 9, 10, 10, -5, Sword.new(:rusty), 8)
    when :normal then super('skeleton', 9, 10, 10, 0, Sword.new(:standard), 10)
    when :tough then super('skeleton', 10, 14, 12, 1, Sword.new(:standard), 12)
    when :toughest then super('skeleton', 12, 16, 14, 2, Sword.new(:good), 16)
    end
    items = generate_contents(40)
    @inventory << items
    @inventory.flatten!
  end
end

class Combat
  ACTIONS = ["'ATTACK' the creature", "'CHANGE' weapons", "'USE' an item", "'RUN' away"]
  INDEX_TO_SYM = {0 => :attack}

  include Rollable
  def initialize(player, creature)
    @player = player
    @creature = creature
    @run = false
    intro
  end

  def intro
    puts ''
    puts "There is a #{@creature.name} in this room."
    player_first = initiative
    if player_first
      puts "It hasn't noticed you. Attack? Y/N"
      ans = gets.chomp.downcase
      if ans.start_with?('y')
        puts "#{@player.name} shouts 'Prepare to die!'"
        fight(player_first)
      else
        @player.sneak = true
        puts "#{@player.name} sneaks around the creature."
      end
    else
      puts "It attacks you! Press Enter."
      gets.chomp
      fight(player_first)
    end
  end

  def initiative
    player_roll = roll(20)
    creature_roll = roll(20)
    player_first = player_roll >= creature_roll
  end

  def display_hps
    puts ''
    puts "#{@player.name.capitalize} HP: #{@player.health}"
    puts "#{@creature.name.capitalize} HP: #{@creature.health}"
    puts ''
  end

  def fight(initiative)
    @player.opponent = @creature
    @creature.opponent = @player
    if initiative
      player_first
    else
      creature_first
    end
    if defeated?(@player)
      puts "#{@player.name} is defeated."
      exit!
    elsif defeated?(@creature)
      puts "#{@creature.name} is defeated."
      end_of_battle
    else
      puts "You hastily flee this room to go to the next one. Press Enter."
      gets.chomp
      Room.new(@player)
    end
  end

  def clear_screen
    puts "Press Enter."
    gets.chomp
    system 'clear'
  end

  def player_first
    loop do
      player_turn
      break if someone_lost? || @run
      creature_turn
      break if someone_lost?
      display_hps
      clear_screen
      display_hps
    end
  end

  def creature_first
    loop do
      creature_turn
      break if someone_lost?
      display_hps
      clear_screen
      display_hps
      player_turn
      break if someone_lost? || @run
    end
  end

  def player_turn
    puts "What would you like to do?"
    ACTIONS.each_with_index do |action, index|
      puts "#{index} - #{action}"
    end
    choice = gets.chomp.to_i

    if @player.effect == nil || @player.resolve_effect
      case choice
      when 0 then @player.attack(@creature)
      when 1 then @player.equip
      when 2 then @player.use
      when 3 then run_away
      else
        puts "Not a valid action."
        puts ''
        player_turn
      end
    end
  end

  def creature_turn
    @creature.attack(@player) if @creature.effect == nil || @creature.resolve_effect && !defeated?(@creature)
  end

  def defeated?(target)
    target.health <= 0
  end

  def someone_lost?
    defeated?(@player) || defeated?(@creature)
  end

  def run_away
    if roll(20) >= 10
      @run = true
      puts "Got away safely!"
    else
      puts "Couldn't get away!"
    end
  end

  def end_of_battle
    @player.opponent = nil
    puts "#{@player.name} gains #{@creature.xp} XP!"
    @player.update_xp(@creature.xp)
    puts ''
    puts "Search #{@creature.name}? Y/N"
    if gets.chomp.downcase.start_with?('y')
      @player.search_something(@creature)
    else
      puts "You leave the corpse behind."
    end
  end
end

class Room
  include Rollable

  DESCRIPTIONS = ['covered in a thick layer of dust.', 'dimly lit by an unseen source.',
  'vast. Your footsteps echo around you.', 'filled with a strange, sweet odor.',
  'charged with a weird energy. You taste copper.']

  CREATURES = ['Skeleton.new(@player.level)', 'Spider.new']

  def initialize(player)
    @rests = 0
    @player = player
    @creature = eval(CREATURES.sample)
    @containers = generate_containers
    @description = 'This room is ' + DESCRIPTIONS.sample + " It contains: #{print(@containers)}."
    enter_room
  end

  def generate_containers
    containers = []
    (roll(3) - 1 ).times do
      containers << Container.new(@player.level)
    end
    containers
  end

  def print(containers)
    list = []
    if containers.empty?
      list << 'nothing'
    else
      containers.each do |container|
        list << container.name
      end
    end
    list.join(' and ')
  end

  def enter_room
    system 'clear'
    puts @description
    if roll(20) >= 5
      Combat.new(@player, @creature)
    end
    loop do
      break if @player.health < 0
      display_actions
      answer = gets.chomp.downcase
      choose_action(answer)
      break if answer == 'leave'
    end
    Room.new(@player) unless @player.health < 0
  end

  def display_actions
    puts ''
    puts "What would you like to do?"
    puts "'SEARCH' the contents of the room,"
    puts "'REST' for a while,"
    puts "'CHECK' your inventory,"
    puts "'LEAVE' the room, or"
    puts "'QUIT' the game"
  end

  def choose_action(choice)
    case choice
    when 'search' then search_container
    when 'rest'   then rest
    when 'check'  then @player.search_yourself
    when 'leave'  then leave_room
    when 'quit'   then quit_game
    else          puts "That's not a valid command."
    end
  end

  def search_container
    if @containers.empty?
      puts "There are no objects to search in this room."
    else
      puts "Which object would you like to search?"
      @containers.each_with_index do |container, index|
        puts "#{index} - #{container.name}"
      end
      choice = gets.chomp.to_i
      @player.search_something(@containers[choice])
    end
  end

  def rest
    if @rests == 0
      @rests += 1
      @player.heal(roll(4) + 1)
    else
      puts "You've already rested in this room."
    end
  end

  def leave_room
    puts "You exit this room to explore another. Press ENTER to proceed."
    gets.chomp
  end

  def quit_game
    @player.display_stats
    exit
  end
end


system "clear"
player = Player.new
Room.new(player)
