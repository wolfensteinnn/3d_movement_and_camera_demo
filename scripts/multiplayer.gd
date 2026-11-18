extends Node3D

const NET_TESTING = true
const ENET_PORT = 7777

var lobby_id: int = 0
var peer: MultiplayerPeer
@export var player_scene: PackedScene
var is_joining: bool = false

@onready var button: Button = $Button
@onready var line_edit: LineEdit = $LineEdit
@onready var button_2: Button = $Button2
@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var bot_spawner: MultiplayerSpawner = $BotSpawner
@onready var bot_spawn_button: Button = $Button3


# -------------------------------------------------------
# LIFECYCLE
# -------------------------------------------------------

func _ready() -> void:
	if not NET_TESTING:
		_steam_init()

# -------------------------------------------------------
# PUBLIC API - call these from UI or anywhere
# -------------------------------------------------------

func host() -> void:
	if NET_TESTING:
		_enet_host()
	else:
		_steam_host()

func join(id: int) -> void:
	if NET_TESTING:
		_enet_join()
	else:
		_steam_join(id)

# -------------------------------------------------------
# SHARED MULTIPLAYER SETUP
# -------------------------------------------------------

func _setup_as_host() -> void:
	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_add_player)
	multiplayer.peer_disconnected.connect(_remove_player)
	_add_player()

func _setup_as_client() -> void:
	multiplayer.multiplayer_peer = peer

#func _process(delta: float) -> void:
	#print("tick: ", NetworkTime.tick, " time: ", NetworkTime.time)

# -------------------------------------------------------
# ENET
# -------------------------------------------------------

func _enet_host() -> void:
	var enet = ENetMultiplayerPeer.new()
	enet.create_server(ENET_PORT)
	peer = enet
	_setup_as_host()

func _enet_join() -> void:
	var enet = ENetMultiplayerPeer.new()
	enet.create_client("127.0.0.1", ENET_PORT)
	peer = enet
	_setup_as_client()

# -------------------------------------------------------
# STEAM
# -------------------------------------------------------

func _steam_init() -> void:
	Steam.steamInit(480, true)
	Steam.initRelayNetworkAccess()
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)

func _steam_host() -> void:
	Steam.createLobby(Steam.LobbyType.LOBBY_TYPE_PUBLIC, 16)

func _steam_join(lobby_id: int) -> void:
	is_joining = true
	Steam.joinLobby(lobby_id)

func _on_lobby_created(result: int, lobby_id: int) -> void:
	if result != Steam.Result.RESULT_OK:
		return
	self.lobby_id = lobby_id
	var steam_peer = SteamMultiplayerPeer.new()
	steam_peer.server_relay = true
	steam_peer.create_host()
	peer = steam_peer
	_setup_as_host()
	print(lobby_id)

func _on_lobby_joined(lobby_id: int, permissions: int, locked: bool, response: int) -> void:
	if not is_joining:
		return
	self.lobby_id = lobby_id
	var steam_peer = SteamMultiplayerPeer.new()
	steam_peer.server_relay = true
	steam_peer.create_client(Steam.getLobbyOwner(lobby_id))
	peer = steam_peer
	_setup_as_client()
	is_joining = false

# -------------------------------------------------------
# PLAYERS
# -------------------------------------------------------

func _add_player(id: int = 1) -> void:
	var random_spawn = Vector3(0,0,0)
	multiplayer_spawner.spawn({ 'peer_id': id, 'initial_transform': random_spawn })
	
	
func _remove_player(id: int) -> void:
	if not has_node(str(id)):
		return
	get_node(str(id)).queue_free()

func _spawn_npc():
	if multiplayer.is_server():
		var random_spawn = Vector3(0,1,0)
		bot_spawner.spawn({'initial_transform': random_spawn })

func _on_button_pressed() -> void:
	host()

func _on_button_2_pressed() -> void:
	join(line_edit.text.to_int())

func _on_button_3_pressed() -> void:
	_spawn_npc()
