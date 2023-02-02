using PMxSim
using ComponentArrays

mdl_basic = @model function test(du, u, params, t)
    @mrparam p = 2
    @mrstate x = 9
    p
end;

mdl_outofplace = @model function oop(u, params, t)
    @mrparam p = 2
    @mrstate x = 9
end;


mdl_differentorder = @model function (du, u, params, t)
    @mrparam p = 2
    @mrstate x = 9
    @mrparam z = 3
    @mrstate begin
        a = 1
        b = 2
        c = 3
    end
    @mrparam begin 
        i = 1
        j = 2
        k = 3
    end
    @mrstate u = -9
    @mrparam w = 2
end



