# Common stuff for levels
import ../entities/player
import ../entities/enemy

import ../../engine/map/map_loader
import ../entities/physical_object
import ../../engine/globals
import ../../engine/graphics/sprite
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
    enemies: seq[Enemy]

proc test(shape: Shape, data: pointer) {.cdecl.} =
    echo "In test: "
    #echo repr shape


proc init*(this: var Level, map: string, scale: int) = 
    this = new(Level)
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

    # Create all types of stuff
    if this.map.points.hasKey("rockman"):
        for point in this.map.points["rockman"]:
            this.enemies.add(create_rockman(point, this.physics_space))
    
    if this.map.points.hasKey("rock"):
        for point in this.map.points["rock"]:
            this.physical_objects.add(create_rock(point, this.physics_space))

    if this.map.points.hasKey("magmarock"):
        for point in this.map.points["magmarock"]:
            this.physical_objects.add(create_magmarock(point, this.physics_space))

proc update*(this: var Level) = 
    this.physics_space.step(dt)
    for enemy in mitems(this.enemies):
        enemy.update(this.player)
    for phys_obj in mitems(this.physical_objects):
        phys_obj.update()
    this.player.update()

    renderer.camera.center = this.player.sprite.position
    renderer.camera.scale = 1.0

proc draw*(this: var Level) = 
    this.map.drawer.draw_tiles()
    for enemy in mitems(this.enemies):
        enemy.draw()
    for phys_obj in mitems(this.physical_objects):
        phys_obj.draw()
    this.player.draw()

