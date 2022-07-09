include ../../engine/base

import enemies/rockman
import player
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

        sprite*: AnimatedSprite
        phys_body: Body
        phys_shape: Shape
        user_data: UserData

proc create_rockman*(pos: Vec2f, space: Space): Enemy = 
    result = new(Enemy)
    result.sprite = create_animated_sprite("res/enemies/rockman.yaml")
    let mass = 50.0
    let moment = momentforBox(mass, 31.0, 31.0)

    result.phys_body = space.addBody(newBody(mass, moment))
    result.phys_shape = space.addShape(newBoxShape(result.phys_body, 31.0, 31.0, 0.0))
    result.user_data = make_enemy_userdata(addr result)
    result.phys_shape.userData = addr result.user_data
    result.phys_shape.friction = 0.8

    result.phys_body.position = v(pos.x, pos.y)

    result.kind = ekRockman

proc update*(this: var Enemy, player: Player) =
    this.sprite.center_position = vec2f(this.phys_body.position.x, this.phys_body.position.y)
    this.sprite.animate(dt)

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
                this.phys_body.velocity = v(player_dir.x * 80.0, this.phys_body.velocity.y)
            else:
                this.phys_body.velocity = v(-player_dir.x * 60.0, this.phys_body.velocity.y)


proc draw*(this: var Enemy) = 
    renderer.draw(this.sprite)
