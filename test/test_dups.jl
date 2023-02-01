using PMxSim
using Test
using Logging

@testset "Check duplication detection" begin
    @test_logs (:warn, "Parameter(s) k defined multiple times, using last value") @macroexpand @model function test(du, u, params, t)
        @mrparam k = 2
        @mrparam k = 9
    end;

    @test_logs (:warn, "State(s) x defined multiple times, using last value for initial condition") @macroexpand @model function test(du, u, params, t)
        @mrparam p = 2
        @mrstate x = 9
        @mrstate x = 0
    end;

    @test_throws ErrorException @macroexpand @model function test(du, u, params, t)
            @mrparam p = 2
            @mrparam x = -99
            @mrstate x = 9
            @mrstate p = 0
        end;
end
