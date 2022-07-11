include ../../engine/base
import ../../engine/map/map_loader
import ../../engine/graphics/sprite
import ../entities/player
import ../entities/platform
import ../entities/physical_object
import ../../engine/base/renderer as rnd
import level
import cutsc2

type Level3Scene* = ref object of Scene
    music: WavHandle
    level: Level
    open: bool
    event_played: bool
    cable: Line
    run_sound: WavHandle

method init(this: Level3Scene) =
    this.music = load_sound("res/level3/music.mp3")
    discard play_sound(this.music, true)
    this.level.init("res/level3/map.yaml", "res/level1/backdrop.png", "none", 20)
    let points = @[vec2f(71.0 * 20.0 + 5.0, 87.0 * 20.0 + 15.0), vec2f(75.0 * 20.0, 87.0 * 20.0 + 15.0), 
        vec2f(75.0 * 20.0, 83.0 * 20.0)]
    this.cable = create_line(points, 8.0)
    this.cable.color = vec4f(0.1, 0.1, 0.1, 0.7)
    this.run_sound = load_sound("res/level3/run.mp3")



method update(this: Level3Scene) =
    if this.level.reinit:
        this.event_played = false

    if this.level.update():
        goto_scene(CutScene2())
    
    let button_obj = this.level.physical_objects[this.level.buttons_idx[0]]
    if button_obj.active:
        this.cable.fx_color = vec4f(1.0, 0.4, 0.4, 1.0)
        this.open = true
        this.level.barriers[1].health = 0.0
    else:
        this.cable.fx_color = vec4f(0, 0, 0, 0)

    if not this.event_played:
        if this.level.player.sprite.center_position.y < 40.0 * 20.0:
            discard this.run_sound.play_sound()
            for obj in this.level.physical_objects:
                if obj.kind == okMagmaRock:
                    let p = obj.phys_body.position
                    obj.phys_body.applyImpulseAtWorldPoint(v(10000.0, 0.0), p)
                    this.event_played = true

method render(this: Level3Scene) = 
    this.level.draw()
    renderer.draw(this.cable)