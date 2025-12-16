(** Command logged during a dune build. *)
type command = {
  command : string;
  (** Command that was run. *)
  output : string list;
  (** Lines of output from the command (including error message). *)
  status : int;
  (** Return code from the command (non-0 on failure). *)
}

(** [command_to_json command] turns [command] into its JSON representation. *)
val command_to_json : command -> Yojson.Safe.t

(** Exception raised by [read]. *)
exception Error of string

(** [read ~log_file] collects all the commands logged in file [log_file]. Note
    that [log_file] should typically be ["_build/log"]. In case of error while
    accessing the file system, the [Sys_error] exception is raised. An [Error]
    exception is raised if unexpected contents is found in the file. *)
val read : log_file:string -> command list

(** [locate ()] attempts to locate the dune log file for the current workspace
    (where the current working directory of the program is). *)
val locate : unit -> string option
