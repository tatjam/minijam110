# Common stuff for levels
import ../entities/player
import ../../engine/map/map_loader

# A level consist of the player, a set of live enemies
# and objects (pushable, pullable, pickable, interactable)
type Level* = object
    player*: Player
    map*: Map
    physics_space*: Space

method init*(this: var Level, map: string, scale: int) = 
    this.physics_space = newSpace()
    this.map = load_map(map, scale, this.physics_space)
