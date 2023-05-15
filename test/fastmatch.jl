
@testset "Fast matching" begin
    rules = OrderedDict(
        :digits => P.some(:digit => P.fail),
        :seq => P.seq(:digits, P.many(:cont => P.seq(:sep => P.fail, :digits))),
    )

    g = P.make_grammar([:seq], P.flatten(rules, Char))
    input = collect("123,234,345")
    p = P.parse(g, input, (input, i, r) -> input[i] == ',' ? r(:sep, i) : r(:digit, i))

    mid = P.find_match_at!(p, :seq, 1)
    @test p.matches[mid].last == lastindex(input)

    x = P.traverse_match(
        p,
        mid,
        fold = (m, p, s) ->
            m.rule == :digits ? parse(Int, String(m.view)) :
            m.rule == :seq ? [s[1], s[2]...] : m.rule == :cont ? s[2] : s,
    )
    @test x == [123, 234, 345]
end

@testset "Lexing" begin
    rules = OrderedDict(
        :digits => P.scan(m -> begin
            i = firstindex(m)
            last = prevind(m, i)
            while i <= lastindex(m) && isdigit(m[i])
                last = i
                i = nextind(m, i)
            end
            last
        end),
        :seq => P.seq(:digits, P.many(:cont => P.seq(:sep => P.token(','), :digits))),
    )

    g = P.make_grammar([:seq], P.flatten(rules, Char))
    input = "123,234,345"

    # lexing shouldn't make too much tokens
    @test sum(length.(P.lex(g, input))) == 5
    @test isempty(P.lex(g, ""))

    p = P.parse_lex(g, input)

    # consequently parsing should generate a smaller match table
    @test length(p.matches) <= 15 # (this is tight)

    mid = P.find_match_at!(p, :seq, 1)
    @test p.matches[mid].last == lastindex(input)

    x = P.traverse_match(
        p,
        mid,
        fold = (m, p, s) ->
            m.rule == :digits ? parse(Int, String(m.view)) :
            m.rule == :seq ? [s[1], s[2]...] : m.rule == :cont ? s[2] : s,
    )
    @test x == [123, 234, 345]
end
