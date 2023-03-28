using Revise
using PMxSim

 mdl_basic = @model function test(du, u, params, t; a = 4)
    @init begin
        # if a<4
        #     p = 2
        # else
        #     p = 3
        # end
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
        end

        @variable begin
            if k <= 2
            x = 2
            y = 4
            else
                x = 9
                y = 3
            end
        end
        peanut = -123
        @dynamic foo = 2
    end
    l = 2
    j = 3
    @ddt begin
        y = 2
        z = 2
    end
    x = 8.2
end;
mdl_basic
mdl_basic.parameters()
mdl_basic.states()



function baz(a,b,c)
    d = 9
    e = 10
    f = 11
    function bar(a,b,c)
        return b + d + e
    end
    return bar
end