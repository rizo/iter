(** An interface for pure iterators with explicit state.

    This module implements combinators for consuming and transforming
    iterators. External containers can use functors provided in this module
    to implement the iteration extensions. Three types of iterables can be
    implemented: input iterables, index iterables and output iterables.

    Functors for both, polymorphic and monomorphic containers are included. *)


(** {6 Type Definitions} *)

type 'a iter =
  Iter : {
    init : unit -> 'cursor;
    next : 'r . ('a -> 'cursor -> 'r) -> 'r -> 'cursor -> 'r;
    stop : 'cursor -> unit;
  } -> 'a iter
(** The type for iterators. *)

type 'a t = 'a iter
(** A local alias for [iter] type. *)


(** {6 Creating an Iterator} *)

val make : 'a list -> 'a t
(** [make l] is an alias for [of_list] and the default way to create an
    iterator.

    {[
      assert (Iter.make [1; 2; 3] |> Iter.sum = 6)
    ]} *)

val empty : 'a t
(** [empty] is an iterator without any elements.

    {[
      assert (Iter.is_empty Iter.empty = true);
      assert (Iter.length Iter.empty = 0);
    ]} *)

val zero : 'a t
(** [zero] is the empty iterator. *)

val one : 'a -> 'a t
(** [one x] is an iterator with one element [x]. *)

val two : 'a -> 'a -> 'a t
(** [two x1 x2] is an iterator with two elements [x1] and [x2]. *)

val three : 'a -> 'a -> 'a -> 'a t
(** [three x1 x2 x3] is an iterator with three elements [x1], [x2] and [x3]. *)

val with_length : int -> (int -> 'a) -> 'a t
(** [with_length n f] is an iterator of length [n] where each element at
    index [i] is [f i].

    {[
      assert (Iter.with_length 3 negate |> Iter.to_list = [0; -1; -2])
    ]} *)

val range : ?by: int -> int -> int -> int t
(** [range ?by:step start stop] is an iterator of integers from [start]
    (inclusive) to [stop] (exclusive) incremented by [step]. *)

val count : ?by: int -> int -> int t
(** [count ?by:step start] is an infinite iterator of integers from [start]
    (inclusive) incremented by [step]. *)

val iota : ?by: int -> int -> int t
(** [iota ?by:step stop] is an iterator of integers from 0 (inclusive) to
    [stop] (exclusive) incremented by [step]. *)

val repeat : ?n: int -> 'a -> 'a t
(** [repeat a] produces an iterator by repeating [a] {i ad infinitum}.
*
    @see {!repeatedly}

    {[
      let xs = Iter.repeat 'x' in
      assert (xs |> Iter.take 0 = Iter.empty);
      assert (xs |> Iter.take 3 |> Iter.to_list = ['x'; 'x'; 'x']);
      assert (xs = Iter.repeatedly (constantly 'x'));
    ]} *)

val repeatedly : (unit -> 'a) -> 'a t
(** [repeatedly f] produces an iterator by calling [f ()] {e ad infinitum}.

    @see {!repeat} *)

val iterate : ('a -> 'a) -> 'a -> 'a t
(** [iterate f x] is an iterator that produces an infinite sequence of
    repeated applications of [f x], [f (f x)], [f (f (f x))]...

    {[
      let pow2 = iterate (fun x -> 2 * x) 2 in
      assert (pow2 |> Iter.take 10 |> Iter.to_list =
              [2; 4; 8; 16; 32; 64; 128; 256; 512; 1024])
    ]} *)


(** {6 Getting Elements} *)

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

val rest : 'a t -> 'a t option
(** [rest self] is an iterator with all elements of the iterator [self] except
    the first one, or [None] if [self] is empty. *)

val get : int -> 'a t -> 'a option
(** [get n self] is the [n]th element from the iterator [self], or None if [n]
    exceeds its length. *)


(** {6 Finding elements} *)

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
      assert (List.find (fun a -> a < 0) numbers = Some 3);
      assert (List.find (fun a -> a < 0) numbers = None);
    ]} *)

