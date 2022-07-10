include ../../engine/base
import nimgl/glfw
import ../userdata


type Player* = ref object
    sprite*: AnimatedSprite
    lantern*: Sprite
    
    phys_body: Body
    phys_shape: Shape
    phys_space: Space

    last_jump: bool
    grounded: bool
    sliding: bool
    time_in_air: float
    our_data: UserData
    attack_timer: float
    played_attack: bool
    in_attack: bool
    in_toss: bool
    release_toss: bool

    step_wav: WavHandle
    fall_wav: WavHandle
    jump_wav: WavHandle
    land_wav: WavHandle
    miss_wav: WavHandle
    hit_wav: WavHandle
    attack_wav: WavHandle
    step_sound: AudioHandle
    fall_sound: AudioHandle


# This must be here to avoid circular dependency hell
import enemy
import physical_object


proc create_player*(pos: Vec2f, space: Space): Player = 
    result = new(Player)
    result.sprite = create_animated_sprite("res/player/player.yaml")
    result.lantern = create_fx_sprite("res/player/lantern_fx.png")

    let mass = 80.0
    let moment = momentForCircle(mass, 0, 25.0, vzero)

    result.phys_body = space.addBody(newBody(mass, moment))
    result.phys_shape = space.addShape(newCircleShape(result.phys_body, 25.0, vzero))
    result.our_data = make_player_userdata()
    result.phys_shape.userData = unsafeAddr result.our_data
    result.phys_shape.friction = 0.0
    result.phys_body.position = v(pos.x, pos.y)
    result.phys_space = space

    result.step_wav = load_sound("res/player/steps.mp3")
    result.jump_wav = load_sound("res/player/jump.mp3")
    result.fall_wav = load_sound("res/player/fall.mp3")
    result.land_wav = load_sound("res/player/land.mp3")
    result.hit_wav = load_sound("res/player/hit_connect.mp3")
    result.attack_wav = load_sound("res/player/attack.mp3")
    result.miss_wav = load_sound("res/player/hit.mp3")
    result.step_sound = create_sound(result.step_wav, true)
    result.fall_sound = create_sound(result.fall_wav, true)



proc ground_query_foot(sh: Shape, p: Vect, n: Vect, a: Float, data: pointer) {.cdecl.} = 
    if sh.userData == nil:
        cast[ptr bool](data)[] = true

    # There's this weird 38 user data that we must ignore
    if cast[int](sh.userData) > 100000:
        let udata = cast[ptr UserData](sh.userData)[]
        if udata.kind != bkPlayer:
            # We can stand on anything
            cast[ptr bool](data)[] = true

type ToHitData = object
    hit: bool
    enemies: seq[Enemy]

# Sends hit to enemies
proc query_hit(sh: Shape, p: Vect, n: Vect, a: Float, data: pointer) {.cdecl.} =
    # There's this weird 38 user data that we must ignore
    if cast[int](sh.userData) > 100000:
        let udata = cast[ptr UserData](sh.userData)[]
        if udata.kind == bkEnemy:
            let enemy_idx = udata.point
            var datac = cast[ptr ToHitData](data)
            datac[].hit = true
            hurt(datac[].enemies[enemy_idx], p)


proc hit(this: Player, enemies: seq[Enemy]): bool =
    let rays = this.phys_body.position + v(0.0, 0.0)
    var raye = this.phys_body.position + v(34.0, 23.0)
    if this.sprite.scale.x < 0.0:
        raye = this.phys_body.position + v(-34.0, 23.0)

    let filter = chipmunk.ShapeFilter(
        group:nil,
        categories: 0b1111,
        mask: 0b1111
    )
    var query_data: ToHitData
    query_data.enemies = enemies
    segmentQuery(this.phys_space, rays, raye, Float(4.0), filter, query_hit, addr query_data)

    return query_data.hit

proc toss(this: Player, enemies: seq[Enemy], objects: seq[PhysicalObject]) =
    discard

