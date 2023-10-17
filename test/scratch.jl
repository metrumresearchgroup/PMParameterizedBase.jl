using Revise
using PMxSim

mdl_basic =  @model function test(du, u, params, t)
    @init begin
        porter = 7
        a = 8
        if a>=4
            p = 2
            p = 3
        end
        q = 8
        j = 1
        k = 2
        fooey = 9

        @parameter begin 
                # porter
                p = 2*a
                h = 2
                p = -99
                h = 1000
                h = 2
                h = 10000
            p = 99999
            p = 232
        
            z = 9
            q = 3
        end
        # @repeated z

        @parameter begin
                peanut = 7
                fooeybar = 2
                peanut = 111
                fooeybar = 2
            end
            peanut = 999

        k = 0
        @IC begin
                x = 2
                y = 4
                x = 2
                x = 9
                y = 3
        end
        @IC peanut = -123
        @repeated fooey = 2
        z = -99
        # @repeated porter

    end
    l = 2
    j = 3
    @ddt begin
        y = 2
        z = 2
    end
    x = 8.2
    println(p)
end;

mdl_basic()

mdl_basic2 =  @model function test(du, u, params, t)
    @init begin
        porter = 7
        a = 8
        if a>=4
            # p = 2
            # p = 3
        end
        q = 8
        j = 1
        k = 2
        fooey = 9

        @parameter begin 
                # porter
                p = 2*a
                h = 2
        
            # z = 9
            # q = 3
        end

        @parameter begin
                fooeybar = 2
                peanut = 111
            end
            # peanut = 999

        k = 0
        @IC begin
                x = 2
                y = 4
                z = 2

        end
        # @repeated fooey = 2
        # z = -99
        # @repeated porter

    end
    l = 2
    # @observed j[1:10] = 3
    @ddt begin
        y = 2
        z = 2
        x = 0
    end
    h = 8
    println(p)
end;