include ../../engine/base
include ../../engine/map/map_loader

type Level1Scene* = ref object of Scene
    music: WavHandle

method init(this: Level1Scene) =
    this.music = load_sound("res/level1/music.mp3")
    load_map("res/level1/map.yaml")
    #discard play_sound(this.music, true)