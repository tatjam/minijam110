include ../../engine/base

import player
import physical_object
import enemy
import glm
import math

import ../userdata

# Default is 0, so 42 is the answer to everything
const BARRIER_COLL = 42


type 
    Barrier* = ref object 
        health*: float
        hurt_wav: WavHandle
        break_wav: WavHandle
        sprites*: seq[AnimatedSprite]
        broken*: bool
        phys_shape*: Shape
        phys_space: Space
        user_data*: UserData
        # via physical impact at speed
        enemies_damage: bool
        objects_damage: bool
        sensor_data: SensorData

        sensor: bool

        # only for sensors
        destroy_object: bool
        destroy_enemy: bool

        min_energy: float
    SensorData = ref object 
        barriers: ptr seq[Barrier]
        objects: ptr seq[PhysicalObject]
        enemies: ptr seq[Enemy]

proc hurt(this: var Barrier, energy: float) =
    discard this.hurt_wav.play_sound()
    this.health -= (energy - this.min_energy) / 300000.0
    echo this.health

proc on_collide*(this: var Barrier, other: BodyKind, energy: float) =
    if (other == bkEnemy and this.enemies_damage) or
        (other == bkObject and this.objects_damage): 
        if energy > this.min_energy:
            this.hurt(energy)



proc barrier_handler(arb: Arbiter, sp: Space, data: pointer) {.cdecl.} =
    var shape_other, shape_barrier: Shape
    # In the order defined by the handler
    shapes(arb, addr shape_other, addr shape_barrier)
    let barriers = cast[ptr SensorData](data)[].barriers
    let budata = cast[ptr UserData](shape_barrier.userData)
    let eng = arb.totalKE
    if shape_other.userData != nil:
        let udata = cast[ptr UserData](shape_other.userData)
        barriers[budata.point].on_collide(udata.kind, eng)

proc sensor_barrier_handler(arb: Arbiter, sp: Space, data: pointer): bool {.cdecl.} =
    var shape_other, shape_barrier: Shape
    # In the order defined by the handler
    shapes(arb, addr shape_other, addr shape_barrier)
    let sdata = cast[ptr SensorData](data)
    let budata = cast[ptr UserData](shape_barrier.userData)
    if shape_other.userData != nil:
        let udata = cast[ptr UserData](shape_other.userData)
        let barrier = sdata.barriers[budata[].point]
        if barrier.sensor:
            if barrier.destroy_object and udata.kind == bkObject:
                sdata.objects[udata.point].indirect_die()
                discard barrier.break_wav.play_sound()
            if barrier.destroy_enemy and udata.kind == bkEnemy:
                sdata.enemies[udata.point].indirect_die()
                discard barrier.break_wav.play_sound()

    return true


proc create_barrier_segment(this: Barrier, sprite: string, pos: Vec2f, size: int, hor: bool, space: Space) =
    var sprite = create_animated_sprite(sprite)
    if hor:
        sprite.rotation = PI * 0.5 
    
    # Center barriers
    sprite.position = pos + vec2f(size.toFloat * 0.5, size.toFloat * 0.5)
    if hor:
        sprite.position = vec2f(sprite.position.x + size.toFloat, sprite.position.y)

    this.sprites.add(sprite)

proc create_barrier(sprite: string, area: Vec4f, size: int, space: Space, id: int, barriers: ptr seq[Barrier], 
    objects: ptr seq[PhysicalObject], enemies: ptr seq[Enemy], sensor: bool = false): Barrier =
    result = new(Barrier)
    result.sensor = sensor

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
    result.phys_shape = newSegmentShape(space.staticBody, v(area.x + hs, area.y + hs), v(area.z + hs, area.w + hs), 8)
    if sensor:
        result.phys_shape.sensor = true
    result.user_data = make_barrier_userdata(id)
    result.phys_shape.userData = addr result.user_data
    # We sign up for collision callbacks between everything and barriers
    result.phys_shape.collisionType = cast[pointer](BARRIER_COLL)
    let all_coll = cast[pointer](0)
    var handler = space.addCollisionHandler(all_coll, cast[pointer](BARRIER_COLL))
    result.sensor_data = new(SensorData)
    result.sensor_data.barriers = barriers
    result.sensor_data.objects = objects
    result.sensor_data.enemies = enemies
    # TODO: Assign it only for the very first time
    handler.postSolveFunc = barrier_handler
    handler.preSolveFunc = sensor_barrier_handler
    handler.userData = addr result.sensor_data

    result.phys_space = space

    discard space.addShape(result.phys_shape)

proc create_wooden_barrier*(area: Vec4f, size: int, space: Space, id: int, barriers: ptr seq[Barrier],
    objects: ptr seq[PhysicalObject], enemies: ptr seq[Enemy]): Barrier =
    result = create_barrier("res/level1/break_wood.yaml", area, size, space, id, barriers, objects, enemies)
    result.health = 10.0
    result.min_energy = 1000000.0
    result.enemies_damage = true
    result.objects_damage = true
    result.hurt_wav = load_sound("res/barrier/wood_hurt.mp3")
    result.break_wav = load_sound("res/barrier/wood_break.mp3")

proc create_gate*(area: Vec4f, size: int, space: Space, id: int, barriers: ptr seq[Barrier],
    objects: ptr seq[PhysicalObject], enemies: ptr seq[Enemy]): Barrier =
    result = create_barrier("res/barrier/gate.yaml", area, size, space, id, barriers, objects, enemies)
    result.health = 10.0
    result.min_energy = 1000000000.0
    result.enemies_damage = false
    result.objects_damage = false
    result.hurt_wav = load_sound("res/barrier/wood_hurt.mp3")
    result.break_wav = load_sound("res/barrier/gate.mp3")

proc create_enemy_killer*(area: Vec4f, size: int, space: Space, id: int, barriers: ptr seq[Barrier],
    objects: ptr seq[PhysicalObject], enemies: ptr seq[Enemy]): Barrier =
    result = create_barrier("res/barrier/enemy_killer.yaml", area, size, space, id, barriers, objects, enemies, true)
    result.health = 10.0
    result.min_energy = 1000000000.0
    result.enemies_damage = false
    result.objects_damage = false
    result.hurt_wav = load_sound("res/barrier/wood_hurt.mp3")
    result.break_wav = load_sound("res/barrier/fry.mp3")
    result.destroy_enemy = true
    result.destroy_object = true

proc update*(this: var Barrier) =
    for sprite in mitems(this.sprites):
        sprite.animate(dt)
    if this.health <= 0.0:
        discard this.break_wav.play_sound()
        this.phys_space.removeShape(this.phys_shape)
        this.broken = true


proc draw*(this: var Barrier) =
    for sprite in this.sprites:
        renderer.draw(sprite)