val find_indices : ('a -> bool) -> 'a t -> int t
(** [find_indices p self] is like {!find_index} but finds indices of all
    elements that match the predicate as an iterator. *)

val index : 'a -> 'a t -> int option
(** [index x self] searches for the element [x] in [self] and returns its
    index.

    This function is equivalent to [find_index ((=) x) self].

    {[
      let letters = ['a'; 'b'; 'c'] in
      assert (Iter.index 'b' letters = Some 1);
      assert (Iter.index 'x' letters = None);
    ]} *)

val indices : 'a -> 'a t -> int t
(** [indices x self] searches for the item [x] in [self] and returns all its
    indices as an iterator.

    This function is equivalent to [find_indices ((=) x) self].

    {[
      let letters = ['a'; 'b'; 'c'; 'b'] in
      assert (Iter.indices 'b' letters = Iter.make [1; 3]);
      assert (Iter.indices 'x' letters = Iter.make []);
    ]} *)

val contains : 'a -> 'a t -> bool
(** [contains x self] is true if the element [x] exists in the iterator [self].
    It is equivalent to [any ((=) x) self)].

    {e Note:} This function relies on the polymorphic equality function.

    {[
      assert (contains 'x' ['a'; 'b'; 'x'] = true);
      assert (contains 'x' ['a'; 'b'; 'd'] = false);
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


(** {6 Selecting Elements} *)

val select : ('a -> bool) -> 'a t -> 'a t
val filter : ('a -> bool) -> 'a t -> 'a t
(** [filter predicate self] selects all elements from the iterator [self] for
    which [predicate] returns [true]. It is an exact opposite of {!reject}.

    @see {!reject} *)

val select_indexed : ('a -> bool) -> 'a t -> 'a t
(** [select_indexed f self] is like {!select} but adds the current index to
    the application of [f] on every element. *)

val select_indices : int t -> 'a t -> 'a t
(** [select_indices indices self] selects the elements form the iterator
    [self] whose indices are in the iterator [indices].

    @see {!reject_indices} *)

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

    @see {!range}, {!take}, {!drop}

    {[
      let world =
        "Hello, World!"
        |> Iter.of_string
        |> Iter.slice 7 12
        |> Iter.to_string in
      assert (world = "World")
    ]} *)


(** {6 Excluding Elements} *)

val reject : ('a -> bool) -> 'a t -> 'a t
(** [reject predicate self] rejects all elements from the iterator [self] for
    which [predicate] returns [false]. It is an exact opposite of {!select}.

    @see {!select} *)

val reject_indexed : ('a -> int -> bool) -> 'a t -> 'a t
(** [reject_indexed f self] is like {!reject} but adds the current index to
    the application of [f] on every element. *)

val reject_indices : int t -> 'a t -> 'a t
(** [reject_indices indices self] rejects the elements form the iterator
    [self] whose indices are in the iterator [indices].

    @see {!select_indices} *)

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


(** {6 Transforming Elements} *)

val map : ('a -> 'b) -> 'a t -> 'b t
(** [map f self] is an iterator that applies the function [f] to every element
    of the iterator [self]. *)

val map_indexed : ('a -> int -> 'b) -> 'a t -> 'b t
(** [map_indexed f self] is like {!map} but adds the current index to the
    application of [f] on every element. *)

val find_map : ('a -> 'b option) -> 'a t -> 'b option
(** [find_map f self] is the first element from the iterator [self] that
    produces an optional [Some] value after applying [f], or [None] if there is
    no such element.

    @see {!select_map} *)

val select_map : ('a -> 'b option) -> 'a t -> 'b t
(** [select_map f self] selects all elements from the iterator [self] that
    produce the optional [Some] value after applying [f], rejecting all
    elements that produce [None].

    @see {!find_map}, {!select}, {!reject} *)

val flat_map : ('a -> 'b t) -> 'a t -> 'b t
(** [flat_map f self] is an iterator that works like [map] but flattens nested
    structures produced by [f].

    This function is equivalent to the Monadic [bind] operation. *)


(** {6 Adding Elements} *)

val append : 'a t -> 'a -> 'a t
(** [append x self] appends the element [x] at the end of the iterator
    [self]. *)

val prepend : 'a t -> 'a -> 'a t
(** [prepend x self] prepends the element [x] at the beginning of the iterator
    [self]. *)

val combine : 'a t -> 'a t -> 'a t
(** [combine self other] is the iterator [self] with all elements from the
    iterator [other] appended at the end. *)


(** {6 Sorting Elements} *)

val sort : 'a t -> 'a t

val sort_by : ('a -> 'a -> order) -> 'a t -> 'a t

val sort_on : ('a -> 'b) -> 'a t -> 'a t


(** {6 Conversions} *)

val of_list : 'a list -> 'a t
(** [of_list l] is an iterator with the elements from the list [l]. *)

val to_list : 'a t -> 'a list
(** [to_list self] is a list with elements from the iterator [self]. *)

val of_string : string -> char t
(** [of_string s] is an iterator with the characters from the string [s]. *)

val to_string : string -> char t
(** [to_string self] is a string with characters from the iterator [self]. *)

val of_array : 'a array -> 'a t
(** [of_array a] is an iterator with the elements from the array [a]. *)

val to_array : 'a array -> 'a t
(** [to_array self] is an array with elements from the iterator [self]. *)


(** {6 Iterating Over Elements} *)

val each : ('a -> unit) -> 'a t -> unit
(** [each f iter] applies the effectful function [f] to each element from
    [iter] discarding the results. *)

val indexed : ?from: int -> 'a t -> (int * 'a) t
(** [indexed ?from:n self] adds an index to each element in [self]. *)

val inspect : ('a -> unit) -> 'a t -> 'a t
(** [inspect f self] is an iterator that does something with each element of
    the iterator [self], passing the value on.

    {[
      let res =
        Iter.iota 5
        |> Iter.select (fun x -> x mod 2 = 0)
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


(** {6 Grouping Elements} *)

val group : 'a t -> 'a list t
(** [group iter] groups consecutive elements from [iter] that are equal. *)

val group_by : ('a -> 'a -> bool) -> 'a t -> 'a list t
(** [group_by f iter] groups consecutive elements from [iter] that are equal
    according to the [f] discriminator. *)

val group_on : ('a -> 'b) -> 'a t -> 'a list t
(** [group_on f iter] groups consecutive elements from [iter] that are equal
    after applying [f].

    Equivalent to [group_by (fun a b -> f a = f b) iter] *)


(** {6 Splitting Elements} *)

val split_at : int -> 'a t -> 'a t * 'a t
(** [split_at i self] is a pair with the elements before the index
    [i] (exclusive) and the elements after [i] (inclusive). *)

val next : 'a t -> ('a * 'a t) option
(** [next self] is a pair with the {!first} element of the iterator and its
    {!rest}, or [None] if the iterator is empty.

    @see {!split_at} *)

val split_while : ('a -> bool) -> 'a t -> 'a t * 'a t

val partition : ('a -> bool) -> 'a t -> 'a t * 'a t
(** [partition p iter] separates the elements from [iter] in two disjoint
    iterators: the first contains the elements that matched the predicate [p]
    and the second the ones that did not. *)

val chunks : int -> 'a t -> 'a t t
(** [chunks n iter] splits iterator [iter] into chunks of length [n] producing
    a new iterator. Note: the last chunk may have less then [n] elements. *)


(* Zipping and Unzipping Iterators *)

val zip : 'a t -> 'b t -> ('a * 'b) t

val zip_with : ('a -> 'b -> 'c) -> 'a t -> 'b t -> 'c t

val unzip : ('a * 'b) t -> ('a t * 'b t)


(** {Other Operations} *)

val collect : 'a t -> 'a list
(** [collect iter] collects all the elements form [iter] into a list. *)

val reverse : 'a t -> 'a t
(** [reverse iter] reverses the elements of [iter]. Only works on finite
    iterables.

    {b Complexity:} {e O(n)} *)

val intersparse : 'a -> 'a t -> 'a t
(** [intersparse x iter] takes element [x] and iterator [iter] and `intersperses'
    that element between the elements of the iterator. *)

val cycle : 'a t -> 'a t
(** [cycle iter] repeats cyclically [iter] ad infinitum. *)

val starts_with : ?by:('a -> 'a -> bool) 'a t -> 'a t -> bool
(** [starts_with prefix self] is [true] if each element from [prefix]
    matches the elements at the beginning of [self]. *)

val ends_with : 'a t -> 'a t -> bool
(** [ends_with end_iter iter] is [true] if each element from [end_iter] matches
    the elements at the end of [iter]. *)

val flatten : 'a t t -> 'a t
(** [flatten iters] concatenates all recursive iterators in [iters] *)

val pairs : 'a t -> ('a * 'a) t
(** [pairs self] is an iterator with the elements from the iterator [self]
    chained pairwise as tuples.

    @see {!map_pairs}

    {[
      let pairs =
        Iter.iota 5
        |> Iter.pairs
        |> Iter.collect in
      assert (pairs = [(1, 2); (2, 3); (3, 4); (4, 5)])
    ]} *)

val powerset : 'a t -> 'a t t
(** [powerset self] is the powerset iterator for the elements of [self]. *)

val fold : ('r -> 'a -> 'r) -> 'r -> 'a t -> 'r
(** [fold f init iter] reduces [iter] to a single value using [f] to combine
    every element with the previous result, starting with [init] and processing
    the elements from left to right. *)

val fold_while : ('r -> 'a -> [ `Continue of 'r | `Done of 'r ]) -> 'r -> 'a t -> 'r
(** [fold_while f init iter] similar to [fold] but adds interruption control to
    the combining function [f]. The processing continues until [f] returns
    [`Done] or the iterator is empty. *)

val fold_right : ('a -> 'r -> 'r) -> 'a t -> 'r -> 'r
(** [fold f init iter] similar to [fold] but starts processing the elements
    from right to left. Note: this function is not tail recursive. *)


val is_empty : 'a t -> bool
(** [is_empty iter] is [true] if the iterator has no elements. *)

val length : 'a t -> int

val sum : int t -> int
(** [product iter] sums all the elements form [iter]. *)

val product : int t -> int
(** [product iter] multiplies all the elements form [iter]. *)

val reduce : ('a -> 'a -> 'a) -> 'a t -> 'a option
(** [reduce f iter] reduces [iter] to a single value using [f] to combine every
    element with the previous result, starting with the first element. Returns
    [None] is the iterator is empty. *)

val chain : 'a t list -> 'a t
(** [chain iter_list] concatenates the list of iterators [iter_list] producing
    a new iterator. *)

val merge : ('a -> 'b -> 'c option) -> 'a t -> 'b t -> 'c t

val scan : ('r -> 'a -> 'r) -> 'r -> 'a t -> 'r t

val scan_right : ('r -> 'a -> 'r) -> 'r -> 'a t -> 'r t


(* Instances *)

val equal : ('a -> 'a -> bool) -> 'a t -> 'a t -> bool
(** [equal eq iter1 iter2] is [true] if every element in [iter1] is
    sequentially equal to elements in [iter2]. *)

val compare : ('a -> 'a -> int) -> 'a t -> 'a t -> int
(** [compare cmp iter1 iter2] sequentially compares each element from [iter1]
    and [iter2] returning [0] if all the elements are equal, [1] if some
    leftmost element from [iter1] is greater then the element with the same
    index from [iter2], and [-1] otherwise. *)



(* Iterables *)

(* Monomorphic Input Iterables *)

module type Input'0 = sig
  type t
  type element

  val all          : (element -> bool) -> t -> bool
  val any          : (element -> bool) -> t -> bool
  val chain        : t list -> element iter
  val chunks       : int -> t -> element iter iter
  val compare      : (element -> element -> int) -> t -> t -> int
  val contains     : element -> t -> bool
  val cycle        : t -> element iter
  val dedup        : ?by: (element -> element -> bool) -> t -> element iter
  val drop         : int -> t -> element iter
  val drop_while   : (element -> bool) -> t -> element iter
  val each         : (element -> unit) -> t -> unit
  val ends_with    : t -> t -> bool
  val enumerate    : ?from: int -> t -> (int * element) iter
  val equal        : (element -> element -> bool) -> t -> t -> bool
  val filter       : (element -> bool) -> t -> element iter
  val filter_map   : (element -> 'b option) -> t -> 'b iter
  val find         : (element -> bool) -> t -> element option
  val find_index   : (element -> bool) -> t ->  int option
  val find_indices : (element -> bool) -> t -> int iter
  val fold         : ('r -> element -> 'r) -> 'r -> t -> 'r
  val fold_while   : ('r -> element -> [ `Continue of 'r | `Done of 'r ]) -> 'r -> t -> 'r
  val fold_right   : (element -> 'r -> 'r) -> t -> 'r -> 'r
  val group        : t -> element list iter
  val group_by     : (element -> element -> bool) -> t -> element list iter
  val group_on     : (element -> 'b) -> t -> element list iter
  val head         : t -> element option
  val index        : element -> t -> int option
  val indices      : element -> t -> int iter
  val intersparse  : t -> element -> element iter
  val is_empty     : t -> bool
  val join         : string -> t -> string
  val merge        : (element -> element -> 'a option) -> t -> t -> 'a iter
  val last         : t -> element option
  val len          : t -> int
  val map          : (element -> 'b) -> t -> 'b iter
  val max          : ?by:(element -> element -> int) -> t -> element option
  val min          : ?by:(element -> element -> int) -> t -> element option
  val nth          : int -> t -> element option
  val pairwise     : t -> (element * element) iter
  val partition    : (element -> bool) -> t -> element iter * element iter
  val powerset     : t -> element iter iter
  val product      : t -> int
  val reduce       : (element -> element -> element) -> t -> element option
  val reject       : (element -> bool) -> t -> element iter
  val reverse      : t -> element iter
  val scan         : ('r -> element -> 'r) -> 'r -> t -> 'r iter
  val scan_right   : ('r -> element -> 'r) -> 'r -> t -> 'r iter
  val slice        : t -> int -> int -> element iter
  val sort         : t -> element iter
  val sort_by      : (element -> element -> int) -> t -> element iter
  val sort_on      : (element -> 'b) -> t -> element iter
  val starts_with  : t -> t -> bool
  val split_at     : int -> t -> element iter * element iter
  val split_while  : (element -> bool) -> t -> element iter * element iter
  val sum          : t -> int
  val tail         : t -> element iter option
  val take         : int -> t -> element iter
  val take_every   : int -> t -> element iter
  val take_while   : (element -> bool) -> t -> element iter
  val take_last    : int -> t -> element iter
  val to_list      : t -> element list
  val uniq         : t -> element iter
  val uniq_by      : (element -> element -> bool) -> t -> element iter
  val zip          : t -> t -> (element * element) iter
  val zip_with     : (element -> element -> 'a) -> t -> t -> 'a iter
end


module Input'0 : sig
  module type Base = sig
    type t
    type element

    val next : t -> (element * t) option
  end

  module Make(M : Base) : (Input'0 with type t := M.t and type element := M.element)
end


(* Polymorphic Input Iterables *)

module type Input'1 = sig
  type 'a t

  val all          : ('a -> bool) -> 'a t -> bool
  val any          : ('a -> bool) -> 'a t -> bool
  val concat       : 'a t -> 'a t -> 'a iter
  val chain        : 'a t list -> 'a iter
  val chunks       : int -> 'a t -> 'a iter iter
  val compare      : ('a -> 'a -> int) -> 'a t -> 'a t -> int
  val compress     : 'a t -> bool t -> 'a iter
  val contains     : 'a -> 'a t -> bool
  val cycle        : 'a t -> 'a iter
  val dedup        : ?by: ('a -> 'a -> bool) -> 'a t -> 'a iter
  val drop         : int -> 'a t -> 'a iter
  val drop_while   : ('a -> bool) -> 'a t -> 'a iter
  val each         : ('a -> unit) -> 'a t -> unit
  val ends_with    : 'a t -> 'a t -> bool
  val enumerate    : ?from: int -> 'a t -> (int * 'a) iter
  val equal        : ('a -> 'a -> bool) -> 'a t -> 'a t -> bool
  val filter       : ('a -> bool) -> 'a t -> 'a iter
  val filter_map   : ('a -> 'b option) -> 'a t -> 'b iter
  val find         : ('a -> bool) -> 'a t -> 'a option
  val find_index   : ('a -> bool) -> 'a t ->  int option
  val find_indices : ('a -> bool) -> 'a t -> int iter
  val flat_map     : ('a -> 'b t) -> 'a t -> 'b iter
  val flatten      : 'a t t -> 'a iter
  val fold         : ('r -> 'a -> 'r) -> 'r -> 'a t -> 'r
  val fold_while   : ('r -> 'a -> [ `Continue of 'r | `Done of 'r ]) -> 'r -> 'a t -> 'r
  val fold_right   : ('a -> 'r -> 'r) -> 'a t -> 'r -> 'r
  val group        : 'a t -> 'a list iter
  val group_by     : ('a -> 'a -> bool) -> 'a t -> 'a list iter
  val group_on     : ('a -> 'b) -> 'a t -> 'a list iter
  val head         : 'a t -> 'a option
  val index        : 'a -> 'a t -> int option
  val indices      : 'a -> 'a t -> int iter
  val intersparse  : 'a t -> 'a -> 'a iter
  val is_empty     : 'a t -> bool
  val join         : string -> string t -> string
  val merge        : ('a -> 'b -> 'c option) -> 'a t -> 'b t -> 'c iter
  val last         : 'a t -> 'a option
  val len          : 'a t -> int
  val map          : ('a -> 'b) -> 'a t -> 'b iter
  val max          : ?by:('a -> 'a -> int) -> 'a t -> 'a option
  val min          : ?by:('a -> 'a -> int) -> 'a t -> 'a option
  val nth          : int -> 'a t -> 'a option
  val pairwise     : 'a t -> ('a * 'a) iter
  val partition    : ('a -> bool) -> 'a t -> 'a iter * 'a iter
  val powerset     : 'a t -> 'a iter iter
  val product      : int t -> int
  val reduce       : ('a -> 'a -> 'a) -> 'a t -> 'a option
  val reject       : ('a -> bool) -> 'a t -> 'a iter
  val reverse      : 'a t -> 'a iter
  val scan         : ('r -> 'a -> 'r) -> 'r -> 'a t -> 'r iter
  val scan_right   : ('r -> 'a -> 'r) -> 'r -> 'a t -> 'r iter
  val slice        : 'a t -> int -> int -> 'a iter
  val sort         : 'a t -> 'a iter
  val sort_by      : ('a -> 'a -> int) -> 'a t -> 'a iter
  val sort_on      : ('a -> 'b) -> 'a t -> 'a iter
  val starts_with  : 'a t -> 'a t -> bool
  val split_at     : int -> 'a t -> 'a iter * 'a iter
  val split_while  : ('a -> bool) -> 'a t -> 'a iter * 'a iter
  val sum          : int t -> int
  val tail         : 'a t -> 'a iter option
  val take         : int -> 'a t -> 'a iter
  val take_every   : int -> 'a t -> 'a iter
  val take_while   : ('a -> bool) -> 'a t -> 'a iter
  val take_last    : int -> 'a t -> 'a iter
  val to_list      : 'a t -> 'a list
  val unzip        : ('a * 'b) t -> 'a iter * 'b iter
  val uniq         : 'a t -> 'a iter
  val uniq_by      : ('a -> 'a -> bool) -> 'a t -> 'a iter
  val zip          : 'a t -> 'b t -> ('a * 'b) iter
  val zip_with     : ('a -> 'b -> 'c) -> 'a t -> 'b t -> 'c iter
end


module Input'1 : sig
  module type Base = sig
    type 'a t

    val next : 'a t -> ('a * 'a t) option
  end

  module Make(M : Base) : (Input'1 with type 'a t := 'a M.t)
end


(* Default input iterable interface *)
module type Input = Input'1

(* Default input iterable *)
module Input = Input'1


(* Index Iterable *)

module type Index'1 = sig
  type 'a t

  include Input'1 with type 'a t := 'a t

  val len   : 'a t -> int
  val get   : 'a t -> int -> 'a option
  val last  : 'a t -> 'a option
  val slice : 'a t -> int -> int -> 'a iter
  val each  : ('a -> unit) -> 'a t -> unit
end


module Index'1 : sig
  module type Base = sig
    type 'a t

    val len : 'a t -> int
    val idx : 'a t -> int -> 'a
  end

  module Make(M : Base) : (Index'1 with type 'a t := 'a M.t)
end

module type Index = Index'1
module Index = Index'1

