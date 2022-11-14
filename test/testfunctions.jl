using PMxSim
using ComponentArrays

mdl_basic = @model function test(du, u, params, t)
    @mrparam p = 2
end;
