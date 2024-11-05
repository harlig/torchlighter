class_name Reward extends Control

@onready var text: Label = $Text

signal reward_chosen(reward: RewardData)

var reward_skipped_gold: int = 25

class RewardData:
	enum Type {CARD, GOLD}

	var type: Type
	var card: Card = null
	var gold: int = 0

	static func for_card(reward_card: Card) -> RewardData:
		var reward_data := RewardData.new()
		reward_data.type = Type.CARD
		reward_data.card = reward_card
		return reward_data

	static func for_gold(reward_gold: int) -> RewardData:
		var reward_data := RewardData.new()
		reward_data.type = Type.GOLD
		reward_data.gold = reward_gold
		return reward_data

func add_card_offerings(cards: Array[Card]) -> void:
	for enemy_card: Card in cards:
		var card_offered := enemy_card.duplicate()
		card_offered.data = enemy_card.data
		card_offered.connect("card_clicked", _on_reward_clicked)
		$Offers.add_child(card_offered)

var last_clicked_reward_card: Card = null

func _on_reward_clicked(times_clicked: int, reward_card: Card) -> void:
	if last_clicked_reward_card and last_clicked_reward_card != reward_card:
		last_clicked_reward_card.reset_selected()

	last_clicked_reward_card = reward_card

	if times_clicked == 2:
		reward_card.reset_selected()
		reward_chosen.emit(RewardData.for_card(reward_card))


func _on_skip_button_pressed() -> void:
	reward_chosen.emit(RewardData.for_gold(reward_skipped_gold))
