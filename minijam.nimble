# Package

version     = "0.1.0"
author      = "Tatjam"
description = "A game for minijam"
license     = "MIT"

# Deps

requires "nim >= 1.6.4"
requires "nimgl"
requires "stb_image"
requires "glm"
requires "https://github.com/zacharycarter/soloud-nim"
requires "yaml"
requires "polymorph"

# Executable
bin = @["src/main"]
