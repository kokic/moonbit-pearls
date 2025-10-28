///|
using @list {type List}

///|
trait HasNil {
  nil() -> Self
}

///|
trait HasOne {
  one() -> Self
}

///|
trait Inverse {
  inverse(Self) -> Self
}

///|
trait AddMonoid: Add + HasNil {}

///|
trait MulMonoid: Mul + HasOne {}

///|
trait Semiring: AddMonoid + MulMonoid {}

///|
trait StarSemiring: Semiring {
  star(Self) -> Self
}

///|
fn[R : HasOne + Add + Neg + Inverse] star(x : R) -> R {
  (R::one() + x.neg()).inverse()
}

///|
struct Mat2x2[R] {
  a : R
  b : R
  c : R
  d : R
} derive(Show, Eq)

///|
fn[R] Mat2x2::mk(a : R, b : R, c : R, d : R) -> Mat2x2[R] {
  { a, b, c, d }
}

///|
impl[R : Semiring] HasNil for Mat2x2[R] with nil() {
  Mat2x2::mk(R::nil(), R::nil(), R::nil(), R::nil())
}

///|
impl[R : Semiring] HasOne for Mat2x2[R] with one() {
  Mat2x2::mk(R::one(), R::nil(), R::nil(), R::one())
}

///|
impl[R : Add] Add for Mat2x2[R] with add(u : Mat2x2[R], v : Mat2x2[R]) {
  Mat2x2::mk(u.a + v.a, u.b + v.b, u.c + v.c, u.d + v.d)
}

///|
impl[R : Add + Mul] Mul for Mat2x2[R] with mul(u : Mat2x2[R], v : Mat2x2[R]) {
  {
    a: u.a * v.a + u.b * v.c,
    b: u.a * v.b + u.b * v.d,
    c: u.c * v.a + u.d * v.c,
    d: u.c * v.b + u.d * v.d,
  }
}

///|
impl[R : Semiring] Semiring for Mat2x2[R]

///|
fn[R, S] Mat2x2::map(u : Mat2x2[R], f : (R) -> S) -> Mat2x2[S] {
  Mat2x2::mk(f(u.a), f(u.b), f(u.c), f(u.d))
}

///|
impl[R : Neg] Neg for Mat2x2[R] with neg(u : Mat2x2[R]) -> Mat2x2[R] {
  u.map(r => -r)
}

///|
impl[R : Neg + Add] Sub for Mat2x2[R] with sub(u : Mat2x2[R], v : Mat2x2[R]) {
  u + v.neg()
}

///|
impl[R : StarSemiring] StarSemiring for Mat2x2[R] with star(u : Mat2x2[R]) {
  let (a, b, c, d) = (u.a, u.b, u.c, u.d)
  let dalt = d.star()
  let balt = b * dalt
  let aalt = (a + balt * c).star()
  let calt = dalt * c * aalt
  Mat2x2::mk(aalt, aalt * balt, calt, dalt + calt * balt)
}

///|
fn[R : StarSemiring + Neg] Mat2x2::inverse(u : Mat2x2[R]) -> Mat2x2[R] {
  (Mat2x2::one() + u.neg()).star()
}

///|
impl[R : StarSemiring + Neg] Div for Mat2x2[R] with div(
  u : Mat2x2[R],
  v : Mat2x2[R],
) {
  u * v.inverse()
}

///|
enum Expr {
  Symbol(String)
  Const(Float)
  Neg(Expr)
  Add(Expr, Expr)
  Mul(Expr, Expr)
  Div(Expr, Expr)
} derive(Eq, Show)

///|
fn Expr::to_sexp(e : Expr) -> String {
  match e {
    Symbol(x) => x
    Const(c) => c.to_string()
    Neg(a) => "(- 0 \{a.to_sexp()})"
    Add(a, b) => "(+ \{a.to_sexp()} \{b.to_sexp()})"
    Mul(a, b) => "(* \{a.to_sexp()} \{b.to_sexp()})"
    Div(a, b) => "(/ \{a.to_sexp()} \{b.to_sexp()})"
  }
}

