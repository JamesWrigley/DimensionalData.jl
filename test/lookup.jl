using DimensionalData, Test, Unitful
using Dates
using DimensionalData.Lookups, DimensionalData.Dimensions
using DimensionalData.Lookups: _slicespan, isrev, _bounds
using DimensionalData.Dimensions: _slicedims

@testset "locus" begin
    @test locus(NoSampling()) == Center()
    @test locus(NoLookup()) == Center()
    @test locus(Categorical()) == Center()
    @test locus(Sampled(; sampling=Points())) == Center()
    @test locus(Sampled(; sampling=Intervals(Center()))) == Center()
    @test locus(Sampled(; sampling=Intervals(Start()))) == Start()
    @test locus(Sampled(; sampling=Intervals(End()))) == End()
end

@testset "equality" begin
    ind = 10:14
    n = NoLookup(ind)
    c = Categorical(ind; order=ForwardOrdered())
    cr = Categorical(reverse(ind); order=ReverseOrdered())
    s = Sampled(ind; order=ForwardOrdered(), sampling=Points(), span=Regular(1))
    si = Sampled(ind; order=ForwardOrdered(), sampling=Intervals(), span=Regular(1))
    sir = Sampled(ind; order=ForwardOrdered(), sampling=Intervals(), span=Irregular())
    sr = Sampled(reverse(ind); order=ReverseOrdered(), sampling=Points(), span=Regular(1))
    @test n == n
    @test c == c
    @test s == s
    @test n != s
    @test n != c
    @test c != s
    @test sr != s
    @test si != s
    @test sir != s
    @test cr != c
end

@testset "isrev" begin
    @test isrev(ForwardOrdered()) == false
    @test isrev(ReverseOrdered()) == true
    @test isrev(Unordered()) == false
    @test_throws MethodError isrev(1)
end

@testset "reverse" begin
    @test reverse(ForwardOrdered()) == ReverseOrdered()
    @test reverse(ReverseOrdered()) == ForwardOrdered()
    @test reverse(Unordered()) == Unordered()
    lu = Sampled(order=ForwardOrdered(), span=Regular(1))
    @test order(reverse(lu)) == ReverseOrdered()
    lu = Categorical(order=ReverseOrdered())
    @test order(reverse(lu)) == ForwardOrdered()
end

