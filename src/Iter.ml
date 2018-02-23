(*---------------------------------------------------------------------------
   Copyright (c) 2017 Rizo Isrof. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)


(* Base definitions *)

type order = int

type ('a, 'b) either = Left of 'a | Right of 'b

let (or) opt def =
  match opt with
  | Some x -> x
  | None -> def

let (<<) f g x = f (g x)
let (>>) g f x = f (g x)

let pass () = ()

let bracket acquire (release : 'a -> unit) f =
  let x = acquire () in
  try
    let r = f x in
    release x;
    r
  with exn ->
    release x;
    raise exn

let constantly x _ = x


type 'a iter =
    Iter : {
      init : unit -> 'cursor;
      next : 'r . ('a -> 'cursor -> 'r) -> (unit -> 'r) -> 'cursor -> 'r;
      stop : 'cursor -> unit;
    } -> 'a iter

type 'a t = 'a iter

let[@inline] fold f r0 (Iter iter) =
  let[@inline] rec loop r s =
    iter.next (fun a s' -> loop (f a r) s') (fun () -> r) s in
  bracket iter.init iter.stop (loop r0)

let make l =
  let next yield r cursor =
    match cursor with
    | [] -> r ()
    | x :: cursor' -> yield x cursor' in
  Iter { init = constantly l; next; stop = ignore; }

let with_length n f =
  (* FIXME: Add checks or support negative ranges. *)
  let next yield r cursor =
    if cursor = n then r ()
    else yield (f cursor) (cursor + 1) in
  Iter { init = constantly 0; stop = ignore; next }

let empty =
  let next _yield r _cursor = r () in
  Iter { init = pass; next; stop = pass }

let singleton a = make [a]
let doubleton a1 a2 = make [a1; a2]

let repeat x =
  let next yield _r cursor = yield x cursor in
  Iter { init = pass; stop = pass; next }

let zeros = repeat 0
let ones = repeat 1

let range ?by:(step = 1) start stop =
  (* FIXME: Add checks or support negative ranges. *)
  let next yield r cursor =
    if cursor >= stop then r ()
    else yield cursor (cursor + step) in
  Iter { init = constantly start; next; stop = ignore }

let count ?by:(step = 1) start =
  (* FIXME: Add checks or support negative ranges. *)
  let next yield _r n = yield n (n + step) in
  Iter { init = constantly start;
         stop = ignore;
         next }

let iota ?by stop =
  range ?by 0 stop

let repeatedly f =
  let next yield _r cursor = yield (f ()) cursor in
  Iter { init = pass; stop = pass; next }

let iterate f x =
  let next yield _r cursor = yield cursor (f cursor) in
  Iter { init = constantly x; stop = ignore; next }


(* Basic Operations *)

let is_empty (Iter iter) =
  bracket iter.init iter.stop
    (iter.next (fun _ _ -> false) (fun () -> true))

let length self =
  fold (fun _ n -> n + 1) 0 self

let reduce f (Iter iter) =
  let[@inline] rec loop r s =
    iter.next (fun a s' -> loop (f r a) s') (fun () -> r) s in
  bracket iter.init iter.stop
    (iter.next
       (fun r0 s0 -> Some (loop r0 s0))
       (fun () -> None))

let fold_while f r0 (Iter iter) =
  let rec loop r s =
    iter.next
      (fun a s' -> f a r (fun r -> loop r s))
      (fun () -> r) s in
  bracket iter.init iter.stop (loop r0)

let find predicate (Iter iter) =
  let rec loop s =
    iter.next
      (fun a s' ->
         if predicate a then Some a
         else loop s')
      (fun () -> None) s in
  bracket iter.init iter.stop loop

let find_index predicate (Iter iter) =
  let rec loop idx s =
    iter.next
      (fun a s' ->
         if predicate a then Some idx
         else loop (idx + 1) s')
      (fun () -> None) s in
  bracket iter.init iter.stop (loop 0)

(* TODO: Return iter *)
let find_indices predicate (Iter iter) =
  let rec loop idx r s =
    iter.next
      (fun a s' ->
         if predicate a then loop (idx + 1) (idx :: r) s'
         else loop (idx + 1) r s')
      (fun () -> r) s in
  loop 0 []
  |> bracket iter.init iter.stop
  |> List.rev

let index x self =
  find_index (Pervasives.(=) x) self

(* XXX *)
let indices x self =
  find_indices (Pervasives.(=) x) self

let find_max ?by self =
  let compare = match by with Some f -> f | None -> Pervasives.compare in
  let (>) a b = compare a b = 1 in
  reduce (fun a b -> if a > b then a else b) self

let find_min ?by self =
  let compare = match by with Some f -> f | None -> Pervasives.compare in
  let (<) a b = compare a b = -1 in
  reduce (fun a b -> if a < b then a else b) self

let contains x self =
  match find ((=) x) self with
  | Some _ -> true
  | _ -> false

let count predicate (Iter iter) =
  let rec loop n s =
    iter.next
      (fun a s' ->
         if predicate a then loop (n + 1) s'
         else loop n s')
      (fun () -> n) s in
  bracket iter.init iter.stop (loop 0)

let sum self =
  fold ( + ) 0 self

let product (Iter iter) =
  let rec loop r s =
    iter.next
      (fun a s' ->
         if a = 0 then 0
         else loop (a * r) s')
      (fun () -> r) s in
  bracket iter.init iter.stop (loop 1)

let all p (Iter iter) =
  let rec loop s =
    iter.next
      (fun a s' ->
         if p a then loop s'
         else false)
      (fun () -> true) s in
  bracket iter.init iter.stop loop

let any p (Iter iter) =
  let rec loop s =
    iter.next
      (fun a s' ->
         if p a then loop s'
         else true)
      (fun () -> false) s in
  bracket iter.init iter.stop loop

let to_list_reversed self =
  fold (fun x xs -> x :: xs) [] self

let to_list self =
  List.rev (to_list_reversed self)

let get n (Iter iter) =
  let rec loop idx cursor =
    iter.next
      (fun a cursor' ->
         if idx = n then Some a
         else loop (idx + 1) cursor')
      (fun () -> None) cursor in
  bracket iter.init iter.stop (loop 0)

let first  self = get 0 self
let second self = get 1 self
let third  self = get 3 self

let last self =
  fold (fun a _ -> Some a) None self

let rest (Iter iter) =
  bracket iter.init iter.stop
    (iter.next
       (fun _a s' -> Some (Iter { iter with init = (fun () -> s') }))
       (fun () -> None))

let list = make

let array array =
  let next yield r cursor =
    if Array.length array = cursor then r ()
    else yield (Array.unsafe_get array cursor) (cursor + 1) in
  Iter { init = constantly 0; next; stop = ignore }


let next (Iter iter) =
  iter.next
    (fun x cursor -> Some (x, Iter { iter with init = (fun () -> cursor) }))
    (fun () -> None) (iter.init ())

let prepend x (Iter iter) =
  let next yield r (s, should_add) =
    if should_add then
      yield x (s, false)
    else
      iter.next (fun a s' -> yield a (s', should_add)) r s
  in
  Iter { init = (fun () -> (iter.init (), true));
         stop = (fun (s, _) -> iter.stop s);
         next }

let append x (Iter iter) =
  let next yield r (s, should_add) =
    iter.next
      (fun a s' -> yield a (s', should_add))
      (fun () -> if should_add then yield x (s, false) else r ()) s
  in
  Iter { init = (fun () -> (iter.init (), true));
         stop = (fun (s, _) -> iter.stop s);
         next }

let to_array self =
  Array.of_list (to_list self)

let to_string self =
  let reduce x acc =
    Buffer.add_char acc x; acc in
  let buffer = fold reduce (Buffer.create 16) self in
  Bytes.to_string (Buffer.to_bytes buffer)

let string self =
  failwith "unimplemented"

let scan_right self =
  failwith "unimplemented"

let scan self =
  failwith "unimplemented"

let collect self =
  failwith "unimplemented"

let fold_right self =
  failwith "unimplemented"

let chain l0 =
  failwith "unimplemented"

let intersparse item (Iter iter) =
  let rec next yield r (should_add, cursor) =
    if should_add then
      yield item (false, cursor)
    else
      iter.next (fun x cursor' -> yield x (true, cursor'))
        r cursor
  in
  Iter { init = (fun () -> (false, iter.init ()));
         stop = (fun (_, cursor) -> iter.stop cursor);
         next }

let powerset self = failwith "unimplemented"
let pairwise self = failwith "unimplemented"

(* Concatenates the left and right iterators into an iterator that produces the
   elements contained in both [left] and [right] in order. The [right] iterator
   is only open when [left] is exhausted. The [left] iterator is closed before
   [right] is started. *)
let concat (Iter left) (Iter right) =
  let rec next yield r (left_cursor, right_cursor_opt) =
    match right_cursor_opt with
    | None ->
      left.next
        (fun x left_cursor' -> yield x (left_cursor', None))
        (fun () -> left.stop left_cursor; next yield r (left_cursor, Some (right.init())))
        left_cursor
    | Some right_cursor ->
      right.next
        (fun x right_cursor' -> yield x (left_cursor, Some right_cursor'))
        r
        right_cursor
  in
  Iter { init = (fun () -> (left.init (), None));
         stop = (fun (left_cursor, right_cursor_opt) ->
             match right_cursor_opt with
             | Some c -> right.stop c
             | None -> ());
         next }

