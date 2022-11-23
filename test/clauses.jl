
@testset "FollowedBy-style clauses" begin
    rules = Dict(
        "seq" => P.many(P.first(P.fail, "a", "b")),
        "a" => P.seq(P.token(1), P.epsilon, P.not_followed_by(P.token(1))),
        "b" => P.seq(P.token(2), P.followed_by(P.token(1))),
    )

    g = P.make_grammar(["seq"], P.flatten(rules, Int, (s, idx) -> "$(s)_$idx"))

    toks = [1, 2, 1, 2, 1]
    p = P.parse(g, toks)

    m = P.find_match_at!(p, "seq", 1)
    @test m != 0
    @test p.matches[m].len == length(toks)

    @test P.traverse_match(
        p,
        m,
        fold = (m, p, subvals) -> Expr(:call, Symbol(m.rule), subvals...),
    ) == :(seq(
        seq_1(a(a_1(), a_2(), a_3())),
        seq_1(b(b_1(), b_2(b_2_1()))),
        seq_1(a(a_1(), a_2(), a_3())),
        seq_1(b(b_1(), b_2(b_2_1()))),
        seq_1(a(a_1(), a_2(), a_3())),
    ))

    toks = [1, 1, 2]
    p = P.parse(g, toks)
    @test p.matches[P.find_match_at!(p, "seq", 1)].len == 0
    @test P.find_match_at!(p, "seq", 2) != 0
    @test p.matches[P.find_match_at!(p, "seq", 2)].len == 1
    @test p.matches[P.find_match_at!(p, "seq", 3)].len == 0

    toks = [2, 2, 2, 1]
    p = P.parse(g, toks)
    @test p.matches[P.find_match_at!(p, "seq", 1)].len == 0
    @test p.matches[P.find_match_at!(p, "seq", 2)].len == 0
    @test p.matches[P.find_match_at!(p, "seq", 3)].len == 2
end

@testset "Multiple token matches" begin
    rules = Dict(
        3 => P.first(
            11 => P.scan(toks -> length(toks) >= 2 && toks[1] == toks[2] ? 2 : -1),
            P.tokens([:one, :two, :three]),
        ),
    )

    g = P.make_grammar([3], P.flatten(rules, Symbol, (s, idx) -> 1000 * s + idx))

    @test issetequal(g.names, [3, 11, 3002])

    p = P.parse(g, [:one, :one, :two, :three, :three])
    @test all(
        ((P.find_match_at!(p, 3, pos) for pos = 1:5) .> 0) .==
        [true, true, false, true, false],
    )
end

@testset "Tie" begin
    rules = Dict(
        :digit => P.satisfy(isdigit),
        :sep => P.token(','),
        :list => P.tie(P.seq(P.seq(:digit), P.many(:sepdigit => P.seq(:sep, :digit)))),
    )

    g = P.make_grammar([:list], P.flatten(rules, Char))

    input = "1,2,3,4,5"
    p = P.parse(g, input)

    mid = P.find_match_at!(p, :list, 1)
    @test mid != 0
    @test p.matches[mid].len == length(input)
    @test P.traverse_match(p, mid) == :(list(
        digit("1"),
        sepdigit(sep(","), digit("2")),
        sepdigit(sep(","), digit("3")),
        sepdigit(sep(","), digit("4")),
        sepdigit(sep(","), digit("5")),
    ))
end

@testset "flatten complains about duplicates" begin
    rules = Dict(:x => P.seq(:x => P.fail))

    @test_throws DomainError P.flatten(rules, Char)
end

@testset "corner-case epsilon matches" begin
    rules = Dict(:x => P.followed_by(P.epsilon))

    p = P.parse(P.flatten(rules, Char), "whatever")

    @test P.find_match_at!(p, :x, 1) != 0
    @test P.find_match_at!(p, :x, 8) != 0
end
