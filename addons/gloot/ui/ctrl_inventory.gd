@tool
@icon("res://addons/gloot/images/icon_ctrl_inventory.svg")
class_name CtrlInventory
extends Control

signal inventory_item_activated(item)
signal inventory_item_context_activated(item)

const Utils = preload("res://addons/gloot/core/utils.gd")

enum SelectMode {SELECT_SINGLE = ItemList.SELECT_SINGLE, SELECT_MULTI = ItemList.SELECT_MULTI}

@export var inventory: Inventory = null :
    set(new_inventory):
        if new_inventory == inventory:
            return
    
        _disconnect_inventory_signals()
        inventory = new_inventory
        _connect_inventory_signals()

        _queue_refresh()
@export var default_item_icon: Texture2D
@export_enum("Single", "Multi") var select_mode: int = SelectMode.SELECT_SINGLE :
    set(new_select_mode):
        if select_mode == new_select_mode:
            return
        select_mode = new_select_mode
        if is_instance_valid(_item_list):
            _item_list.deselect_all();
            _item_list.select_mode = select_mode

var _vbox_container: VBoxContainer
var _item_list: ItemList
var _refresh_queued: bool = false

const KEY_IMAGE = "image"
const KEY_NAME = "name"


func _ready():
    if Engine.is_editor_hint():
        # Clean up, in case it is duplicated in the editor
        if is_instance_valid(_vbox_container):
            _vbox_container.queue_free()

    _vbox_container = VBoxContainer.new()
    _vbox_container.size_flags_horizontal = SIZE_EXPAND_FILL
    _vbox_container.size_flags_vertical = SIZE_EXPAND_FILL
    _vbox_container.anchor_right = 1.0
    _vbox_container.anchor_bottom = 1.0
    add_child(_vbox_container)

    _item_list = ItemList.new()
    _item_list.size_flags_horizontal = SIZE_EXPAND_FILL
    _item_list.size_flags_vertical = SIZE_EXPAND_FILL
    _item_list.item_activated.connect(_on_list_item_activated)
    _item_list.item_clicked.connect(_on_list_item_clicked)
    _item_list.select_mode = select_mode
    _vbox_container.add_child(_item_list)

    _queue_refresh()


func _connect_inventory_signals() -> void:
    if !is_instance_valid(inventory):
        return
    Utils.safe_connect(inventory.contents_changed, _queue_refresh)
    Utils.safe_connect(inventory.item_property_changed, _on_item_property_changed)


func _disconnect_inventory_signals() -> void:
    if !is_instance_valid(inventory):
        return
    Utils.safe_disconnect(inventory.contents_changed, _queue_refresh)
    Utils.safe_disconnect(inventory.item_property_changed, _on_item_property_changed)


func _on_list_item_activated(index: int) -> void:
    inventory_item_activated.emit(_get_inventory_item(index))


func _on_list_item_clicked(index: int, at_position: Vector2, mouse_button_index: int) -> void:
    if mouse_button_index == MOUSE_BUTTON_RIGHT:
        inventory_item_context_activated.emit(_get_inventory_item(index))


func _process(_delta) -> void:
    if _refresh_queued:
        _refresh()
        _refresh_queued = false


func _queue_refresh() -> void:
    _refresh_queued = true

    
func _on_item_property_changed(_item: InventoryItem, _property: String) -> void:
    _queue_refresh()


func _refresh() -> void:
    if is_inside_tree():
        _clear_list()
        _populate_list()


func _clear_list() -> void:
    if is_instance_valid(_item_list):
        _item_list.clear()


func _populate_list() -> void:
    if !is_instance_valid(inventory):
        return

    for item in inventory.get_items():
        var texture := item.get_texture()
        if !texture:
            texture = default_item_icon
        _item_list.add_item(inventory._get_item_title(item), texture)
        _item_list.set_item_metadata(_item_list.get_item_count() - 1, item)


func get_selected_inventory_item() -> InventoryItem:
    if _item_list.get_selected_items().is_empty():
        return null

    return _get_inventory_item(_item_list.get_selected_items()[0])


func get_selected_inventory_items() -> Array[InventoryItem]:
    var result: Array[InventoryItem]
    var indexes = _item_list.get_selected_items()
    for i in indexes:
        result.append(_get_inventory_item(i))
    return result


func _get_inventory_item(index: int) -> InventoryItem:
    assert(index >= 0)
    assert(index < _item_list.get_item_count())

    return _item_list.get_item_metadata(index)


func deselect_inventory_item() -> void:
    _item_list.deselect_all()


func select_inventory_item(item: InventoryItem) -> void:
    _item_list.deselect_all()
    for index in _item_list.item_count:
        if _item_list.get_item_metadata(index) != item:
            continue
        _item_list.select(index)
        return

