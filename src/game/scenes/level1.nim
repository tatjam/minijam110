include ../../engine/base
import ../../engine/map/map_loader
import ../../engine/graphics/sprite

type Level1Scene* = ref object of Scene
    music: WavHandle
    sprite: Sprite

method init(this: Level1Scene) =
    this.music = load_sound("res/level1/music.mp3")
    let tiles = load_map("res/level1/map.yaml")
    let tile = tiles["ground"][0]
    this.sprite = create_sprite(tile.image, tile.width, tile.height)
    this.sprite.scale = vec2f(1, 1)
    #discard play_sound(this.music, true)

method render(this: Level1Scene) = 
    renderer.draw(this.sprite)