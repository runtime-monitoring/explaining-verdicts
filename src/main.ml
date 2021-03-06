(*******************************************************************)
(*     This is part of Explanator2, it is distributed under the    *)
(*     terms of the GNU Lesser General Public License version 3    *)
(*           (see file LICENSE for more details)                   *)
(*                                                                 *)
(*  Copyright 2021:                                                *)
(*  Dmitriy Traytel (UCPH)                                         *)
(*  Leonardo Lima (UCPH)                                           *)
(*******************************************************************)

open Util
open Expl
open Mtl
open Io
open Mtl_parser
open Mtl_lexer
open Monitor

exception EXIT

let full_ref = ref true
let check_ref = ref false
let debug_ref = ref false
let mode_ref = ref ALL
let measure_le_ref = ref None
let measure_sl_ref = ref None
let fmla_ref = ref None
let log_ref = ref stdin
let out_ref = ref stdout

let usage () =
  Format.eprintf
    "Example usage: explanator2 -O size -mode sat -fmla test.fmla -log test.log -out test.out
     Arguments:
     \t -ap      - output only the \"responsible atomic proposition\" view
     \t -check   - include output of verified checker
     \t -mode
     \t\t all    - output all satisfaction and violation proofs (default)
     \t\t sat    - output only satisfaction proofs
     \t\t viol   - output only violation proofs
     \t\t bool   - output boolean values (for testing)
     \t -O
     \t\t size   - optimize proof size (default)
     \t\t high   - optimize highest time-point occuring in a proof (lower is better)
     \t\t pred   - optimize multiset cardinality of atomic predicates
     \t\t none   - give any proof
     \t -fmla
     \t\t <file> or <string> - formula to be explained (if none given some default formula will be used)\n
     \t -log
     \t\t <file> - log file (default: stdin)
     \t -out
     \t\t <file> - output file where the explanation is printed to (default: stdout)
     \t -debug   - verbose output (useful for debugging)\n%!";
  raise EXIT

let mode_error () =
  Format.eprintf "mode should be either \"sat\", \"viol\" or \"all\" (without quotes)\n%!";
  raise EXIT

let measure_error () =
  Format.eprintf "measure should be either \"size\", \"high\", \"pred\", or \"none\" (without quotes)\n%!";
  raise EXIT

let process_args =
  let rec go = function
    | ("-ap" :: args) ->
       full_ref := false;
       go args
    | ("-check" :: args) ->
       check_ref := true;
       go args
    | ("-debug" :: args) ->
       debug_ref := true;
       go args
    | ("-mode" :: mode :: args) ->
       mode_ref :=
         (match mode with
          | "all" | "ALL" | "All" -> ALL
          | "sat" | "SAT" | "Sat" -> SAT
          | "viol" | "VIOL" | "Viol" -> VIOL
          | "bool" | "BOOL" | "Bool" -> BOOL
          | _ -> mode_error ());
       go args
    | ("-O" :: measure :: args) ->
       let measure_le, measure_sl =
         match measure with
         | "size" | "SIZE" | "Size" -> size_le, size_sl
         | "high" | "HIGH" | "High" -> high_le, high_sl
         | "pred" | "PRED" | "Pred" -> predicates_le, predicates_sl
         | "none" | "NONE" | "None" -> (fun _ _ -> true), (fun _ _ -> true)
         | _ -> measure_error () in
       measure_le_ref :=
         (match !measure_le_ref with
          | None -> Some measure_le
          | Some measure_le' -> Some(prod measure_le measure_le'));
       measure_sl_ref :=
         (match !measure_sl_ref with
          | None -> Some measure_sl
          | Some measure_sl' -> Some(prod measure_sl measure_sl'));
       go args
    | ("-Olex" :: measure :: args) ->
       let measure_le, measure_sl =
         match measure with
         | "size" | "SIZE" | "Size" -> size_le, size_sl
         | "high" | "HIGH" | "High" -> high_le, high_sl
         | "pred" | "PRED" | "Pred" -> predicates_le, predicates_sl
         | "none" | "NONE" | "None" -> (fun _ _ -> true), (fun _ _ -> true)
         | _ -> measure_error () in
       measure_le_ref :=
         (match !measure_le_ref with
          | None -> Some measure_le
          | Some measure_le' -> Some(lex measure_le measure_le'));
       measure_sl_ref :=
         (match !measure_sl_ref with
          | None -> Some measure_sl
          | Some measure_sl' -> Some(lex measure_sl measure_sl'));
       go args
    | ("-log" :: logfile :: args) ->
       log_ref := open_in logfile;
       go args
    | ("-fmla" :: fmlafile :: args) ->
       (try
          let in_ch = open_in fmlafile in
          fmla_ref := Some(Mtl_parser.formula Mtl_lexer.token (Lexing.from_channel in_ch));
          close_in in_ch
        with
          _ -> fmla_ref := Some(Mtl_parser.formula Mtl_lexer.token (Lexing.from_string fmlafile)));
       go args
    | ("-out" :: outfile :: args) ->
       out_ref := open_out outfile;
       go args
    | [] -> ()
    | _ -> usage () in
  go

let _ =
  try
    process_args (List.tl (Array.to_list Sys.argv));
    match !fmla_ref with
    | None -> ()
    | Some(f) -> let measure_le, measure_sl =
                   match !measure_le_ref, !measure_sl_ref with
                   | None, None -> size_le, size_sl
                   | Some measure_le', Some measure_sl' -> measure_le', measure_sl'
                   | _ -> failwith "Invalid measure" in
                 if !full_ref then
                   let _ = monitor !log_ref !out_ref !mode_ref !debug_ref !check_ref measure_le measure_sl f in ()
                 else ()
  with
  | End_of_file -> let _ = output_event !out_ref "Bye.\n" in close_out !out_ref; exit 0
  | EXIT -> close_out !out_ref; exit 1
