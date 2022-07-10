type
    BodyKind* = enum
        bkTerrain,
        bkPlayer,
        bkEnemy,
        bkObject

    UserData* = ref object
        kind*: BodyKind 
        point*: int

proc make_terrain_userdata*(): UserData =
    result = new(UserData)
    result.kind = bkPlayer
    result.point = 0

proc make_player_userdata*(): UserData =
    result = new(UserData)
    result.kind = bkPlayer
    result.point = 0

proc make_enemy_userdata*(enemy: int): UserData =
    result = new(UserData)
    result.kind = bkEnemy
    result.point = enemy

proc make_object_userdata*(obj: int): UserData =
    result = new(UserData)
    result.kind = bkObject
    result.point = obj