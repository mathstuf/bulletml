set(elements_srcs
    elements/_all.d

    elements/accel.d
    elements/action.d
    elements/actionref.d
    elements/bullet.d
    elements/bulletref.d
    elements/changedirection.d
    elements/changespeed.d
    elements/direction.d
    elements/fire.d
    elements/fireref.d
    elements/horizontal.d
    elements/param.d
    elements/repeat.d
    elements/speed.d
    elements/term.d
    elements/times.d
    elements/vanish.d
    elements/vertical.d
    elements/wait.d)

set(bulletml_srcs
    ${elements_srcs}
    )

add_library(bulletml
    ${bulletml_srcs})
