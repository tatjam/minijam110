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

include objects/rocks

proc update*(this: var PhysicalObject) =
    this.sprite.center_position = vec2f(this.phys_body.position.x, this.phys_body.position.y)
    this.sprite.rotation = this.phys_body.angle
    echo this.phys_body.angle
    this.sprite.animate(dt)

proc draw*(this: var PhysicalObject) = 
    renderer.draw(this.sprite)

