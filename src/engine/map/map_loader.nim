# Renders a set of high resolution images from a set of level maps, a set of textures
# and a config map. Also generates colliders (noise free), areas, and points 
# Multiple level maps are allowed, but only one for the ground textures
# Uses marching squares + perlin noise

import glm
import yaml/serialization, streams
import ../physics/chipmunk
import stb_image/read as stbi
import nimgl/opengl
import std/sets
import std/tables
import std/random
import std/hashes
import std/options
import ../graphics/sprite
import ../base/renderer as rnd
import ../globals

export tables
export chipmunk

type TileInfo = object
    class: string
    texture: string
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
    images: seq[string]
    tiles: seq[TileInfo]
    areas: seq[AreaInfo]
    points: seq[PointInfo]

# Helper, internal image class. Not to be used outside!
type Image = ref object
    width: int
    height: int
    has_alpha: bool
    # RGB(A) pixels
    pixels: seq[uint8]

# Used during marching squares
type TileData = object
    texture*: Image
    noise*: float


# A tile is an image, alongside a set of collision lines and its location
# in the whole world (coordinates in final image)
# Each separate set of pixels will form a tile
type Tile* = ref object
    width*, height*: int
    image*: GLuint
    position*: Vec2i
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


type Map* = ref object
    drawer*: MapDrawer
    points*: Table[string, seq[Vec2f]]

proc hash(x: Vec3i): Hash =
    return x.x.hash !& x.y.hash !& x.z.hash

proc set_pixel(image: var Image, pos: Vec2i, color: Vec3i) =
    if pos.x >= 0 and pos.y >= 0 and pos.x < image.width and pos.y < image.height:
        if image.has_alpha:
            image.pixels[(pos.y * image.width + pos.x) * 4 + 0] = cast[uint8](color.x)
            image.pixels[(pos.y * image.width + pos.x) * 4 + 1] = cast[uint8](color.y)
            image.pixels[(pos.y * image.width + pos.x) * 4 + 2] = cast[uint8](color.z)
            image.pixels[(pos.y * image.width + pos.x) * 4 + 3] = 255'u8
        else:
            image.pixels[(pos.y * image.width + pos.x) * 3 + 0] = cast[uint8](color.x)
            image.pixels[(pos.y * image.width + pos.x) * 3 + 1] = cast[uint8](color.y)
            image.pixels[(pos.y * image.width + pos.x) * 3 + 2] = cast[uint8](color.z)

proc set_pixel(image: var Image, pos: Vec2i, color: Vec4i) =
    if pos.x >= 0 and pos.y >= 0 and pos.x < image.width and pos.y < image.height:
        if image.has_alpha:
            image.pixels[(pos.y * image.width + pos.x) * 4 + 0] = cast[uint8](color.x)
            image.pixels[(pos.y * image.width + pos.x) * 4 + 1] = cast[uint8](color.y)
            image.pixels[(pos.y * image.width + pos.x) * 4 + 2] = cast[uint8](color.z)
            image.pixels[(pos.y * image.width + pos.x) * 4 + 3] = cast[uint8](color.w)
        else:
            image.pixels[(pos.y * image.width + pos.x) * 3 + 0] = cast[uint8](color.x)
            image.pixels[(pos.y * image.width + pos.x) * 3 + 1] = cast[uint8](color.y)
            image.pixels[(pos.y * image.width + pos.x) * 3 + 2] = cast[uint8](color.z)

proc get_pixel(image: Image, pos: Vec2i): Vec3i = 
    if pos.x >= 0 and pos.y >= 0 and pos.x < image.width and pos.y < image.height:
        var r, g, b: uint8
        if image.has_alpha:
            r = image.pixels[(pos.y * image.width + pos.x) * 4 + 0]
            g = image.pixels[(pos.y * image.width + pos.x) * 4 + 1]
            b = image.pixels[(pos.y * image.width + pos.x) * 4 + 2]
        else:
            r = image.pixels[(pos.y * image.width + pos.x) * 3 + 0]
            g = image.pixels[(pos.y * image.width + pos.x) * 3 + 1]
            b = image.pixels[(pos.y * image.width + pos.x) * 3 + 2]
        return vec3i(r.int32, g.int32, b.int32)
    else:
        return vec3i(255, 255, 255)

