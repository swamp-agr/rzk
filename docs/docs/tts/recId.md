# Tope disjuction elimination along identity paths

\(\mathsf{rec}_{\lor}^{\psi,\phi}(a_\psi, a_\phi)\) (written `recOR(psi, phi, a_psi, a_phi)` in the code)
is well-typed when \(a_\psi\) and \(a_\phi\) are _definitionally equal_ on \(\psi \land \phi\).
Sometimes this is too strong since many terms are not _definitionally_ equal, but only equal up to a path.
Luckily, assuming relative function extensionality, we can define a weaker version of \(rec_{\lor}\) (`recOR`), which we call `recId`, that can work in presence of a witness of type \(\prod_{t : I \mid \psi \land \phi} a_\psi = a_\phi\).

## Prerequisites

We begin by introducing common HoTT definitions:

```rzk
#lang rzk-1

-- A is contractible there exists x : A such that for any y : A we have x = y.
#def iscontr : (A : U) -> U
  := \A -> ∑ (a : A), (x : A) -> a =_{A} x

-- A is a proposition if for any x, y : A we have x = y
#def isaprop : (A : U) -> U
  := \A -> (x : A) -> (y : A) -> x =_{A} y

-- A is a set if for any x, y : A the type x =_{A} y is a proposition
#def isaset : (A : U) -> U
  := \A -> (x : A) -> (y : A) -> isaprop (x =_{A} y)

-- Non-dependent product of A and B
#def prod : (A : U) -> (B : U) -> U
  := \A -> \B -> ∑ (x : A), B

-- A function f : A -> B is an equivalence
-- if there exists g : B -> A
-- such that for all x : A we have g (f x) = x
-- and for all y : B we have f (g y) = y
#def isweq : (A : U) -> (B : U) -> (f : (x : A) -> B) -> U
  := \A -> \B -> \f -> ∑ (g : (x : B) -> A), prod ((x : A) -> g (f x) =_{A} x) ((y : B) -> f (g y) =_{B} y)

-- Equivalence of types A and B
#def weq : (A : U) -> (B : U) -> U
  := \A -> \B -> ∑ (f : (x : A) -> B), isweq A B f

-- Transport along a path
#def transport
  : (A : U) ->
    (C : (x : A) -> U) ->
    (x : A) ->
    (y : A) ->
    (p : x =_{A} y) ->
    (cx : C x) ->
    C y
  := \A -> \C -> \x -> \y -> \p -> \cx -> idJ(A, x, (\z -> \q -> C z), cx, y, p)
```

## Relative function extensionality

We can now define relative function extensionality. There are several formulations, we provide two, following Riehl and Shulman:

```rzk
-- [RS17, Axiom 4.6] Relative function extensionality.
#def relfunext : U
  :=
    (I : CUBE) ->
    (psi : (t : I) -> TOPE) ->
    (phi : (t : I) -> TOPE) ->
    (A : <{t : I | psi t} -> U >) ->
    (iscontrA : <{t : I | psi t} -> iscontr (A t) >) ->
    (a : <{t : I | psi t /\ phi t} -> A t >) ->
    <{t : I | psi t} -> A t [ psi t /\ phi t |-> a t]>

-- [RS17, Proposition 4.8] A (weaker) formulation of function extensionality.
#def relfunext2 : U
  :=
    (I : CUBE) ->
    (psi : (t : I) -> TOPE) ->
    (phi : (t : I) -> TOPE) ->
    (A : <{t : I | psi t} -> U >) ->
    (a : <{t : I | psi t /\ phi t} -> A t >) ->
    (f : <{t : I | psi t} -> A t [ psi t /\ phi t |-> a t ]>) ->
    (g : <{t : I | psi t} -> A t [ psi t /\ phi t |-> a t ]>) ->
    weq (f =_{<{t : I | psi t} -> A t [ psi t /\ phi t |-> a t ]>} g)
      <{t : I | psi t} -> f t =_{A t} g t [ psi t /\ phi t |-> refl_{f t} ]>
```

## Construction of `recId`

The idea is straightforward. We ask for a proof that `a = b` for all points in `psi /\ phi`. Then, by relative function extensionality (`relfunext2`), we can show that restrictions of `a` and `b` to `psi /\ phi` are equal. If we reformulate `a` as extension of its restriction, then we can `transport` such reformulation along the path connecting two restrictions and apply `recOR`.

First, we define how to restrict an extension type to a subshape:

```rzk
-- Restrict extension type to a subshape.
#def restrict
  : (I : CUBE) ->
    (psi : (t : I) -> TOPE) ->
    (phi : (t : I) -> TOPE) ->
    (A : <{t : I | psi t \/ phi t} -> U >) ->
    (a : <{t : I | psi t} -> A t >) ->
    <{t : I | psi t /\ phi t} -> A t >
  := \I -> \psi -> \phi -> \A -> \a ->
     \t -> a t
```

