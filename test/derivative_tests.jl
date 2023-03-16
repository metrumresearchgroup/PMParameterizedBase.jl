using PMxSim

function deriv_test1()
mdl = @macroexpand @model function deriv_test1(du, u, p; t,q)
        @mrparam begin
            k1 = 1
            k2 = 3
            k3 = 9
        end

        @mrstate begin
            R1 = 0.0
            R2 = 0.0
        end

        @ddt R1 = k1 * R1 - k2 * R2;
    end
    return mdl
end

function deriv_test2()
    mdl = @macroexpand @model function deriv_test2(du, u, p, t)
        @mrparam begin
            k1 = 1
            k2 = 3
            k3 = 9
        end

        @mrstate begin
            R1 = 0.0
            R2 = 0.0
            R3 = 1.0
        end

        @ddt R1 = k1 * R1 - k2 * R2;
        @ddt R2 = -k2 * R2;
    end
    return mdl
end