import base/renderer as rnd
import nimgl/[glfw, opengl]

var should_quit* = false
var renderer*: Renderer = nil
var dt*: float32
var glfw_window*: GLFWWindow 

var update_fnc*: proc() = nil
var render_fnc*: proc() = nil
var quit_fnc*: proc() = nil