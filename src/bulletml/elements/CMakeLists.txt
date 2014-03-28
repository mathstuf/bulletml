set(elements_srcs
    _all.d
    _element.d
    _expression.d
    _types.d

    accel.d
    action.d
    actionref.d
    bullet.d
    bulletml.d
    bulletref.d
    changedirection.d
    changespeed.d
    direction.d
    fire.d
    fireref.d
    horizontal.d
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
