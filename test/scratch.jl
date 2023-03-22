using Revise
using PMxSim

 mdl_basic = @model function test(du, u, params, t; a = 4)
    @mrparam begin
        # if a<4
        #     p = 2
        # else
        #     p = 3
        # end
        p = 2
        p = 3
    end

    @mrparam z = 3
    @mrparam begin
        
        q = 3
    end
end;
mdl_basic.parameters


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