type generation_config =
  {
    nouns : string array;
    adjectives : string array;
    verbs : string array;
    adverbs : string array;
    random : int * int -> int;
  }

type pos = | Noun | Adj | Verb | Adv

type token =
  | Static of string
  | Number of int
  | Word of pos

exception Invalid_template of string

let generate_random item ~(gen_cfg : generation_config) =
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

module Par = struct
  (* can't use `parser` here, ugh *)
  type ('a, 'c) par = Pa of ('c list -> ('a * 'c list, string) result)

  let parse (Pa p) inp = p inp

  let return x = Pa (fun inp -> Ok (x, inp))

  let fail e = Pa (fun _ -> Error e)

  let choose q w =
    Pa (fun inp ->
      match parse q inp with
      | Ok _ as ok -> ok
      | Error _ -> parse w inp
    )

  let item = Pa (function
    | [] -> Error "expected item"
    | hd :: tl -> Ok (hd, tl)
  )

  let bind p f = Pa (fun inp ->
    match parse p inp with
    | Ok (x, inp') -> parse (f x) inp'
    | Error _ as e -> e
  )
  let (>>=) = bind

  let combine q w = q >>= fun _ -> w
  let (>>) = combine

  let sat pred =
    item
    >>= fun x ->
    if pred x then (return x) else (fail "no sat")

  let a_char x = sat ((==) x)

  let rec a_string = function
    | [] -> fail "empty string"
    | x :: xs ->
      a_char x >> a_string xs >> return (x :: xs)

  let rec many p =
    choose (many1 p) (return [])

  and many1 p =
    p
    >>= fun v ->
    many p
    >>= fun vs ->
    return (v :: vs)

  let map f p = p >>= fun x -> return (f x)

end

let parse_template template_string =
  let rec explode = function
    | "" -> []
    | s  ->
      (String.get s 0) ::
      explode (String.sub s 1 ((String.length s) - 1))
  in

  let rec implode = function
    | [] -> ""
    | x :: xs -> (Char.escaped x) ^ (implode xs)
  in

  let (>>=) = Par.(>>=)
  in

  let the_parser =
    let meta =
      let word_meta =
        Par.many1 (Par.sat ((<>) '}'))
        >>= fun meta_name ->
        match implode meta_name with
        | "noun" -> Par.return (Word Noun)
        | "adj" -> Par.return (Word Adj)
        | "verb" -> Par.return (Word Verb)
        | "adv" -> Par.return (Word Adv)
        | other -> Par.fail ("unrecognized meta: " ^ other)
      in

      let number_meta =
        Par.many1 (Par.sat ((==) '0'))
        >>= fun numdef ->
        Par.return (Number (List.length numdef)) 
      in

      Par.a_char '{'
      >>= fun _ ->
      Par.choose word_meta number_meta
      >>= fun r ->
      Par.a_char '}'
      >>= fun _ ->
      Par.return r
    in

    let static =
      Par.many1 (Par.sat ((<>) '{'))
      |> Par.map (fun x -> Static (implode x))

    in
    Par.many1 (Par.choose meta static)

  in
  Par.parse the_parser (explode template_string)

let _ = Random.self_init ()

let _ =
  let m = Js.Unsafe.obj [||] in
  Js.Unsafe.global##pwdGen <- m;

  let cfg : generation_config =
    {
      nouns = [| "ball"; "balls" |];
      adjectives = [| "big"; "dirty" |];
      verbs = [| "bounce" |];
      adverbs = [| "bouncing" |];
      random = fun (l, h) -> l + (Random.int (h - l));
    }
  in
  let js_generate tpl_string =
    let tpl = parse_template (Js.to_string tpl_string) in
    match tpl with
    | Ok (tpl, _) -> Js.string (generate_from_template tpl cfg)
    | Error e -> Js.string e
  in

  m##generate <- Js.wrap_callback js_generate;
  m##parseTemplate <- Js.wrap_callback (fun s -> parse_template (Js.to_string s));

