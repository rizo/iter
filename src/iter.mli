(** An interface for pure iterators with explicit state.

    This module implements combinators for consuming and transforming
    iterators. External containers can use functors provided in this module
    to implement the iteration extensions. Three types of iterables can be
    implemented: input iterables, index iterables and output iterables.
    
    Functors for both, polymorphic and monomorphic containers are included. *)

type 'a iter = Iter : 's * ('s -> ('a * 's) option) -> 'a iter
(** The type for iterators. *)

type 'a t = 'a iter
(** A local alias for [iter] type. *)

val append  : 'a t -> 'a -> 'a t
(** [append iter a] appends the item [a] at the end of [iter]. *)

val prepend : 'a t -> 'a -> 'a t
(** [prepend iter a] prepends the item [a] at the begining of [iter]. *)

val all : ('a -> bool) -> 'a t -> bool
(** [all ppred iter] is [true] if all the elements from [iter] match the
    predicate [pred]. *)

val any : ('a -> bool) -> 'a t -> bool
(** [any ppred iter] is [true] if at least one element from [iter] matches the
    predicate [pred]. *)

val concat : 'a t -> 'a t -> 'a t
(** [concat iter1 iter2] concatenates the iterators [iter1] and [iter2]
    producing a new iterator. *)

val chain : 'a t list -> 'a t
(** [chain iter_list] concatenates the list of iterators [iter_list] producing
    a new iterator. *)

val chunks : int -> 'a t -> 'a t t
(** [chunks n iter] splits iterator [iter] into chunks of length [n] producing
    a new iterator. Note: the last chunk may have less then [n] elements. *)

val compare : ('a -> 'a -> int) -> 'a t -> 'a t -> int
(** [compare cmp iter1 iter2] sequentially compares each element from [iter1]
    and [iter2] returning [0] if all the elements are equal, [1] if some
    leftmost element from [iter1] is greater then the element with the same
    index from [iter2], and [-1] otherwise. *)

val compress : 'a t -> bool t -> 'a t
(** [compress iterable selector] excludes the elements form [iterable] for
    which the corresponding selector index is [false]. *)

val contains : 'a -> 'a t -> bool
(** [contains x iter] is [true] if [x] is an element of [iter]. *)

val ints : int t
(** [ints] is the sequence of all non-negative integers starting with zero and
    to infinity. *)

val cycle : 'a t -> 'a t
(** [cycle iter] repeats cyclically [iter] ad infinitum. *)

val dedup : ?by: ('a -> 'a -> bool) -> 'a t -> 'a t

val drop : int -> 'a t -> 'a t
(** [drop n iter] drops exactly [n] leftmost elements from [iter] producing an
    iterator with the remaining elements. *)

val drop_while : ('a -> bool) -> 'a t -> 'a t
(** [drop_while p iter] drops the leftmost elements from [iter] that match the
    predicate [p] producing an iterator with the remaining elements. *)

val each : ('a -> unit) -> 'a t -> unit
(** [each f iter] applies the effectful function [f] to each element from
    [iter] discarding the results. *)

val empty : 'a t
(** [empty] is an iterator without elements. *)

val ends_with : 'a t -> 'a t -> bool
(** [ends_with end_iter iter] is [true] if each element from [end_iter] matches
    the elements at the end of [iter]. *)

val enumerate : ?from: int -> 'a t -> (int * 'a) t
(** [enumerate ?from:n iter] adds an index to each element in [iter]. *)

val equal : ('a -> 'a -> bool) -> 'a t -> 'a t -> bool
(** [equal eq iter1 iter2] is [true] if every element in [iter1] is
    sequentially equal to elements in [iter2]. *)

val filter : ('a -> bool) -> 'a t -> 'a t
(** [filter p iter] selects all elements from [iter] for which [p] is [true].
    An exact opposite of {!val:reject}. *)

val filter_map : ('a -> 'b option) -> 'a t -> 'b t
(** [filter_map f iter] selects all elements from [iter] that are [Some] after
    the application of [f] rejecting all [None] elements. *)

val find : ('a -> bool) -> 'a t -> 'a option
(** [find p iter] returns the first leftmost element from [iter] matching the
    predicate [p], or [None] if there is no such element. *)

val find_index : ('a -> bool) -> 'a t ->  int option
(** [find p iter] returns the index of the first leftmost element from [itr]
    matching the predicate [p], or [None] if there is no such element. *)

val find_indices : ('a -> bool) -> 'a t -> int t
(** [find_indices p iter] returns indices of all the elements from [iter]
    matching the predicate [p]. *)

val flat_map : ('a -> 'b t) -> 'a t -> 'b t

val flatten : 'a t t -> 'a t
(** [flatten iters] concatenates all recursive iterators in [iters] *)

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

val group : 'a t -> 'a list t
(** [group iter] groups consecutive elements from [iter] that are equal. *)

val group_by : ('a -> 'a -> bool) -> 'a t -> 'a list t
(** [group_by f iter] groups consecutive elements from [iter] that are equal
    according to the [f] discriminator. *)

val group_on : ('a -> 'b) -> 'a t -> 'a list t
(** [group_on f iter] groups consecutive elements from [iter] that are equal
    after applying [f].

    Equivalent to [group_by (fun a b -> f a = f b) iter] *)

val head : 'a t -> 'a option
(** [head iter] is the first element of [iter] or [None] if [iter] is empty. *)

val index : 'a -> 'a t -> int option
(** [index x iter] returns the index of the first leftmost element from [itr]
    that is equal to [x], or [None] if there is no such element. *)

val indices: 'a -> 'a t -> int t
(** [indices x iter] returns indices of all the elements from [iter]
    that are equal to [x]. *)

val init : int -> (int -> 'a) -> 'a t
(** [init n f] is an iterator of length [n] for which the element at index [i]
    is [f i]. *)

val intersparse : 'a -> 'a t -> 'a t
(** [intersparse x iter] takes element [x] and iterator [iter] and `intersperses'
    that element between the elements of the iterator. *)

val is_empty : 'a t -> bool
(** [is_empty iter] is [true] if the iterator has no elements. *)

val iterate : ('a -> 'a) -> 'a -> 'a t

val join : string -> string t -> string

val merge : ('a -> 'b -> 'c option) -> 'a t -> 'b t -> 'c t

val last : 'a t -> 'a option

val take_last : int -> 'a t -> 'a t

val len : 'a t -> int

val map : ('a -> 'b) -> 'a t -> 'b t

val max : ?by:('a -> 'a -> int) -> 'a t -> 'a option

val min : ?by:('a -> 'a -> int) -> 'a t -> 'a option

val nth : int -> 'a t -> 'a option
(** [nth n iter] gets the [n]th element from the [iter] or None if [n] exceeds
    the length of [iter]. *)

val pairwise : 'a t -> ('a * 'a) t

val partition : ('a -> bool) -> 'a t -> 'a t * 'a t
(** [partition p iter] separates the elements from [iter] in two disjoint
    iterators: the first contains the elements that matched the predicate [p]
    and the second the ones that did not. *)

val powerset : 'a t -> 'a t t

val product : int t -> int
(** [product iter] multiplies all the elements form [iter]. *)

val zero : 'a t
(** [zero] is the empty iterator. *)

val one : 'a -> 'a t
(** [one a] is the iterator with element [a]. *)

val two : 'a -> 'a -> 'a t
(** [two a b] is the iterator with elements [a] and [b]. *)

val three : 'a -> 'a -> 'a -> 'a t
(** [three a b c] is the iterator with elements [a], [b] and [c]. *)

val range : ?by: int -> int -> int -> int t
(** [range ?by:step start stop] is an iterator of integers from [start]
    (inclusive) to [stop] (exclusive) incremented by [step]. *)

val iota : ?by: int -> int -> int t
(** [iota ?by:step stop] is an iterator of integers from 0 (inclusive) to
    [stop] (exclusive) incremented by [step]. *)

val reduce : ('a -> 'a -> 'a) -> 'a t -> 'a option
(** [reduce f iter] reduces [iter] to a single value using [f] to combine every
    element with the previous result, starting with the first element. Returns
    [None] is the iterator is empty. *)

val reject : ('a -> bool) -> 'a t -> 'a t
(** [reject p iter] rejects all elements from [iter] for which [p] is [false].
    An exact opposite of {!val:filter}. *)

val repeat : 'a -> 'a t
(** [repeat x] produces an iterator by repeating [x] ad infinitum. *)

val repeatedly : (unit -> 'a) -> 'a t
(** [repeatedly f] produces an iterator by calling [f] ad infinitum. *)

val remove : ?eq: ('a -> 'a -> bool) -> 'a -> 'a t -> 'a t
(** [remove ?eq x iter] removes the first occurrence of [x] from [iter] using
    the comparison function [eq]. *)

val remove_at : int -> 'a t -> 'a t
(** [remove_at i iter] removes the element from [iter] at index [i]. *)

val reverse : 'a t -> 'a t
(** [reverse iter] reverses the elements of [iter]. Only works on finite
    iterables.

    {b Complexity:} {e O(n)} *)

val scan : ('r -> 'a -> 'r) -> 'r -> 'a t -> 'r t

val scan_right : ('r -> 'a -> 'r) -> 'r -> 'a t -> 'r t

val slice : 'a t -> int -> int -> 'a t

val sort : 'a t -> 'a t

val sort_by : ('a -> 'a -> int) -> 'a t -> 'a t

val sort_on : ('a -> 'b) -> 'a t -> 'a t

val starts_with : 'a t -> 'a t -> bool
(** [starts_with start_iter iter] is [true] if each element from [start_iter] matches
    the elements at the begining of [iter]. *)

val split_at : int -> 'a t -> 'a t * 'a t

val split_while : ('a -> bool) -> 'a t -> 'a t * 'a t

val sum : int t -> int
(** [product iter] sums all the elements form [iter]. *)

val tail : 'a t -> 'a t
(** [tail iter] is the tail of [iter], i.e., all elements except the first one. *)

val take : int -> 'a t -> 'a t
(** [take n iter] takes exactly [n] leftmost elements from iter producing a new
    iterator. *)

val take_every : int -> 'a t -> 'a t
(** [take_every n iter] takes every [n]th element from [iter], i.e. the
    elements whose index is multiple of [n]. *)

val take_while : ('a -> bool) -> 'a t -> 'a t
(** [take_while n iter] takes the leftmost elements from [iter] that match the
    predicate [p]. *)

val to_list : 'a t -> 'a list
(** [to_list iter] collects all the elements form [iter] into a list. *)

val collect : 'a t -> 'a list
(** [collect iter] collects all the elements form [iter] into a list. *)

val of_list : 'a list -> 'a t
(** [iter list] creates an iterator with the elements from [list]. *)

val iter : 'a list -> 'a t
(** [iter list] creates an iterator with the elements from [list]. *)

val unzip : ('a * 'b) t -> ('a t * 'b t)

val uniq : 'a t -> 'a t

val uniq_by : ('a -> 'a -> bool) -> 'a t -> 'a t

val view : 'a t -> ('a * 'a t) option
(** [view iter] shows the head and the tail of [iter] or [None] if the iterator
    is empty. *)

val zip : 'a t -> 'b t -> ('a * 'b) t

val zip_with : ('a -> 'b -> 'c) -> 'a t -> 'b t -> 'c t


(* Iterables *)

(* Input Iterable *)

module Input : sig

  (* Monomorphic Iterables *)

  module type Sig0 = sig
    type t
    type item
    val iter : t -> item iter
  end

  module type Ext0 = sig
    type t
    type item

    val all          : (item -> bool) -> t -> bool
    val any          : (item -> bool) -> t -> bool
    val chain        : t list -> item iter
    val chunks       : int -> t -> item iter iter
    val compare      : (item -> item -> int) -> t -> t -> int
    val contains     : item -> t -> bool
    val cycle        : t -> item iter
    val dedup        : ?by: (item -> item -> bool) -> t -> item iter
    val drop         : int -> t -> item iter
    val drop_while   : (item -> bool) -> t -> item iter
    val each         : (item -> unit) -> t -> unit
    val ends_with    : t -> t -> bool
    val enumerate    : ?from: int -> t -> (int * item) iter
    val equal        : (item -> item -> bool) -> t -> t -> bool
    val filter       : (item -> bool) -> t -> item iter
    val filter_map   : (item -> 'b option) -> t -> 'b iter
    val find         : (item -> bool) -> t -> item option
    val find_index   : (item -> bool) -> t ->  int option
    val find_indices : (item -> bool) -> t -> int iter
    val fold         : ('r -> item -> 'r) -> 'r -> t -> 'r
    val fold_while   : ('r -> item -> [ `Continue of 'r | `Done of 'r ]) -> 'r -> t -> 'r
    val fold_right   : (item -> 'r -> 'r) -> t -> 'r -> 'r
    val group        : t -> item list iter
    val group_by     : (item -> item -> bool) -> t -> item list iter
    val group_on     : (item -> 'b) -> t -> item list iter
    val head         : t -> item option
    val index        : item -> t -> int option
    val indices      : item -> t -> int iter
    val intersparse  : t -> item -> item iter
    val is_empty     : t -> bool
    val join         : string -> t -> string
    val merge        : (item -> item -> 'a option) -> t -> t -> 'a iter
    val last         : t -> item option
    val len          : t -> int
    val map          : (item -> 'b) -> t -> 'b iter
    val max          : ?by:(item -> item -> int) -> t -> item option
    val min          : ?by:(item -> item -> int) -> t -> item option
    val nth          : int -> t -> item option
    val pairwise     : t -> (item * item) iter
    val partition    : (item -> bool) -> t -> item iter * item iter
    val powerset     : t -> item iter iter
    val product      : t -> int
    val reduce       : (item -> item -> item) -> t -> item option
    val reject       : (item -> bool) -> t -> item iter
    val reverse      : t -> item iter
    val scan         : ('r -> item -> 'r) -> 'r -> t -> 'r iter
    val scan_right   : ('r -> item -> 'r) -> 'r -> t -> 'r iter
    val slice        : t -> int -> int -> item iter
    val sort         : t -> item iter
    val sort_by      : (item -> item -> int) -> t -> item iter
    val sort_on      : (item -> 'b) -> t -> item iter
    val starts_with  : t -> t -> bool
    val split_at     : int -> t -> item iter * item iter
    val split_while  : (item -> bool) -> t -> item iter * item iter
    val sum          : t -> int
    val tail         : t -> item iter
    val take         : int -> t -> item iter
    val take_every   : int -> t -> item iter
    val take_while   : (item -> bool) -> t -> item iter
    val take_last    : int -> t -> item iter
    val to_list      : t -> item list
    val uniq         : t -> item iter
    val uniq_by      : (item -> item -> bool) -> t -> item iter
    val zip          : t -> t -> (item * item) iter
    val zip_with     : (item -> item -> 'a) -> t -> t -> 'a iter
  end

  module Make0(M : Sig0) : (Ext0 with type t := M.t and type item := M.item)


  (* Polymorphic Iterables *)

  module type Sig1 = sig
    type 'a t
    val iter : 'a t -> 'a iter
  end

  module type Ext1 = sig
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
    val tail         : 'a t -> 'a iter
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

  module Make1(M : Sig1) : (Ext1 with type 'a t := 'a M.t)


  (* Default Polymorphic Iterables *)

  module type Sig = Sig1
  module type Ext = Ext1

  module Make = Make1
end


(* Index Iterable *)

module Index : sig
  module type Sig1 = sig
    type 'a t

    val len : 'a t -> int
    val idx : 'a t -> int -> 'a
  end

  module type Ext1 = sig
    type 'a t

    include Input.Sig1 with type 'a t := 'a t
    include Input.Ext1 with type 'a t := 'a t

    val len   : 'a t -> int
    val get   : 'a t -> int -> 'a option
    val last  : 'a t -> 'a option
    val slice : 'a t -> int -> int -> 'a iter
    val each  : ('a -> unit) -> 'a t -> unit
  end

  module Make1(M : Sig1) : (Ext1 with type 'a t := 'a M.t)


  (* Default Polymorphic Iterables *)

  module type Sig = Sig1
  module type Ext = Ext1

  module Make = Make1
end


