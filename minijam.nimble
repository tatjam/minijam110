# Package

version     = "0.1.0"
author      = "Tatjam"
description = "A game for minijam"
license     = "MIT"

# Deps

requires "nim >= 1.6.4"
requires "nimgl"
requires "https://github.com/oprypin/nim-chipmunk"
requires "stb_image"
requires "parasound"
requires "glm"

# Executable
bin = @["src/main"]
