-module(fe).

-export([papply/2]).
-export([all/1, any/1]).
-export([true/0, false/0, id/1]).
-export([count/2, uniq/1, foldl1/2, find/2, find/3]).
-export([fst/1, snd/1, curry/1, uncurry/1]).
-export([pnand/2, pnot/1, pand/2, por/2]).

-type predicate() :: fun(() -> boolean()).

%% =====================================================================
%% Composition
%% =====================================================================

-spec papply(Fun::fun(), Fix::any()) -> fun().
papply(Fun, Fix) ->
    case arity(Fun) of
        0 ->
            {error, badarity};
        1 ->
            fun() -> apply(Fun, [Fix]) end;
        2 ->
            fun(Arg) -> apply(Fun, [Fix|[Arg]]) end;
        _ ->
            fun(Args) when is_list(Args) -> apply(Fun, [Fix|Args]) end
    end.

%% =====================================================================
%% Logics
%% =====================================================================

-spec pnand(P::predicate(), Q::predicate()) -> predicate().
pnand(P, Q) -> fun() -> nand(P(), Q()) end.

-spec pnot(Prop::predicate()) -> predicate().
pnot(Prop) -> pnand(Prop, Prop).

-spec pand(P::predicate(), Q::predicate()) -> predicate().
pand(P, Q) -> pnot(pnand(P, Q)).

-spec por(P::predicate(), Q::predicate()) -> predicate().
por(P, Q) -> pnand(pnand(P, P), pnand(Q, Q)).

-spec all(Preds::[predicate()]) -> predicate().
all(Preds) when is_list(Preds) ->
    fun() -> lists:foldl(fun(Pred, Acc) -> Acc and Pred() end, true, Preds) end.

-spec any(Preds::[predicate()]) -> predicate().
any(Preds) when	is_list(Preds) ->
    fun() -> lists:foldl(fun(Pred, Acc) -> Acc or Pred() end, false, Preds) end.

%% =====================================================================
%% Tuples
%% =====================================================================

-spec fst(tuple(any())) -> any() | undefined.
fst({}) -> undefined;
fst(Tup) when is_tuple(Tup) -> erlang:element(1, Tup).

-spec snd(tuple(any())) -> any() | undefined.
snd({})     -> undefined;
snd({_})    -> undefined;
snd(Tup) when is_tuple(Tup) -> erlang:element(2, Tup).

-spec curry(fun(({A::any(), B::any()}) -> C::any())) ->
                   fun((A::any(), B::any()) -> C::any()).
curry(F) when is_function(F, 1) ->
    fun(A, B) -> F({A,B}) end.

-spec uncurry(fun((A::any(), B::any()) -> C::any())) ->
                     fun(({A::any(), B::any()}) -> C::any()).
uncurry(F) when is_function(F, 2) ->
    fun({A, B}) -> F(A, B) end.

%% =====================================================================
%% Collections
%% =====================================================================

-spec count(Needle::any(), Haystack::[any()]) -> non_neg_integer().
count(Needle, Haystack) ->
    lists:foldl(fun(N, Count) when N =:= Needle -> Count + 1;
                   (_, Count) -> Count end, 0, Haystack).

-spec uniq(List::list()) -> list().
uniq(List) ->
    lists:usort(List).

-spec foldl1(fun((Element::any(), Acc::any()) -> Acc::any()), nonempty_list()) -> Acc::any().
foldl1(Fun, [X|Rest]) -> lists:foldl(Fun, X, Rest).

-spec find(Needle::any(), Haystack::[any()]) -> any() | notfound.
find(Needle, Haystack) ->
    find(Needle, Haystack, notfound).

-spec find(Needle::any(), Haystack::[any()], NotFound::any()) -> any().
find(_, [], NotFound) ->
    NotFound;
find(Needle, [H|_], _) when Needle =:= H ->
    Needle;
find(Needle, [_|T], NotFound) ->
    find(Needle, T, NotFound).

%% =====================================================================
%% Utility
%% =====================================================================

-spec true() -> true.
true() -> true.

-spec false() -> false.
false() -> false.

-spec id(Any::any()) -> any().
id(Any) -> Any.

arity(Fun) ->
    {arity, N} = erlang:fun_info(Fun, arity),
    N.

-spec nand(P::boolean(), Q::boolean()) -> boolean().
nand(false, false) -> true;
nand(false, true)  -> true;
nand(true,  false) -> true;
nand(true,  true)  -> false.
