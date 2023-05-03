using Revise
using ParameterizedModels
using Unitful

function fooey(x)
    sum(x)
end


mdl =  @model function test(du, u, p, t)
    @init begin
        aa = 2
        @parameter pp = 0.0*fooey([1,2,3])
        @parameter a = 2*aa
        @parameter b = 3*a
        @parameter c = 4
        @IC begin
            x = a
            y = 0.0
            z = 0.0
        end
    end


    k1 = a * 2#*fooey([1,2,3])
    k2 = b * 3
    
    @ddt x = -k1 * x
    @ddt y = -k2 * y
    @ddt z = 0.0

end;



mdl2 = @model function test2(du, u, p, t)
    @init begin
        @IC x = 1.0
        @IC y = 0.0
        @IC z = 0.0
        @parameter k = 1.0
    end
    rhs1 = 10.0*k

    @ddt x = rhs1 * (y - x)
    @ddt y = x * (28.0 - u[3]) - y
    @ddt z  = x * y - (8 / 3) * z
    end