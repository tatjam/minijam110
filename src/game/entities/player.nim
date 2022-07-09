import ../../engine/base/scene_manager

type PlayerEntity* = ref object of Entity

method update(this: PlayerEntity, scene: ptr Scene) =
    echo "Wow!"
