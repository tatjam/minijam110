# A simple 2D (fullscreen always) camera and transformation functions

import glm

type Camera* = ref object
    center: Vec2f
    # Scale is pixels / unit, rotation in radians
    scale, rotation: float

proc create_camera*(): Camera =
    return Camera(center: vec2f(0, 0), scale: 1.0, rotation: 0.0)

# Obtains a transform matrix such that the world is rendered
proc get_transform_matrix*(cam: Camera): Mat4f =
    result = result.translate(vec3f(cam.center, 0.0))
        .rotate(cam.rotation, 0, 0, 1)
        .scale(cam.scale, cam.scale, cam.scale)