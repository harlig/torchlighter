class_name Combat extends Node2D

@export var unit: PackedScene

signal combat_over(combat_state: CombatState)

enum CombatState {PLAYING, WON, LOST}

var state: CombatState = CombatState.PLAYING
var time_since_last_enemy_spawn: float = 0

func _ready() -> void:
	$PlayerHand.setup_deck($PlayerCombatDeck)
	$EnemyHand.setup_deck($EnemyCombatDeck)

func _process(delta: float) -> void:
	if state != CombatState.PLAYING:
		return
	# every 5 seconds spawn an enemy's best card
	time_since_last_enemy_spawn += delta
	if time_since_last_enemy_spawn > 500:
		$EnemyHand.play_best_card()
		time_since_last_enemy_spawn = 0


func spawn_unit(unit_to_spawn: PackedScene, unit_position: Vector2, team: Attackable.Team) -> Unit:
	var new_unit: Unit = unit_to_spawn.instantiate()
	new_unit.position = unit_position
	new_unit.direction = Unit.Direction.RIGHT if team == Attackable.Team.PLAYER else Unit.Direction.LEFT
	new_unit.get_node("TargetArea").scale.x = 1 if team == Attackable.Team.PLAYER else -1
	new_unit.get_node("Attackable").team = team
	add_child(new_unit)
	return new_unit

func _on_hand_card_played(played_card: Card) -> void:
	var unit_position: Vector2 = $PlayerBase.position + Vector2(75, 0)
	unit_position.y = $Ground.position.y - $Ground.scale.y * 0.5 - 40
	var created_unit: Unit = spawn_unit(unit, unit_position, Attackable.Team.PLAYER)
	created_unit.set_stats(played_card.data)

func _on_enemy_hand_card_played(played_card: Card) -> void:
	var unit_position: Vector2 = $EnemyBase.position - Vector2(75, 0)
	unit_position.y = $Ground.position.y - $Ground.scale.y * 0.5 - 40
	var created_unit: Unit = spawn_unit(unit, unit_position, Attackable.Team.ENEMY)
	created_unit.set_stats(played_card.data)


func _on_player_base_died() -> void:
	state = CombatState.LOST
	emit_signal("combat_over", state)


func _on_enemy_base_died() -> void:
	state = CombatState.WON
	provide_rewards()

func provide_rewards() -> void:
	var best_enemy_cards: Array[Card] = $EnemyCombatDeck.get_best_cards(3)
	print("Best enemy cards")
	for card: Card in best_enemy_cards:
		var card_offered := card.duplicate()
		card_offered.data = card.data
		$Reward.add_child(card_offered)
		$PlayerHand.queue_free()
		$EnemyHand.queue_free()
		print(card.data)

	# emit_signal("combat_over", state)
