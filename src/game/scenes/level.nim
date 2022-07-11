# Common stuff for levels
import ../entities/player
import ../entities/enemy
import ../entities/barrier
import ../entities/door
import ../entities/platform

import ../../engine/map/map_loader
import ../entities/physical_object
import ../../engine/globals
import ../../engine/audio/audio_engine
import ../../engine/graphics/sprite
import ../../engine/graphics/shader
import ../../engine/base/renderer as rnd
import ../userdata
import options

import nimgl/glfw

import glm

# A level consist of the player, a set of live enemies
# and objects (pushable, pullable, pickable, interactable)
type Level* = ref object
    player*: Player
    map*: Map
    scale: int
    terr_udata: UserData
    physics_space*: Space
    physical_objects*: seq[PhysicalObject]
    barriers*: seq[Barrier]
    enemies*: seq[Enemy]
    # Must be manually created
    platforms*: seq[Platform]
    doors: seq[Door]
    backdrop: Sprite
    deco: seq[AnimatedSprite]
    kill: seq[Vec4f]

    reinit*: bool

    die_timer: float
    die_sprite: Sprite
    die_sound: WavHandle
    # Buttons have a preset ammount of buttons
    buttons_idx*: array[4, int]



proc init_no_map(this: var Level, scale: int) = 
    this.reinit = true
    this.player = create_player(this.map.points["player"][0], this.physics_space)
    this.die_timer = -1.0

    # Create all types of enemies / objects
    if this.map.points.hasKey("rockman"):
        for point in this.map.points["rockman"]:
            this.enemies.add(create_rockman(point, this.physics_space, this.enemies.len))
    
    if this.map.points.hasKey("bird"):
        for point in this.map.points["bird"]:
            this.enemies.add(create_bird(point, this.physics_space, this.enemies.len))

    if this.map.points.hasKey("rockman_spawner"):
        for point in this.map.points["rockman_spawner"]:
            this.enemies.add(create_rockman_spawner(point, this.physics_space, this.enemies.len))
    
    if this.map.points.hasKey("rock"):
        for point in this.map.points["rock"]:
            this.physical_objects.add(create_rock(point, this.physics_space, this.physical_objects.len))

    if this.map.points.hasKey("magmarock"):
        for point in this.map.points["magmarock"]:
            this.physical_objects.add(create_magmarock(point, this.physics_space, this.physical_objects.len))
    
    if this.map.points.hasKey("box"):
        for point in this.map.points["box"]:
            this.physical_objects.add(create_box(point, this.physics_space, this.physical_objects.len))
    
    for i in countup(0, this.buttons_idx.len - 1):
        this.buttons_idx[i] = -1
        let str = "button" & $i
        if this.map.points.hasKey(str) and this.map.points[str].len == 1:
            let point = this.map.points[str][0]
            this.physical_objects.add(create_button(point, this.physics_space, this.physical_objects.len, 
                addr this.physical_objects))
            this.buttons_idx[i] = this.physical_objects.len - 1


    # Load barriers
    if this.map.areas.hasKey("break_wood"):
        for area in this.map.areas["break_wood"]:
            this.barriers.add(create_wooden_barrier(area, scale, this.physics_space, this.barriers.len, 
                addr this.barriers, addr this.physical_objects, addr this.enemies))
    
    if this.map.areas.hasKey("gate"):
        for area in this.map.areas["gate"]:
            this.barriers.add(create_gate(area, scale, this.physics_space, this.barriers.len,
                addr this.barriers, addr this.physical_objects, addr this.enemies))

    if this.map.areas.hasKey("enemy_killer"):
        for area in this.map.areas["enemy_killer"]:
            this.barriers.add(create_enemy_killer(area, scale, this.physics_space, this.barriers.len, 
                addr this.barriers, addr this.physical_objects, addr this.enemies))
    # Kill zones
    if this.map.areas.hasKey("kill"):
        for area in this.map.areas["kill"]:
            this.kill.add(area)
    
    # Load doors
    if this.map.points.hasKey("door"):
        for point in this.map.points["door"]:
            this.doors.add(create_door(point))

    # Load deco
    if this.map.points.hasKey("light1l"):
        for point in this.map.points["light1l"]:
            var sprite = create_animated_sprite("res/deco/light1.yaml")
            sprite.position = vec2f(point.x - 10.0, point.y)
            this.deco.add(sprite)
    
    if this.map.points.hasKey("light"):
        for point in this.map.points["light"]:
            var sprite = create_animated_sprite("res/deco/light.yaml")
            sprite.center_position = vec2f(point.x, point.y)
            this.deco.add(sprite)