(* FIXME: Flatten enters an infinite loop if given an infinite iterator (allocating memory).

     flatten (repeat (singleton 4)) |> take 4 |> to_list

   If the iterator is finite flatten works correctly:

     flatten (repeat (singleton 4) |> take 4) |> to_list
*)
(* let flatten_ (Iter iter) =
   let rec next yield r cursor =
    iter.next
      begin fun (Iter subiter) cursor' ->
        let subcursor = subiter.init () in
        subiter.next
          (fun x subcursor' -> yield x cursor')
          r
          subcursor
      end
      r
      cursor
   in
   Iter { iter with next } *)

let flatten (Iter iter) =
  let rec loop iter_i cursor =
    iter.next
      (fun iter_j cursor' -> loop (concat iter_i iter_j) cursor')
      (fun () -> iter_i)
      cursor in
  bracket iter.init iter.stop
    (iter.next
       (fun iter0 cursor0 -> loop iter0 cursor0)
       (fun () -> empty))

let cycle (Iter iter) =
  let rec next yield r cursor =
    iter.next
      (fun x cursor' -> yield x cursor')
      (fun () -> iter.stop cursor; next yield r (iter.init ()))
      cursor
  in
  Iter { iter with next }

let reverse self =
  make (fold List.cons [] self)

let sort ?by self =
  let compare = by or Pervasives.compare in
  let arr = to_array self in
  Array.sort compare arr;
  array arr

