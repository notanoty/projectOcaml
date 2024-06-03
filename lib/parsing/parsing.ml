open Peano
open Tokenize

exception WrongVariable of string
exception LispError of string

(* open Language.Rutalg *)
let find_max_int (current_expr : int list) : int =
  let rec find_max list max =
    match list with
    | [] -> 0
    | head :: [] -> if head > max then head else max
    | head :: tail -> find_max tail (if head > max then head else max)
  in
  find_max current_expr 0

let string_to_sexpr (str : string) : s_expression =
  list_string_to_exp (tokenize str)

let print_list (list_arg : int list) : unit =
  List.iter (fun x -> Printf.printf "%d " x) list_arg;
  print_endline ""

let rutal_original (list_args : string list) : int list =
  let len = List.length list_args in
  let rec rutishauser_algorithm i depth =
    if i >= len then []
    else
      match List.nth list_args i with
      | ")" | "+" | "-" | "*" | "/" ->
          (depth - 1) :: rutishauser_algorithm (i + 1) (depth - 1)
      | _ -> (depth + 1) :: rutishauser_algorithm (i + 1) (depth + 1)
  in
  rutishauser_algorithm 0 0

let rutal (list_args : string list) : int list =
  let len = List.length list_args in
  let rec rutishauser_algorithm i depth =
    if i >= len then []
    else
      match List.nth list_args i with
      | ")" -> depth :: rutishauser_algorithm (i + 1) (depth - 1)
      | "(" -> (depth + 1) :: rutishauser_algorithm (i + 1) (depth + 1)
      | _ -> -1 :: rutishauser_algorithm (i + 1) depth
  in
  rutishauser_algorithm 0 0

let strint_to_expr_int : s_expression -> s_expression = function
  | SString { value = s } -> (
      match int_of_string_opt s with
      | Some i -> SInt { value = i }
      | None -> SString { value = s })
  | x -> x

let reverse_expression (exp : s_expression) : s_expression =
  let rec rev exspression new_expr =
    match exspression with
    | Nil -> new_expr
    | SString { value } -> SString { value }
    | SInt { value } -> SInt { value }
    | S_expr { current = head_expr; next = tail_expr } ->
        rev tail_expr
          (S_expr { current = strint_to_expr_int head_expr; next = new_expr })
    | _ -> raise (WrongVariable "Closure should not be here")
  in
  rev exp Nil

let rec build_list current_expr current_depths expr_accumulator
    depth_accumulator new_expr max_depth =
  match (current_expr, current_depths) with
  | _, [] -> raise (LispError "Parenthesis are not closed")
  | ( S_expr { current = head_expr; next = tail_expr },
      current_depth :: tail_depths ) ->
      if current_depth = max_depth then
        (tail_expr, reverse_expression new_expr, -1 :: tail_depths)
      else
        build_list tail_expr tail_depths expr_accumulator depth_accumulator
          (S_expr { current = head_expr; next = new_expr })
          max_depth
  | _ -> raise (WrongVariable "This expression cannot be supported")

let parsing_par (expression_list : s_expression) (list_depth : int list) :
    s_expression * int list =
  let max_depth = find_max_int list_depth in
  let rec build_expression current_expr current_depths expr_accumulator
      depth_accumulator =
    match (current_expr, current_depths) with
    (* | (_, []) ->  *)
    (* (expr_accumulator, depth_accumulator) *)
    | Nil, _ ->
        (* Printf.printf "This happed\n"; *)
        (expr_accumulator, depth_accumulator)
    | ( S_expr { current = head_expr; next = tail_expr },
        current_depth :: tail_depths ) ->
        if current_depth = max_depth then
          let new_tail, new_expr_accumulator, new_depth_accumulator =
            build_list tail_expr tail_depths expr_accumulator depth_accumulator
              Nil max_depth
          in
          build_expression Nil new_depth_accumulator
            (S_expr { current = new_expr_accumulator; next = new_tail })
            new_depth_accumulator
        else
          let new_expr_accumulator, new_depth_accumulator =
            build_expression tail_expr tail_depths expr_accumulator
              depth_accumulator
          in
          ( S_expr { current = head_expr; next = new_expr_accumulator },
            current_depth :: new_depth_accumulator )
    | _ -> raise (WrongVariable "This expression cannot be supported")
  in

  build_expression expression_list list_depth Nil []

let parsing (exspression : string) : s_expression =
  let depth_list = rutal (tokenize exspression) in
  let rec parsing_rec expression_list list_depth =
    (* print_exsprassion expression_list; *)
    (* Printf.printf "max_depth = %d List.len = %d\n" (find_max_int list_depth) (List.length list_depth); *)
    (* print_list list_depth; *)
    if find_max_int list_depth == 0 && List.length list_depth > 1 then
      raise (WrongVariable "Too many arguments for this exspression")
    else
      match list_depth with
      | [ -1 ] -> expression_list
      | _ ->
          let new_exspression, new_depth =
            parsing_par expression_list list_depth
          in
          parsing_rec new_exspression new_depth
  in
  let res_expression = parsing_rec (string_to_sexpr exspression) depth_list in
  match res_expression with S_expr { current = x; next = _ } -> x | x -> x
