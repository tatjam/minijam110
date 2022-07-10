include ../../engine/base
import ../../engine/map/map_loader
import ../../engine/graphics/sprite
import ../entities/player
import ../entities/platform
import ../entities/physical_object
import ../../engine/base/renderer as rnd
import level
import level3

type Level2Scene* = ref object of Scene
    music: WavHandle
    level: Level
    tut: seq[Sprite]
    open: bool
    cable: Line

method init(this: Level2Scene) =
    this.music = load_sound("res/level1/music.mp3")
    discard play_sound(this.music, true)
    this.level.init("res/level2/map.yaml", "res/level2/backdrop.png", "res/level2/backdrop_fx.png", 20)
    let points = @[vec2f(92.0 * 20.0 + 5.0, 75.0 * 20.0 + 15.0), vec2f(98.0 * 20.0, 75.0 * 20.0 + 15.0), 
        vec2f(98.0 * 20.0, 59.0 * 20.0)]
    this.cable = create_line(points, 8.0)
    this.cable.color = vec4f(0.1, 0.1, 0.1, 0.7)

    this.tut.add(create_sprite("res/level2/tutorial00.png"))
    this.tut[0].center_position = vec2f(99 * 20.0, 54 * 20.0)
    this.tut.add(create_sprite("res/level2/tutorial01.png"))
    this.tut[1].center_position = vec2f(104 * 20.0, 61 * 20.0)
    for tut in mitems(this.tut):
        tut.clear_fx = false

    this.level.platforms.add(create_platform(
        v(111.0 * 20.0 + 30.0, 55.0 * 20.0),
        v(145 * 20.0, 23.0 * 20.0),
        vec2f(103.0 * 20.0, 55.0 * 20.0),
        vec2f(156 * 20.0, 23.0 * 20.0),
        this.level.physics_space
    ))



method update(this: Level2Scene) =
    if this.level.update():
        echo "Scene change"
        goto_scene(Level3Scene())
    let button_obj = this.level.physical_objects[this.level.buttons_idx[0]]
    if button_obj.active:
        this.cable.fx_color = vec4f(1.0, 0.4, 0.4, 1.0)
        this.open = true
        this.level.barriers[0].health = 0.0
    else:
        this.cable.fx_color = vec4f(0, 0, 0, 0)

method render(this: Level2Scene) = 
    this.level.draw()
    renderer.draw(this.cable)
    if not this.open:
        renderer.draw(this.tut[0])
    renderer.draw(this.tut[1])