Then, how to reformulate an `a` (or `b`) as an extension of its restriction:

```rzk
-- Reformulate extension type as an extension of a restriction.
#def ext-of-restrict
  : (I : CUBE) ->
    (psi : (t : I) -> TOPE) ->
    (phi : (t : I) -> TOPE) ->
    (A : <{t : I | psi t \/ phi t} -> U >) ->
    (a : <{t : I | psi t} -> A t >) ->
    <{t : I | psi t} -> A t [ psi t /\ phi t |-> restrict I psi phi A a t ]>
  := \I -> \psi -> \phi -> \A -> \a ->
     \t -> a t
```

Now, assuming relative function extensionality, we construct a path between restrictions:

```rzk
-- Transform extension of an identity into an identity of restrictions.
#def restricts-path
  : (r : relfunext2) ->
    (I : CUBE) ->
    (psi : (t : I) -> TOPE) ->
    (phi : (t : I) -> TOPE) ->
    (A : <{t : I | psi t \/ phi t} -> U >) ->
    (a_psi : <{t : I | psi t} -> A t >) ->
    (a_phi : <{t : I | phi t} -> A t >) ->
    (e : <{t : I | psi t /\ phi t} -> a_psi t =_{A t} a_phi t >) ->
    restrict I psi phi A a_psi
      =_{ <{t : I | psi t /\ phi t} -> A t > }
    restrict I phi psi A a_phi
  :=
    \r ->
    \I -> \psi -> \phi -> \A -> \a_psi -> \a_phi -> \e ->
    (first (second (r I
      (\t -> psi t /\ phi t)
      (\t -> BOT)
      (\t -> A t)
      (\t -> recBOT)
      (\t -> a_psi t)
      (\t -> a_phi t)))) e
```

Finally, we bring everything together into `recId`:

```rzk
-- A weaker version of recOR, demanding only a path between a and b:
-- recOR(psi, phi, a, b) demands that for psi /\ phi we have a == b (definitionally)
-- (recId psi phi a b e) demands that e is the proof that a = b (intensionally) for psi /\ phi
#def recId
  : (r : relfunext2) ->
    (I : CUBE) ->
    (psi : (t : I) -> TOPE) ->
    (phi : (t : I) -> TOPE) ->
    (A : <{t : I | psi t \/ phi t} -> U >) ->
    (a_psi : <{t : I | psi t} -> A t >) ->
    (a_phi : <{t : I | phi t} -> A t >) ->
    (e : <{t : I | psi t /\ phi t} -> a_psi t =_{A t} a_phi t >) ->
    <{t : I | psi t \/ phi t} -> A t >
  := \r ->
     \I -> \psi -> \phi -> \A -> \a_psi -> \a_phi -> \e ->
     \t -> recOR(psi t, phi t
       , transport
            <{t : I | psi t /\ phi t} -> A t >
            (\ra -> <{t : I | psi t} -> A t [ psi t /\ phi t |-> ra t]>)
            (restrict I psi phi A a_psi)
            (restrict I phi psi A a_phi)
            (restricts-path r I psi phi A a_psi a_phi e)
            (ext-of-restrict I psi phi A a_psi)
            t
       , ext-of-restrict I phi psi A a_phi t)
```

## Gluing extension types

An application of of `recId` is gluing together extension types,
whenever we can show that they are equal on the intersection of shapes:

```rzk
-- If two extension types are equal along two subshapes,
-- then they are also equal along their union.
#def id-along-border
  : (r : relfunext2) ->
    (I : CUBE) ->
    (psi : (t : I) -> TOPE) ->
    (phi : (t : I) -> TOPE) ->
    (A : <{t : I | psi t \/ phi t} -> U >) ->
    (a : <{t : I | psi t \/ phi t} -> A t >) ->
    (b : <{t : I | psi t \/ phi t} -> A t >) ->
    (e_psi : <{t : I | psi t} -> a t =_{A t} b t >) ->
    (e_phi : <{t : I | phi t} -> a t =_{A t} b t >) ->
    (border-is-a-set : <{t : I | psi t /\ phi t} -> isaset (A t) >) ->
    <{t : I | psi t \/ phi t} -> a t =_{A t} b t >
  := \r -> \I -> \psi -> \phi -> \A -> \a -> \b -> \e_psi -> \e_phi -> \border-is-a-set ->
     recId r I psi phi
        (\{t : I | psi t \/ phi t} -> a t =_{A t} b t)
        e_psi e_phi
        (\{t : I | psi t /\ phi t} -> border-is-a-set t (a t) (b t) (e_psi t) (e_phi t))
```