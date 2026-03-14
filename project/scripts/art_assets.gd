extends RefCounted
class_name ArtAssets

const CARD_PATHS := {
	GameRules.CardType.FIRE: "res://assets/sprites/cards/fire.png",
	GameRules.CardType.POISON: "res://assets/sprites/cards/poison.png",
	GameRules.CardType.HEAL: "res://assets/sprites/cards/heal.png",
	GameRules.CardType.CHAOS: "res://assets/sprites/cards/chaos.png",
}
const CURSOR_TILTED_PATH := "res://assets/sprites/hand/sprite_0.png"
const CURSOR_HORIZONTAL_PATH := "res://assets/sprites/hand/sprite_1.png"

static var _card_texture_cache: Dictionary = {}
static var _cursor_texture_cache: Dictionary = {}
static var _loose_texture_cache: Dictionary = {}


static func get_card_texture(card_type: int) -> Texture2D:
	if _card_texture_cache.has(card_type):
		return _card_texture_cache[card_type]

	var path: String = str(CARD_PATHS.get(card_type, ""))
	var texture := _load_trimmed_texture(path)
	_card_texture_cache[card_type] = texture
	return texture


static func get_cursor_texture(horizontal: bool) -> Texture2D:
	var cache_key := "horizontal" if horizontal else "tilted"
	if _cursor_texture_cache.has(cache_key):
		return _cursor_texture_cache[cache_key]

	var cursor_path := CURSOR_HORIZONTAL_PATH if horizontal else CURSOR_TILTED_PATH
	var image := _load_image(cursor_path)
	if image == null:
		return null

	var trimmed := _crop_to_visible_pixels(image)
	var target_width := 38 if horizontal else 30
	var target_height := int(round(trimmed.get_height() * float(target_width) / float(trimmed.get_width())))
	trimmed.resize(target_width, maxi(target_height, 1), Image.INTERPOLATE_LANCZOS)

	var texture := ImageTexture.create_from_image(trimmed)
	_cursor_texture_cache[cache_key] = texture
	return texture


static func get_loose_texture(path: String) -> Texture2D:
	if _loose_texture_cache.has(path):
		return _loose_texture_cache[path]

	var image := Image.new()
	if image.load(ProjectSettings.globalize_path(path)) != OK:
		return null

	var texture := ImageTexture.create_from_image(_crop_to_visible_pixels(image))
	_loose_texture_cache[path] = texture
	return texture


static func _load_trimmed_texture(path: String) -> Texture2D:
	var image := _load_image(path)
	if image == null:
		return load(path) as Texture2D

	var trimmed := _crop_to_visible_pixels(image)
	return ImageTexture.create_from_image(trimmed)


static func _load_image(path: String) -> Image:
	var texture := load(path) as Texture2D
	if texture == null:
		return null
	return texture.get_image()


static func _crop_to_visible_pixels(image: Image) -> Image:
	var used_rect: Rect2i = image.get_used_rect()
	if used_rect.size.x <= 0 or used_rect.size.y <= 0:
		return image
	return image.get_region(used_rect)