let unzip self =
  failwith "unimplemented"

let merge self =
  failwith "unimplemented"

let zip_with f (Iter iter1) (Iter iter2) =
  let next yield r (cursor1, cursor2) =
    iter1.next
      (fun x cursor1' ->
         iter2.next (fun y cursor2' ->
             yield (f x y) (cursor1', cursor2'))
           r cursor2)
      r cursor1 in
  let init () =
    (iter1.init (), iter2.init ()) in
  let stop (cursor1, cursor2) =
    iter1.stop cursor1;
    iter2.stop cursor2 in
  Iter { init; stop; next }

let zip iter1 iter2 =
  zip_with (fun x y -> (x, y)) iter1 iter2

let group ?by self = failwith "unimplemented"
let chunks self = failwith "unimplemented"
let partition self = failwith "unimplemented"
let split_while self = failwith "unimplemented"

let split_at self = failwith "unimplemented"

let indexed ?from self = failwith "unimplemented"

let each f (Iter iter) =
  let rec loop cursor =
    iter.next (fun a cursor' -> f a; loop cursor') pass cursor in
  bracket iter.init iter.stop loop

type ('a, 'cursor) flat_map_cursor =
    Flat_map_cursor : {
      top_cursor : 'cursor;
      sub_cursor : 'sub_cursor;
      sub_next : 'r . ('a -> 'sub_cursor -> 'r) -> (unit -> 'r) -> 'sub_cursor -> 'r;
      sub_stop : 'sub_cursor -> unit
    } -> ('a, 'cursor) flat_map_cursor

