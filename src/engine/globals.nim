import base/renderer as rnd

var should_quit* = false
var renderer*: Renderer = nil
var dt*: float32

var update_fnc*: proc() = nil
var render_fnc*: proc() = nil
var quit_fnc*: proc() = nil