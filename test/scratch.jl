using Revise
using PMxSim


PMxSim.model_warnings = true
mdl_basic = @model function test(du, u, params, t)#; a = 4, b =3)
    @init begin
        a = 8
        if a>=4
            p = 2
            p = 3
        end
        q = 8
        j = 1
        k = 2
        fooey =9
        @parameter begin 
            if a > 2
                p = 2*a
                h = 2
            else
                p = -99
                h = 1000
            end
            if q < 3
                h = 2
            else
                h = 10000
            end
            p = 99999
            p = 232
        
            z = 9
            q = 3
        end

        @parameter begin
            if q ==2
                peanut = 7
                fooeybar = 2
            else
                peanut = 111
                fooeybar = 2
            end
            peanut = 999
        end

        k = 0
        @IC begin
            if k < 2
                x = 2
                y = 4
                x = 2
            else
                x = 9
                y = 3
            end
        end
        @IC peanut = -123
        @repeated foo = 2
        z = -99
    end
    l = 2
    j = 3
    @ddt begin
        y = 2
        z = 2
    end
    x = 8.2
end;

foo = mdl_basic.model.initFcn()
mdl_basic.parameters
mdl_basic.states


test2 = @model function test2(du, u, p, t)
    @init begin
        @parameter a = 9
        a = 3
    end

end;

test2()