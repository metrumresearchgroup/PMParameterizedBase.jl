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
            p = 2*a
            z = 9
            q = 3
        end

        @variable begin
            x = 2
            y = 4
        end
        
    end
    l = 2
    j = 3
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