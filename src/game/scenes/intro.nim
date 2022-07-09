include ../../engine/base
include level1


type IntroScene* = ref object of Scene
    stars: Sprite
    sky: Sprite
    sea_f1: Sprite
    sea_f2: Sprite
    sun: Sprite
    island: Sprite
    fore_deact: Sprite 
    fore_act: Sprite
    monk: Sprite
    music: WavHandle
    time: float
    frame: bool
    frame_timer: float

method init(this: IntroScene) =
    renderer.camera.center = vec2f(200, 150)
    this.stars = create_sprite("res/intro/stars.png")
    this.sky = create_sprite("res/intro/sky.png")
    this.sea_f1 = create_sprite("res/intro/sea_f1.png")
    this.sea_f2 = create_sprite("res/intro/sea_f2.png")
    this.sun = create_sprite("res/intro/sun.png")
    this.island = create_sprite("res/intro/island.png")
    this.fore_deact = create_sprite("res/intro/fore_deact.png")
    this.fore_act = create_sprite("res/intro/fore_act.png")
    this.monk = create_sprite("res/intro/monk.png")
    this.music = load_sound("res/intro/intro.mp3")
    discard play_sound(this.music)

method update(this: IntroScene) =
    this.time += dt
    this.frame_timer += dt
    if this.frame_timer > 0.5:
        this.frame = not this.frame
        this.frame_timer = 0.0

    this.sun.position.y += 3.0 * dt
    this.stars.tint.w = this.time / 20.0

    if this.time > 27:
        goto_scene(Level1Scene())

method render(this: IntroScene) = 
    renderer.draw(this.sky)
    renderer.draw(this.sun)
    if this.frame:
        renderer.draw(this.sea_f1)
    else:
        renderer.draw(this.sea_f2)

    renderer.draw(this.island)
    renderer.draw(this.stars)
    
    if this.time < 20.0:
        renderer.draw(this.fore_deact)
    else:
        renderer.draw(this.fore_act)

    renderer.draw(this.monk)