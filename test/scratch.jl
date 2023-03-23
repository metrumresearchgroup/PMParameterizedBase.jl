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
            p = 2
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
mdl_basic.parameters
mdl_basic.model.Cfcn(0,0,0,0;a=4)

testfun = :(function foo(du, u, params, t; a, b)
a + 9
end)
# @capture(testfun, function f_(args__) body_ end )
@capture(testfun, (f_(args__) = body_) | (function f_(args__) body_ end) | (function (args__) body_ end))



testmac = :(@mrparam begin
    a = 2
    b = 3
end)

testmac2 = :(@mrparam j = 0)
@capture(testmac2, @mrparam body_)