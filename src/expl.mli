(*******************************************************************)
(*     This is part of Explanator2, it is distributed under the    *)
(*     terms of the GNU Lesser General Public License version 3    *)
(*           (see file LICENSE for more details)                   *)
(*                                                                 *)
(*  Copyright 2021:                                                *)
(*  Dmitriy Traytel (UCPH)                                         *)
(*  Leonardo Lima (UCPH)                                           *)
(*******************************************************************)

type sexpl =
  | STT of int
  | SAtom of int * string
  | SNeg of vexpl
  | SDisjL of sexpl
  | SDisjR of sexpl
  | SConj of sexpl * sexpl
  | SImplL of vexpl
  | SImplR of sexpl
  | SIffS of sexpl * sexpl
  | SIffV of vexpl * vexpl
  | SPrev of sexpl
  | SOnce of int * sexpl
  | SHistorically of sexpl list
  | SNext of sexpl
  | SEventually of int * sexpl
  | SAlways of sexpl list
  | SSince of sexpl * sexpl list
  | SUntil of sexpl * sexpl list
and vexpl =
  | VFF of int
  | VAtom of int * string
  | VNeg of sexpl
  | VDisj of vexpl * vexpl
  | VConjL of vexpl
  | VConjR of vexpl
  | VImpl of sexpl * vexpl
  | VIffL of sexpl * vexpl
  | VIffR of vexpl * sexpl
  | VPrev0
  | VPrevOutL of int
  | VPrevOutR of int
  | VPrev of vexpl
  | VOnce of vexpl list
  | VHistorically of int * vexpl
  | VNextOutL of int
  | VNextOutR of int
  | VNext of vexpl
  | VEventually of vexpl list
  | VAlways of int * vexpl
  | VSince of int * vexpl * vexpl list
  | VSinceInf of int * vexpl list
  | VSinceOutL of int
  | VUntil of int * vexpl * vexpl list
  | VUntilInf of int * vexpl list

type expl = S of sexpl | V of vexpl

exception VEXPL
exception SEXPL

val unS: expl -> sexpl
val unV: expl -> vexpl

val sappend: sexpl -> sexpl -> sexpl
val vappend: vexpl -> vexpl -> vexpl
val slift: sexpl -> sexpl
val vlift: vexpl -> vexpl

val size: expl -> int
val size_le: expl -> expl -> bool
val size_sl: expl -> expl -> bool
val minsize: expl -> expl -> expl
val minsize_list: expl list -> expl

val high: expl -> int
val high_le: expl -> expl -> bool
val high_sl: expl -> expl -> bool

val low: expl -> int
val low_le: expl -> expl -> bool
val low_sl: expl -> expl -> bool

val predicates: expl -> int
val predicates_le: expl -> expl -> bool
val predicates_sl: expl -> expl -> bool

val v_to_string: string -> vexpl -> string
val expl_to_string: expl -> string
