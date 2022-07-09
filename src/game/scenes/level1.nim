include ../../engine/base
import ../../engine/map/map_loader
import ../../engine/graphics/sprite
import ../entities/player

type Level1Scene* = ref object of Scene
    music: WavHandle
    map: Map
    physics_space: Space
    player_ent: EntityID

method init(this: var Level1Scene) =
    echo "Init!"
    this.music = load_sound("res/level1/music.mp3")
    #discard play_sound(this.music, true)
    
    this.physics_space = newSpace()
    this.map = load_map("res/level1/map.yaml", 8, this.physics_space)
    renderer.camera.scale = 1.0
    renderer.camera.center = vec2f(27 * 8.0, 21 * 8.0)

    this.player_ent = create_entity(PlayerEntity())

method update(this: var Level1Scene) = 
    base_update()

    
method render(this: var Level1Scene) = 
    base_render()

    this.map.drawer.draw_tiles()