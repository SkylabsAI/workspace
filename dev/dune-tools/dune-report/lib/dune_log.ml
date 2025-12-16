type command = {
  command : string;
  output : string list;
  status : int;
}
[@@deriving yojson]

let command_to_json = command_to_yojson

exception Error of string

let error : string -> 'a = fun s ->
  raise (Error(s))

type item =
  | Command of string
  | Output of string
  | Status of int

let rec next_item : int -> In_channel.t -> (int * item) option = fun n ic ->
  let skip_space ic =
    match In_channel.input_char ic with
    | Some(' ') -> ()
    | _         -> error (Printf.sprintf "space expected on line %i" n)
  in
  let get_line ic =
    match In_channel.input_line ic with
    | Some(line) -> line
    | None       ->
        error (Printf.sprintf "unexpected end of input on line %i" n)
  in
  let get_output_line ic =
    let remove_space line =
      match String.get line 0 with
      | ' ' -> String.sub line 1 (String.length line - 1)
      | _   -> error (Printf.sprintf "space expected on line %i" n)
    in
    match In_channel.input_line ic with
    | Some(line) -> if line = "" then line else remove_space line
    | None       ->
        error (Printf.sprintf "unexpected end of input on line %i" n)
  in
  let read_status ic =
    let line = get_line ic in
    try Scanf.sscanf line "%d]" Fun.id with
    | Failure(_) | Scanf.Scan_failure(_) | End_of_file ->
        error (Printf.sprintf "invalid status on line %i" n)
  in
  match In_channel.input_char ic with
  | None      -> None
  | Some('#') -> ignore (get_line ic); next_item (n + 1) ic
  | Some('$') -> skip_space ic; Some(n + 1, Command(get_line ic))
  | Some('>') -> Some(n + 1, Output(get_output_line ic))
  | Some('[') -> Some(n + 1, Status(read_status ic))
  | Some(c  ) ->
  error (Printf.sprintf "unexpected start of line (%C) on line %i" c n)

let rev_items : In_channel.t -> item list = fun ic ->
  let rec loop n acc =
    match next_item n ic with
    | None          -> acc
    | Some(n, item) -> loop n (item :: acc)
  in
  loop 1 []

let read : log_file:string -> command list = fun ~log_file ->
  let rev_items = In_channel.with_open_text log_file rev_items in
  let rec loop acc output status rev_items =
    match (rev_items, output, status) with
    | (Status(i)  :: rev_items, [], None   ) ->
        loop acc [] (Some(i)) rev_items
    | (Status(_)  :: _        , _ , Some(_)) ->
        error "duplicated status line"
    | (Status(_)  :: _        , _ , None   ) ->
        error "leftover output"
    | (Output(s)  :: rev_items, [], None   ) ->
        loop acc [s] (Some(0)) rev_items
    | (Output(_)  :: _        , _ , None   ) ->
        error "leftover output"
    | (Output(s)  :: rev_items, _ , Some(_)) ->
        loop acc (s :: output) status rev_items
    | (Command(s) :: rev_items, _ , None   ) ->
        loop ({command = s; output; status = 0} :: acc) [] None rev_items
    | (Command(s) :: rev_items, _ , Some(i)) ->
        loop ({command = s; output; status = i} :: acc) [] None rev_items
    | ([]                     , [], None   ) ->
        acc
    | ([]                     , [] , _     ) ->
        error "hanging status line"
    | ([]                     , _  , _     ) ->
        error "leftover output"
  in
  loop [] [] None rev_items

let locate : unit -> string option = fun () ->
  let rec locate_build dir =
    let candidate = Filename.concat dir "_build" in
    let found = try Sys.is_directory candidate with Sys_error(_) -> false in
    match found with
    | true  -> Some(candidate)
    | false ->
    let parent_dir = Filename.dirname dir in
    match parent_dir = dir with
    | true  -> None
    | false -> locate_build parent_dir
  in
  match locate_build (Sys.getcwd ()) with
  | None        -> None
  | Some(build) ->
  let log_file = Filename.concat build "log" in
  if Sys.file_exists log_file then Some(log_file) else None