@testset "getindex" begin
    ind = [10.0, 20.0, 30.0, 40.0, 50.0]

    @testset "Irregular forwards" begin
        m = Sampled(ind, order=ForwardOrdered(), span=Irregular((10.0, 60.0)), sampling=Intervals(Start()))
        mr = Sampled(ind, order=ForwardOrdered(), span=Regular(10.0), sampling=Intervals(Start()))
        @test bounds(getindex(m, 3:3)) == (30.0, 40.0)
        @test bounds(getindex(m, 1:5)) == (10.0, 60.0)
        @test bounds(getindex(m, 2:3)) == (20.0, 40.0)
        m = Sampled(ind, ForwardOrdered(), Irregular((0.0, 50.0)), Intervals(End()), NoMetadata())
        mr = Sampled(ind, ForwardOrdered(), Regular(10.0), Intervals(End()), NoMetadata())
        @test bounds(getindex(m, 3:3)) == (20.0, 30.0)
        @test bounds(getindex(m, 1:5)) == (0.0, 50.0)
        @test bounds(getindex(m, 2:3)) == (10.0, 30.0)
        m = Sampled(ind, ForwardOrdered(), Irregular((5.0, 55.0)), Intervals(Center()), NoMetadata())
        mr = Sampled(ind, ForwardOrdered(), Regular(10.0), Intervals(Center()), NoMetadata())
        @test bounds(getindex(m, 3:3)) == bounds(getindex(mr, 3:3)) == (25.0, 35.0)
        @test bounds(getindex(m, 1:5)) == bounds(getindex(mr, 1:5)) == (5.0, 55.0)
        @test bounds(getindex(m, 2:3)) == bounds(getindex(mr, 2:3)) == (15.0, 35.0)
    end

    @testset "Irregular reverse" begin
        revind = [50.0, 40.0, 30.0, 20.0, 10.0]
        m = Sampled(revind; order=ReverseOrdered(), span=Irregular(10.0, 60.0), sampling=Intervals(Start()))
        mr = Sampled(revind; order=ReverseOrdered(), span=Regular(-10.0), sampling=Intervals(Start()))
        @test bounds(getindex(m, 1:5)) == bounds(getindex(mr, 1:5)) == (10.0, 60.0)
        @test bounds(getindex(m, 1:2)) == bounds(getindex(mr, 1:2)) == (40.0, 60.0)
        @test bounds(getindex(m, 2:3)) == bounds(getindex(mr, 2:3)) == (30.0, 50.0)
        m = Sampled(revind, ReverseOrdered(), Irregular(0.0, 50.0), Intervals(End()), NoMetadata())
        mr = Sampled(revind, ReverseOrdered(), Regular(-10.0), Intervals(End()), NoMetadata())
        @test bounds(getindex(m, 1:5)) == bounds(getindex(mr, 1:5)) == (0.0, 50.0)
        @test bounds(getindex(m, 1:2)) == bounds(getindex(mr, 1:2)) == (30.0, 50.0)
        @test bounds(getindex(m, 2:3)) == bounds(getindex(mr, 2:3)) == (20.0, 40.0)
        m = Sampled(revind, ReverseOrdered(), Irregular(5.0, 55.0), Intervals(Center()), NoMetadata())
        mr = Sampled(revind, ReverseOrdered(), Regular(-10.0), Intervals(Center()), NoMetadata())
        @test bounds(getindex(m, 1:5)) == bounds(getindex(mr, 1:5)) == (5.0, 55.0)
        @test bounds(getindex(m, 1:2)) == bounds(getindex(mr, 1:2)) == (35.0, 55.0)
        @test bounds(getindex(m, 2:3)) == bounds(getindex(mr, 2:3)) == (25.0, 45.0)
    end

    @testset "Irregular with no bounds" begin
        m = Sampled(ind, ForwardOrdered(), Irregular(nothing, nothing), Intervals(Start()), NoMetadata())
        @test bounds(getindex(m, 3:3)) == (30.0, 40.0)
        @test bounds(getindex(m, 2:4)) == (20.0, 50.0)
        # TODO should this be built into `identify` to at least get one bound?
        @test bounds(getindex(m, 1:5)) == (10.0, nothing)
        m = Sampled(ind, ForwardOrdered(), Irregular(nothing, nothing), Intervals(End()), NoMetadata())
        @test bounds(getindex(m, 3:3)) == (20.0, 30.0)
        @test bounds(getindex(m, 2:4)) == (10.0, 40.0)
        @test bounds(getindex(m, 1:5)) == (nothing, 50.0)
        m = Sampled(ind, ForwardOrdered(), Irregular(nothing, nothing), Intervals(Center()), NoMetadata())
        @test bounds(getindex(m, 3:3)) == (25.0, 35.0)
        @test bounds(getindex(m, 2:4)) == (15.0, 45.0)
        @test bounds(getindex(m, 1:5)) == (nothing, nothing)
    end

end

