
let odd  x = x mod 2 <> 0
let even x = x mod 2 =  0

open Iter

let test_append () =
  let i1 = append empty 'x' in
  let i2 = append (iter ['a'; 'b'; 'c']) 'x' in

  assert (collect i1 = ['x']);
  assert (collect i2 = ['a'; 'b'; 'c'; 'x'])


let test_prepend () =
  let i1 = prepend empty 'x' in
  let i2 = prepend (iter ['a'; 'b'; 'c']) 'x' in

  assert (collect i1 = ['x']);
  assert (collect i2 = ['x'; 'a'; 'b'; 'c'])


let test_take () =
  let i1 = take 4 (iota 10) in
  let i2 = take 5 (ints) in

  assert (collect i1 = [0; 1; 2; 3]);
  assert (collect i2 = [0; 1; 2; 3; 4])


let test_iota () =
  let i1 = iota 10 in
  let i2 = iota 10 ~by:2 in

  assert (collect i1 = [0; 1; 2; 3; 4; 5; 6; 7; 8; 9]);
  assert (collect i2 = [0; 2; 4; 6; 8])


let test_range () =
  let i0 = range 0 0 in
  let i1 = range 2 10 in
  let i2 = range 2 10 ~by:2 in

  assert (len i0 = 0);
  assert (collect i1 = [2; 3; 4; 5; 6; 7; 8; 9]);
  assert (collect i2 = [2; 4; 6; 8])


let test_contains () =
  let i1 = iota 10 in
  let i2 = iter ['a'; 'b'; 'c'] in

  assert (contains 4   i1 = true);
  assert (contains 'x' i2 = false)


let test_naturals () =
  let i1 = take 5 ints in
  let i2 = take 5 (filter odd ints) in

  assert (collect i1 = [0; 1; 2; 3; 4]);
  assert (collect i2 = [1; 3; 5; 7; 9])

let () =
  test_append ();
  test_prepend ();
  test_take ();
  test_iota ();
  test_range ();
  test_contains ();
  test_naturals ()