proc get_pixel_wrap(image: Image, pos: Vec2i): Vec3i = 
    var wrap_pos = pos
    wrap_pos.x = wrap_pos.x mod image.width.int32
    wrap_pos.y = wrap_pos.y mod image.height.int32
    return get_pixel(image, wrap_pos)

proc create_image(width: int, height: int, has_alpha: bool = false): Image = 
    let size = (if has_alpha: 4 else: 3)
    return Image(width: width, height: height, pixels: newSeq[uint8](width * height * size), has_alpha: has_alpha)

proc load_image(path: string): Image = 
    var width, height, nCh : int
    let data = stbi.load(path, width, height, nCh, 3)
    result = create_image(width, height)
    for i in countup(0, width * height - 1):
        result.pixels[i * 3 + 0] = data[i * 3 + 0]
        result.pixels[i * 3 + 1] = data[i * 3 + 1]
        result.pixels[i * 3 + 2] = data[i * 3 + 2]

proc create_tile_data(info: TileInfo): TileData = 
    result.noise = info.noise
    result.texture = load_image(info.texture)

proc upload_to_gl*(image: Image): GLuint =
    var tex: Gluint
    glGenTextures(1, addr tex)
    glBindTexture(GL_TEXTURE_2D, tex)

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST.GLint)
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST.GLint)

    # The OpenGL bindings are a bit annoying with the types of enums!
    if image.has_alpha:
        glTexImage2D(GL_TEXTURE_2D, 0'i32, GL_RGBA.GLint, image.width.GLsizei, 
            image.height.GLsizei, 0.GLint, GL_RGBA, GL_UNSIGNED_BYTE, addr image.pixels[0])
    else:
        glTexImage2D(GL_TEXTURE_2D, 0'i32, GL_RGB.GLint, image.width.GLsizei, 
            image.height.GLsizei, 0.GLint, GL_RGB, GL_UNSIGNED_BYTE, addr image.pixels[0])

    return tex

proc load_map_info(map: string): MapInfo =
    var mapinfo: MapInfo
    var s = newFileStream(map)
    load(s, mapinfo)
    s.close()
    return mapinfo

# returns an image with only the tiles of desired class
proc extract_tiles_of_class(map: MapInfo, class: string, ground: Image): Image = 
    result = create_image(ground.width, ground.height)
    # Get valid colors
    var valid_colors: seq[array[3, uint8]]
    for tile in map.tiles:
        if tile.class == class:
            var color: array[3, uint8]
            color[0] = cast[uint8](tile.color[0])
            color[1] = cast[uint8](tile.color[1])
            color[2] = cast[uint8](tile.color[2])
            valid_colors.add(color)

    # Extract them from the image
    for i in countup(0, ground.width * ground.height - 1):
        var copy = false
        for color in valid_colors:
           if color[0] == ground.pixels[i * 3 + 0] and
                color[1] == ground.pixels[i * 3 + 1] and
                color[2] == ground.pixels[i * 3 + 2]:
                    copy = true
        if copy:
            result.pixels[i * 3 + 0] = ground.pixels[i * 3 + 0]
            result.pixels[i * 3 + 1] = ground.pixels[i * 3 + 1]
            result.pixels[i * 3 + 2] = ground.pixels[i * 3 + 2]
        else:
            result.pixels[i * 3 + 0] = 255
            result.pixels[i * 3 + 1] = 255
            result.pixels[i * 3 + 2] = 255

proc is_pixel_white(image: Image, x: int, y: int): bool =
    if x < 0 or y < 0 or x >= image.width or y >= image.height:
        return true

    let idx = y * image.width + x
    return image.pixels[idx * 3 + 0] == 255 and 
        image.pixels[idx * 3 + 1] == 255 and image.pixels[idx * 3 + 2] == 255