@testset "bounds and intervalbounds" begin
    @testset "Intervals" begin
        @testset "Regular bounds are calculated from interval type and span value" begin
            @testset "Forward Center DateTime" begin
                ind = DateTime(2000):Month(1):DateTime(2000, 11)
                dim = format(X(ind; sampling=Intervals(Center())))
                @test bounds(dim) == (DateTime(1999, 12, 16, 12), DateTime(2000, 11, 16))
                @test intervalbounds(dim, 3) == (DateTime(2000, 03, 15, 12), DateTime(2000, 02, 14, 12))
            end
            @testset "Reverse Center DateTime" begin
                ind = DateTime(2000, 11):Month(-1):DateTime(2000, 1)
                dim = format(X(ind; sampling=Intervals(Center())))
                @test bounds(dim) == (DateTime(1999, 12, 16, 12), DateTime(2000, 11, 16))
                @test intervalbounds(dim, 3) == (DateTime(2000, 09, 16, 12), DateTime(2000, 08, 17))
            end
            @testset "forward ind" begin
                ind = 10.0:10.0:50.0
                dim = X(Sampled(ind, order=ForwardOrdered(), sampling=Intervals(Start()), span=Regular(10.0)))
                @test bounds(dim) == (10.0, 60.0)
                @test intervalbounds(dim, 2) == (20.0, 30.0)
                @test intervalbounds(dim) == [
                    (10.0, 20.0)
                    (20.0, 30.0)
                    (30.0, 40.0)
                    (40.0, 50.0)
                    (50.0, 60.0)
                ]
                dim = X(Sampled(ind, order=ForwardOrdered(), sampling=Intervals(End()), span=Regular(10.0)))
                @test bounds(dim) == (0.0, 50.0)
                @test intervalbounds(dim, 2) == (10.0, 20.0)
                @test intervalbounds(dim) == [
                    (0.0, 10.0)
                    (10.0, 20.0)
                    (20.0, 30.0)
                    (30.0, 40.0)
                    (40.0, 50.0)
                ]
                dim = X(Sampled(ind, order=ForwardOrdered(), sampling=Intervals(Center()), span=Regular(10.0)))
                @test bounds(dim) == (5.0, 55.0)
                @test intervalbounds(dim, 2) == (15.0, 25.0)
                @test intervalbounds(dim) == [
                    (5.0, 15.0)
                    (15.0, 25.0)
                    (25.0, 35.0)
                    (35.0, 45.0)
                    (45.0, 55.0)
                ]
                # Test non keyword constructors too
                dim = X(Sampled(ind, ForwardOrdered(), Regular(10.0), Intervals(Start()), NoMetadata()))
                @test bounds(dim) == (10.0, 60.0)                                        
                dim = X(Sampled(ind, ForwardOrdered(), Regular(10.0), Intervals(End()), NoMetadata()))
                @test bounds(dim) == (0.0, 50.0)                                         
                dim = X(Sampled(ind, ForwardOrdered(), Regular(10.0), Intervals(Center()), NoMetadata()))
                @test bounds(dim) == (5.0, 55.0)
            end
            @testset "reverse ind" begin
                revind = [10.0, 9.0, 8.0, 7.0, 6.0]
                dim = X(Sampled(revind, ReverseOrdered(), Regular(-1.0), Intervals(Start()), NoMetadata()))
                @test bounds(dim) == (6.0, 11.0)
                @test intervalbounds(dim, 2) == (9.0, 10.0)
                @test intervalbounds(dim) == [
                    (10.0, 11.0)
                    (9.0, 10.0)
                    (8.0, 9.0)
                    (7.0, 8.0)
                    (6.0, 7.0)
                ]
                dim = X(Sampled(revind, ReverseOrdered(), Regular(-1.0), Intervals(End()), NoMetadata()))
                @test bounds(dim) == (5.0, 10.0)
                @test intervalbounds(dim, 2) == (8.0, 9.0)
                @test intervalbounds(dim) == [
                    (9.0, 10.0)
                    (8.0, 9.0)
                    (7.0, 8.0)
                    (6.0, 7.0)
                    (5.0, 6.0)
                ]
                dim = X(Sampled(revind, ReverseOrdered(), Regular(-1.0), Intervals(Center()), NoMetadata()))
                @test bounds(dim) == (5.5, 10.5)
                @test intervalbounds(dim, 2) == (8.5, 9.5)
                @test intervalbounds(dim) == [
                    (9.5, 10.5)
                    (8.5, 9.5)
                    (7.5, 8.5)
                    (6.5, 7.5)
                    (5.5, 6.5)
                ]
            end
        end
        @testset "Irregular bounds are whatever is stored in span" begin
            ind = 10.0:10.0:50.0
            dim = X(Sampled(ind, ForwardOrdered(), Irregular(10.0, 50000.0), Intervals(Start()), NoMetadata()))
            @test bounds(dim) == (10.0, 50000.0)
            @test bounds(getindex(dim, 2:3)) == (20.0, 40.0)
            @test intervalbounds(dim) == [
                (10.0, 20.0)
                (20.0, 30.0)
                (30.0, 40.0)
                (40.0, 50.0)
                (50.0, 50000.0)
            ]
        end
        @testset "Explicit bounds are is stored in span matrix" begin
            ind = 10.0:10.0:50.0
            bnds = vcat(ind', (20.0:10.0:60.0)')
            dim = X(Sampled(ind, ForwardOrdered(), Explicit(bnds), Intervals(Start()), NoMetadata()))
            @test bounds(dim) == (10.0, 60.0)
            @test bounds(_slicedims(getindex, dim, 2:3)[1][1]) == (20.0, 40.0)
            @test intervalbounds(dim) == [
                (10.0, 20.0)
                (20.0, 30.0)
                (30.0, 40.0)
                (40.0, 50.0)
                (50.0, 60.0)
            ]
        end
    end

    @testset "Points" begin
        ind = 10:15
        dim = X(Sampled(ind; order=ForwardOrdered(), sampling=Points()))
        @test bounds(dim) == (10, 15)
        ind = 15:-1:10
        dim = X(Sampled(ind; order=ReverseOrdered(), sampling=Points()))
        last(dim), first(dim)
        @test bounds(dim) == (10, 15)
        dim = X(Sampled(ind; order=Unordered(), sampling=Points()))
        @test bounds(dim) == (nothing, nothing)
        @test intervalbounds(dim) == collect(zip(15:-1:10, 15:-1:10))
    end

    @testset "Categorical" begin
        ind = [:a, :b, :c, :d]
        dim = X(Categorical(ind; order=ForwardOrdered()))
        @test order(dim) == ForwardOrdered()
        @test_throws ErrorException step(dim)
        @test span(dim) == NoSpan()
        @test sampling(dim) == NoSampling()
        @test dims(lookup(dim)) === nothing
        @test locus(dim) == Center()
        @test bounds(dim) == (:a, :d)
        dim = X(Categorical(ind; order=ReverseOrdered()))
        @test bounds(dim) == (:d, :a)
        @test order(dim) == ReverseOrdered()
        dim = X(Categorical(ind; order=Unordered()))
        @test bounds(dim) == (nothing, nothing)
        @test order(dim) == Unordered()
        @test_throws ErrorException intervalbounds(dim)
    end

    @testset "Cyclic" begin
        vals = -180.0:1:179.0
        l = Cyclic(vals; cycle=360.0, order=ForwardOrdered(), span=Regular(1.0), sampling=Intervals(Start()))
        dim = X(l)
        @test order(dim) == ForwardOrdered()
        @test step(dim) == 1.0
        @test span(dim) == Regular(1.0)
        @test sampling(dim) == Intervals(Start())
        @test locus(dim) == Start()
        @test bounds(dim) == (-Inf, Inf)
        # Indexing with AbstractArray returns Sampled
        for f in (getindex, view, Base.dotview)
            @test f(l, 1:10) isa Sampled
        end
        # TODO clarify intervalbounds - we cant return the whole set to typemax, so we return onecycle?
        # @test intervalbounds(dim) 
        dim = X(Cyclic(reverse(vals); cycle=360.0, order=ReverseOrdered(), span=Regular(1.0), sampling=Intervals(Start())))
        @test bounds(dim) == (typemin(Float64), typemax(Float64))
        @test order(dim) == ReverseOrdered()
        @test bounds(dim) == (-Inf, Inf)
        @test_throws ArgumentError Cyclic(vals; cycle=360, order=Unordered())
    end

