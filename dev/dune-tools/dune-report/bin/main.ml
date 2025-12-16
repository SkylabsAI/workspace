open Cmdliner

let version = "dev"

let pp_command : Format.formatter -> Dune_log.command -> unit = fun ff cmd ->
  Format.fprintf ff "$ %s\n%!" cmd.Dune_log.command;
  List.iter (Format.fprintf ff "%s\n%!") cmd.Dune_log.output;
  Format.fprintf ff "[%i]\n%!" cmd.Dune_log.status

let run : bool -> bool -> string option -> unit = fun json all log_file ->
  let log_file =
    match log_file with
    | Some(log_file) -> log_file
    | None           ->
    match Dune_log.locate () with
    | Some(log_file) -> log_file
    | None           ->
        Printf.eprintf "Could not locate the dune log. ";
        Printf.eprintf "Did you run \"dune build\"?\n%!";
        exit 3
  in
  let commands =
    try Dune_log.read ~log_file with
    | Sys_error(s)      ->
        Printf.eprintf "File system error: %s.\n%!" s;
        exit 2
    | Dune_log.Error(s) ->
        Printf.eprintf "Ill-formed log file: %s.\n%!" s;
        exit 1
  in
  let commands =
    let non_0_status Dune_log.{status; _} = status <> 0 in
    match all with
    | true  -> commands
    | false -> List.filter non_0_status commands
  in
  match json with
  | true  ->
      let json = `List(List.map Dune_log.command_to_json commands) in
      Format.printf "%a\n%!" (Yojson.Safe.pretty_print ~std:true) json
  | false ->
      let pp_sep = Format.pp_force_newline in
      Format.printf "%a%!" (Format.pp_print_list ~pp_sep pp_command) commands

let json =
  let doc = "Output JSON instead of the default text output." in
  Arg.(value & flag & info ["json"] ~doc)

let all =
  let doc =
    "Produce entries for all commands. When not set, only the commands with \
     non-0 return status are included in the output."
  in
  Arg.(value & flag & info ["all"] ~doc)

let log_file =
  let doc =
    "Specify a path to the dune log to process. When not specified, the log \
     from the current dune workspace is located."
  in
  let i = Arg.(info ["log-file"] ~docv:"LOGFILE" ~doc) in
  Arg.(value & opt (some non_dir_file) None & i)

let cmd =
  let doc = "Builds a report form the dune build log." in
  let term = Term.(const run $ json $ all $ log_file) in
  let exits =
    let open Cmd.Exit in
    info ~doc:"On success." ok ::
    info ~doc:"On errors while reading the log." 1 ::
    info ~doc:"On file system errors." 2 ::
    info ~doc:"On errors while locating the log." 3 ::
    info ~doc:"On command line parsing errors." cli_error ::
    info ~doc:"On unexpected internal errors (bugs)." internal_error :: []
  in
  Cmd.(v (info "dune-report" ~version ~doc ~exits) term)

let _ =
  exit (Cmd.eval cmd)