proc get_bounds(tile: Image): Vec4i = 
    var min_x = 999999'i32
    var min_y = 999999'i32
    var max_x = -1'i32
    var max_y = -1'i32
    for x in countup(0, tile.width - 1):
        for y in countup(0, tile.height - 1):
            if not is_pixel_white(tile, x, y):
                min_x = min(x.int32, min_x)
                min_y = min(y.int32, min_y)
                max_x = max(x.int32, max_x)
                max_y = max(y.int32, max_y)

    return vec4i(min_x, min_y, max_x, max_y)

proc bilinear_interp(tl: float, tr: float, bl: float, br: float, h: float, v: float): float =
    let h_interp_top = tl * (1.0 - h) + tr * h
    let h_interp_bottom = bl * (1.0 - h) + br * h
    return h_interp_top * (1.0 - v) + h_interp_bottom * v

proc bilinear_interp(tl: Vec3i, tr: Vec3i, bl: Vec3i, br: Vec3i, h: float, v: float): Vec3i =
    # Cast all to floats
    let h1 = 1.0 - h
    let v1 = 1.0 - v
    let tlf = vec3(tl.x.float * h1, tl.y.float * h1, tl.z.float * h1)
    let trf = vec3(tr.x.float * h, tr.y.float * h, tr.z.float * h)
    let blf = vec3(bl.x.float * h1, bl.y.float * h1, bl.z.float * h1)
    let brf = vec3(br.x.float * h, br.y.float * h, br.z.float * h)
    let h_interp_top = vec3((tlf.x + trf.x) * v1, (tlf.y + trf.y) * v1, (tlf.z + trf.z) * v1)
    let h_interp_bottom = vec3((blf.x + brf.x) * v, (blf.y + brf.y) * v, (blf.z + brf.z) * v)
    let sum = h_interp_top + h_interp_bottom
    return vec3i(sum.x.int32, sum.y.int32, sum.z.int32)

