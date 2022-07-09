include ../../engine/base

type Player* = ref object
    sprite*: AnimatedSprite
    lantern*: Sprite
    phys_body: Body
    phys_shape: Shape

proc create_player*(pos: Vec2f, space: Space): Player = 
    let sprite = create_animated_sprite("res/player/player.yaml")
    let mass = 100.0
    let moment = momentForCircle(mass, 0, 16.0, vzero)

    let phys_body = space.addBody(newBody(mass, moment))
    let phys_shape = space.addShape(newCircleShape(phys_body, 16.0, vzero))

    phys_body.position = v(pos.x, pos.y)

    return Player(sprite: sprite, 
        lantern: create_fx_sprite("res/player/lantern_fx.png"), 
        phys_body: phys_body, phys_shape: phys_shape)

proc update*(this: var Player) =
    # Note that sprites are placed by their top-left corner, so:
    this.sprite.position = vec2f(this.phys_body.position.x - 20.0, this.phys_body.position.y - 38.0)
    this.lantern.center_position = this.sprite.position + vec2f(32.0, 9.0)
    this.sprite.animate(dt)

proc draw*(this: var Player) = 
    renderer.draw(this.sprite)
    renderer.draw(this.lantern)