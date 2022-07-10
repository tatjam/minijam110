# Common stuff for levels
import ../entities/player
import ../entities/enemy
import ../entities/barrier

import ../../engine/map/map_loader
import ../entities/physical_object
import ../../engine/globals
import ../../engine/graphics/sprite
import ../../engine/graphics/shader
import ../userdata

import glm

# A level consist of the player, a set of live enemies
# and objects (pushable, pullable, pickable, interactable)
type Level* = ref object
    player*: Player
    map*: Map
    terr_udata: UserData
    physics_space*: Space
    physical_objects*: seq[PhysicalObject]
    barriers*: seq[Barrier]
    enemies: seq[Enemy]


proc init*(this: var Level, map: string, scale: int) = 
    this = new(Level)
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
    
    this.player = create_player(this.map.points["player"][0], this.physics_space)

    # Create all types of enemies / objects
    if this.map.points.hasKey("rockman"):
        for point in this.map.points["rockman"]:
            this.enemies.add(create_rockman(point, this.physics_space, this.enemies.len))
    
    if this.map.points.hasKey("rock"):
        for point in this.map.points["rock"]:
            this.physical_objects.add(create_rock(point, this.physics_space, this.physical_objects.len))

    if this.map.points.hasKey("magmarock"):
        for point in this.map.points["magmarock"]:
            this.physical_objects.add(create_magmarock(point, this.physics_space, this.physical_objects.len))

    # Load barriers
    if this.map.areas.hasKey("break_wood"):
        for area in this.map.areas["break_wood"]:
            this.barriers.add(create_wooden_barrier(area, scale, this.physics_space, this.barriers.len, addr this.barriers))

proc update*(this: var Level) = 
    this.physics_space.step(dt)
    for enemy in mitems(this.enemies):
        if not enemy.dead:
            enemy.update(this.player, this.physical_objects, this.physics_space)
    for phys_obj in mitems(this.physical_objects):
        phys_obj.update()
    this.player.update(this.enemies, this.physical_objects)

    renderer.camera.center = this.player.sprite.position
    renderer.camera.scale = 1.0

proc draw*(this: var Level) = 
    this.map.drawer.draw_tiles()

    for enemy in mitems(this.enemies):
        if not enemy.dead:
            enemy.draw()
    for phys_obj in mitems(this.physical_objects):
        phys_obj.draw()

    for barrier in mitems(this.barriers):
        if not barrier.broken:
            barrier.draw()
    this.player.draw()



