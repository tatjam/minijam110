include ../../engine/base

import player
import physical_object
import random

import ../userdata

type 
    EnemyKind = enum
        ekRockman

    Enemy* = ref object 
        case kind: EnemyKind
        of ekRockman:
            retreat_timer: float
            retreat_goal: float
            retreat: bool

        dead*: bool
        health: float
        hurt_wav: WavHandle
        sprite*: AnimatedSprite
        phys_body: Body
        phys_shape: Shape
        user_data*: UserData

proc create_rockman*(pos: Vec2f, space: Space, id: int): Enemy = 
    result = new(Enemy)
    result.sprite = create_animated_sprite("res/enemies/rockman.yaml")
    let mass = 50.0
    let moment = momentforBox(mass, 31.0, 31.0)

    result.phys_body = space.addBody(newBody(mass, moment))
    result.phys_shape = space.addShape(newBoxShape(result.phys_body, 31.0, 31.0, 0.0))
    result.phys_shape.friction = 0.8

    result.phys_body.position = v(pos.x, pos.y)
    result.hurt_wav = load_sound("res/enemies/rockman_hurt.mp3")
    result.user_data = make_enemy_userdata(id)
    result.phys_shape.userData = addr result.user_data

    result.kind = ekRockman
    result.health = 2.0


proc die(this: var Enemy, objects: var seq[PhysicalObject], space: Space) = 
    space.removeShape(this.phys_shape)
    space.removeBody(this.phys_body)
    this.dead = true
    discard

proc update*(this: var Enemy, player: Player, objects: var seq[PhysicalObject], space: Space) =
    this.sprite.center_position = vec2f(this.phys_body.position.x, this.phys_body.position.y)
    this.sprite.animate(dt)

    if this.health <= 0.0:
        this.die(objects, space)

    if this.kind == ekRockman:
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


proc hurt*(this: var Enemy, point: Vect) =
    this.health -= 1.0
    let p = this.phys_body.position
    this.phys_body.applyImpulseAtWorldPoint(v(0, -5000.0), p)
    discard this.hurt_wav.play_sound()

proc draw*(this: var Enemy) = 
    renderer.draw(this.sprite)

