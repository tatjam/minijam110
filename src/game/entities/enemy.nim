include ../../engine/base

import player
import physical_object
import random
import options
import sequtils

import ../userdata

type 
    EnemyKind = enum
        ekRockman,
        ekRockmanSpawner,
        ekBird

    Enemy* = ref object 
        case kind: EnemyKind
        of ekRockman:
            retreat_timer: float
            retreat_goal: float
            retreat: bool
            # -1 go left 0 not dumb 1 go right
            dumb: int
        of ekRockmanSpawner:
            spawn_timer: float
            children: seq[Enemy]
            max_children: int
        of ekBird:
            spawn_point: Vec2f
            turn_timer: float

        dead*: bool
        health: float
        no_loot: bool
        hurt_wav: WavHandle
        sprite*: AnimatedSprite
        phys_body*: Body
        phys_shape*: Shape
        user_data*: UserData
        toss_timer: float

proc base_create(kind: EnemyKind): Enemy =
    return Enemy(kind: kind)

proc create_rockman*(pos: Vec2f, space: Space, id: int): Enemy = 
    result = base_create(ekRockman)
    result.sprite = create_animated_sprite("res/enemies/rockman.yaml")
    let mass = 50.0
    let moment = momentforBox(mass, 31.0, 31.0)

    result.phys_body = space.addBody(newBody(mass, moment))
    result.phys_shape = space.addShape(newBoxShape(result.phys_body, 31.0, 31.0, 0.0))
    result.phys_shape.friction = 0.2
    result.phys_body.position = v(pos.x, pos.y)

    result.hurt_wav = load_sound("res/enemies/rockman_hurt.mp3")
    result.user_data = make_enemy_userdata(id)
    result.phys_shape.userData = addr result.user_data

    result.health = 2.0

proc create_rockman_spawner*(pos: Vec2f, space: Space, id: int): Enemy = 
    result = base_create(ekRockmanSpawner)
    result.sprite = create_animated_sprite("res/enemies/spawner.yaml")
    let mass = 500.0
    let moment = momentForBox(mass, 40.0, 80.0)

    result.phys_body = space.addBody(newBody(mass, moment))
    result.phys_shape = space.addShape(newBoxShape(result.phys_body, 40.0, 80.0, 0.0))
    result.phys_shape.friction = 1.0
    result.phys_body.position = v(pos.x, pos.y - 40.0)

    result.hurt_wav = load_sound("res/enemies/rockman_hurt.mp3")
    result.user_data = make_enemy_userdata(id)
    result.phys_shape.userData = addr result.user_data

    result.health = 6.0
    result.spawn_timer = 0.0
    result.max_children = 5

proc create_bird*(pos: Vec2f, space: Space, id: int): Enemy = 
    result = base_create(ekBird)
    result.sprite = create_animated_sprite("res/enemies/bird.yaml")
    let mass = 200.0
    let moment = momentForBox(mass, 40.0, 36.0)

    result.phys_body = space.addBody(newBody(mass, moment))
    result.phys_shape = space.addShape(newBoxShape(result.phys_body, 40.0, 36.0, 0.0))
    result.phys_shape.friction = 0.3
    result.phys_body.position = v(pos.x, pos.y - 10.0)

    result.hurt_wav = load_sound("res/enemies/rockman_hurt.mp3")
    result.user_data = make_enemy_userdata(id)
    result.phys_shape.userData = addr result.user_data

    result.health = 10.0
    result.spawn_point = pos
    result.turn_timer = 0.0


proc indirect_die*(this: var Enemy) = 
    this.health = -1.0
    this.no_loot = true

proc die*(this: var Enemy, objects: var seq[PhysicalObject], space: Space) = 
    if not this.dead:
        let pos = this.phys_body.position
        let vpos = vec2f(pos.x, pos.y)
        space.removeShape(this.phys_shape)
        space.removeBody(this.phys_body)
        this.dead = true
        if this.kind == ekRockman and not this.no_loot:
            # Spawn a dead rockman
            objects.add(create_deadrockman(vpos, space, objects.len))