end

@testset "dims2indices with Transformed" begin
    tdimz = X(Transformed(identity)), Y(Transformed(identity)), Z(NoLookup(1:1))
    @test dims2indices(tdimz, (X(1), Y(2), Z())) == (1, 2, Colon())
end

@testset "Pointer conversion" begin
    x = Sampled(rand(10))
    @test Base.unsafe_convert(Ptr{Float64}, x) == pointer(parent(x)) == pointer(x)
    @test strides(x) == (1,)
end

@testset "extra lookups" begin
    # Construction with extra lookups
    dim = X(1:10; lookups=(foo=rand(10), bar=1:10))
    @test dim.lookups isa NamedTuple
    @test length(lookup(dim, :foo)) == 10
    @test lookup(dim, :bar) == 1:10

    # AnonDim smoke test
    dim = AnonDim(1:3, (a=1:3,))
    @test lookup(dim, :a) == 1:3

    # Error on nonexistent name
    @test_throws ArgumentError lookup(dim, :nope)

    # Test 3-arg lookup
    A = DimArray(rand(10, 10), (X(1:10; lookups=(foo=11:20,)), Y(1:10)))
    @test lookup(A, X, :foo) == 11:20
    @test_throws ArgumentError lookup(A, Y, :foo)

    @testset "rebuild propagation" begin
        dim = X(1:10, (foo=collect(1:10),))

        # 2-arg rebuild preserves extra lookups
        dim2 = rebuild(dim, 1:10)
        @test dim2.lookups == dim.lookups

        # 3-arg rebuild replaces extra lookups
        dim3 = rebuild(dim, 1:10, (bar=collect(1:10),))
        @test lookup(dim3, :bar) == collect(1:10)
        @test_throws ArgumentError lookup(dim3, :foo)

        # 3-arg rebuild can clear extra lookups
        dim4 = rebuild(dim, 1:10, NamedTuple())
        @test isempty(dim4.lookups)
    end

    @testset "Dimension indexing slices extra lookups" begin
        dim = X(1:10; lookups=(foo=collect(11:20), bar=collect(21:30)))

        # Range indexing
        dim2 = dim[1:5]
        @test length(lookup(dim2, :foo)) == 5
        @test length(lookup(dim2, :bar)) == 5

        # Colon
        dim2 = dim[:]
        @test dim2.lookups == dim.lookups

        # Array indexing
        dim2 = dim[[1, 3, 5]]
        @test lookup(dim2, :foo) == [11, 13, 15]
    end

    @testset "DimArray getindex preserves extra lookups" begin
        A = DimArray(rand(10, 5), (X(1:10; lookups=(foo=collect(11:20),)), Y(1:5)))

        # Slicing preserves extra lookups on sliced dims
        B = A[X(3:7)]
        @test lookup(B, X, :foo) == collect(13:17)

        # View preserves extra lookups
        V = @view A[X=3:7, Y=:]
        @test lookup(V, X, :foo) == collect(13:17)
    end

    @testset "format validates extra lookups" begin
        # Length mismatch should error
        @test_throws DimensionMismatch DimArray(rand(5), (X(1:5, (foo=collect(1:3),)),))
    end

    @testset "reverse reverses extra lookups" begin
        d = X(1:5; lookups=(foo=11:15,))
        dr = reverse(d)
        @test lookup(dr, :foo) == reverse(11:15)
    end

    @testset "_reducedims reduces extra lookups" begin
        A = DimArray(rand(10), (X(1:10; lookups=(foo=collect(1:10),)),))
        B = sum(A; dims=X)
        @test length(lookup(B, X, :foo)) == 1
    end

    @testset "== includes extra lookups" begin
        d1 = X(1:10, (foo=1:10,))
        d2 = X(1:10, (foo=1:10,))
        d3 = X(1:10, (foo=2:11,))
        d4 = X(1:10)

        @test d1 == d2
        @test d1 != d3
        @test d1 != d4
    end

    @testset "show doesn't error and includes coordinates" begin
        A = DimArray(rand(5, 3), (X(1:5; lookups=(foo=collect(11:15),)), Y(1:3)))
        output = sprint(show, MIME"text/plain"(), A)
        @test occursin("coordinates", output)
        @test occursin("foo", output)

        # No extra lookups - no coordinates block
        A2 = DimArray(rand(5, 3), (X(1:5), Y(1:3)))
        output2 = sprint(show, MIME"text/plain"(), A2)
        @test !occursin("coordinates", output2)
    end

    @testset "set preserves/merges extra lookups" begin
        A = DimArray(rand(10), (X(1:10; lookups=(foo=collect(1:10),)),))
        d = dims(A, X)
        d2 = set(d, ForwardOrdered())
        @test lookup(d2, :foo) isa Lookup
    end

    @testset "extra lookup selector dispatch" begin
        lon_vals = Sampled(collect(10.0:10.0:50.0); order=ForwardOrdered(), sampling=Points())
        lat_vals = Sampled(collect(-10.0:-10.0:-30.0); order=ReverseOrdered(), sampling=Points())
        A = DimArray(
            reshape(1:15, 5, 3),
            (X(1:5; lookups=(Lon=lon_vals,)), Y(1:3; lookups=(Lat=lat_vals,)))
        )

        @testset "At selector via extra lookup" begin
            result = A[Dim{:Lon}(At(30.0))]
            @test result == A[X(3)]
        end

        @testset "Near selector via extra lookup" begin
            result = A[Dim{:Lon}(Near(32.0))]
            @test result == A[X(3)]
        end

        @testset "Between/.. selector via extra lookup" begin
            result = A[Dim{:Lon}(20.0..40.0)]
            @test result == A[X(2:4)]
        end

        @testset "Where selector via extra lookup" begin
            result = A[Dim{:Lon}(Where(x -> x >= 30.0))]
            @test Array(result) == Array(A[X(3:5)])
        end

        @testset "Extra lookups on multiple dims" begin
            result = A[Dim{:Lon}(At(20.0)), Dim{:Lat}(At(-30.0))]
            @test result == A[X(2), Y(3)]
        end

        @testset "Mix of primary + extra" begin
            result = A[X(2), Dim{:Lat}(At(-30.0))]
            @test result == A[X(2), Y(3)]
        end

        @testset "Unresolvable dim still warns" begin
            @test_logs (:warn,) A[Dim{:Foo}(At(1))]
        end

        @testset "view works via extra lookup" begin
            V = view(A, Dim{:Lon}(At(30.0)))
            @test V == A[X(3)]
        end

        @testset "setindex! works via extra lookup" begin
            B = DimArray(
                collect(reshape(1:15, 5, 3)),
                (X(1:5; lookups=(Lon=lon_vals,)), Y(1:3; lookups=(Lat=lat_vals,)))
            )
            B[Dim{:Lon}(At(30.0))] = fill(0, 3)
            @test all(B[X(3)] .== 0)
        end

        @testset "Backward compat: no extra lookups unchanged" begin
            C = DimArray(reshape(1:15, 5, 3), (X(1:5), Y(1:3)))
            @test C[X(2)] == C[X=2]
            @test C[X(2), Y(3)] == C[X=2, Y=3]
        end
    end
end
