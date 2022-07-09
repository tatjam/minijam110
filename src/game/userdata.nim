type
    BodyKind* = enum
        bkTerrain,
        bkPlayer,
        bkEnemy,
        bkObject

    UserData* = ref object
        kind*: BodyKind 
        point*: pointer

proc make_terrain_userdata*(): UserData =
    result = new(UserData)
    result.kind = bkPlayer
    result.point = nil

proc make_player_userdata*(player: pointer): UserData =
    result = new(UserData)
    result.kind = bkPlayer
    result.point = player

proc make_enemy_userdata*(enemy: pointer): UserData =
    result = new(UserData)
    result.kind = bkEnemy
    result.point = enemy

proc make_object_userdata*(obj: pointer): UserData =
    result = new(UserData)
    result.kind = bkObject
    result.point = obj