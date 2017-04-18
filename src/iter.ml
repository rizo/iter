
(* Base Definitions *)

type ('a, 'b) either = Left of 'a | Right of 'b

let (//) opt def =
  match opt with
  | Some x -> x
  | None -> def

let (<<) f g x = f (g x)
let (>>) g f x = f (g x)


(* Iterators *)

type 'a iter = Iter : 's * ('s -> ('a * 's) option) -> 'a iter

type 'a t = 'a iter

let empty = Iter ((), fun () -> None)

let ints =
  Iter (0, fun i -> Some (i, i + 1))

let range ?by:(step = 1) start stop =
  let next i =
    if i >= stop then None
    else Some (i, i + step) in
  Iter (start, next)

let iota ?by stop = range ?by 0 stop

let repeat x =
  Iter ((), fun () -> Some (x, ()))

let repeatedly f =
  Iter ((), fun () -> Some (f (), ()))

let iterate f x =
  Iter (x, fun x -> Some (x, f x))

let init n f =
  let next i =
    if i = n then None
    else Some (f i, i + 1) in
  Iter (0, next)

let view (Iter (s0, next)) =
  match next s0 with
  | Some (a, s1) -> Some (a, Iter (s1, next))
  | None -> None

let append (Iter (s0, next)) a =
  let next' (s, is_done) =
    if is_done then None
    else match next s with
      | None         -> Some (a, (s, true))
      | Some (a, s') -> Some (a, (s', is_done)) in
  Iter ((s0, false), next')

let prepend (Iter (s0, next)) x =
  let next' (s, opt) =
    match opt with
    | Some x ->
      begin match next s with
        | Some (a, s') -> Some (x, (s', Some a))
        | None         -> Some (x, (s,  None))
      end
    | None -> None in
  Iter ((s0, Some x), next')

let zero = empty

let one a =
  Iter (false, function false -> Some (a, true) | true -> None)

let two a b =
  append (one a) b

let three a b c =
  append (two a b) c

let fold f r0 (Iter (s0, next)) =
  let rec loop r s =
    match next s with
    | None -> r
    | Some (a, s') -> loop (f r a) s' in
  loop r0 s0

let fold_while f r0 (Iter (s0, next)) =
  let rec loop r s =
    match next s with
    | Some (a, s') ->
      begin match f r a with
        | `Continue r' -> loop r' s'
        | `Done r' -> r'
      end
    | None -> r in
  loop r0 s0

let reduce f iter =
  match view iter with
  | Some (a, iter') -> Some (fold f a iter')
  | None -> None

let fold_right f (Iter (s0, next)) r0 =
  let rec loop r s =
    match next s with
    | None -> r
    | Some (a, s') -> f a (loop r s') in
  loop r0 s0

let all p iter =
  fold_while
    (fun r a -> if not (p a) then `Done false else `Continue r)
    true
    iter

let any p iter =
  fold_while
    (fun r a -> if p a then `Done true else `Continue r)
    false
    iter

let concat (Iter (s0_a, next_a)) (Iter (s0_b, next_b)) =
  let next' = function
    | Left s_a ->
      begin match next_a s_a with
        | Some (a, s_a') -> Some (a, Left s_a')
        | None ->
          begin match next_b s0_b with
            | Some (b, s_b') -> Some (b, Right s_b')
            | None -> None
          end
      end
    | Right s_b ->
      begin match next_b s_b with
        | Some (b, s_b') -> Some (b, Right s_b')
        | None -> None
      end in
  Iter (Left s0_a, next')

let chain iter_list =
  let rec loop r xs =
    match xs with
    | x :: xs' -> loop (concat r x)  xs'
    | [] -> r in
  match iter_list with
  | [] -> empty
  | x :: xs -> loop x xs

let chunks n iter =
  failwith "todo"

let compare cmp iter iter = failwith "todo"

let compress iter selector      = failwith "todo"

let contains x iter =
  fold_while
    (fun r a -> if a = x then `Done true else `Continue r)
    false
    iter

let rec cycle (Iter (s0, next)) =
  let next' s =
    match next s with
    | None -> next s0
    | some -> some in
  Iter (s0, next')

let dedup ?by iter =
  failwith "todo"

let drop n (Iter (s0, next)) =
  let next' (s, i) =
    let rec loop s i =
      if i = 0 then
        match next s with
        | Some (a, s') -> Some (a, (s', i))
        | None -> None
      else
        match next s with
        | Some (_, s') -> loop s' (i - 1)
        | None -> None in
    loop s i in
  Iter ((s0, n), next')

let drop_while p (Iter (s0, next)) =
  let next' (s, dropping) =
    let rec loop s =
      match next s with
      | Some (a, s') when p a && dropping -> loop s'
      | Some (a, s') -> Some (a, (s', false))
      | None -> None in
    loop s in
  Iter ((s0, true), next')

let each f self =
  fold (fun () a -> f a) () self

let ends_with target iter       = failwith "todo"

let enumerate ?from:(start = 0) (Iter (s0, next)) =
  let next' (s, i) =
    match next s with
    | Some (a, s') -> Some ((i, a), (s', i + 1))
    | None -> None in
  Iter ((s0, start), next')

let equal eq iter iter    = failwith "todo"

let filter p (Iter (s0, next)) =
  let next' s =
    let rec loop s =
      match next s with
      | Some (a, s') when p a -> Some (a, s')
      | Some (_, s') -> loop s'
      | None -> None in
    loop s in
  Iter (s0, next')

let map f (Iter (s0, next)) =
  let next' s =
    match next s with
    | Some (a, s') -> Some (f a, s')
    | None -> None in
  Iter (s0, next')

let filter_map f (Iter (s0, next)) =
  let next' s =
    let rec loop s =
      match next s with
      | Some (a, s') ->
        begin match f a with
          | Some b -> Some (b, s')
          | None -> loop s'
        end
      | None -> None in
    loop s in
  Iter (s0, next')

let find p iter =
  fold_while
    (fun r a -> if p a then `Done (Some a) else `Continue r)
    None
    iter

let find_index p iter =
  fold_while
    (fun r (i, a) -> if p a then `Done (Some i) else `Continue r)
    None
    (enumerate iter)

let find_indices p iter =
  iter
  |> enumerate
  |> filter (fun (i, a) -> p a)
  |> map    (fun (i, a) -> i)

let flat_map f iter             = failwith "todo"
let flatten iter                = failwith "todo"

let group iter                  = failwith "todo"

let group_by p (Iter (s0, next)) =
  let next' (s, g0, is_done) =
    if is_done then None
    else
      let rec loop g s =
        match g, next s with
        | []       , Some (a, s')               -> loop [a]      s'
        | last :: _, Some (a, s') when p last a -> loop (a :: g) s'
        |    _ :: _, Some (a, s')               -> Some (List.rev g, (s', [a], is_done))
        |    _ :: _, None                       -> Some (List.rev g, (s , [] , true))
        | []       , None                       -> None in
      loop g0 s in
  Iter ((s0, [], false), next')

let group_on f iter =
  group_by (fun a b -> f a = f b) iter

let head (Iter (s0, next)) =
  match next s0 with
  | Some (x, _) -> Some x
  | None -> None

let index x iter =
  find_index ((=) x) iter

let indices x iter =
  find_indices ((=) x) iter

let intersparse iter x = failwith "todo"

let is_empty (Iter (s0, next)) =
  match next s0 with
  | Some _ -> false
  | None   -> true

let join sep iter     = failwith "todo"
let merge f iter iter = failwith "todo"

let last iter =
  fold (fun _ a -> Some a) None iter

let len self =
  fold (fun r _ -> r + 1) 0 self

let max ?by iter =
  let cmp = by // Pervasives.compare in
  let max' x y =
    match cmp x y with
    | 1 -> x
    | _ -> y in
  reduce max' iter

let min ?by iter =
  let cmp = by // Pervasives.compare in
  let min' x y =
    match cmp x y with
    | -1 -> x
    | _  -> y in
  reduce min' iter

let nth n iter =
  fold (fun r (i, a) -> if i = n then Some a else r)
    None (enumerate iter)

let pairwise iter               = failwith "todo"
let partition p iter            = failwith "todo"
let powerset iter               = failwith "todo"
let product iter                = failwith "todo"

let reject p iter =
  filter (not << p) iter

let remove ?(eq = (=)) x (Iter (s0, next)) =
  let next' s =
    match next s with
    | Some (a, s') when eq a x -> next s'
    | original -> original in
  Iter (s0, next')

let remove_at i iter            = failwith "todo"

let reverse iter                = failwith "todo"
let scan f z iter               = failwith "todo"
let scan_right f z iter         = failwith "todo"
let slice iter n m              = failwith "todo"
let sort iter                   = failwith "todo"
let sort_by f iter              = failwith "todo"
let sort_on f iter              = failwith "todo"
let starts_with target iter     = failwith "todo"
let split_at i iter             = failwith "todo"
let split_while p iter          = failwith "todo"

let sum iter =
  fold (+) 0 iter

let tail (Iter (s0, next)) =
  match next s0 with
  | Some (_, s1) -> Some (Iter (s1, next))
  | None -> None

let take n (Iter (s0, next)) =
  let next' (s, i) =
    if i <= 0 then None
    else match next s with
      | Some (a, s') -> Some (a, (s', i - 1))
      | None -> None in
  Iter ((s0, n), next')

let take_every n iter =
  iter
  |> enumerate
  |> filter (fun (i, _) -> i mod n = 0)
  |> map    (fun (_, a) -> a)

let take_while p iter           = failwith "todo"
let take_last n iter            = failwith "todo"

let to_list self =
  List.rev (fold (fun acc x -> x :: acc) [] self)

let collect = to_list

let of_list l =
  let next = function
    | []    -> None
    | x::xs -> Some (x, xs) in
  Iter (l, next)

let iter = of_list

let unzip iter            = failwith "todo"
let uniq iter             = failwith "todo"
let uniq_by f iter        = failwith "todo"
let zip iter iter         = failwith "todo"
let zip_with f iter iter  = failwith "todo"


(* Monomorphic Input Iterables *)

module type Input'0 = sig
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
  val tail         : t -> item iter option
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


module Input'0 = struct
  module type Base = sig
    type t
    type item

    val next : t -> (item * t) option
  end

  module Make(M : Base) : (Input'0 with type    t := M.t
                                    and type item := M.item) = struct
    let iter iterable =
      Iter (iterable, M.next)

    let all p iterable                  = all p (iter iterable)
    let any p iterable                  = any p (iter iterable)
    let concat iterable1 iterable2      = concat (iter iterable1) (iter iterable2)
    let chain iterables                 = chain (List.map iter iterables)
    let chunks size iterable            = chunks size (iter iterable)
    let compare cmp iterable1 iterable2 = compare cmp (iter iterable1) (iter iterable2)
    let map f iterable                  = map f (iter iterable)
    let contains x iterable             = contains x (iter iterable)
    let cycle iterable                  = cycle (iter iterable)
    let dedup ?by iterable              = dedup ?by (iter iterable)
    let drop n iterable                 = drop n (iter iterable)
    let drop_while p iterable           = drop_while p (iter iterable)
    let each f iterable                 = each f (iter iterable)
    let ends_with end_iterable iterable = ends_with (iter end_iterable) (iter iterable)
    let enumerate ?from iterable        = enumerate ?from (iter iterable)
    let equal eq iterable1 iterable2    = equal eq (iter iterable1) (iter iterable2)
    let filter p iterable               = filter p (iter iterable)
    let filter_map p iterable           = filter_map p (iter iterable)
    let find p iterable                 = find p (iter iterable)
    let find_index p iterable           = find_index p (iter iterable)
    let find_indices p iterable         = find_indices p (iter iterable)
    let flat_map f iterable             = failwith "todo"
    let fold f z iterable               = fold f z (iter iterable)
    let fold_while f z iterable         = fold_while f z (iter iterable)
    let fold_right f iterable z         = fold_right f (iter iterable) z
    let group iterable                  = group (iter iterable)
    let group_by f iterable             = group_by f (iter iterable)
    let group_on f iterable             = group_on f (iter iterable)
    let head iterable                   = head (iter iterable)
    let index x iterable                = index x (iter iterable)
    let indices x iterable              = indices x (iter iterable)
    let intersparse iterable x          = intersparse (iter iterable) x
    let is_empty iterable               = is_empty (iter iterable)
    let join sep iterable               = failwith "todo"
    let merge f iterable1 iterable2     = merge f (iter iterable1) (iter iterable2)
    let last iterable                   = last (iter iterable)
    let len iterable                    = len (iter iterable)
    let max ?by iterable                = max ?by (iter iterable)
    let min ?by iterable                = min ?by (iter iterable)
    let nth n iterable                  = nth n (iter iterable)
    let pairwise iterable               = pairwise (iter iterable)
    let partition p iterable            = partition p (iter iterable)
    let powerset iterable               = powerset (iter iterable)
    let product iterable                = failwith "todo"
    let reduce f iterable               = reduce f (iter iterable)
    let reject p iterable               = reject p (iter iterable)
    let reverse iterable                = reverse (iter iterable)
    let scan f z iterable               = scan f z (iter iterable)
    let scan_right f z iterable         = scan_right f z (iter iterable)
    let slice iterable n m              = slice (iter iterable) n m
    let sort iterable                   = sort (iter iterable)
    let sort_by f iterable              = sort_by f (iter iterable)
    let sort_on f iterable              = sort_on f (iter iterable)
    let starts_with start iterable      = starts_with (iter start) (iter iterable)
    let split_at i iterable             = split_at i (iter iterable)
    let split_while p iterable          = split_while p (iter iterable)
    let sum iterable                    = failwith "todo"
    let tail iterable                   = tail (iter iterable)
    let take n iterable                 = take n (iter iterable)
    let take_every n iterable           = take_every n (iter iterable)
    let take_while p iterable           = take_while p (iter iterable)
    let take_last n iterable            = take_last n (iter iterable)
    let to_list iterable                = to_list (iter iterable)
    let uniq iterable                   = uniq (iter iterable)
    let uniq_by f iterable              = uniq_by f (iter iterable)
    let zip iterable1 iterable2         = zip (iter iterable1) (iter iterable2)
    let zip_with f iterable1 iterable2  = zip_with f (iter iterable1) (iter iterable2)
  end

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


module Input'1 = struct
  module type Base = sig
    type 'a t

    val next : 'a t -> ('a * 'a t) option
  end

  module type Base_with_iter = sig
    type 'a t

    val iter : 'a t -> 'a iter
  end

  module Make_with_iter(M : Base_with_iter) : (Input'1 with type 'a t := 'a M.t) = struct
    let all p iterable                  = all p (M.iter iterable)
    let any p iterable                  = any p (M.iter iterable)
    let concat iterable1 iterable2      = concat (M.iter iterable1) (M.iter iterable2)
    let chain iterables                 = chain (List.map M.iter iterables)
    let chunks size iterable            = chunks size (M.iter iterable)
    let compare cmp iterable1 iterable2 = compare cmp (M.iter iterable1) (M.iter iterable2)
    let compress iterable selector      = compress (M.iter iterable) (M.iter selector)
    let map f iterable                  = map f (M.iter iterable)
    let contains x iterable             = contains x (M.iter iterable)
    let cycle iterable                  = cycle (M.iter iterable)
    let dedup ?by iterable              = dedup ?by (M.iter iterable)
    let drop n iterable                 = drop n (M.iter iterable)
    let drop_while p iterable           = drop_while p (M.iter iterable)
    let each f iterable                 = each f (M.iter iterable)
    let ends_with end_iterable iterable = ends_with (M.iter end_iterable) (M.iter iterable)
    let enumerate ?from iterable        = enumerate ?from (M.iter iterable)
    let equal eq iterable1 iterable2    = equal eq (M.iter iterable1) (M.iter iterable2)
    let filter p iterable               = filter p (M.iter iterable)
    let filter_map p iterable           = filter_map p (M.iter iterable)
    let find p iterable                 = find p (M.iter iterable)
    let find_index p iterable           = find_index p (M.iter iterable)
    let find_indices p iterable         = find_indices p (M.iter iterable)
    let flat_map f iterable             = failwith "todo"
    let flatten iterable                = flatten (map M.iter iterable)
    let fold f z iterable               = fold f z (M.iter iterable)
    let fold_while f z iterable         = fold_while f z (M.iter iterable)
    let fold_right f iterable z         = fold_right f (M.iter iterable) z
    let group iterable                  = group (M.iter iterable)
    let group_by f iterable             = group_by f (M.iter iterable)
    let group_on f iterable             = group_on f (M.iter iterable)
    let head iterable                   = head (M.iter iterable)
    let index x iterable                = index x (M.iter iterable)
    let indices x iterable              = indices x (M.iter iterable)
    let intersparse iterable x          = intersparse (M.iter iterable) x
    let is_empty iterable               = is_empty (M.iter iterable)
    let join sep iterable               = join sep (M.iter iterable)
    let merge f iterable1 iterable2     = merge f (M.iter iterable1) (M.iter iterable2)
    let last iterable                   = last (M.iter iterable)
    let len iterable                    = len (M.iter iterable)
    let max ?by iterable                = max ?by (M.iter iterable)
    let min ?by iterable                = min ?by (M.iter iterable)
    let nth n iterable                  = nth n (M.iter iterable)
    let pairwise iterable               = pairwise (M.iter iterable)
    let partition p iterable            = partition p (M.iter iterable)
    let powerset iterable               = powerset (M.iter iterable)
    let product iterable                = product (M.iter iterable)
    let reduce f iterable               = reduce f (M.iter iterable)
    let reject p iterable               = reject p (M.iter iterable)
    let reverse iterable                = reverse (M.iter iterable)
    let scan f z iterable               = scan f z (M.iter iterable)
    let scan_right f z iterable         = scan_right f z (M.iter iterable)
    let slice iterable n m              = slice (M.iter iterable) n m
    let sort iterable                   = sort (M.iter iterable)
    let sort_by f iterable              = sort_by f (M.iter iterable)
    let sort_on f iterable              = sort_on f (M.iter iterable)
    let starts_with start iterable      = starts_with (M.iter start) (M.iter iterable)
    let split_at i iterable             = split_at i (M.iter iterable)
    let split_while p iterable          = split_while p (M.iter iterable)
    let sum iterable                    = sum (M.iter iterable)
    let tail iterable                   = tail (M.iter iterable)
    let take n iterable                 = take n (M.iter iterable)
    let take_every n iterable           = take_every n (M.iter iterable)
    let take_while p iterable           = take_while p (M.iter iterable)
    let take_last n iterable            = take_last n (M.iter iterable)
    let to_list iterable                = to_list (M.iter iterable)
    let unzip iterable                  = unzip (M.iter iterable)
    let uniq iterable                   = uniq (M.iter iterable)
    let uniq_by f iterable              = uniq_by f (M.iter iterable)
    let view iterable                   = view (M.iter iterable)
    let zip iterable1 iterable2         = zip (M.iter iterable1) (M.iter iterable2)
    let zip_with f iterable1 iterable2  = zip_with f (M.iter iterable1) (M.iter iterable2)
  end

  module Make(M : Base) : (Input'1 with type 'a t := 'a M.t) = struct
    include Make_with_iter(struct
        type 'a t = 'a M.t
        let iter iterable = Iter (iterable, M.next)
      end)
  end
end


(* Default input iterable interface *)
module type Input = Input'1

(* Default input iterable *)
module Input = Input'1



module type Index'1 = sig
  type 'a t

  include Input'1 with type 'a t := 'a t

  val len : 'a t -> int
  val get    : 'a t -> int -> 'a option
  val last   : 'a t -> 'a option
  val slice  : 'a t -> int -> int -> 'a iter
  val each  : ('a -> unit) -> 'a t -> unit
end

module Index'1 = struct
  module type Base = sig
    type 'a t

    val len : 'a t -> int
    val idx : 'a t -> int -> 'a
  end

  module Make(M : Base) : (Index'1 with type 'a t := 'a M.t) = struct

    let iter indexable =
      let len = M.len indexable in
      let next i =
        if i >= len then None
        else Some (M.idx indexable i, i + 1) in
      Iter (0, next)

    include Input.Make_with_iter(struct
        type 'a t = 'a M.t
        let iter = iter
      end)

    let each f indexable =
      let len = M.len indexable in
      let rec loop i =
        if i = len then ()
        else (f (M.idx indexable i); loop (i + 1)) in
      loop 0

    let len = M.len

    let get indexable i =
      let len = M.len indexable in
      let i = if i < 0 then len + i else i in
      if i < 0 || i >= len then None
      else Some (M.idx indexable i)

    let last indexable =
      let len = M.len indexable in
      if len <= 0 then None
      else Some (M.idx indexable (len - 1))

    let slice indexable n m =
      failwith "todo"
  end
end

module type Index = Index'1
module Index = Index'1

