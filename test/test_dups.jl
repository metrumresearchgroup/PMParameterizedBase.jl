using PMxSim
using Test
using Logging

@testset "Check duplication detection" begin
    function getmd1()
        mdl = @macroexpand @model function test(du, u, params, t)
            @mrparam k = 2
            @mrparam k = 9
        end;
        return mdl
    end

    @test_throws ErrorException("Parameter(s) k defined multiple times") getmd1()

    function getmd2()
        mdl = @macroexpand @model function test(du, u, params, t)
            @mrparam p = 2
            @mrstate x = 9
            @mrstate x = 0
            @ddt x = 0.0
        end
        return mdl
    end
    @test_throws ErrorException("State(s) x defined multiple times") getmd2()

    function getmd3()
        mdl = @macroexpand @model function test(du, u, params, t)
            @mrparam p = 2
            @mrparam x = -99
            @mrstate x = 9
            @mrstate p = 0
            @ddt x = 0.0
        end;
    end

    @test_throws ErrorException("There are both parameters and states named p and x") getmd3()

    function getmd4()
        mdl = @macroexpand @model function test(du, u, params, t)
            @mrparam p = 2
            @constant p = 2
            @mrstate x = 9
            @ddt x = 0.0
        end;
        return mdl
    end;
    @test_logs (:warn, "Parameter(s) p over-written by constants") getmd4()


    function getmd5()
        mdl = @macroexpand @model function test(du, u, params, t)
            @mrparam p = 2
            @constant x = 2
            @mrstate x = 9
            @ddt x = 0.0
        end;
        return mdl
    end;
    @test_throws ErrorException("There are both states and constants named x") getmd5()
end
