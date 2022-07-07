import nimgl/opengl
import glm

type Shader* = distinct GLuint

proc toString(str: openArray[char]): string =
    result = newStringOfCap(len(str))
    for ch in str:
        if ch != '\0': add(result, ch)


proc get_errors(sh: GLuint, for_program: bool): string =
    var success: GLint
    var infolog: array[1024, char]
    if for_program:
        glGetProgramiv(sh, GL_LINK_STATUS, addr success)
        if success == 0:
            glGetShaderInfoLog(sh, 1024, nil, addr infolog[0])
    else:
        glGetShaderiv(sh, GL_COMPILE_STATUS, addr success)
        if success == 0:
            glGetShaderInfoLog(sh, 1024, nil, addr infolog[0])

    # "Safe" as we have zero padding by OpenGL
    if success == 1: result = "OK" else: result = toString(infolog)

# Pass the path without .vs or .fs
proc load_shader*(path: string): Shader =
    let vshader = readFile(path & ".vs").cstring
    let fshader = readFile(path & ".fs").cstring

    var vert, frag: GLuint
    vert = glCreateShader(GL_VERTEX_SHADER)
    glShaderSource(vert, 1.GLsizei, unsafeAddr vshader, nil)
    glCompileShader(vert)
    var msg = get_errors(vert, false)
    echo "Compile vertex " & path & ".vs: " & msg

    frag = glCreateShader(GL_FRAGMENT_SHADER)
    glShaderSource(frag, 1.GLsizei, unsafeAddr fshader, nil)
    glCompileShader(frag)
    msg = get_errors(frag, false)
    echo "Compile fragment " & path & ".fs: " & msg

    let sh = glCreateProgram()
    glAttachShader(sh, vert)
    glAttachShader(sh, frag)
    glLinkProgram(sh)
    msg = get_errors(frag, false)
    echo "Link shader " & path & ": " & msg

    glDeleteShader(vert)
    glDeleteShader(frag)

    return cast[Shader](sh)

proc gl(shader: Shader) : GLuint =
    return cast[Gluint](shader)

proc use*(shader: Shader) =
    glUseProgram(shader.gl)

proc set_mat4*(shader: Shader, name: cstring, mat: var Mat4f) =
    glUniformMatrix4fv(glGetUniformLocation(shader.gl, name), 1.GLsizei, false, mat.caddr)