proc update*(this: var Player, enemies: seq[Enemy], objects: seq[PhysicalObject]) =
    # Ground check
    let rfootp = this.phys_body.position + v(34.0, 25.0)
    let lfootp = this.phys_body.position + v(-34.0, 25.0)
    let rfoots = this.phys_body.position + v(5.0, 25.0)
    let lfoots = this.phys_body.position + v(-5.0, 25.0)
    let filter = chipmunk.ShapeFilter(
        group:nil,
        categories: 0b1111,
        mask: 0b1111
    )

    # TODO: For wathever reason, foot are flipped
    var result = false
    segmentQuery(this.phys_space, rfoots, rfootp, Float(4.0), filter, ground_query_foot, addr result)
    var lfoot = result
    result = false
    segmentQuery(this.phys_space, lfoots, lfootp, Float(4.0), filter, ground_query_foot, addr result)
    var rfoot = result

    if rfoot and lfoot:
        this.grounded = true
        this.sliding = false
    elif rfoot or lfoot:
        this.sliding = true
        this.grounded = false
    else:
        this.grounded = false

    if this.grounded:
        if this.time_in_air > 0.5:
            discard this.land_wav.play_sound()
        this.time_in_air = 0.0
    else:
        this.time_in_air += dt

    # Movement
    if this.in_attack:
        this.attack_timer += dt
        this.sprite.start_anim("attack")
        this.step_sound.pause()
        if this.attack_timer > 0.3 and not this.played_attack:
            let connect = this.hit(enemies)
            if connect:
                discard this.hit_wav.play_sound()
            else:
                discard this.miss_wav.play_sound()
            this.played_attack = true
        if this.attack_timer > 0.8:
            this.in_attack = false
    elif this.in_toss:
        if glfw_window.getKey(GLFWKey.C) != GLFW_PRESS or this.attack_timer > 1.8:
            this.in_toss = false
            this.toss(enemies, objects)
        this.attack_timer += dt
        this.sprite.start_anim("toss")
        this.step_sound.pause()

    else:
        var lateral = false
        if glfw_window.getKey(GLFWKey.A) == GLFW_PRESS:
            this.phys_body.position = this.phys_body.position + v(-dt * 100.0, 0.0)
            this.sprite.scale = vec2f(-1.0, 1.0)
            lateral = true
        if glfw_window.getKey(GLFWKey.D) == GLFW_PRESS:
            this.phys_body.position = this.phys_body.position + v(dt * 100.0, 0.0)
            this.sprite.scale = vec2f(1.0, 1.0)
            lateral = true
        if glfw_window.getKey(GLFWKey.V) == GLFW_PRESS:
            this.attack_timer = 0.0
            this.in_attack = true
            this.played_attack = false
            discard this.attack_wav.play_sound()
        if glfw_window.getKey(GLFWKey.C) == GLFW_PRESS:
            if this.release_toss:
                this.attack_timer = 0.0
                this.in_toss = true
                this.played_attack = false
                this.release_toss = false
                discard this.attack_wav.play_sound()
        else:
            this.release_toss = true
        if glfw_window.getKey(GLFWKey.Space) == GLFW_PRESS:
            if not this.last_jump and this.grounded:
                this.phys_body.applyImpulseAtWorldPoint(v(0, -15000.0), v(0, 0))
                discard this.jump_wav.play_sound()
            this.last_jump = true
        else:
            this.last_jump = false

        if this.time_in_air > 0.5:
            this.sprite.start_anim("fall")
            this.step_sound.pause()
            this.fall_sound.resume()
            this.fall_sound.set_volume(this.time_in_air - 0.5)
        else:
            this.fall_sound.pause()
            if lateral:
                this.sprite.start_anim("walk")
                this.step_sound.resume()
            
            if not lateral:
                this.sprite.start_anim("idle")
                this.step_sound.pause()

    if not this.sliding:
        this.phys_body.velocity = v(0, this.phys_body.velocity.y)
    
    # Note that sprites are placed by their top-left corner, so:
    this.sprite.position = vec2f(this.phys_body.position.x - 19.0, this.phys_body.position.y - 50.0)
    let off = if this.sprite.scale.x > 0.0: 32.0 else: 7.0
    this.lantern.center_position = this.sprite.position + vec2f(off, 9.0)
    this.sprite.animate(dt)




proc draw*(this: var Player) = 
    renderer.draw(this.sprite)
    renderer.draw(this.lantern)
