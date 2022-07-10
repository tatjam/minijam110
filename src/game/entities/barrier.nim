include ../../engine/base

import player
import physical_object
import enemy
import glm
import math

import ../userdata

# Default is 0, so 42 is the answer to everything
const BARRIER_COLL = 42

type Barrier* = ref object 
    health: float
    hurt_wav: WavHandle
    sprites*: seq[AnimatedSprite]
    broken*: bool
    phys_shape: Shape
    user_data*: UserData
    # via physical impact at speed
    enemies_damage: bool
    objects_damage: bool
    min_energy: float

proc hurt(this: Barrier, energy: float) =
    echo "Was hurt"

proc on_collide(this: Barrier, other: BodyKind, energy: float) =
    if (other == bkEnemy and this.enemies_damage) or
        (other == bkObject and this.objects_damage): 
        if energy > 0:
            echo "Collide with energy: " & $energy
        if energy > this.min_energy:
            this.hurt(energy)


proc barrier_handler(arb: Arbiter, sp: Space, data: pointer) {.cdecl.} =
    var shape_other, shape_barrier: Shape
    # In the order defined by the handler
    shapes(arb, addr shape_other, addr shape_barrier)
    let barriers = cast[ptr seq[Barrier]](data)
    let budata = cast[ptr UserData](shape_barrier.userData)
    let eng = arb.totalKE
    if shape_other.userData != nil:
        let udata = cast[ptr UserData](shape_other.userData)
        barriers[budata.point].on_collide(udata.kind, eng)


proc create_barrier_segment(this: Barrier, sprite: string, pos: Vec2f, size: int, hor: bool, space: Space) =
    var sprite = create_animated_sprite(sprite)
    if hor:
        sprite.rotation = PI * 0.5 
    
    # Center barriers
    sprite.position = pos + vec2f(size.toFloat * 0.5, size.toFloat * 0.5)

    this.sprites.add(sprite)

proc create_barrier(sprite: string, area: Vec4f, size: int, space: Space, id: int, barriers: ptr seq[Barrier]): Barrier =
    result = new(Barrier)

    if area.x == area.z:
        # Vertical barrier
        for i in countup(0, (area.w - area.y).toInt, size):
            create_barrier_segment(result, sprite, vec2f(area.x, area.y + i.toFloat), size, false, space)
    elif area.y == area.w:
        # Horizontal barrier
        for i in countup(0, (area.z - area.x).toInt, size):
            create_barrier_segment(result, sprite, vec2f(area.x + i.toFloat, area.y), size, true, space)
    else:
        # Error
        echo "Wrong coordinates for barrier! Everything will be wonky"
        
    # The collider is a simple static segment
    let hs = size.toFloat * 0.5
    result.phys_shape = newSegmentShape(space.staticBody, v(area.x + hs, area.y + hs), v(area.z + hs, area.w + hs), 1)
    result.user_data = make_barrier_userdata(id)
    result.phys_shape.userData = addr result.user_data
    # We sign up for collision callbacks between everything and barriers
    result.phys_shape.collisionType = cast[pointer](BARRIER_COLL)
    let all_coll = cast[pointer](0)
    var handler = space.addCollisionHandler(all_coll, cast[pointer](BARRIER_COLL))
    # TODO: Assign it only for the very first time
    handler.postSolveFunc = barrier_handler
    handler.userData = barriers

    discard space.addShape(result.phys_shape)

proc create_wooden_barrier*(area: Vec4f, size: int, space: Space, id: int, barriers: ptr seq[Barrier]): Barrier =
    result = create_barrier("res/level1/break_wood.yaml", area, size, space, id, barriers)
    result.health = 10.0
    result.min_energy = 1.0

proc update*(this: var Barrier) =
    for sprite in mitems(this.sprites):
        sprite.animate(dt)

proc draw*(this: var Barrier) =
    for sprite in this.sprites:
        renderer.draw(sprite)