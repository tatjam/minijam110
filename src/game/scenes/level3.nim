include ../../engine/base
import ../../engine/map/map_loader
import ../../engine/graphics/sprite
import ../entities/player
import ../entities/platform
import ../entities/physical_object
import ../../engine/base/renderer as rnd
import level

type Level3Scene* = ref object of Scene
    music: WavHandle
    level: Level
    open: bool
    cable: Line

method init(this: Level3Scene) =
    this.music = load_sound("res/level3/music.mp3")
    #discard play_sound(this.music, true)
    this.level.init("res/level3/map.yaml", "res/level1/backdrop.png", "none", 20)
    let points = @[vec2f(71.0 * 20.0 + 5.0, 67.0 * 20.0 + 15.0), vec2f(75.0 * 20.0, 67.0 * 20.0 + 15.0), 
        vec2f(75.0 * 20.0, 63.0 * 20.0)]
    this.cable = create_line(points, 8.0)
    this.cable.color = vec4f(0.1, 0.1, 0.1, 0.7)



method update(this: Level3Scene) =
    if this.level.update():
        goto_scene(Level3Scene())
    
    let button_obj = this.level.physical_objects[this.level.buttons_idx[0]]
    if button_obj.active:
        this.cable.fx_color = vec4f(1.0, 0.4, 0.4, 1.0)
        this.open = true
        this.level.barriers[1].health = 0.0
    else:
        this.cable.fx_color = vec4f(0, 0, 0, 0)

method render(this: Level3Scene) = 
    this.level.draw()
    renderer.draw(this.cable)