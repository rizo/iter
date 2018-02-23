(*---------------------------------------------------------------------------
   Copyright (c) 2017 Rizo Isrof. All rights reserved.
   Distributed under the ISC license, see terms at the end of the file.
   %%NAME%% %%VERSION%%
  ---------------------------------------------------------------------------*)

(* <<< Ether *)
type order
(* >>> Ether *)

(** Safe and fast functional iterators

    {e %%VERSION%% — {{:%%PKG_HOMEPAGE%% }homepage}} *)

(** {2:overview Overview}

    This module implements combinators for consuming and transforming
    iterators. External containers can use functors provided in this module
    to implement the iteration extensions. Three types of iterables can be
    implemented: input iterables, index iterables and output iterables.

    Functors for both, polymorphic and monomorphic containers are included. *)


(** {3:expected_performance Expected Performance}

    The creation of the iterator is a constant time operation. Most other
    operations in this module assume sequenced access to the elements and
    consequently {i O(n)} time complexity.


    {3:content Content}

    {ol
    {- {{: #type_definitions} Type Definitions}}

    {- {{: #creating_an_iterator} Creating an Iterator}}
    {- {{: #basic_operations} Basic Operations}}
    {- {{: #getting_elements} Getting Elements}}
    {- {{: #finding_elements} Finding Elements}}
    {- {{: #selecting_elements} Selecting Elements}}
    {- {{: #excluding_elements} Excluding Elements}}
    {- {{: #transforming_elements} Transforming Elements}}
    {- {{: #adding_and_combining_elements} Adding and Combining Elements}}
    {- {{: #splitting_and_grouping} Splitting and Grouping}}
    {- {{: #rearranging_elements} Rearranging Elements}}
    {- {{: #iterator_reducers} Iterator Reducers}}
    {- {{: #conversions} Conversions}}
    {- {{: #implemented_instances} Implemented Instances}}} *)


(** {2:type_definitions Type Definitions} *)

(** Iterators of values of type ['a]. *)
type 'a iter

type 'a t = 'a iter
(** A local alias for [iter] type. *)

module type Iterable = sig
  type 'a t

  type 'a cursor

  val cursor : 'a t -> 'a cursor

  val next : 'a t -> ('a -> 'cursor -> 'r) -> (unit -> 'r) -> 'a cursor -> 'r
end


(** {2:creating_an_iterator Creating an Iterator} *)

val make : 'a list -> 'a t
(** [make l] is an alias for [of_list] and the default way to create an
    iterator.

    {[
      assert (Iter.make [1; 2; 3] |> Iter.sum = 6)
    ]} *)

val with_length : int -> (int -> 'a) -> 'a t
(** [with_length n f] is an iterator of length [n] where each element at
    index [i] is [f i].

    {[
      assert (Iter.with_length 3 negate |> Iter.to_list = [0; -1; -2])
    ]} *)

val empty : 'a t
(** [empty] is an iterator without any elements.

    {[
      assert (Iter.is_empty Iter.empty = true);
      assert (Iter.length Iter.empty = 0)
    ]} *)

val singleton : 'a -> 'a t
(** [singleton x] is an iterator with one element [x]. *)

val doubleton : 'a -> 'a -> 'a t
(** [doubleton x1 x2] is an iterator with two elements [x1] and [x2]. *)

val zeros : int t
(** [zeros] is equivalent to [repeat 0], {i i.e.} an infinite sequence of
    zeros. *)

val ones : int t
(** [ones] is equivalent to [repeat 1], {i i.e.} an infinite sequence of
    ones. *)

val range : ?by:int -> int -> int -> int t
(** [range ?by:step start stop] is an iterator of integers from [start]
    (inclusive) to [stop] (exclusive) incremented by [step]. *)

val iota : ?by:int -> int -> int t
(** [iota ?by:step stop] is an iterator of integers from 0 (inclusive) to
    [stop] (exclusive) incremented by [step]. *)

val repeat : 'a -> 'a t
(** [repeat x] produces an iterator by repeating the element [x] {i ad
    infinitum}.

    {e See also:} {!repeatedly}

    {[
      let xs = Iter.repeat 'x' in
      assert (xs |> Iter.take 0 = Iter.empty);
      assert (xs |> Iter.take 3 |> Iter.to_list = ['x'; 'x'; 'x']);
      assert (xs = Iter.repeatedly (constantly 'x'));
    ]} *)

val repeatedly : (unit -> 'a) -> 'a t
(** [repeatedly f] produces an iterator by calling [f ()] {e ad infinitum}.

    {e See also:} {!repeat} *)

val iterate : ('a -> 'a) -> 'a -> 'a t
(** [iterate f x] is an iterator that produces an infinite sequence of
    repeated applications of [f x], [f (f x)], [f (f (f x))]...

    {[
      let powers_of_2 = iterate (fun x -> 2 * x) 2 in
      assert (powers_of_2 |> Iter.take 10 |> Iter.to_list =
                                             [2; 4; 8; 16; 32; 64; 128; 256; 512; 1024])
    ]} *)


(** {2:basic_operations Basic Operations} *)

val is_empty : 'a t -> bool
(** [is_empty self] is [true] if the iterator [self] does not have any
    elements.

    This function will initialize the iterator [self] and attempt to request
    one element.

    {[
      assert Iter.(is_empty zero);
      assert Iter.(not (is_empty (range 10)));
    ]} *)

val length : 'a t -> int
(** [length self] is the number of elements in the iterator [self]. *)


(** {2:getting_elements Getting Elements} *)

val first : 'a t -> 'a option
(** [first self] is the first element from the iterator [self], or [None] if
    the iterator is empty. *)

val second : 'a t -> 'a option
(** [second self] is the second element from the iterator [self], or [None] if
    the iterator has less than two elements. *)

val third : 'a t -> 'a option
(** [third self] is the third element from the iterator [self], or [None] if
    the iterator has less than three elements. *)

val last : 'a t -> 'a option
(** [last self] is the last element from the iterator [self], or [None] if
    the iterator is empty. *)

val get : int -> 'a t -> 'a option
(** [get n self] is the [n]th element from the iterator [self], or None if [n]
    exceeds its length. *)

val rest : 'a t -> 'a t option
(** [rest self] is an iterator with all elements of the iterator [self] except
    the first one, or [None] if [self] is empty. *)


(** {2:finding_elements Finding Elements} *)

val find: ('a -> bool) -> 'a t -> 'a option
(** [find predicate self] returns the first leftmost element from the iterator
    [self] matching a given [predicate], or [None] if there is no such element.

    {[
      let numbers = [42; 21; 53; -2; 32] in
      assert (Iter.find (fun a -> a < 0) numbers = Some (-2));
      assert (Iter.find (fun a -> a = 0) numbers = None);
    ]} *)

val find_index : ('a -> bool) -> 'a t ->  int option
(** [find_index predicate self] returns the index of the first leftmost
    element from the iterator [self] matching a given [predicate], or [None] if
    there is no such element.

    {[
      let numbers = [42; 21; 53; -2; 32] in
      assert (List.find_index (fun a -> a < 0) numbers = Some 3);
      assert (List.find_index (fun a -> a < 0) numbers = None);
    ]} *)

val find_indices : ('a -> bool) -> 'a t -> int list
(** [find_indices p self] is like {!find_index} but finds indices of all
    elements that match the predicate as an iterator. *)

val index : 'a -> 'a t -> int option
(** [index x self] searches for the element [x] in [self] and returns its
    index.

    This function is equivalent to [find_index ((=) x) self].

    {e Note:} This function relies on the polymorphic equality function.

    {[
      let letters = ['a'; 'b'; 'c'] in
      assert (Iter.index 'b' letters = Some 1);
      assert (Iter.index 'x' letters = None);
    ]} *)

val indices : 'a -> 'a t -> int list
(** [indices x self] searches for the item [x] in [self] and returns all its
    indices as an iterator.

    This function is equivalent to [find_indices ((=) x) self].

    {e Note:} This function relies on the polymorphic equality function.

    {[
      let letters = ['a'; 'b'; 'c'; 'b'] in
      assert (Iter.indices 'b' letters = Iter.make [1; 3]);
      assert (Iter.indices 'x' letters = Iter.make []);
    ]} *)

val contains : 'a -> 'a t -> bool
(** [contains x self] is true if the element [x] exists in the iterator [self].
    It is equivalent to [any ((=) x) self)].

    {e Note:} This function relies on the polymorphic equality function.

    {e See also:} {!find}, {!any}

    {[
      assert (contains 'x' ['a'; 'b'; 'x'] = true);
      assert (contains 'x' ['a'; 'b'; 'd'] = false);
    ]} *)

val starts_with : 'a t -> ?by:('a -> 'a -> bool) -> 'a t -> bool
(** [starts_with prefix ?by:equal self] is [true] if each element from [prefix]
    matches the elements at the beginning of [self] by using [equal] to compare
    the elements.

    {[
      (* Use polymorphic comparison function. *)
      assert Iter.(string "abcdef" |> starts_with (string "abc"))

      (* Use a custom equality function. *)
      let equal_no_case a b =
        Char.(lowercase_ascii a = lowercase_ascii b) in
      let answer =
        Iter.string "ABCDEF"
        |> Iter.starts_with (string "abc") ~by:equal_no_case in
      assert (answer = true)
    ]} *)

val count : ('a -> bool) -> 'a t -> int
(** [count predicate self] counts the number of elements from the
    iterator [self] that match the [predicate] function.

    {[
      assert (Iter.count ((=) 'x') (Iter.make ['a'; 'b'; 'c']) = 0);
      assert (Iter.count ((=) 'x') (Iter.make ['a'; 'x'; 'b'; 'x']) = 2)
    ]} *)

val all : ('a -> bool) -> 'a t -> bool
(** [all predicate self] is [true] if all the elements from [self] match the
    predicate [predicate] function.

    {[
      assert (Iter.all (fun x -> x > 0) (Iter.make []) = true);
      assert (Iter.all (fun x -> x > 0) (Iter.make [1; 2; 3]) = true);
      assert (Iter.all (fun x -> x > 0) (Iter.make [1; 2; -3]) = false);
    ]} *)

val any : ('a -> bool) -> 'a t -> bool
(** [any predicate self] is [true] if at least one element from [self] matches
    the [predicate] function.

    {[
      assert (Iter.any (fun x -> x > 0) (Iter.make []) = false);
      assert (Iter.any (fun x -> x > 0) (Iter.make [1; 2; -3]) = true);
      assert (Iter.any (fun x -> x > 0) (Iter.make [-1; -2; -3]) = false);
    ]} *)

val find_min : ?by:('a -> 'a -> order) -> 'a t -> 'a option
(** [find_min ?by:compare self] is the minimum element in the iterator [self]
    according to the [compare] function or [None] if the iterator is empty. *)

val find_max : ?by:('a -> 'a -> order) -> 'a t -> 'a option
(** [find_max ?by:compare self] is the maximum element in the iterator [self]
    according to the [compare] function or [None] if the iterator is empty. *)


(** {2:selecting_elements Selecting Elements} *)

val filter : ('a -> bool) -> 'a t -> 'a t
(** [filter predicate self] selects all elements from the iterator [self] for
    which [predicate] returns [true]. It is an exact opposite of {!reject}.

    {e See also:} {!reject} *)

val filter_indexed : (int -> 'a -> bool) -> 'a t -> 'a t
(** [filter_indexed f self] is like {!filter} but adds the index to
    the application of [f] on every element. *)

val filter_indices : int t -> 'a t -> 'a t
(** [filter_indices indices self] selects the elements form the iterator
    [self] whose indices are in the iterator [indices].

    {e See also:} {!reject_indices} *)

val take : int -> 'a t -> 'a t
(** [take n self] takes exactly [n] leftmost elements from the iterator [self]
    producing a new iterator.

    To get the last [n] items use [Iter.take n (Iter.reverse self)]. Note that
    if [self] is an infinite iterator it will not terminate. *)

val take_every : int -> 'a t -> 'a t
(** [take_every n self] takes every [n]th element from the iterator [self],
    {i i.e.} the elements whose index is multiple of [n]. *)

val take_while : ('a -> bool) -> 'a t -> 'a t
(** [take_while predicate self] takes the leftmost elements from the iterator
    [self] that match the [predicate]. *)

val slice : int -> int -> 'a t -> 'a t
(** [slice i j self] is an iterator that will select all elements from the
    iterator [self] between the indices [i] (inclusive) and [j] (exclusive)

    {e See also:} {!range}, {!take}, {!drop}

    {[
      let world =
        "Hello, World!"
        |> Iter.of_string
        |> Iter.slice 7 12
        |> Iter.to_string in
      assert (world = "World")
    ]} *)


(** {2:excluding_elements Excluding Elements} *)

val reject : ('a -> bool) -> 'a t -> 'a t
(** [reject predicate self] rejects all elements from the iterator [self] for
    which [predicate] returns [false]. It is an exact opposite of {!filter}.

    {e See also:} {!filter} *)

val reject_indexed : ('a -> int -> bool) -> 'a t -> 'a t
(** [reject_indexed f self] is like {!reject} but adds the current index to
    the application of [f] on every element. *)

val reject_indices : int t -> 'a t -> 'a t
(** [reject_indices indices self] rejects the elements form the iterator
    [self] whose indices are in the iterator [indices].

    {e See also:} {!filter_indexed} *)

val remove : 'a -> 'a t -> 'a t
(** [remove x self] is [reject ((=) x)], {i i.e.} the iterator [self] with all
    occurrence of [x] removed. *)

val remove_at : int -> 'a t -> 'a t
(** [remove_at i self] removes the element from the iterator [self] at
    the index [i].

    This function is equivalent to [reject_indexed (fun _ j -> i = j)].

    {[
      let letters = Iter.make ['a'; 'b'; 'c'; 'd'] in
      assert (Iter.remove_at 2 letters |> Iter.to_list = ['a'; 'b'; 'd'])
    ]} *)

val drop : int -> 'a t -> 'a t
(** [drop n self] drops exactly [n] leftmost elements from the iterator [self]
    producing an iterator with the remaining elements. *)

val drop_while : ('a -> bool) -> 'a t -> 'a t
(** [drop_while predicate self] drops the leftmost elements from the iterator
    [self] that match the [predicate] function producing an iterator with all
    remaining elements. *)

val uniq : ?by:('a -> 'a -> bool) -> 'a t -> 'a t
(** [uniq ?by:equal self] is an iterator with consecutive duplicate elements
    from the iterator [self] removed.

    The elements are compared for equality with the [equal] function. *)


(** {2:transforming_elements Transforming Elements} *)

val map : ('a -> 'b) -> 'a t -> 'b t
(** [map f self] is an iterator that applies the function [f] to every element
    of the iterator [self]. *)

val map_indexed : (int -> 'a -> 'b) -> 'a t -> 'b t
(** [map_indexed f self] is like {!map} but adds the current index to the
    application of [f] on every element. *)

val find_map : ('a -> 'b option) -> 'a t -> 'b option
(** [find_map f self] is the first element from the iterator [self] that
    produces an optional [Some] value after applying [f], or [None] if there is
    no such element.

    {e See also:} {!filter_map} *)

val filter_map : ('a -> 'b option) -> 'a t -> 'b t
(** [filter_map f self] selects all elements from the iterator [self] that
    produce the optional [Some] value after applying [f], rejecting all
    elements that produce [None].

    {e See also:} {!find_map}, {!filter}, {!reject} *)

val flat_map : ('a -> 'b t) -> 'a t -> 'b t
(** [flat_map f self] is an iterator that works like [map] but flattens nested
    structures produced by [f].

    This function is equivalent to the Monadic [bind] operation. *)


(** {2:adding_and_combining_elements Adding and Combining Elements} *)

val append : 'a -> 'a t -> 'a t
(** [append x self] appends the element [x] at the end of the iterator
    [self]. *)

val prepend : 'a -> 'a t -> 'a t
(** [prepend x self] prepends the element [x] at the beginning of the iterator
    [self]. *)

val concat : 'a t -> 'a t -> 'a t
(** [concat self other] is the iterator [self] with all elements from the
    iterator [other] appended at the end. *)


(** {2:iterating_over_elements Iterating Over Elements} *)

val each : ('a -> unit) -> 'a t -> unit
(** [each f iter] applies the function [f] to each element from the iterator
    [self] discarding the results. *)

val indexed : ?from: int -> 'a t -> (int * 'a) t
(** [indexed ?from:n self] adds an index, starting with [n], to each element
    in the iterator [self].

    {[
      let abc = Iter.of_string "abc"
                |> Iter.indexed ~from:97
                |> Iter.collect in
      assert (abc = [(97, 'a'); (98, 'b'); (99, 'c')])
    ]} *)

val inspect : ('a -> unit) -> 'a t -> 'a t
(** [inspect f self] is an iterator that does something with each element of
    the iterator [self], passing the value on.

    {[
      let res =
        Iter.iota 5
        |> Iter.filter (fun x -> x mod 2 = 0)
        |> Iter.inspect Int.print
        |> Iter.sum in
      assert (res = 6)
    ]}

    This will print:

    {[
      0
        2
        4
    ]} *)


(** {2:splitting_and_grouping Splitting and Grouping} *)

val split_at : int -> 'a t -> 'a t * 'a t
(** [split_at i self] is a pair with the elements before the index
    [i] (exclusive) and the elements after [i] (inclusive). *)

val next : 'a t -> ('a * 'a t) option
(** [next self] is a pair with the {!first} element of the iterator and its
    {!rest}, or [None] if the iterator is empty.

    {e See also:} {!split_at} *)

val split_while : ('a -> bool) -> 'a t -> 'a t * 'a t

val partition : ('a -> bool) -> 'a t -> 'a t * 'a t
(** [partition p iter] separates the elements from [iter] in two disjoint
    iterators: the first contains the elements that matched the predicate [p]
    and the second the ones that did not. *)

val chunks : int -> 'a t -> 'a t t
(** [chunks n iter] splits iterator [iter] into chunks of length [n] producing
    a new iterator.

    {e Note:} The last chunk may have less then [n] elements. *)

val group : ?by:('b -> 'b -> bool) -> 'a t -> 'a t t
(** [group ?by:equal self] groups consecutive elements from the iterator [self]
    that are equal according to the [equal] function.

    {e See also:} {!on}

    {[
      (* Group by equality on absolute values of the integers. *)
      let group_counts =
        Iter.make [1; 1; -1; 2; -3; 3; 4; 5; -5; -5; 5]
        |> Iter.group ~by:Int.(equal |> on abs)
        |> Iter.map Iter.length
        |> Iter.collect in
      assert (group_counts = [3; 1; 2; 1; 4])
    ]} *)

val zip : 'a t -> 'b t -> ('a * 'b) t

val zip_with : ('a -> 'b -> 'c) -> 'a t -> 'b t -> 'c t

val merge : ('a -> 'b -> 'c option) -> 'a t -> 'b t -> 'c t
(** [merge f self other] is similar to {!zip_with} but will also exclude
    elements for which [f] returns [None].  *)

val unzip : ('a * 'b) t -> ('a t * 'b t)


(** {2:rearranging_elements Rearranging Elements} *)

val sort : ?by:('a -> 'a -> order) -> 'a t -> 'a t
(** [sort ?by:compare self] is an iterator with all elements from the iterator
    [self] sorted from the lowest to the highest according to the [compare]
    function.

    {e See also:} {!on}

    {[
      let items =
        Iter.make [(99, 'c'); (97, 'a'); (98, 'b')]
        |> Iter.sort ~by:(Int.compare |> on first)
        |> Iter.collect in
      assert (items = [(97, 'a'); (98, 'b'); (99, 'c')])
    ]} *)

val reverse : 'a t -> 'a t
(** [reverse self] reverses the order of the elements of the iterator [self].

    {e WARNING:} Should only be used on finite iterators. Will block
    indefinitely and consume unbounded amounts of memory on infinite iterators.

    {b Complexity:} {e O(n)} *)

val flatten : 'a t t -> 'a t
(** [flatten self] concatenates all sub-iterators in the iterator [self].

    {[
      let items =
        Iter.make [0; 1]
        |> Iter.repeat
        |> Iter.take 6
        |> Iter.flatten
        |> Iter.collect in
      assert (items = [0; 1; 0; 1; 0; 1])
    ]} *)

val cycle : 'a t -> 'a t
(** [cycle self] repeats cyclically the elements of the iterator [self] {i ad
    infinitum}.

    {[
      let items =
        Iter.make [0; 1]
        |> Iter.cycle
        |> Iter.take 6
        |> Iter.collect in
      assert (items = [0; 1; 0; 1; 0; 1])
    ]} *)

val pairwise : 'a t -> ('a * 'a) t
(** [pairwise self] is an iterator with the elements from the iterator [self]
    chained pairwise as tuples

    {[
      let items =
        Iter.iota 5
        |> Iter.pairwise
        |> Iter.collect in
      assert (items = [(1, 2); (2, 3); (3, 4); (4, 5)])
    ]} *)

val powerset : 'a t -> 'a t t
(** [powerset self] is an iterator of all sub-iterators of the iterator
    [self].

    {[
      let items =
        Iter.make ['a'; 'b'; 'c']
        |> Iter.powerset items
        |> Iter.map Iter.collect
        |> Iter.collect in
      assert (items = [[]; ['a']; ['b']; ['c']; ['a'; 'b'];
                       ['a'; 'c']; ['b'; 'c']; ['a'; 'b'; 'c']])
    ]} *)

val intersparse : 'a -> 'a t -> 'a t
(** [intersparse x self] is an iterator with the element [x]
    {i interspersed} between the elements of the iterator [self].

    {[
      let items =
        Iter.make ['a'; 'b'; 'c']
        |> Iter.intersparse 'x'
        |> Iter.collect in
      assert (items = ['a'; 'x'; 'b'; 'x'; 'c'])
    ]} *)

val chain : 'a t list -> 'a t
(** [chain l] concatenates all iterators in the list [l] producing
    a new iterator with all elements flattened. *)


(** {2:iterator_reducers Iterator Reducers} *)

val fold : ('a -> 'r -> 'r) -> 'r -> 'a t -> 'r
(** [fold f r self] reduces the iterator [self] to a single value of type ['r]
    using [f] to combine each element with the previous result, starting with
    [r] and processing the elements from left to right. *)

val fold_while : ('a -> 'r -> ('r -> 'r) -> 'r) -> 'r -> 'a t -> 'r
(** [fold_while f r self] similar to [fold] but passes explicit continuation
    function to the reducing function [f]. The processing will stop when [f]
    returns without calling the continuation function.

    {[
      (* Multiply numbers stopping when 0 is found. *)
      let product =
        Iter.make [32; 4; 5; 23; 0; 6]
        |> fold_while (fun x r continue ->
            if x = 0 then 0 else continue (x * r)) 1 in
      assert (product = 0)

      (* Here is the implementation of the `contains` function with `fold_while`. *)
      let contains x =
        fold_while
          (fun item res continue -> if x = y then true else continue res)
          false
    ]} *)

val fold_right : ('a -> 'r -> 'r) -> 'a t -> 'r -> 'r
(** [fold_right f r self] similar to [fold] but starts processing the
    elements from right to left.

    {e WARNING:} This function is not tail recursive. *)

val collect : 'a t -> 'a list
(** [collect self] collects all the elements form the iterator [self] into a
    list. *)

val reduce : ('a -> 'a -> 'a) -> 'a t -> 'a option
(** [reduce f self] reduces the iterator [self] to a single value, of the same
    type as the elements of [self], using [f] to combine each element with the
    previous result, starting with the first element. Returns [None] is the
    iterator is empty.

    {[
      assert (Iter.iota 6 |> Iter.reduce (+) = Some 15)
    ]} *)

val scan : ('r -> 'a -> 'r) -> 'r -> 'a t -> 'r t
(** [scan f r self] is like [fold] but creates an iterator for intermediate
    results produced by applications [f]. *)

val scan_right : ('a -> 'r -> 'r) -> 'r -> 'a t -> 'r t
(** [scan_right f r self] similar to [scan] but starts processing the
    elements from right to left.

    {e WARNING:} This function is not tail recursive. *)

val sum : int t -> int
(** [product iter] sums all the elements form [iter]. *)

val product : int t -> int
(** [product iter] multiplies all the elements form [iter]. *)


(** {2:conversions Conversions} *)

val list : 'a list -> 'a t
(** [list l] is an iterator with the elements from the list [l]. *)

val to_list : 'a t -> 'a list
(** [to_list self] is a list with elements from the iterator [self]. *)

val string : string -> char t
(** [string s] is an iterator with the characters from the string [s].

    {[
      assert (Iter.string "hello" |> Iter.collect = ['h'; 'e'; 'l'; 'l'; 'o'])
    ]} *)

val to_string : char t -> string
(** [to_string self] is a string with characters from the iterator [self]. *)

val array : 'a array -> 'a t
(** [array a] is an iterator with the elements from the array [a]. *)

val to_array : 'a t -> 'a array
(** [to_array self] is an array with elements from the iterator [self]. *)


(** {2:implemented_instances Implemented Instances} *)

(* include Monoid1     with type 'a t := 'a t *)
(* include Comparable1 with type 'a t := 'a t *)
(* include Equatable1  with type 'a t := 'a t *)


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
