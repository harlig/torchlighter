class_name Combat extends Node3D

@onready var unit: PackedScene = preload("res://src/combat/unit.tscn")
@onready var card_scene := preload("res://src/card.tscn")
@onready var reward := $Reward

signal combat_over(combat_state: CombatState)
signal reward_chosen(reward: Reward.RewardData)

enum CombatState {PLAYING, WON, LOST}

const ENEMY_SPAWN_TIMER := 4.0
const OFFSET_FROM_BASE_DISTANCE := 3

var state: CombatState = CombatState.PLAYING
var time_since_last_enemy_spawn: float = 0
var difficulty := 1


func randomize_new_enemy_deck(strength_limit: int, single_card_strength_limit: int) -> Array[Card]:
	print("Strength Limit:" + str(strength_limit) + " Difficulty: " + str(single_card_strength_limit))
	var new_deck: Array[Card] = []
	var total_strength := 0
	var strengh_limited_creatures: Array[UnitList.Creature] = UnitList.creature_cards.filter(func(card: UnitList.Creature) -> bool: return card.strength_factor <= single_card_strength_limit)
	while total_strength < strength_limit:
		var dict := strengh_limited_creatures[randi_range(0, strengh_limited_creatures.size() - 1)]
		total_strength += dict["strength_factor"]
		new_deck.append(UnitList.create_card(dict))
	return new_deck


func _ready() -> void:
	print("ready")
	var player_deck := get_parent().get_node("DeckControl").get_node("Deck")
	var enemy_cards := randomize_new_enemy_deck(difficulty * 10, difficulty)
	$PlayerCombatDeck.prepare_combat_deck(player_deck.cards)
	$EnemyCombatDeck.prepare_combat_deck(enemy_cards)
	$PlayerHand.setup_deck($PlayerCombatDeck)
	$EnemyHand.setup_deck($EnemyCombatDeck)
	set_process(true)
	$Camera3D.make_current()

func _process(delta: float) -> void:
	if state != CombatState.PLAYING:
		return
	time_since_last_enemy_spawn += delta
	if time_since_last_enemy_spawn > ENEMY_SPAWN_TIMER:
		print("Play enemy")
		$EnemyHand.play_best_card()
		$EnemyHand.replenish_mana()
		time_since_last_enemy_spawn = 0

	$Draw/Label.text = str(int($Draw/DrawTimer.time_left) + 1);

func _on_draw_timer_timeout() -> void:
	$Draw.disabled = false

func spawn_unit(unit_to_spawn: PackedScene, unit_position: Vector3, team: Attackable.Team, card_played: Card) -> Unit:
	var new_unit: Unit = unit_to_spawn.instantiate()
	var random_z_offset := randf_range(-1, 1)
	var y := 0
	match card_played.creature.type:
		UnitList.CardType.AIR:
			y = 5
		_:
			y = 0
	new_unit.position = Vector3(unit_position.x, y, unit_position.z + random_z_offset)
	new_unit.direction = Unit.Direction.RIGHT if team == Attackable.Team.PLAYER else Unit.Direction.LEFT
	if team == Attackable.Team.ENEMY:
		new_unit.get_node("TargetArea").scale.x *= -1
		new_unit.get_node("TargetArea").position.x *= -1
		new_unit.get_node("Attackable").scale.x *= -1
	new_unit.get_node("Attackable").team = team
	new_unit.set_stats(card_played.creature, true if team == Attackable.Team.ENEMY else false)
	add_child(new_unit)
	return new_unit

func _on_player_hand_card_played(played_card: Card) -> void:
	var unit_x: float = $PlayerBase.position.x + OFFSET_FROM_BASE_DISTANCE
	var unit_z: float = $PlayerBase.position.z
	spawn_unit(unit, Vector3(unit_x, 0, unit_z), Attackable.Team.PLAYER, played_card)

func _on_enemy_hand_card_played(played_card: Card) -> void:
	var unit_x: float = $EnemyBase.position.x - OFFSET_FROM_BASE_DISTANCE
	var unit_z: float = $EnemyBase.position.z
	spawn_unit(unit, Vector3(unit_x, 0, unit_z), Attackable.Team.ENEMY, played_card)


func _on_player_base_died() -> void:
	state = CombatState.LOST
	$Draw.hide()
	combat_over.emit(state)


func _on_enemy_base_died() -> void:
	state = CombatState.WON
	$Draw.hide()
	provide_rewards()

func provide_rewards() -> void:
	var best_enemy_cards: Array[Card] = $EnemyCombatDeck.get_best_cards(3)
	reward.add_card_offerings(best_enemy_cards)
	reward.show()
	$PlayerHand.queue_free()
	$EnemyHand.queue_free()

func _on_draw_pressed() -> void:
	$Draw.disabled = true
	$PlayerHand.refresh_hand()

func _on_reward_reward_chosen(reward_data: Reward.RewardData) -> void:
	reward_chosen.emit(reward_data)
	combat_over.emit(state)
