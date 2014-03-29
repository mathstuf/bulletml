set(elements_srcs
    _element.d

    accel.d
    action.d
    bullet.d
    bulletml.d
    changedirection.d
    changespeed.d
    direction.d
    fire.d
    horizontal.d
    oref.d
    param.d
    repeat.d
    speed.d
    term.d
    times.d
    vanish.d
    vertical.d
    wait.d)

add_library(bulletml_elements STATIC
    ${elements_srcs})
