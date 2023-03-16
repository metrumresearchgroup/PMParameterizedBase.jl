using PMxSim
using ComponentArrays

mdl_basic = @model function test(du, u, params, t)
    @mrparam p = 2
    @mrstate x = 9
    p
    @ddt x = 0.0
end;

mdl_outofplace = @model function oop(u, params, t)
    @mrparam p = 2
    @mrstate x = 9
    @ddt x = 0.0
end;


mdl_differentorder = @model function (du, u, params, t; k =2)
    @mrparam p = 2
    @mrstate x = 9
    @mrparam z = 3
    @mrstate begin
        a = 1
        b = 2
        c = 3
    end
    @ddt a = 0.0
    @ddt b = 0.0
    @ddt c = 0.0
    @mrparam begin 
        i = 1
        j = 2
        k = 3
    end
    @mrstate u = -9
    @ddt u = 0.0
    @ddt x = 0.0
    @mrparam w = 2
end;



mdl_kws_iip = @model function test(du, u, p, t; k=2, foo=-99)
    @mrparam begin
       q = 2
       x = 6
    end
     k = 3+q

    @mrstate begin
       g = -99/k
       y = 2
       h = q * 2.3 + x
    end

    @ddt g = -2 * y
    @ddt y = 0.0
    @ddt h = 0.0
end;

mdl_kws_oop = @model function test(u, p, t; k, foo=-99)
    @mrparam begin
       q = 2
       x = 6
    end
     k = 3+q

    @mrstate begin
       g = -99/k
       y = 2
       h = q * 2.3 + x
    end

    @ddt g = -2 * y
    @ddt y = 0.0
    @ddt h = 0.0
end;


function test_iip_oop()
    mdl = @macroexpand  @model function test(du, u, p, t, q; k=2, foo=-99)
        @mrparam begin
        q = 2
        x = 6
        end
        k = 3+q

        @mrstate begin
        g = -99/k
        y = 2
        h = q * 2.3 + x
        end

        @ddt g = -2 * y
        @ddt y = 0.0
        @ddt h = 0.0
    end;
end