proc marching_squares(tile: Image, scale: int, tile_info: Table[Vec3i, TileData], space: Space): Tile =
    let bounds = get_bounds(tile)
    echo "Processing tile of size: " & $(bounds.z - bounds.x + 1) & "x" & $(bounds.w - bounds.y + 1)
    let pos = vec2i(bounds.x * scale.int32, bounds.y * scale.int32)
    echo bounds
    var image = create_image((bounds.z - bounds.x + 2) * scale, (bounds.w - bounds.y + 2) * scale)
    var body = newBody(1.0, 1.0)

    # We travel the corners of the pixels in the map texture
    for x in countup(bounds.x, bounds.z + 1):
        for y in countup(bounds.y, bounds.w + 1):
            let tex_x = (x - bounds.x) * scale
            let tex_y = (y - bounds.y) * scale
            # For colliders:
            let tx = (x * scale).toFloat
            let ty = (y * scale).toFloat

            let tl = not is_pixel_white(tile, x - 1, y - 1)
            let tr = not is_pixel_white(tile, x, y - 1)
            let bl = not is_pixel_white(tile, x - 1, y)
            let br = not is_pixel_white(tile, x, y)
            

            var ms_case = tl.int * 8 + tr.int * 4 + br.int * 2 + bl.int
            # Early optimization
            if ms_case == 0:
                continue

            # Generate the segment(s)
            if ms_case != 15:
                var v0: Vect
                var v1: Vect
                var has_two: bool
                var v2: Vect
                var v3: Vect
                case ms_case:
                of 1, 14:
                    v0 = v(tx - 0.5, ty + 0.5)
                    v1 = v(tx, ty + 1.0)
                of 2, 13:
                    v0 = v(tx + 0.5, ty + 0.5)
                    v1 = v(tx, ty + 1.0)
                of 3, 12:
                    v0 = v(tx - 0.5, ty)
                    v1 = v(tx + 0.5, ty)
                of 4, 11:
                    v0 = v(tx + 0.5, ty)
                    v1 = v(tx, ty - 0.5)
                of 5:
                    v0 = v(tx - 0.5, ty)
                    v1 = v(tx, ty - 0.5)
                    has_two = true
                    v2 = v(tx + 0.5, ty + 0.5)
                    v1 = v(tx, ty + 1.0)
                of 6, 9:
                    v0 = v(tx, ty - 0.5)
                    v1 = v(tx, ty + 0.5)
                of 7, 8:
                    v0 = v(tx - 0.5, ty)
                    v1 = v(tx, ty - 0.5)
                of 10:
                    v0 = v(tx - 0.5, ty + 0.5)
                    v1 = v(tx, ty + 1.0)
                    has_two = true
                    v2 = v(tx + 0.5, ty)
                    v3 = v(tx, ty - 0.5)
                else:
                    discard

                let segment = newSegmentShape(space.staticBody, v0, v1, 0)
                discard space.addShape(segment)
                if has_two:
                    let segment2 = newSegmentShape(space.staticBody, v2, v3, 0)
                    discard space.addShape(segment2)


            var tldata, trdata, bldata, brdata: Option[TileData]

            if tl:
                tldata = some(tile_info[get_pixel(tile, vec2i(x - 1, y - 1))])
            if tr:
                trdata = some(tile_info[get_pixel(tile, vec2i(x, y - 1))])
            if bl:
                bldata = some(tile_info[get_pixel(tile, vec2i(x - 1, y))])
            if br:
                brdata = some(tile_info[get_pixel(tile, vec2i(x, y))])

            # Fill unknown data so interpolation is always the same
            # This is very rough but it looks decent
            if tldata.isNone and trdata.isSome:
                tldata = trdata
            if trdata.isNone and tldata.isSome:
                trdata = tldata
            if trdata.isNone and brdata.isSome:
                trdata = brdata
            if tldata.isNone and bldata.isSome:
                tldata = bldata
            if tldata.isNone and brdata.isSome:
                tldata = brdata
            if trdata.isNone and bldata.isSome:
                trdata = bldata
            # Now one of tldata or trdata MUST have data so:
            if bldata.isNone and tldata.isSome:
                bldata = tldata
            if brdata.isNone and trdata.isSome:
                brdata = trdata

            # Finally, all must have data
            let tld = tldata.get
            let trd = trdata.get
            let bld = bldata.get
            let brd = brdata.get

            # Draw fill texture using regions technique. 
            # Note that samples were on pixel corner, but we draw on
            for sy in countup(0, scale - 1):
                for sx in countup(0, scale - 1):
                    # Interpolate between corners
                    let h = sx / (scale - 1)
                    let v = sy / (scale - 1)
                    let noise_interp = bilinear_interp(tld.noise, trd.noise, bld.noise, brd.noise, h, v)
                    
                    var noise_val = ((rand(200) - 100).toFloat / 100.0) * noise_interp
                    let noise_tex = noise_Val.toInt
                    
                    let tex = vec2i(int32(sx + x * scale + noiseTex), int32(sy + y * scale + noiseTex))
                    # Sample all textures at current pixel, with noise
                    let tls = tld.texture.get_pixel_wrap(tex)
                    let trs = trd.texture.get_pixel_wrap(tex)
                    let bls = bld.texture.get_pixel_wrap(tex)
                    let brs = brd.texture.get_pixel_wrap(tex)
                    
                    let tex_interp = bilinear_interp(tls, trs, bls, brs, h, v)


                    let hscale = toInt(scale / 2 + noise_val)
                    let in_tl_trig = sx < max(hscale - sy, 0)
                    let in_tr_trig = sx > max(hscale + sy, 0)
                    let in_bl_trig = sx < max(sy - hscale, 0)
                    let in_br_trig = sx >= max(scale - sy + hscale, 0)
                    let in_right = sx >= hscale
                    let in_bottom = sy >= hscale

                    # We set pixels if inside a region
                    var fill = false;
                    case ms_case:
                    of 1:
                        fill = in_bl_trig
                    of 2:
                        fill = in_br_trig
                    of 3:
                        fill = in_bottom
                    of 4:
                        fill = in_tr_trig
                    of 5:
                        fill = not in_tl_trig and not in_br_trig
                    of 6:
                        fill = in_right
                    of 7:
                        fill = not in_tl_trig
                    of 8:
                        fill = in_tl_trig
                    of 9:
                        fill = not in_right
                    of 10:
                        fill = not in_tr_trig and not in_bl_trig
                    of 11:
                        fill = not in_tr_trig
                    of 12:
                        fill = not in_bottom
                    of 13:
                        fill = not in_br_trig
                    of 14:
                        fill = not in_bl_trig
                    of 15:
                        fill = true
                    else:
                        fill = false
                    
                    let rx = sx + tex_x
                    let ry = sy + tex_y
                    # Interpolate textures
                    if fill:
                        image.set_pixel(vec2i(rx.int32, ry.int32), tex_interp)
                    else:
                        image.set_pixel(vec2i(rx.int32, ry.int32), vec4i(0, 0, 0, 0))

    return Tile(image: image.upload_to_gl(), position: pos, width: image.width, height: image.height)


