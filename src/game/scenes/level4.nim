include ../../engine/base
import ../../engine/map/map_loader
import ../../engine/graphics/sprite
import ../entities/player
import ../entities/enemy
import ../entities/platform
import ../entities/physical_object
import ../../engine/base/renderer as rnd
import level

type Level4Scene* = ref object of Scene
    music: WavHandle
    musich: AudioHandle
    final: WavHandle
    finalh: AudioHandle
    roar1: WavHandle
    roar2: WavHandle
    level: Level
    open: bool
    event_timer: float
    roared: bool
    roared2: bool
    roared3: bool

method init(this: Level4Scene) =
    this.music = load_sound("res/level4/music.mp3")
    this.final = load_sound("res/final/finalboss.mp3")
    this.roar1 = load_sound("res/final/roar1.mp3")
    this.roar2 = load_sound("res/final/roar2.mp3")
    this.finalh = this.final.create_sound(true)
    this.musich = play_sound(this.music, true)
    this.level.init("res/level4/map.yaml", "res/level4/backdrop.png", "none", 20)
    
    this.level.platforms.add(create_platform(
        v(60.0 * 20.0 + 30.0, 86.0 * 20.0),
        v(173 * 20.0, 31.0 * 20.0),
        vec2f(55.0 * 20.0, 86.0 * 20.0),
        vec2f(176 * 20.0, 31.0 * 20.0),
        this.level.physics_space
    ))
    this.level.platforms[0].speed = 60.0
    this.event_timer = -1.0


method update(this: Level4Scene) =
    if this.level.reinit:
        for enemy in this.level.enemies:
            if enemy.kind == ekRockmanSpawner:
                enemy.sprite.scale = vec2f(-1.0, 1.0)
                enemy.spawn_timer_def = 7.0
        this.event_timer = -1.0
        this.musich.set_volume(0.8)
        this.finalh.pause()
        this.roared = false
        this.roared2 = false
        this.roared3 = false

    if this.level.update():
        this.musich.pause()
        goto_scene(Level4Scene())

    var op = true
    for button in this.level.buttons_idx:
        if button > 0:
            op = op and this.level.physical_objects[button].active
    
    if op:
        this.level.barriers[0].health = 0.0

    if this.event_timer >= 0.0:
        this.event_timer += dt
        this.musich.set_volume(max(1.0 - this.event_timer, 0.0))
        this.finalh.set_volume(min(this.event_timer, 1.0))
        this.finalh.resume()

        if this.event_timer >= 4.0 and not this.roared:
            discard this.roar1.play_sound(false)
            this.roared = true

        if this.event_timer >= 12.0 and not this.roared2:
            discard this.roar1.play_sound(false)
            this.roared2 = true
        
        if this.event_timer >= 16.0 and not this.roared3:
            discard this.roar2.play_sound(false)
            this.roared3 = true
    else:
        if this.level.player.sprite.position.x > 90.0 * 20.0:
            this.event_timer = 0.0
    

method render(this: Level4Scene) = 
    this.level.draw()