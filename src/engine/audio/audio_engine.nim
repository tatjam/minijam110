# Very simple wrapper for the soloud engine so its more nim-like

import solouddotnim

var soloud : ptr Soloud

type AudioHandle* = distinct int
type WavHandle* = object
    wave: ptr Wav

proc `=destroy`(x: var WavHandle) =
    if x.wave != nil:
        echo "Destroying sound " & repr x.wave
        Wav_destroy(x.wave)



proc init_soloud*() =
    soloud = Soloud_create()
    discard Soloud_init(soloud)

proc deinit_soloud*() =
    Soloud_deinit(soloud)
    Soloud_destroy(soloud)

proc load_sound*(path: cstring): WavHandle =
    var wave = Wav_create()
    discard Wav_load(wave, path)
    return WavHandle(wave: wave)

proc play_sound*(sound: WavHandle, loop: bool = false): AudioHandle = 
    let handle = Soloud_play(soloud, sound.wave)
    Soloud_setLooping(soloud, handle, loop.int32)
    return cast[AudioHandle](handle)

proc pause*(sound: AudioHandle) =
    Soloud_setPause(soloud, cast[cuint](sound), 1)

proc resume*(sound: AudioHandle) =
    Soloud_setPause(soloud, cast[cuint](sound), 0)

proc set_volume*(sound: AudioHandle, vol: float) = 
    let clipvol = max(min(vol, 1.0), 0.0)
    Soloud_setVolume(soloud, cast[cuint](sound), clipvol)

proc create_sound*(sound: WavHandle, loop: bool = false): AudioHandle = 
    let handle = play_sound(sound, loop)
    handle.pause()
    return handle