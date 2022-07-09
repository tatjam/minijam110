# Common stuff for levels
import ../entities/player
import ../entities/enemy

import ../../engine/map/map_loader
import ../entities/physical_object
import ../../engine/globals
import ../../engine/graphics/sprite

import glm

# A level consist of the player, a set of live enemies
# and objects (pushable, pullable, pickable, interactable)
type Level* = object
    player*: Player
    map*: Map
    physics_space*: Space
    physical_object: seq[PhysicalObject]
    enemies: seq[Enemy]

proc test(shape: Shape, data: pointer) {.cdecl.} =
    echo "In test: "
    #echo repr shape


proc init*(this: var Level, map: string, scale: int) = 
    this.physics_space = newSpace()
    this.physics_space.gravity = v(0, 100)
    this.map = load_map(map, scale, this.physics_space)

    this.player = create_player(vec2f(250.0, -50.0), this.physics_space)

    for i in countup(5, 40):
        this.enemies.add(create_rockman(vec2f(i.toFloat * 32.0, 0.0), this.physics_space))

proc update*(this: var Level) = 
    this.physics_space.step(dt)
    for enemy in mitems(this.enemies):
        enemy.update()
    this.player.update()

    renderer.camera.center = this.player.sprite.position
    renderer.camera.scale = 1.0

proc draw*(this: var Level) = 
    this.map.drawer.draw_tiles()
    for enemy in mitems(this.enemies):
        enemy.draw()
    this.player.draw()