# Breaks down an image into each unconnected chunk using an
# iterated flood-fill algorithm
proc extract_separated_tiles(imageo: Image): seq[Image] =
    var image = imageo
    var tiles: seq[Image]
    while true:
        # Find a non-white pixel
        var px, py: int
        var found = false
        block find_pixel_loop:
            for x in countup(0, image.width - 1):
                for y in countup(0, image.height - 1):
                    if not is_pixel_white(image, x, y):
                            px = x
                            py = y
                            found = true
                            break find_pixel_loop
        if not found:
            break
        # Flood fill algorithm 
        var tile = create_image(image.width, image.height)
        for i in countup(0, image.width * image.height * 3 - 1):
            tile.pixels[i] = 255
        var open = newSeq[Vec2i]()
        open.add(vec2i(px.int32, py.int32))
        while open.len > 0:
            # Eat current point
            let p = open[^1]
            open.setLen(open.len - 1)
            if not is_pixel_white(image, p.x, p.y):
                tile.set_pixel(p, image.get_pixel(p))
            image.set_pixel(p, vec3i(255, 255, 255))
            # Open all non-white sides
            for ox in countup(-1, 1):
                for oy in countup(-1, 1):
                    if not is_pixel_white(image, p.x + ox, p.y + oy):
                        open.add(vec2i((p.x + ox).int32, (p.y + oy).int32))

        tiles.add(tile)

    return tiles

proc load_map*(map: string, scale: int, space: Space): Map =
    let map_info = load_map_info(map)
    # Load images
    var images: seq[Image]
    for image in map_info.images:
        images.add(load_image(image))
    # Check that all images are the same size
    for image in images:
        assert((image.width == images[0].width) and (image.height == images[0].height))

    # Load tile textures
    var tile_textures: Table[Vec3i, TileData]
    for tile_type in map_info.tiles:
        let colorvec = vec3i(tile_type.color[0].int32, tile_type.color[1].int32, tile_type.color[2].int32)
        tile_textures[colorvec] = create_tile_data(tile_type)

    # Extract all ground classes and their image
    var all_ground_classes: sets.HashSet[string]
    for tile in map_info.tiles:
        all_ground_classes.incl(tile.class)
    var ground_classes: Table[string, Image]
    for class in all_ground_classes:
        ground_classes[class] = extract_tiles_of_class(map_info, class, images[0])
    
    var ground_tiles_img: Table[string, seq[Image]]
    for class, image in ground_classes:
        ground_tiles_img[class] = extract_separated_tiles(image)
        echo "Found " & $ground_tiles_img[class].len & " tile of class " &  class

    # Run marching squares
    echo "Running marching squares, this may take a while!"
    var ground_tiles: Table[string, seq[Tile]]
    for class, images in ground_tiles_img:
        var tiles: seq[Tile]
        for image in images:
            tiles.add(marching_squares(image, scale, tile_textures, space))
        ground_tiles[class] = tiles

    # Load points
    var points: Table[string, seq[Vec2f]]
    for point in map_info.points:
        points[point.name] = newSeq[Vec2f]()
        # Search for the color over the whole map
        let color = vec3i(point.color[0].int32, point.color[1].int32, point.color[2].int32)
        for image in images:
            for x in countup(0, image.width - 1):
                for y in countup(0, image.height - 1):
                    if image.get_pixel(vec2i(x.int32, y.int32)) == color:
                        let pf = vec2f((x * scale).toFloat, (y * scale).toFloat)
                        points[point.name].add(pf)
    let drawer = create_map_drawer(ground_tiles)
    return Map(drawer: drawer)



