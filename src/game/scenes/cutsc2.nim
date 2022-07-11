include ../../engine/base
import ../../engine/graphics/shader

import level4


type CutScene2* = ref object of Scene
    back: Sprite
    eldritch: Sprite
    factory: Sprite
    wall: Sprite
    fore: Sprite
    text: seq[Sprite]
    text_prg: int
    cur_time: float
    text_time: float
    text_times: seq[float]
    music: WavHandle
    time: float

method init(this: CutScene2) =
    renderer.camera.center = vec2f(320, 150)
    renderer.camera.scale = 1.0
    renderer.fullscreen_shader = load_shader("res/shader/fullscreen_intro")
    this.back = create_sprite("res/clip2/back.png")
    this.eldritch = create_sprite("res/clip2/eldritch.png")
    this.factory = create_sprite("res/clip2/factory.png")
    this.wall = create_sprite("res/clip2/wall.png")
    this.fore = create_sprite("res/clip2/fore.png")

    this.text.add(create_sprite("res/clip2/text0.png"))
    this.text.add(create_sprite("res/clip2/text1.png"))
    this.text.add(create_sprite("res/clip2/text3.png"))
    this.text_times.add(10.0)
    this.text_times.add(5.0)
    this.text_times.add(7.0)
    this.text_prg = -1
    this.text_time = 0.0

    this.music = load_sound("res/clip1/music.mp3")

    discard play_sound(this.music)

method update(this: CutScene2) =
    this.time += dt
    this.text_time -= dt
    this.cur_time -= dt
    
    renderer.camera.center = vec2f(320, 192)
    if this.time > 18.0:
        this.eldritch.position = vec2f(0, 500 - (this.time - 18.0) * 100.0)
    else:
        this.eldritch.position = vec2f(0, 500.0)

    this.fore.position = vec2f(
        (sin(this.time) + 1.0)  * 10.0,
        (cos(this.time) + 1.0) * 20.0
    )

    if this.time > 28.0:
        goto_scene(Level4Scene())

    if this.text_time < 0.0:
        inc this.text_prg
        if this.text_prg < this.text.len:
            this.text_time = this.text_times[this.text_prg]
            this.cur_time = 1.0

    for i in countup(0, this.text.len - 1):
        if i == this.text_prg:
            this.text[i].tint = vec4f(1.0, 1.0, 1.0, min(1.0 - this.cur_time, 1.0))
        elif i == this.text_prg - 1:
            this.text[i].tint = vec4f(1.0, 1.0, 1.0, max(this.cur_time, 0.0))
        else:
            this.text[i].tint = vec4f(1.0, 1.0, 1.0, 0.0)



method render(this: CutScene2) = 
    renderer.draw(this.back)
    renderer.draw(this.eldritch)
    renderer.draw(this.factory)
    renderer.draw(this.wall)
    renderer.draw(this.fore)
    for text in this.text:
        renderer.draw(text)