proc update*(this: var Enemy, player: Player, objects: var seq[PhysicalObject], enemy_count: var int, space: Space): Option[Enemy] =
    this.sprite.center_position = vec2f(this.phys_body.position.x, this.phys_body.position.y)
    this.sprite.animate(dt)

    if this.health <= 0.0:
        this.die(objects, space)

    if this.toss_timer < 0.0:
        this.phys_body.angle = 0.0
        if this.kind == ekRockman:
            if this.dumb != 0:
                this.phys_body.velocity = v(50.0 * this.dumb.toFloat, this.phys_body.velocity.y)
            else:
                # Simple moving towards player behaviour, with random retreats
                if this.retreat:
                    this.retreat_timer -= dt * 4.0
                    if this.retreat_timer < 0.0:
                        this.retreat = false
                        this.retreat_goal = rand(10.0)
                else:
                    this.retreat_timer += dt
                    if this.retreat_timer > this.retreat_goal:
                        this.retreat = true

                var player_dir = this.sprite.position - player.sprite.position
                let player_dist = length(player_dir)
                player_dir /= player_dist
                if player_dist < 300.0:
                    if this.retreat:
                        this.phys_body.velocity = v(player_dir.x * 70.0, this.phys_body.velocity.y)
                    else:
                        this.phys_body.velocity = v(-player_dir.x * 60.0, this.phys_body.velocity.y)
        elif this.kind == ekRockmanSpawner:
            this.spawn_timer -= dt
            # remove dead children
            this.children = this.children.filter do (x: Enemy) -> bool: x.dead
            if this.spawn_timer < 1.2:
                this.sprite.start_anim("spawn")
            elif this.spawn_timer < 5.0:
                this.sprite.start_anim("idle")
            if this.spawn_timer < 0.0 and this.children.len < this.max_children:
                this.spawn_timer = 15.0
                var pos = vec2f(this.sprite.center_position.x - 40.0, this.sprite.center_position.y)
                var dumb = -1
                if this.sprite.scale.x < 0.0:
                    dumb = 1
                    pos = vec2f(this.sprite.center_position.x + 40.0, this.sprite.center_position.y)
                result = some(create_rockman(pos, space, enemy_count))
                inc enemy_count
                result.get().dumb = dumb
                this.children.add(result.get())
        elif this.kind == ekBird:
            var player_dir = player.sprite.position - this.sprite.position
            let player_dist = length(player_dir)
            player_dir /= player_dist
            let scale = this.sprite.scale
            if this.turn_timer > 0.0:
                this.turn_timer -= dt
                if this.turn_timer < 0.0:
                    # Turn
                    this.sprite.scale = vec2f(-this.sprite.scale.x, 1.0)
                if (scale.x < 0.0 and player_dir.x < 0.0) or
                    (scale.x > 0.0 and player_dir.x > 0.0):
                        # Player walked into our attack!
                        this.turn_timer = 0.0
            elif player_dist < 150.0:            
                # Move quickly towards the player, but with turn-around inertia
                if (scale.x < 0.0 and player_dir.x > 0.0) or
                    (scale.x > 0.0 and player_dir.x < 0.0):
                    # we are looking one way, but must go the other, start timer
                    this.turn_timer = 3.0
                else:
                    this.phys_body.velocity = v(player_dir.x * 120.0, this.phys_body.velocity.y)

    else:
        this.toss_timer -= dt

    this.sprite.rotation = this.phys_body.angle

proc hurt*(this: var Enemy, point: Vect) =
    this.health -= 1.0
    let p = this.phys_body.position
    if this.kind == ekRockman:
        this.phys_body.applyImpulseAtWorldPoint(v(0, -5000.0), p)
    discard this.hurt_wav.play_sound()

# Enemies are knocked by default
proc toss*(this: var Enemy) =
    this.toss_timer = 2.0

proc is_tossable*(this: Enemy): bool =
    return this.kind == ekRockman

proc draw*(this: var Enemy) = 
    renderer.draw(this.sprite)