///|
test {
  assert_eq(Mat2x2::nil(), Mat2x2::mk(Const(0), Const(0), Const(0), Const(0)))
}

///|
impl HasNil for Expr with nil() {
  Const(0)
}

///|
impl HasOne for Expr with one() {
  Const(1)
}

///|
impl Neg for Expr with neg(x : Expr) {
  Neg(x)
}

///|
impl Inverse for Expr with inverse(x : Expr) {
  Div(Const(1), x)
}

///|
impl Add for Expr with add(a : Expr, b : Expr) {
  Add(a, b)
}

///|
impl Mul for Expr with mul(a : Expr, b : Expr) {
  Mul(a, b)
}

///|
impl Semiring for Expr

///|
impl StarSemiring for Expr with star(x : Expr) {
  star(x)
}

///|
fn shear(a : Expr, b : Expr) -> Mat2x2[Expr] {
  Mat2x2::mk(a, b, Expr::nil(), a)
}

///|
let symbol : (String) -> Mat2x2[Expr] = name => shear(Symbol(name), Const(1))

///|
fn function(name : String) -> Mat2x2[Expr] {
  shear(Symbol(name), Symbol("\{name}'"))
}

///|
let extract : (Mat2x2[Expr]) -> String = u => u.b.to_sexp()

///|
test "leibniz rule" {
  let (f, g) = (function("f"), function("g"))
  assert_eq(extract(f * g), "(+ (* f g') (* f' g))")
  assert_eq(
    extract(f * g.inverse()),
    "(+ (* f (* (/ 1 (+ 1 (- 0 (+ (+ 1 (- 0 g)) (* (* (+ 0 (- 0 g')) (/ 1 (+ 1 (- 0 (+ 1 (- 0 g)))))) (+ 0 (- 0 0))))))) (* (+ 0 (- 0 g')) (/ 1 (+ 1 (- 0 (+ 1 (- 0 g)))))))) (* f' (+ (/ 1 (+ 1 (- 0 (+ 1 (- 0 g))))) (* (* (* (/ 1 (+ 1 (- 0 (+ 1 (- 0 g))))) (+ 0 (- 0 0))) (/ 1 (+ 1 (- 0 (+ (+ 1 (- 0 g)) (* (* (+ 0 (- 0 g')) (/ 1 (+ 1 (- 0 (+ 1 (- 0 g)))))) (+ 0 (- 0 0)))))))) (* (+ 0 (- 0 g')) (/ 1 (+ 1 (- 0 (+ 1 (- 0 g))))))))))",
  )
}

///|
test "differentiation" {
  let x = symbol("x")
  let y = symbol("y")
  assert_eq(extract(x), "1")
  assert_eq(extract(x - y), "(+ 1 (- 0 1))")
  assert_eq(
    extract(x / y),
    "(+ (* x (* (/ 1 (+ 1 (- 0 (+ (+ 1 (- 0 y)) (* (* (+ 0 (- 0 1)) (/ 1 (+ 1 (- 0 (+ 1 (- 0 y)))))) (+ 0 (- 0 0))))))) (* (+ 0 (- 0 1)) (/ 1 (+ 1 (- 0 (+ 1 (- 0 y)))))))) (* 1 (+ (/ 1 (+ 1 (- 0 (+ 1 (- 0 y))))) (* (* (* (/ 1 (+ 1 (- 0 (+ 1 (- 0 y))))) (+ 0 (- 0 0))) (/ 1 (+ 1 (- 0 (+ (+ 1 (- 0 y)) (* (* (+ 0 (- 0 1)) (/ 1 (+ 1 (- 0 (+ 1 (- 0 y)))))) (+ 0 (- 0 0)))))))) (* (+ 0 (- 0 1)) (/ 1 (+ 1 (- 0 (+ 1 (- 0 y))))))))))",
  )
}
