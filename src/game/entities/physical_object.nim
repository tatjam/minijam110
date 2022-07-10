# An object is a physical thing you can interact with by some means

include ../../engine/base

import ../userdata
    

type 
    ObjectKind = enum
        okRock,
        okMagmaRock

    PhysicalObject* = ref object 
        kind: ObjectKind
        sprite*: AnimatedSprite
        phys_body: Body
        phys_shape: Shape
        user_data: UserData

proc update*(this: var PhysicalObject) =
    this.sprite.center_position = vec2f(this.phys_body.position.x, this.phys_body.position.y)
    this.sprite.rotation = this.phys_body.angle
    this.sprite.animate(dt)

proc draw*(this: var PhysicalObject) = 
    renderer.draw(this.sprite)

proc create_rock*(pos: Vec2f, space: Space, id: int): PhysicalObject = 
    result = new(PhysicalObject)
    result.sprite = create_animated_sprite("res/objects/rock.yaml")
    let mass = 50.0
    let moment = momentForCircle(mass, 0.0, 58.0, vzero)

    result.phys_body = space.addBody(newBody(mass, moment))
    result.phys_shape = space.addShape(newCircleShape(result.phys_body, 58.0, vzero))
    result.user_data = make_enemy_userdata(id)
    result.phys_shape.userData = addr result.user_data
    result.phys_body.position = v(pos.x, pos.y)
    result.phys_shape.friction = 0.1

    result.kind = okRock

proc create_magmarock*(pos: Vec2f, space: Space, id: int): PhysicalObject = 
    result = new(PhysicalObject)
    result.sprite = create_animated_sprite("res/objects/magmarock.yaml")
    let mass = 60.0
    let moment = momentForCircle(mass, 0.0, 58.0, vzero)

    result.phys_body = space.addBody(newBody(mass, moment))
    result.phys_shape = space.addShape(newCircleShape(result.phys_body, 58.0, vzero))
    result.user_data = make_enemy_userdata(id)
    result.phys_shape.userData = addr result.user_data
    result.phys_body.position = v(pos.x, pos.y)
    result.phys_shape.friction = 0.1

    result.kind = okMagmaRock