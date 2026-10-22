@abstract
class_name PlayerCharacter
extends Character
## Base dos players de qualquer gênero: o que é "ser o player", independente de
## como ele se move. Liga a vida à HUD (via EventBus), entra nos grupos PLAYER e
## PERSIST, anuncia a morte e guarda as HABILIDADES destraváveis. Cada gênero
## estende e implementa movimento + ganchos de Character (apply_knockback,
## get_facing_vector).
##
## Habilidades (progressão metroidvania / itens de zelda-like): `abilities` lista
## o que o player já pode fazer. Os estados consultam `has_ability()`, itens
## chamam `unlock_ability()` (ex.: AbilityPickup) e o progresso vai para o save.

## Chave do progresso de habilidades em SaveSystem.data.
const ABILITIES_SAVE_KEY := "abilities"

## Duração do fade-out ao morrer (s).
@export var death_fade_time := 0.4
## Habilidades iniciais (usadas quando o save ainda não tem progresso).
@export var abilities: Array[StringName] = []


func _ready() -> void:
	super._ready()
	add_to_group(Groups.PLAYER)
	add_to_group(Groups.PERSIST)
	_load_abilities()
	health.health_changed.connect(_on_health_changed)
	# Adiado para que a HUD (instanciada depois do player) já esteja conectada.
	_on_health_changed.call_deferred(health.current, health.max_health)


#region Habilidades

func has_ability(ability: StringName) -> bool:
	return ability in abilities


## Retorna true se a habilidade era nova.
func unlock_ability(ability: StringName) -> bool:
	if has_ability(ability):
		return false
	abilities.append(ability)
	_on_abilities_changed()
	EventBus.ability_unlocked.emit(ability)
	return true


func lock_ability(ability: StringName) -> void:
	abilities.erase(ability)
	_on_abilities_changed()


## Gancho: a lista de habilidades mudou (ex.: recalcular pulos extras no ar).
func _on_abilities_changed() -> void:
	pass


## Chamado pelo SaveSystem (grupo Groups.PERSIST).
func save_state(data: Dictionary) -> void:
	var names: Array[String] = []
	for ability: StringName in abilities:
		names.append(String(ability))
	data[ABILITIES_SAVE_KEY] = names


## Chamado pelo SaveSystem (grupo Groups.PERSIST).
func load_state(_data: Dictionary) -> void:
	_load_abilities()


## O save é entrada não confiável: só aceita uma lista, e cada item vira texto.
func _load_abilities() -> void:
	var saved: Variant = SaveSystem.data.get(ABILITIES_SAVE_KEY)
	if not saved is Array:
		return
	abilities.clear()
	for ability: Variant in saved:
		abilities.append(StringName(str(ability)))
	_on_abilities_changed()

#endregion


func _play_death() -> void:
	var tween := create_tween()
	tween.tween_property(visual, "modulate:a", 0.0, death_fade_time)
	EventBus.player_died.emit()


func _on_health_changed(current: int, max_health: int) -> void:
	EventBus.player_health_changed.emit(current, max_health)
