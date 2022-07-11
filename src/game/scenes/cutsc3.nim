include ../../engine/base
import ../../engine/graphics/shader


type CutScene3* = ref object of Scene
    sky0: Sprite
    sky1: Sprite
    sky2: Sprite
    sun: Sprite
    eldritch: Sprite
    big: Sprite
    backdrop0: Sprite
    backdrop1: Sprite
    backdrop2: Sprite
    backdrop3: Sprite

    text: seq[Sprite]
    text_prg: int
    cur_time: float
    text_time: float
    text_times: seq[float]
    music: WavHandle
    time: float

method init(this: CutScene3) =
    renderer.camera.center = vec2f(320, 150)
    renderer.camera.scale = 1.0
    renderer.fullscreen_shader = load_shader("res/shader/fullscreen_intro")

    this.sky0 = create_sprite("res/clip3/sky0.png")
    this.sky1 = create_sprite("res/clip3/sky1.png")
    this.sky2 = create_sprite("res/clip3/sky2.png")
    
    this.sun = create_sprite("res/clip3/sun.png")
    this.eldritch = create_sprite("res/clip3/smallboi.png")
    this.big = create_sprite("res/clip3/bigboi.png")
    
    this.backdrop0 = create_sprite("res/clip3/backdrop0.png")
    this.backdrop1 = create_sprite("res/clip3/backdrop1.png")
    this.backdrop2 = create_sprite("res/clip3/backdrop2.png")
    this.backdrop3 = create_sprite("res/clip3/backdrop3.png")

    this.text.add(create_sprite("res/clip3/text0.png"))
    this.text.add(create_sprite("res/clip3/text1.png"))
    this.text.add(create_sprite("res/clip3/text2.png"))
    this.text.add(create_sprite("res/clip3/text3.png"))
    this.text_times.add(10.0)
    this.text_times.add(8.0)
    this.text_times.add(6.0)
    this.text_times.add(20.0)
    this.text_prg = -1
    this.text_time = 0.0

    this.music = load_sound("res/clip1/music.mp3")

    discard play_sound(this.music)

method update(this: CutScene3) =
    this.time += dt
    this.text_time -= dt
    this.cur_time -= dt
    
    renderer.camera.center = vec2f(320, 192)
    
    this.eldritch.position = vec2f(
        (sin(this.time * 0.3) + 1.0) * 5.0,
        (cos(this.time * 0.4) + 0.5) * 10.0
    )

    this.sun.position = vec2f(
        0.0,
        max(200.0 - 200.0 * (this.time / 40.0), 0.0)
    )

    if this.time > 20.0:
        this.backdrop3.tint = vec4f(1.0, 1.0, 1.0, (this.time - 20.0) * 0.2)
        this.big.position = vec2f(0.0, max(200.0 - (this.time - 20.0) * 50.0, 0.0))

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



method render(this: CutScene3) = 
    if this.time < 5.0:
        renderer.draw(this.sky0)
    elif this.time < 10.0:
        renderer.draw(this.sky1)
    else:
        renderer.draw(this.sky2)
    
    renderer.draw(this.sun)
    if this.time > 20.0:
        renderer.draw(this.big)
    
    renderer.draw(this.eldritch)
    
    if this.time < 5.0:
        renderer.draw(this.backdrop0)
    elif this.time < 10.0:
        renderer.draw(this.backdrop1)
    elif this.time < 20.0:
        renderer.draw(this.backdrop2)
    else:
        renderer.draw(this.backdrop2)
        renderer.draw(this.backdrop3)

    for text in this.text:
        renderer.draw(text)