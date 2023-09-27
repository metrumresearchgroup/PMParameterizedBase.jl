macro create_class2(classname, fields_tuple)
    fields = fields_tuple.args
    quote
        mutable struct $classname
            $(fields...)
            function $classname($(fields...))
                new($(fields...))
            end
        end
    end
end


function poopeyhead()
    @create_class2 poop (bar, baz)
    out = poop(1,2)
end