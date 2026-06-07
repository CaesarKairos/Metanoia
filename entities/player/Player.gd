extends CharacterBody2D

# Configurações de Movimento
@export var START_SPEED = 150.0      # Velocidade inicial
@export var MAX_SPEED = 400.0        # Velocidade máxima
@export var ACCELERATION = 15.0      # Ganho de velocidade por segundo
@export var JUMP_VELOCITY = -380.0

var current_speed = START_SPEED
# CORREÇÃO DA GRAVIDADE: Se não achar no ProjectSettings, define o padrão de 980.0 automaticamente
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity") if ProjectSettings.get_setting("physics/2d/default_gravity") != null else 980.0

@onready var sprite = $AnimatedSprite2D

func _ready():
	# FORÇA O MOTOR A IGNORAR DEGRAUS PEQUENOS:
	floor_snap_length = 8.0
	floor_constant_speed = true
	floor_max_angle = deg_to_rad(46.0) # Permite subir inclinações e quinas leves automaticamente

func _physics_process(delta):
	# 1. Aplica a gravidade
	if not is_on_floor():
		velocity.y += gravity * delta

	# 2. Comando de Pulo
	if Input.is_action_just_pressed("pular") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# 3. Movimentação Horizontal
	var direction = Input.get_axis("esquerda", "direita")
	
	if direction != 0:
		current_speed = move_toward(current_speed, MAX_SPEED, ACCELERATION * delta)
		velocity.x = direction * current_speed
		
		if is_on_floor():
			sprite.flip_h = (direction < 0)
	else:
		current_speed = START_SPEED
		
		# FREIO DE EMERGÊNCIA INTELIGENTE:
		# Só deixa deslizar se houver bloco firme à frente. Se vir o vazio, para imediatamente!
		if is_on_floor() and not checar_chao_a_frente():
			velocity.x = 0
		else:
			velocity.x = move_toward(velocity.x, 0, MAX_SPEED * delta * 2)

	# 4. Cálculo do Ratio para animação
	var speed_ratio = (current_speed - START_SPEED) / (MAX_SPEED - START_SPEED)
	speed_ratio = clamp(speed_ratio, 0.0, 1.0) 

	# 5. Estados de Animação
	if not is_on_floor():
		var jump_fps = lerp(4.0, 10.0, speed_ratio)
		if velocity.y < 0:
			sprite.play("jump_up")
			sprite.speed_scale = jump_fps / 4.0
		else:
			sprite.play("jump_down")
			sprite.speed_scale = jump_fps / 4.0
	else:
		if direction != 0:
			sprite.play("run")
			var run_fps = lerp(6.0, 14.0, speed_ratio)
			sprite.speed_scale = run_fps / 6.0
		else:
			sprite.play("idle")
			sprite.speed_scale = 1.0

	# Move e resolve as colisões
	move_and_slide()

# Função de checagem do abismo usando varredura física do mundo
func checar_chao_a_frente() -> bool:
	var direcao_olhar = -1.0 if sprite.flip_h else 1.0
	
	# Projeta o sensor à frente e ligeiramente abaixo dos pés
	var posicao_checagem = global_position + Vector2(direcao_olhar * 24.0, 20.0)
	
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsRayQueryParameters2D.create(global_position, posicao_checagem)
	
	query.exclude = [self.get_rid()]
	
	var result = space_state.intersect_ray(query)
	return result.size() > 0