let flat_map f (Iter iter) =
  let rec next yield r (Flat_map_cursor cursor) =
    cursor.sub_next
      (fun a sub_cursor' ->
         yield a (Flat_map_cursor { cursor with sub_cursor = sub_cursor' }))
      (fun () ->
         cursor.sub_stop cursor.sub_cursor;
         iter.next
           (fun a top_cursor' ->
              let Iter sub_iter = f a in
              let cursor' = Flat_map_cursor {
                  top_cursor = top_cursor';
                  sub_cursor = sub_iter.init ();
                  sub_next = sub_iter.next;
                  sub_stop = sub_iter.stop
                } in
              next yield r cursor')
           r
           cursor.top_cursor)
      cursor.sub_cursor in
  let init () =
    let Iter sub_iter = empty in
    Flat_map_cursor {
      top_cursor = iter.init ();
      sub_cursor = sub_iter.init ();
      sub_next = sub_iter.next;
      sub_stop = sub_iter.stop
    } in
  let stop (Flat_map_cursor {top_cursor; sub_cursor; sub_stop}) =
    iter.stop top_cursor;
    sub_stop sub_cursor in
  Iter { init; stop; next }

let filter_map self = failwith "unimplemented"

let find_map self = failwith "unimplemented"

let map_indexed f (Iter iter) =
  let[@inline] next yield r (cursor, i) =
    iter.next (fun x cursor' -> yield (f i x) (cursor', i + 1)) r cursor in
  Iter { init = (fun () -> (iter.init (), 0));
         stop = (fun (cursor, _) -> iter.stop cursor);
         next }

let map f (Iter iter) =
  let[@inline] next yield r s =
    iter.next (fun a s' -> yield (f a) s') r s in
  Iter { iter with next }

let inspect (f : 'a -> unit) iter =
  map (fun x -> f x; x) iter


let uniq ?by self = failwith "unimplemented"
let drop_while self = failwith "unimplemented"
let drop self = failwith "unimplemented"
let remove_at self = failwith "unimplemented"
let remove self = failwith "unimplemented"
let reject_indices self = failwith "unimplemented"
let reject_indexed self = failwith "unimplemented"
let reject self = failwith "unimplemented"
let slice self = failwith "unimplemented"
let take_while self = failwith "unimplemented"
let take_every self = failwith "unimplemented"

let take n (Iter iter) =
  if n = 0 then empty else
  if n < 0 then
    let err = "Iter.take: positive number expected but got: " in
    raise (Invalid_argument (err ^ string_of_int n))
  else
    let[@inline] next yield r (s, i) =
      if i <= 0 then r ()
      else iter.next (fun a s' -> yield a (s', i - 1)) r s in
    Iter { init = (fun () -> (iter.init (), n));
           stop = (fun (s, _) -> iter.stop s);
           next }

let filter_indices self =
  failwith "unimplemented"

let filter_indexed predicate (Iter iter) =
  let[@inline] rec next yield r (cursor, i) =
    iter.next
      (fun x cursor' ->
         if predicate i x then yield x (cursor', i + 1)
         else next yield r (cursor', i + 1))
      r cursor in
  Iter { init = (fun () -> iter.init (), 0);
         stop = (fun (cursor, _) -> iter.stop cursor);
         next }

let filter predicate (Iter iter) =
  let[@inline] rec next yield r s =
    iter.next
      ((fun a s' ->
          if predicate a then yield a s'
          else next yield r s')) r s in
  Iter { iter with next }

let reject predicate =
  filter (fun x -> not (predicate x))

let starts_with self = failwith "unimplemented"


(*---------------------------------------------------------------------------
   Copyright (c) 2017 Rizo Isrof

   Permission to use, copy, modify, and/or distribute this software for any
   purpose with or without fee is hereby granted, provided that the above
   copyright notice and this permission notice appear in all copies.

   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
   WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
   MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
   ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
   WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
   ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
   OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
  ---------------------------------------------------------------------------*)
