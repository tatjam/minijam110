include ../../engine/base
import ../../engine/map/map_drawer
import ../../engine/graphics/sprite

type Level1Scene* = ref object of Scene
    music: WavHandle
    map_drawer: MapDrawer
    physics_space: Space

method init(this: Level1Scene) =
    this.music = load_sound("res/level1/music.mp3")
    #discard play_sound(this.music, true)
    
    this.physics_space = newSpace()
    this.map_drawer = create_map_drawer("res/level1/map.yaml", 16, this.physics_space)
    renderer.camera.scale = 0.4
    renderer.camera.center = vec2f(27 * 16.0, 21 * 16.0)

method render(this: Level1Scene) = 
    this.map_drawer.draw_tiles()