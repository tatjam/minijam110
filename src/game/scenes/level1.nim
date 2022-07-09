include ../../engine/base
import ../../engine/map/map_loader
import ../../engine/graphics/sprite
import ../entities/player
import level

type Level1Scene* = ref object of Scene
    music: WavHandle
    level: Level

method init(this: Level1Scene) =
    echo "Init!"
    this.music = load_sound("res/level1/music.mp3")
    #discard play_sound(this.music, true)
    
    this.level.init("res/level1/map.yaml", 8)
    renderer.camera.scale = 1.0
    renderer.camera.center = vec2f(27 * 8.0, 21 * 8.0)


method update(this: Level1Scene) = 
    return
method render(this: Level1Scene) = 
    this.level.map.drawer.draw_tiles()