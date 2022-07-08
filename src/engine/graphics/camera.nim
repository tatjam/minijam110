# A simple 2D (fullscreen always) camera and transformation functions

import glm

type Camera* = ref object
    center*: Vec2f
    # Scale is pixels / unit, rotation in radians
    scale*, rotation*: float

proc create_camera*(): Camera =
    return Camera(center: vec2f(0, 0), scale: 1.0, rotation: 0.0)

# Obtains a transform matrix such that the world is rendered
proc get_transform_matrix*(cam: Camera, width: int, height: int): Mat4f =
    let center_scaled = 2.0'f32 * cam.center / vec2f(width.toFloat, height.toFloat)
    return mat4f().translate(vec3f(-center_scaled, 0.0))
        .rotate(cam.rotation, 0, 0, 1)
        .scale((2.0 * cam.scale) / width.toFloat, (2.0 * cam.scale) / height.toFloat, 1.0)