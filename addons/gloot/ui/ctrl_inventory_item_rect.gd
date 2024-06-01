extends "res://addons/gloot/ui/ctrl_dragable.gd"

const CtrlInventoryItemRect = preload("res://addons/gloot/ui/ctrl_inventory_item_rect.gd")

signal activated
signal clicked
signal context_activated

const Utils = preload("res://addons/gloot/core/utils.gd")

var item: InventoryItem :
    set(new_item):
        if item == new_item:
            return

        _disconnect_item_signals()
        _connect_item_signals(new_item)

        item = new_item
        if item:
            texture = item.get_texture()
            activate()
        else:
            texture = null
            deactivate()
        _update_stack_size()
var texture: Texture2D :
    set(new_texture):
        if new_texture == texture:
            return
        texture = new_texture
        _update_texture()
var stretch_mode: TextureRect.StretchMode = TextureRect.StretchMode.STRETCH_SCALE :
    set(new_stretch_mode):
        if stretch_mode == new_stretch_mode:
            return
        stretch_mode = new_stretch_mode
        if is_instance_valid(_texture_rect):
            _texture_rect.stretch_mode = stretch_mode
var item_slot: ItemSlot
var _texture_rect: TextureRect
var _stack_size_label: Label
static var _stored_preview_size: Vector2
static var _stored_preview_offset: Vector2


func _connect_item_signals(new_item: InventoryItem) -> void:
    if new_item == null:
        return
    Utils.safe_connect(new_item.property_changed, _on_item_property_changed)


func _disconnect_item_signals() -> void:
    if !is_instance_valid(item):
        return
    Utils.safe_disconnect(item.property_changed, _on_item_property_changed)


func _on_item_property_changed(_property: String) -> void:
    _refresh()


func _get_item_position() -> Vector2:
    if is_instance_valid(item) && item.get_inventory():
        return item.get_inventory().get_item_position(item)
    return Vector2(0, 0)


func _ready() -> void:
    _texture_rect = TextureRect.new()
    _texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    _texture_rect.stretch_mode = stretch_mode
    _stack_size_label = Label.new()
    _stack_size_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _stack_size_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    _stack_size_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
    add_child(_texture_rect)
    add_child(_stack_size_label)

    resized.connect(func():
        _texture_rect.size = size
        _stack_size_label.size = size
    )

    if item == null:
        deactivate()

    _refresh()


func _update_texture() -> void:
    if !is_instance_valid(_texture_rect):
        return
    _texture_rect.texture = texture
    if is_instance_valid(item) && GridConstraint.is_item_rotated(item):
        _texture_rect.size = Vector2(size.y, size.x)
        if GridConstraint.is_item_rotation_positive(item):
            _texture_rect.position = Vector2(_texture_rect.size.y, 0)
            _texture_rect.rotation = PI/2
        else:
            _texture_rect.position = Vector2(0, _texture_rect.size.x)
            _texture_rect.rotation = -PI/2

    else:
        _texture_rect.size = size
        _texture_rect.position = Vector2.ZERO
        _texture_rect.rotation = 0


func _update_stack_size() -> void:
    if !is_instance_valid(_stack_size_label):
        return
    if !is_instance_valid(item):
        _stack_size_label.text = ""
        return
    var stack_size: int = Inventory.get_item_stack_size(item).count
    if stack_size <= 1:
        _stack_size_label.text = ""
    else:
        _stack_size_label.text = "%d" % stack_size
    _stack_size_label.size = size


func _refresh() -> void:
    _update_texture()
    _update_stack_size()


func create_preview() -> Control:
    var preview = CtrlInventoryItemRect.new()
    preview.item = item
    preview.texture = texture
    preview.size = size
    preview.stretch_mode = stretch_mode
    return preview


func _gui_input(event: InputEvent) -> void:
    if !(event is InputEventMouseButton):
        return

    var mb_event: InputEventMouseButton = event
    if mb_event.button_index == MOUSE_BUTTON_LEFT:
        if mb_event.double_click:
            activated.emit()
        else:
            clicked.emit()
    elif mb_event.button_index == MOUSE_BUTTON_MASK_RIGHT:
        context_activated.emit()


func get_stretched_texture_size(container_size: Vector2) -> Vector2:
    if texture == null:
        return Vector2.ZERO

    match stretch_mode:
        TextureRect.StretchMode.STRETCH_TILE, \
        TextureRect.StretchMode.STRETCH_SCALE:
            return container_size
        TextureRect.StretchMode.STRETCH_KEEP, \
        TextureRect.StretchMode.STRETCH_KEEP_CENTERED:
            return texture.get_size()
        TextureRect.StretchMode.STRETCH_KEEP_ASPECT, \
        TextureRect.StretchMode.STRETCH_KEEP_ASPECT_CENTERED, \
        TextureRect.StretchMode.STRETCH_KEEP_ASPECT_COVERED:
            return size

    return Vector2.ZERO
