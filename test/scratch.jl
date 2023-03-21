using Revise
using PMxSim

 mdl_basic = @model function test(du, u, params, t)
    @mrparam begin
        p = 2
        b = 3
    end
end;



foo = :(if u == 0
    #= /Users/knabt/.julia/dev/PMxSim/test/scratch.jl:6 =#
    p = 2
else
    #= /Users/knabt/.julia/dev/PMxSim/test/scratch.jl:8 =#
    p = 3
end)

# MacroTools.postwalk(x -> (println(typeof(x)); println(x); @capture(x, a_ = b_)), foo)
bar = MacroTools.postwalk(x -> ((isexpr(x) && @capture(x, a_ = b_)) ? push!(list, x) : x), foo)


function get_ex_symbols2(ex)
    list = []
    walk!(list) = ex -> begin
       println(ex)
       ex isa Symbol && push!(list, ex)
       ex isa Expr && ex.head == :(=) && map(walk!(list), ex.args)
       list
    end
    Set{Symbol}(walk!([])(ex))
end