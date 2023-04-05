using Revise
using PMxSim


function fooey(x)
    sum(x)
end


mdl = @model function test(du, u, p, t)
    @init begin
        aa = 2
        @parameter pp = fooey([1,2,3])
        @parameter a = 2*aa
        @parameter b = 3*a
        @parameter c = 4

        # @IC begin
            # x = 0.0
            # y = 0.0
            # z = 0.0
        # end
    end


    k1 = a * 2*fooey([1,2,3])
    k2 = b * 3
    
    # @ddt x = -k1 * x
    # @ddt y = -k2 * y
    # @ddt z = 0.0

end;


mdl.f(similar(mdl.states), mdl.states, mdl.parameters,0.0)