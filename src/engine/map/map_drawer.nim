import ../graphics/sprite
import ../globals
import ../base/renderer as rnd
import ../../engine/map/map_loader
import ../physics/chipmunk
import glm

export map_loader
export chipmunk

type MapDrawer* = object
    sprites: seq[Sprite]

proc draw_tiles*(map: MapDrawer) = 
    for sprite in map.sprites:
        renderer.draw(sprite)

proc create_map_drawer*(map: Table[string, seq[Tile]]): MapDrawer = 
    for class, tiles in map:
        for tile in tiles:
            let sprite = create_sprite(tile.image, tile.width, tile.height)
            # We must make a few adjustments as positioning is inverted
            sprite.position = vec2f(tile.position.x.toFloat, tile.position.y.toFloat)
            echo tile.position
            result.sprites.add(sprite)

# TODO: Misnomer, as it actually loads the map
proc create_map_drawer*(map: string, scale: int, space: Space): MapDrawer = 
    return create_map_drawer(load_map(map, scale, space))
