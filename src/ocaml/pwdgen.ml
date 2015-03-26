type generation_config =
  {
    nouns : string array;
    adjectives : string array;
    verbs : string array;
    adverbs : string array;
    random : int * int -> int;
  }

type pos = Noun | Adj | Verb | Adv

type token =
  | Static of string
  | Number of int
  | Word of pos

type template = token list

exception Invalid_template of string

let generate_random item ~(gen_cfg: generation_config) =
  let rng = gen_cfg.random in
  let choose_from arr = Array.get arr (rng (0, Array.length arr)) in

  match item with
  | Static s -> s
  | Number count ->
    if count <= 0
    then raise (Invalid_template "Number must be > 0")
    else
      let rec pow x = function
        | 0 -> 1 | 1 -> x
        | n -> let y = pow x (n / 2) in y * y * (if n mod 2 = 0 then 1 else x)
      in
      let low = pow 10 (count - 1) in
      let high = pow 10 (count) - 1 in

      string_of_int (rng (low, high))
  | Word w ->
    let dict =
      match w with
        | Noun -> gen_cfg.nouns
        | Adj -> gen_cfg.adjectives
        | Verb -> gen_cfg.verbs
        | Adv -> gen_cfg.adverbs
    in
      choose_from dict

let generate_from_template template gen_cfg =
  let words = List.map (generate_random ~gen_cfg:gen_cfg) template in
  String.concat "" words

type ('a, 'b) result = Ok of 'a | Error of 'b

(* primitive parser combinators *)
module Par = struct
  (* can't use `parser` here, ugh *)
  type ('a, 'c) par = Pa of ('c list -> ('a * 'c list, string) result)

  let parse (Pa p) inp = p inp
  let return x = Pa (fun inp -> Ok (x, inp))
  let fail e = Pa (fun _ -> Error e)

  let bind p f = Pa (fun inp ->
    match parse p inp with
    | Ok (x, inp') -> parse (f x) inp'
    | Error _ as e -> e
  )
  let (>>=) = bind

  let combine q w = q >>= fun _ -> w
  let fmap f p = p >>= fun x -> return (f x)
  let ap pf p = pf >>= fun f -> p >>= fun a -> return (f a)

  let (>>) = combine
  let (<$>) = fmap
  let (<*>) = ap
  let (<* ) a b = a >>= fun x -> b >>= fun _ -> return x
  let ( *>) a b = a >>= fun _ -> b >>= fun x -> return x

  let choose q w = Pa (fun inp ->
    match parse q inp with
    | Ok _ as ok -> ok
    | Error _ -> parse w inp
  )

  let item = Pa (function
    | [] -> Error "expected item"
    | hd :: tl -> Ok (hd, tl)
  )

  let eoi = Pa (function
    | [] -> Ok ((), [])
    | _ -> Error "expected end of input"
  )

  let rec many p = choose (many1 p) (return [])
  and many1 p = p >>= fun v -> many p >>= fun vs -> return (v :: vs)

  let label msg p = Pa (fun inp ->
    match parse p inp with
    | Error _ -> Error ("expected: " ^ msg)
    | ok -> ok
  )
  let (<?>) p msg = label msg p

  let sat pred =
    item >>= fun x -> if pred x then (return x) else (fail "no sat")

  let a_char x = sat ((==) x) <?> (Char.escaped x)

  let rec a_string = function
    | [] -> raise (Failure "invalid argument")
    | x :: xs -> a_char x >> a_string xs >> return (x :: xs)

end

(* generation template parser *)
module Parse_template : sig
  val parse : string -> (template, string) result
end =
struct
  let rec explode : string -> char list = function
    | "" -> []
    | s  ->
      (String.get s 0) ::
      explode (String.sub s 1 ((String.length s) - 1))

  let rec implode : char list -> string = function
    | [] -> ""
    | x :: xs -> (Char.escaped x) ^ (implode xs)

  open Par

  let p_word_meta =
    many1 (sat ((<>) '}'))
    >>= fun meta_name ->
    match implode meta_name with
    | "noun" -> return (Word Noun)
    | "adj" -> return (Word Adj)
    | "verb" -> return (Word Verb)
    | "adv" -> return (Word Adv)
    | other -> fail ("unrecognized meta: " ^ other)

  let p_number_meta =
    many1 (sat ((==) '0'))
    >>= fun numdef ->
    return (Number (List.length numdef))

  let p_meta = a_char '{' *> choose p_word_meta p_number_meta <* a_char '}'

  let p_static =
    many1 (sat ((<>) '{'))
    |> fmap (fun x -> Static (implode x))

  let parse template_string =
    let the_parser =
      many1 (Par.choose p_meta p_static) <* eoi

    in
    match parse the_parser (explode template_string) with
    | Ok (tpl, _) -> Ok tpl
    | Error _ as e -> e
end

let _ = Random.self_init ()

let _ =
  let m = Js.Unsafe.obj [||] in
  Js.Unsafe.global##pwdGen <- m;

  let js_generate tpl_string dict =
    let tpl = Parse_template.parse (Js.to_string tpl_string) in
    match tpl with
    | Ok tpl ->
      let cfg : generation_config =
        {
          nouns = Array.map Js.to_string dict##nouns;
          adjectives = Array.map Js.to_string dict##adjectives;
          verbs = Array.map Js.to_string dict##verbs;
          adverbs = Array.map Js.to_string dict##adverbs;
          random = fun (l, h) -> l + (Random.int (h - l));
        }
      in
      let r = Js.Unsafe.obj [| |] in
      r##password <- Js.string (generate_from_template tpl cfg);
      r

    | Error e ->
      let r = Js.Unsafe.obj [| |] in
      r##error <- Js.string ("Could not parse template: " ^ e);
      r
  in

  m##generate <- Js.wrap_callback js_generate;
