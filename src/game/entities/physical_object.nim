# An object is a physical thing you can interact with by some means

include ../../engine/base
import ../../engine/audio/audio_engine

import ../userdata
import options

const OBJECT_COLL = 42 * 2

type 
    ObjectKind* = enum
        okRock,
        okMagmaRock,
        okDeadRockman,
        okBox,
        okButton

    PhysicalObject* = ref object 
        case kind*: ObjectKind
        of okButton: 
            active*: bool
            active_timer: float
            hold_active*: bool
        else: discard
        sprite*: AnimatedSprite
        phys_body*: Body
        phys_shape*: Shape
        user_data: UserData

        move_wav: Option[WavHandle]
        move_sound: AudioHandle
        vel_timer: float

        dead*: bool
        next_die: bool

# A button will remain
proc on_collide(this: PhysicalObject, other: BodyKind, dir: Vect) =
    if this.kind == okButton:
        this.active = true
        this.active_timer = 0.0

# Physical objects may be activated by collisions with other stuff
proc phys_object_handler(arb: Arbiter, sp: Space, data: pointer) {.cdecl.} =
    var shape_other, shape_us: Shape
    # In the order defined by the handler
    shapes(arb, addr shape_other, addr shape_us)
    let objects = cast[ptr seq[PhysicalObject]](data)
    let oudata = cast[ptr UserData](shape_us.userData)
    if shape_other.userData != nil:
        let udata = cast[ptr UserData](shape_other.userData)
        let cset = contactPointSet(arb)
        objects[oudata.point].on_collide(udata.kind, cset.normal)

proc indirect_die*(this: var PhysicalObject) =
    this.next_die = true

proc die*(this: var PhysicalObject, space: Space) = 
    let pos = this.phys_body.position
    let vpos = vec2f(pos.x, pos.y)
    space.removeShape(this.phys_shape)
    space.removeBody(this.phys_body)
    this.dead = true

proc update*(this: var PhysicalObject, space: Space) =
    this.sprite.center_position = vec2f(this.phys_body.position.x, this.phys_body.position.y)
    this.sprite.rotation = this.phys_body.angle

    if this.next_die:
        this.die(space)
    this.vel_timer -= dt
    if this.move_wav.isSome:
        var vel = this.phys_body.velocity.vlength
        vel = min(vel, 40.0)
        vel /= 40.0
        if vel < 0.1:
            vel = 0.0
        else:
            this.vel_timer = 1.0
        this.move_sound.set_volume(max(vel, this.vel_timer))

    if this.kind == okButton:
        if this.active:
            this.sprite.start_anim("on")
            this.active_timer += dt
            if this.active_timer >= 0.5:
                this.active = false
        else:
            this.sprite.start_anim("off")

    this.sprite.animate(dt)

proc draw*(this: var PhysicalObject) = 
    renderer.draw(this.sprite)

proc base_create(kind: ObjectKind): PhysicalObject =
    return PhysicalObject(kind: kind)

proc create_rock*(pos: Vec2f, space: Space, id: int): PhysicalObject = 
    result = base_create(okRock)
    result.sprite = create_animated_sprite("res/objects/rock.yaml")
    let mass = 40.0
    let moment = momentForCircle(mass, 0.0, 58.0, vzero)

    result.phys_body = space.addBody(newBody(mass, moment))
    result.phys_shape = space.addShape(newCircleShape(result.phys_body, 58.0, vzero))
    result.user_data = make_object_userdata(id)
    result.phys_shape.userData = addr result.user_data
    result.phys_body.position = v(pos.x, pos.y)
    result.phys_shape.friction = 0.1
    result.move_wav = some(load_sound("res/objects/roll.mp3"))
    result.move_sound = result.move_wav.get().play_sound(true)


proc create_magmarock*(pos: Vec2f, space: Space, id: int): PhysicalObject = 
    result = base_create(okMagmaRock)
    result.sprite = create_animated_sprite("res/objects/magmarock.yaml")
    let mass = 40.0
    let moment = momentForCircle(mass, 0.0, 58.0, vzero)

    result.phys_body = space.addBody(newBody(mass, moment))
    result.phys_shape = space.addShape(newCircleShape(result.phys_body, 58.0, vzero))
    result.user_data = make_object_userdata(id)
    result.phys_shape.userData = addr result.user_data
    result.phys_body.position = v(pos.x, pos.y)
    result.phys_shape.friction = 0.1
    
    result.move_wav = some(load_sound("res/objects/roll_lava.mp3"))
    result.move_sound = result.move_wav.get().play_sound(true)


proc create_deadrockman*(pos: Vec2f, space: Space, id: int): PhysicalObject =
    result = base_create(okDeadRockman)
    result.sprite = create_animated_sprite("res/enemies/deadrockman.yaml")
    let mass = 12.0
    let moment = momentForBox(mass, 12.0, 12.0)
    
    result.phys_body = space.addBody(newBody(mass, moment))
    result.phys_shape = space.addShape(newBoxShape(result.phys_body, 12.0, 12.0, 0.0))
    result.user_data = make_object_userdata(id)
    result.phys_shape.userData = addr result.user_data
    result.phys_body.position = v(pos.x, pos.y)
    result.phys_shape.friction = 0.7



proc create_box*(pos: Vec2f, space: Space, id: int): PhysicalObject =
    result = base_create(okBox)

    result.sprite = create_animated_sprite("res/objects/box.yaml")
    let mass = 80.0
    let moment = momentForBox(mass, 60.0, 60.0)
    
    result.phys_body = space.addBody(newBody(mass, moment))
    result.phys_shape = space.addShape(newBoxShape(result.phys_body, 60.0, 60.0, 0.0))
    result.user_data = make_object_userdata(id)
    result.phys_shape.userData = addr result.user_data
    result.phys_body.position = v(pos.x, pos.y)
    result.phys_shape.friction = 0.4


proc create_button*(pos: Vec2f, space: Space, id: int, obj: ptr seq[PhysicalObject]): PhysicalObject =
    result = base_create(okButton)
    result.sprite = create_animated_sprite("res/objects/button.yaml")
    let mass = 40.0
    let moment = momentForBox(mass, 27.0, 35.0)
    
    result.phys_body = space.addBody(newBody(mass, moment))
    result.phys_shape = space.addShape(newBoxShape(result.phys_body, 27.0, 35.0, 0.0))
    result.user_data = make_object_userdata(id)
    result.phys_shape.userData = addr result.user_data
    result.phys_body.position = v(pos.x + 30.0, pos.y - 10.0)
    result.phys_shape.friction = 0.4

    # We sign up for collision callbacks between everything and barriers
    result.phys_shape.collisionType = cast[pointer](OBJECT_COLL)
    let all_coll = cast[pointer](0)
    var handler = space.addCollisionHandler(all_coll, cast[pointer](OBJECT_COLL))
    # TODO: Assign it only for the very first time
    handler.postSolveFunc = phys_object_handler
    handler.userData = obj

proc is_tossable*(this: PhysicalObject): bool =
    return this.kind == okDeadRockman

proc is_draggable*(this: PhysicalObject): bool = 
    return this.kind == okBox or this.kind == okButton