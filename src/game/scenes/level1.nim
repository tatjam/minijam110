include ../../engine/base
import ../../engine/map/map_loader
import ../../engine/graphics/sprite
import ../entities/player
import level
import cutsc1

type Level1Scene* = ref object of Scene
    music: WavHandle
    musich: AudioHandle
    level: Level
    tut: seq[Sprite]

method init(this: Level1Scene) =
    echo "Init!"
    this.music = load_sound("res/level1/music.mp3")
    this.musich = play_sound(this.music, true)
    
    this.level.init("res/level1/map.yaml", "res/level1/backdrop.png", "none", 20)
    this.tut.add(create_sprite("res/tutorial/tut000.png"))
    this.tut.add(create_sprite("res/tutorial/tut0.png"))
    this.tut.add(create_sprite("res/tutorial/tut00.png"))
    this.tut.add(create_sprite("res/tutorial/tut1.png"))
    this.tut.add(create_sprite("res/tutorial/tut2.png"))
    this.tut.add(create_sprite("res/tutorial/tut3.png"))

    this.tut[0].center_position = vec2f(52 * 20.0, 21 * 20.0)
    this.tut[1].center_position = vec2f(49 * 20.0, 13 * 20.0)
    this.tut[2].center_position = vec2f(73 * 20.0, 23 * 20.0)
    this.tut[3].center_position = vec2f(152 * 20.0, 17 * 20.0)
    this.tut[4].center_position = vec2f(176 * 20.0, 29 * 20.0)
    this.tut[5].center_position = vec2f(207 * 20.0, 13 * 20.0)

    for tut in mitems(this.tut):
        tut.clear_fx = false


method update(this: Level1Scene) =
    if this.level.update():
        this.musich.pause() 
        goto_scene(CutScene1())
method render(this: Level1Scene) = 
    this.level.draw()
    for tut in this.tut:
        renderer.draw(tut)