# the control of the player is taken as long as he is near and presses E
include ../../engine/base
import nimgl/glfw
import ../userdata

type Platform* = ref object
    sprite*: Sprit
    lights*: Sprite
    lights_cabin*: Sprite
    
    phys_body*: Body
    phys_shape*: Shape
    phys_space: Space

    in_control*: bool


proc make_platform(p0: Vect, p1: Vect, space: Space): Platform = 
    result = new(Platform)