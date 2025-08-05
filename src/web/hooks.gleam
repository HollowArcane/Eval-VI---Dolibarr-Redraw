import redraw
import toolkit_util/resource

pub fn use_init_effect(effect, dependencies)
{
    redraw.use_effect(fn() {
        use <- resource.defer(Nil)
        effect()
    }, dependencies)
}