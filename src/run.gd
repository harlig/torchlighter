class_name Run extends Control

@onready var camera := $Camera3D
@onready var deck := $DeckControl/Deck
@onready var relic_area := $RelicArea

var combat_difficulty := 1
var bank := 10:
	set(value):
		print("Bank value changed to: ", value)
		bank = value

# TODO: do we even want relics?
var relics: Array[Relic] = [
	Relic.create_relic("Torchlighter Relic", "Your first hand of each combat will always draw a Torchlighter", "res://textures/relic/torchlighter_secret.png", []),
]
# var relics: Array[Relic] = [
# 	Relic.create_relic("Health Relic", "When you spawn a unit, give it +5 max hp", "res://textures/relic/health_secret.jpg", [Card.CardType.UNIT]),
# 	Relic.create_relic("Spells Mana Relic", "Your spells each cost -1 mana", "res://textures/relic/mana_secret.jpg", [Card.CardType.SPELL]),
	# Relic.create_relic("Torchlighter Relic", "Your first hand of each combat will always draw a Torchlighter", "res://textures/relic/torchlighter_secret.png", []),
# 	]

var time_for_preload := 0.5
var time_spent := 0.0
var has_preloaded := false
var current_combat: Combat

func _ready() -> void:
	# TODO: need to figure out how to dynamically do this when a relic is added
	for relic in relics:
		relic_area.add_child(relic)

	create_combat()

func _process(delta: float) -> void:
	if has_preloaded:
		return
	if OS.has_feature("editor"):
		has_preloaded = true
		$PreloadedCombat.queue_free()
		$Loading.hide()

	time_spent += delta
	print("Preloading combat maybe - time spent waiting: ", time_spent)
	if time_spent > time_for_preload:
		has_preloaded = true
		await get_tree().create_timer(0.1).timeout
		$PreloadedCombat.show()

		await get_tree().create_timer(0.1).timeout
		$PreloadedCombat.queue_free()

		await get_tree().create_timer(0.1).timeout
		$Loading.hide()

		print("has done preloaded shit")

func create_combat() -> Combat:
	var new_combat: Combat = Combat.create_combat(combat_difficulty, relics)
	current_combat = new_combat
	combat_difficulty += 1

	new_combat.connect("reward_chosen", _on_combat_reward_chosen)
	new_combat.connect("combat_over", _on_combat_over)
	add_child(new_combat)
	return new_combat

func _on_combat_over(_combat_state: Combat.CombatState) -> void:
	var existing_combat := current_combat
	existing_combat.get_node("Hand").queue_free()
	for torch: Torch in existing_combat.all_torches:
		torch.get_node("CPUParticles3D").emitting = false

	var new_combat := create_combat()
	new_combat.get_node("HandDisplay").hide()
	for torch: Torch in new_combat.all_torches:
		torch.get_node("CPUParticles3D").emitting = false

	var offset := 56
	new_combat.position = Vector3(existing_combat.position.x + offset, existing_combat.position.y, existing_combat.position.z)

	var tween: Tween = get_tree().create_tween();
	tween.parallel().tween_property(existing_combat, "position", Vector3(existing_combat.position.x - offset, existing_combat.position.y, existing_combat.position.z), 5.0).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(new_combat, "position", Vector3(new_combat.position.x - offset, new_combat.position.y, new_combat.position.z), 5.0).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
	await tween.finished
	for ndx in range(new_combat.furthest_torch_lit + 1):
		var torch := new_combat.all_torches[ndx]
		torch.get_node("CPUParticles3D").emitting = true
	new_combat.show()

	existing_combat.queue_free()
	new_combat.get_node("HandDisplay").show()

	# if combat_state == Combat.CombatState.WON:
	# 	print("Combat won!")
	# 	map.visited_node(current_node)
	# 	show_map()
	# elif combat_state == Combat.CombatState.LOST:
	# 	print("Combat lost!")
	# 	map.hide_node(current_node)
	# 	move_to_unvisited_node()

func _on_combat_reward_chosen(reward: Reward.RewardData) -> void:
	if reward.type == Reward.RewardData.Type.CARD:
		print("Received card reward: ", reward.card.creature)
		deck.add_card(reward.card)
	elif reward.type == Reward.RewardData.Type.GOLD:
		print("Received gold reward: ", reward.gold)
		bank += reward.gold
	current_combat.reward.queue_free()

func _on_item_purchased(item: Card, cost: int) -> void:
	deck.add_card(item)
	bank -= cost
	# TODO: support items other than cards
	# if item.type == Shop.Item.Type.CARD:
	# 	deck.add_card(item.card)
	# else:
	# 	push_warning("Item type not supported yet")
