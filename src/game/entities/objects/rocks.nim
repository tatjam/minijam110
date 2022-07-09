proc create_rock*(pos: Vec2f, space: Space): PhysicalObject = 
    result = new(PhysicalObject)
    result.sprite = create_animated_sprite("res/objects/rock.yaml")
    let mass = 50.0
    let moment = momentForCircle(mass, 0.0, 58.0, vzero)

    result.phys_body = space.addBody(newBody(mass, moment))
    result.phys_shape = space.addShape(newCircleShape(result.phys_body, 58.0, vzero))
    result.user_data = make_enemy_userdata(addr result)
    result.phys_shape.userData = addr result.user_data
    result.phys_body.position = v(pos.x, pos.y)
    result.phys_shape.friction = 0.1

    result.kind = okRock

proc create_magmarock*(pos: Vec2f, space: Space): PhysicalObject = 
    result = new(PhysicalObject)
    result.sprite = create_animated_sprite("res/objects/magmarock.yaml")
    let mass = 60.0
    let moment = momentForCircle(mass, 0.0, 58.0, vzero)

    result.phys_body = space.addBody(newBody(mass, moment))
    result.phys_shape = space.addShape(newCircleShape(result.phys_body, 58.0, vzero))
    result.user_data = make_enemy_userdata(addr result)
    result.phys_shape.userData = addr result.user_data
    result.phys_body.position = v(pos.x, pos.y)
    result.phys_shape.friction = 0.1

    result.kind = okMagmaRock
