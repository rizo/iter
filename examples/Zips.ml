
open Iter


let example_1 input =
  Iter.zip_with (fun e1 e2 -> (e1, e2))
    (Iter.array input
     |> Iter.map (fun x -> x * x)
     |> Iter.take 12
     |> Iter.filter (fun x -> x mod 2 = 0)
     |> Iter.map (fun x -> x * x))
    (Iter.iota 1
     |> Iter.flat_map (fun x -> Iter.iota (x + 1) |> Iter.take 3)
     |> Iter.filter (fun x -> x mod 2 = 0))
  |> Iter.fold (fun a res -> a :: res) []


