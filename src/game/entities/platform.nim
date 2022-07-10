# the control of the player is taken as long as he is near and presses E
include ../../engine/base
import nimgl/glfw
import player
import ../userdata
import options

type Platform* = ref object
    sprite*: Sprite
    lights*: Sprite
    lights_cabin*: Sprite
    line: Line
    
    phys_body*: Body
    phys_shape*: Shape
    track_body*: Body
    track_shape*: Shape
    spring*: Constraint
    speed: float

    progress: float
    p0: Vect
    p1: Vect

    phys_space: Space

    in_control*: bool
    just_hopped: bool


proc create_platform*(p0: Vect, p1: Vect, lanchor0: Vec2f, lanchor1: Vec2f, space: Space): Platform = 
    result = new(Platform)
    result.sprite = create_sprite("res/platform/platform.png")
    result.lights = create_fx_sprite("res/platform/emit_base.png")
    result.lights_cabin = create_fx_sprite("res/platform/emit_cabin.png")

    result.sprite.scale_origin = vec2f(160.0 / result.sprite.texture_width.toFloat, 94.0 / result.sprite.texture_height.toFloat)
    result.lights.scale_origin = result.sprite.scale_origin
    result.lights_cabin.scale_origin = result.sprite.scale_origin
    
    # Create the tracker body
    let tracker_mass = 100.0
    let tracker_moment = momentForCircle(tracker_mass, 0.0, 10.0, vzero)
    result.track_body = space.addBody(newBody(tracker_mass, tracker_moment))
    result.track_body.bodyType = BODY_TYPE_KINEMATIC
    result.track_shape = space.addShape(newCircleShape(result.track_body, 10.0, vzero))

    # Create the platform body
    let platform_mass = 800.0
    let platform_moment = momentForBox(platform_mass, 118.0, 137.0)
    result.phys_body = space.addBody(newBody(platform_mass, platform_moment))
    result.phys_shape = space.addShape(newBoxShape(result.phys_body, 118.0, 137.0, 0.0))

    # Constraint them
    let spring = newDampedSpring(result.track_body, result.phys_body,
        vzero, v(0.0, -126.0 / 2.0), 0.0, 15000.0, 5000.0) 
    spring.collideBodies = false
    result.spring = space.addConstraint(cast[Constraint](spring))
    
    result.phys_body.position = v(p0.x, p0.y + 126.0 / 2.0)
    result.track_body.position = p0

    result.p0 = p0
    result.p1 = p1

    result.speed = 50.0 / vdist(result.p0, result.p1)

    var points: seq[Vec2f]
    points.add(lanchor0)
    points.add(vec2f(p0.x, p0.y))
    points.add(vec2f(p1.x, p1.y))
    points.add(lanchor1)
    result.line = create_line(points, 1.0)
    result.line.color = vec4f(0.4, 0.4, 0.4, 1.0)


proc update*(this: var Platform, player: Player, control_platform: Option[Platform]) =

    let interp_pos = v(
        this.p0.x * (1.0 - this.progress) + this.p1.x * this.progress, 
        this.p0.y * (1.0 - this.progress) + this.p1.y * this.progress)
    this.track_body.position = interp_pos
    
    this.sprite.center_position = vec2f(this.phys_body.position.x, this.phys_body.position.y + 65.0)
    this.lights.center_position = this.sprite.center_position
    this.lights.rotation = this.sprite.rotation
    this.lights_cabin.center_position = this.sprite.center_position
    this.lights_cabin.rotation = this.sprite.rotation
    this.sprite.rotation = this.phys_body.angle

    if glfw_window.getKey(GLFWKey.E) == GLFW_RELEASE:
        this.just_hopped = false

    if control_platform.isNone:
        if glfw_window.getKey(GLFWKey.E) == GLFW_PRESS and not this.just_hopped:
            let dist = vdist(player.phys_body.position, this.phys_body.position)
            if dist < 130.0:
                this.in_control = true
                this.just_hopped = true
    elif control_platform.get == this:
        # We may control the platform or leave
        renderer.camera.center = vec2f(this.phys_body.position.x, this.phys_body.position.y)
        # Set the player physics off-world, but move its sprite
        let pos = this.sprite.center_position
        player.sprite.center_position = vec2f(pos.x, pos.y - 60.0)
        player.lantern.center_position = vec2f(pos.x, pos.y - 60.0)
        player.phys_body.position = v(-100.0, -100.0)
        player.fall_sound.pause()
        player.step_sound.pause()
        if glfw_window.getKey(GLFWKey.A) == GLFW_PRESS:
            this.progress -= dt * this.speed
        elif glfw_window.getKey(GLFWKey.D) == GLFW_PRESS:
            this.progress += dt * this.speed
        
        # Stop controlling
        if glfw_window.getKey(GLFWKey.E) == GLFW_PRESS and not this.just_hopped:
            this.in_control = false
            # throw the player
            var exit_pos = this.phys_body.position
            if this.progress > 0.5:
                exit_pos.x += 130.0
            else:
                exit_pos.x -= 130.0
            exit_pos.y -= 50.0
            player.phys_body.position = exit_pos
            player.phys_body.velocity = vzero
            this.just_hopped = true

        this.progress = max(min(this.progress, 1.0), 0.0)

proc draw*(this: Platform) =
    renderer.draw(this.line)
    renderer.draw(this.sprite)
    renderer.draw(this.lights)
    renderer.draw(this.lights_cabin)