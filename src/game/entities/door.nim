include ../../engine/base

import player
import glm
import math

import ../userdata
# Doors are positioned using their bottom left corner
type Door* = ref object 
    open_wav: WavHandle
    sprite*: AnimatedSprite
    sound: WavHandle
    requires_key: bool
    

proc create_door*(pos: Vec2f): Door =
    result = new(Door)
    result.sprite = create_animated_sprite("res/barrier/door.yaml")
    result.open_wav = load_sound("res/barrier/exit.mp3")
    result.requires_key = false
    result.sprite.position = vec2f(pos.x, pos.y - result.sprite.sprite.texture_height.toFloat)

proc update*(this: Door, player: Player): bool =
    let diff = player.sprite.center_position - this.sprite.center_position
    let dist = length(diff)

    if dist < 50.0:

        return true
    return false

proc draw*(this: Door) =
    renderer.draw(this.sprite)