# Removes all physical objects EXCEPT the world, and reinits
proc restart(this: var Level) =
    for obj in this.physical_objects:
        if not obj.dead:
            this.physics_space.removeBody(obj.phys_body)
            this.physics_space.removeShape(obj.phys_shape)
    for barrier in this.barriers:
        if not barrier.broken:
            this.physics_space.removeShape(barrier.phys_shape)
    for enemy in this.enemies:
        if not enemy.dead:
            this.physics_space.removeBody(enemy.phys_body)
            this.physics_space.removeShape(enemy.phys_shape)


    this.player.deinit()
    this.physics_space.removeBody(this.player.phys_body)
    this.physics_space.removeShape(this.player.phys_shape)

    this.physical_objects.setLen(0)
    this.barriers.setLen(0)
    this.enemies.setLen(0)
    this.doors.setLen(0)
    this.init_no_map(this.scale)


proc die(this: var Level) =
    if this.die_timer < 0.0:
        discard this.die_sound.play_sound()
        this.die_timer = 2.0

proc init*(this: var Level, map: string, backdrop: string, backdrop_fx: string, scale: int) = 
    this = new(Level)
    this.scale = scale
    renderer.fullscreen_shader = load_shader("res/shader/fullscreen")
    renderer.camera.scale = 1.0
    this.physics_space = newSpace()
    this.physics_space.gravity = v(0, 400)
    this.map = load_map(map, scale, this.physics_space)
    
    this.terr_udata = make_terrain_userdata()
    # Assign the userdata to all segments
    for segment in mitems(this.map.segments):
        # TODO: FIx this
        ##segment.userData = addr this.terr_udata
        segment.friction = 0.5
    
    if backdrop_fx != "none":
        this.backdrop = create_sprite(backdrop, backdrop_fx)
    else:
        this.backdrop = create_sprite(backdrop)
    this.die_sprite = create_sprite("res/perish.png", "res/perish.png")
    this.die_sound = load_sound("res/perish.mp3")
    
    init_no_map(this, this.scale)

proc update*(this: var Level): bool = 
    this.reinit = false
    # we do multiple substeps to prevent pass-through
    # TODO: Tune this
    const steps = 4
    for i in countup(0, steps - 1):
        this.physics_space.step(dt / steps)
    
    var nenemies: seq[Enemy]
    var enemy_count = this.enemies.len
    for enemy in mitems(this.enemies):
        if not enemy.dead:
            let nenemy = enemy.update(this.player, this.physical_objects, enemy_count, this.physics_space)
            if nenemy.isSome:
                nenemies.add(nenemy.get())
    
    for nenemy in nenemies:
        this.enemies.add(nenemy)

    for phys_obj in mitems(this.physical_objects):
        if not phys_obj.dead:
            phys_obj.update(this.physics_space)
    
    for barrier in mitems(this.barriers):
        if not barrier.broken:
            barrier.update()

    var in_platform: bool = false
    var control_platform: Option[Platform]
    for platform in this.platforms:
        if platform.in_control:
            control_platform = some(platform)
            in_platform = true
            break

    for platform in mitems(this.platforms):
        platform.update(this.player, control_platform)
    
    if not in_platform:
        this.player.update(this.enemies, this.physical_objects)
    

    var exit = false
    for door in this.doors:
        exit = exit or door.update(this.player)

    if exit:
        this.player.deinit()
        return true


    if glfw_window.getKey(GLFWKey.R) == GLFW_PRESS:
        this.restart()
    
    let screens = vec2f(
        this.backdrop.texture_width.toFloat / 640,
        this.backdrop.texture_height.toFloat / 384
    )

    let screenp = vec2f(
        ((renderer.camera.center.x / this.map.size.x) * screens.x - 0.5) * 2.0,
        ((renderer.camera.center.y / this.map.size.y) * screens.y - 0.5) * 2.0
    )

    let offset = vec2f(
        renderer.camera.center.x - 640 * 0.25 * screenp.x,
        renderer.camera.center.y - 384 * 0.25 * screenp.y
    )


    this.backdrop.center_position = offset

    # Check die areas
    for area in this.kill:
        let pos = this.player.sprite.position
        if pos.x > area.x and pos.y > area.y and pos.x < area.z and pos.y < area.w:
            this.die()

    if this.player.health < 0.0:
        this.die()
    
    if this.die_timer > 0.0:
        this.die_timer -= dt
        if this.die_timer < 0.0:
            this.restart()

    return false

proc draw*(this: var Level) = 
    if this.die_timer > 0.0:
        this.die_sprite.center_position = renderer.camera.center
        renderer.draw(this.die_sprite)
    else:

        renderer.draw(this.backdrop)

        this.map.drawer.draw_tiles()
        

        for enemy in mitems(this.enemies):
            if not enemy.dead:
                enemy.draw()
        for phys_obj in mitems(this.physical_objects):
            if not phys_obj.dead:
                phys_obj.draw()

        for barrier in mitems(this.barriers):
            if not barrier.broken:
                barrier.draw()
        this.player.draw()
        
        for door in this.doors:
            door.draw()
    
        for deco in this.deco:
            renderer.draw(deco)

        for platform in this.platforms:
            platform.draw()
        
        this.player.draw_fx()


