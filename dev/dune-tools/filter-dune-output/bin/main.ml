let _ =
  let ignore_cache_store_lines start_line =
    (* Wrapper around [input_line] to print all ignored lines upon error. *)
    let input_line : in_channel -> string =
      let lines = ref [start_line] in
      let input_line ic =
        let line =
          try input_line ic with End_of_file ->
            List.iter (Printf.printf "%s\n%!") (List.rev !lines);
            raise End_of_file
        in
        lines := line :: !lines; line
      in
      input_line
    in
    let found = ref false in
    while not !found do
      let line = input_line stdin in
      if String.ends_with ~suffix:"after executing" line then found := true
    done;
    let found = ref false in
    while not !found do
      let line = input_line stdin in
      if String.ends_with ~suffix:")" line then found := true
    done
  in
  try while true do
    let line = input_line stdin in
    if String.starts_with ~prefix:"Warning: cache store error" line then
      ignore_cache_store_lines line
    else
      Printf.printf "%s\n%!" line
  done with End_of_file -> ()
