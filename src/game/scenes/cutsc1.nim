include ../../engine/base
import ../../engine/graphics/shader
import level2


type CutScene1* = ref object of Scene
    back: Sprite
    eldritch: Sprite
    text: seq[Sprite]
    text_prg: int
    cur_time: float
    text_time: float
    text_times: seq[float]
    music: WavHandle
    time: float

method init(this: CutScene1) =
    renderer.camera.center = vec2f(320, 150)
    renderer.camera.scale = 1.0
    renderer.fullscreen_shader = load_shader("res/shader/fullscreen_intro")
    this.back = create_sprite("res/clip1/back.png")
    this.eldritch = create_sprite("res/clip1/eldritch.png")
    this.text.add(create_sprite("res/clip1/text0.png"))
    this.text.add(create_sprite("res/clip1/text1.png"))
    this.text.add(create_sprite("res/clip1/text2.png"))
    this.text[2].position = vec2f(0.0, 100.0)
    this.text_times.add(10.0)
    this.text_times.add(7.0)
    this.text_times.add(4.0)
    this.text_prg = -1
    this.text_time = 0.0

    this.music = load_sound("res/clip1/music.mp3")

    discard play_sound(this.music)

method update(this: CutScene1) =
    this.time += dt
    this.text_time -= dt
    this.cur_time -= dt
    
    renderer.camera.center = vec2f(320, 150 + this.time * 4.0)
    if this.time > 20.0:
        this.eldritch.position = vec2f(0, 500 - (this.time - 20.0) * 160.0)
    else:
        this.eldritch.position = vec2f(0, 500.0)

    if this.time > 28.0:
        goto_scene(Level2Scene())

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



method render(this: CutScene1) = 
    renderer.draw(this.eldritch)
    renderer.draw(this.back)
    for text in this.text:
        renderer.draw(text)