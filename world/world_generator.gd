extends Node2D

# Configurações dos Chunks
@export_group("Configurações dos Chunks")
@export var spawn_chunk_scene: PackedScene   # Arraste o seu 'chunk_start.tscn' para cá no Inspector
@export var chunk_scenes: Array[PackedScene] = []
@export var chunk_size_tiles: int = 79       
@export var tile_size_pixels: int = 16       

@export_group("Alvos e Tela")
@export var player_path: NodePath            
@export var chunks_on_screen: int = 3

var player: CharacterBody2D
var chunk_width: float
var spawned_chunks: Array = []
var next_spawn_x: float = 0.0

func _ready():
	chunk_width = chunk_size_tiles * tile_size_pixels
	
	# Busca automática: Tenta pelo caminho do Inspector primeiro
	if player_path:
		player = get_node(player_path) as CharacterBody2D
		
	# Se ainda assim estiver vazio, varre os nós vizinhos para achar o Player pelo tipo
	if not player:
		player = get_parent().get_node_or_null("Player") as CharacterBody2D
		if not player:
			var siblings = get_parent().get_children()
			for child in siblings:
				if child is CharacterBody2D:
					player = child
					break
	
	# 1. Spawna o bloco inicial seguro (Spawn Chunk) se ele estiver configurado
	if spawn_chunk_scene:
		spawn_specific_chunk(spawn_chunk_scene)
	
	# 2. Preenche o restante dos blocos iniciais da tela com os chunks aleatórios
	var remaining_chunks = chunks_on_screen - 1 if spawn_chunk_scene else chunks_on_screen
	for i in range(remaining_chunks):
		spawn_chunk()

func _process(_delta):
	if player:
		# Aumentamos para 3.0 para o chão ser gerado muito antes do player chegar no fim
		if player.global_position.x > next_spawn_x - (chunk_width * 3.0):
			spawn_chunk()
			remove_old_chunk()

# Função para instanciar o chunk inicial respeitando a altura (Y) do gerador
func spawn_specific_chunk(scene: PackedScene):
	var chunk_instance = scene.instantiate()
	chunk_instance.global_position = Vector2(next_spawn_x, global_position.y)
	add_child(chunk_instance)
	
	spawned_chunks.append(chunk_instance)
	next_spawn_x += chunk_width

# Função para instanciar os chunks aleatórios respeitando a altura (Y) do gerador
func spawn_chunk():
	if chunk_scenes.is_empty():
		return
		
	var random_index = randi() % chunk_scenes.size()
	var chunk_instance = chunk_scenes[random_index].instantiate()
	
	chunk_instance.global_position = Vector2(next_spawn_x, global_position.y)
	add_child(chunk_instance)
	
	spawned_chunks.append(chunk_instance)
	next_spawn_x += chunk_width

func remove_old_chunk():
	if spawned_chunks.size() > chunks_on_screen + 1:
		var old_chunk = spawned_chunks.pop_front()
		if is_instance_valid(old_chunk):
			old_chunk.queue_free()
