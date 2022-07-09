include ../../engine/base

import enemies/rockman


type 
    EnemyKind = enum
        ekRockman

    Enemy* = object 
        kind: EnemyKind
        sprite*: AnimatedSprite
        phys_body: Body
        phys_shape: Shape

proc create_rockman*(pos: Vec2f, space: Space): Enemy = 
    let sprite = create_animated_sprite("res/enemies/rockman.yaml")
    let mass = 100.0
    let moment = momentForCircle(mass, 0, 16.0, vzero)

    let phys_body = space.addBody(newBody(mass, moment))
    let phys_shape = space.addShape(newCircleShape(phys_body, 16.0, vzero))

    phys_body.position = v(pos.x, pos.y)

    return Enemy(kind: ekRockman, sprite: sprite, phys_body: phys_body, phys_shape: phys_shape)

proc update*(this: var Enemy) =
    # Note that sprites are placed by their top-left corner, so:
    this.sprite.position = vec2f(this.phys_body.position.x - 8.0, this.phys_body.position.y - 8.0)
    this.sprite.animate(dt)

proc draw*(this: var Enemy) = 
    renderer.draw(this.sprite)
