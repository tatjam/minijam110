# Renders a set of high resolution images from a set of level maps, a set of textures
# and a config map. Also generates colliders (noise free), areas, and points 
# Multiple level maps are allowed, but only one for the ground textures
# Uses marching squares + perlin noise

import glm
import yaml/serialization, streams
import ../physics/chipmunk

type TileInfo = object
    class: string
    texture: string
    edge: array[3, int]
    edge_width: int
    noise: float
    color: array[3, int]

type AreaInfo = object
    name: string
    color: array[3, int]

type PointInfo = object
    name: string
    color: array[3, int]

type MapInfo = object 
    seed: int
    tiles: seq[TileInfo]
    areas: seq[AreaInfo]
    points: seq[PointInfo]

type Image* = object
    width: int
    height: int
    # RGB pixels
    pixels: seq[uint8]

# A tile is an image, alongside a set of concave collision polygons and its location
# in the whole world (coordinates in original pixel image)
type Tile* = object
    image: Image
    position: Vec2i
    polys: seq[PolyShape]


proc set_pixel(image: var Image, pos: Vec2i, color: Vec3i) =
    if pos.x >= 0 and pos.y >= 0 and pos.x < image.width and pos.y < image.height:
        image.pixels[(pos.y * image.width + pos.x) * 3 + 0] = cast[uint8](color.x)
        image.pixels[(pos.y * image.width + pos.x) * 3 + 0] = cast[uint8](color.y)
        image.pixels[(pos.y * image.width + pos.x) * 3 + 0] = cast[uint8](color.z)
    
proc create_image(size: Vec2i): Image = 
    return Image(width: size.x, height: size.y, pixels: newSeq[uint8](size.x * size.y * 3))

proc load_map_info(map: string): MapInfo =
    var mapinfo: MapInfo
    var s = newFileStream(map)
    load(s, mapinfo)
    s.close()
    return mapinfo

proc extract_tiles() =
    return

proc load_map*(map: string) =
    let map_info = load_map_info(map)
    


