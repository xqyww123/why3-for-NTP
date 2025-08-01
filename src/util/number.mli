(********************************************************************)
(*                                                                  *)
(*  The Why3 Verification Platform   /   The Why3 Development Team  *)
(*  Copyright 2010-2024 --  Inria - CNRS - Paris-Saclay University  *)
(*                                                                  *)
(*  This software is distributed under the terms of the GNU Lesser  *)
(*  General Public License version 2.1, with the special exception  *)
(*  on linking described in file LICENSE.                           *)
(*                                                                  *)
(********************************************************************)

(** {1 General functions for representations of numeric values} *)

open Format

exception InvalidConstantLiteral of int * string

type int_value = BigInt.t
[@@deriving sexp]

type int_literal_kind =
  ILitUnk | ILitDec | ILitHex | ILitOct | ILitBin
[@@deriving sexp]

type int_constant = {
  il_kind : int_literal_kind;
  il_int  : int_value;
}
[@@deriving sexp]

type real_value = private {
  rv_sig  : BigInt.t;
  rv_pow2 : BigInt.t;
  rv_pow5 : BigInt.t;
}

type real_literal_kind =
  RLitUnk | RLitDec of int | RLitHex of int
[@@deriving sexp]

type real_constant = {
  rl_kind : real_literal_kind;
  rl_real : real_value
}
[@@deriving sexp]

val neg_int : int_constant -> int_constant
val abs_int : int_constant -> int_constant

val neg_real : real_constant -> real_constant
val abs_real : real_constant -> real_constant

val compare_real : ?structural:bool -> real_value -> real_value -> int
(** Compare two real values.
    By default, the comparison is structural,
    that is, two ordered values might compare differently.
*)

val int_literal : int_literal_kind -> neg:bool -> string -> int_constant

val real_literal : radix:int -> neg:bool -> int:string -> frac:string -> exp:string option -> real_constant
(** [real_literal ~radix ~neg ~int ~frac ~exp] builds the real value
   given by the mantissa [int.frac] and exponent [exp]. The [radix]
   must be either 10 or 16. If [radix] is 16, then [int] and [frac] are
   interpreted in hexadecimal (but not [exp] which is always in
   decimal) and the base of the exponent is 2 instead of 10. The
   resulting number is negative when [neg] is true.

   Examples:
   - [real_literal ~radix:10 ~neg:false ~int:"12" ~frac:"34" ~exp:(Some "-5")]
     denotes the number [12.34e-5],
   - [real_literal ~radix:10 ~neg:true ~int:"67" ~frac:"" ~exp:None]
     denotes [-67],
   - [real_literal ~radix:16 ~neg:false ~int:"9A" ~frac:"B" ~exp:(Some "5")]
     denotes [0x9A.Bp5], i.e., [4950].
*)

val real_value : ?pow2:BigInt.t -> ?pow5:BigInt.t -> BigInt.t -> real_value
(** [real_value ~pow2 ~pow5 n] builds the value [n * 2 ^ pow2 * 5 ^ pow5]. *)

(** {2 Pretty-printing with conversion} *)

type default_format =
  Format.formatter -> string -> unit

type integer_format =
  Format.formatter -> BigInt.t -> unit

type real_format =
  Format.formatter -> string -> string -> string option -> unit

type frac_real_format =
  (Format.formatter -> string -> unit) * (Format.formatter -> string -> string -> unit)

type delayed_format =
  Format.formatter -> (Format.formatter -> unit) -> unit

type number_support = {
  long_int_support  : [`Default|`Custom of default_format];
  negative_int_support : [`Default|`Custom of delayed_format];
  dec_int_support   : [`Default|`Custom of integer_format|`Unsupported of default_format];
  hex_int_support   : [`Default|`Custom of integer_format|`Unsupported];
  oct_int_support   : [`Default|`Custom of integer_format|`Unsupported];
  bin_int_support   : [`Default|`Custom of integer_format|`Unsupported];
  negative_real_support : [`Default|`Custom of delayed_format];
  dec_real_support  : [`Default|`Custom of real_format|`Unsupported];
  hex_real_support  : [`Default|`Custom of real_format|`Unsupported];
  frac_real_support : [`Custom of frac_real_format|`Unsupported of default_format];
}

val full_support : number_support

val print_int_constant : number_support -> formatter -> int_constant -> unit
val print_real_constant : number_support -> formatter -> real_constant -> unit

val print_in_base : int -> int option -> formatter -> BigInt.t -> unit
(** [print_in_base radix digits fmt i] prints the value of non-negative [i]
    in base [radix]. If digits is not [None], it adds leading 0s to have [digits]
    characters. *)

(** {2 Range checking} *)

val to_small_integer : int_constant -> int
(* may raise invalid_argument *)

type int_range = {
  ir_lower : BigInt.t;
  ir_upper : BigInt.t;
}
[@@deriving sexp]

val create_range : BigInt.t -> BigInt.t -> int_range

exception OutOfRange of int_constant

val check_range : int_constant -> int_range -> unit
(** [check_range c ir] checks that [c] is in the range described by [ir].
    @raise OutOfRange if out of range. *)

val int_range_equal : int_range -> int_range -> bool

(** {2 Float checking} *)

type float_format = {
  fp_exponent_digits    : int;
  fp_significand_digits : int; (* counting the hidden bit *)
}
[@@deriving sexp]

exception NonRepresentableFloat of real_constant

val compute_float : real_constant -> float_format -> bool * BigInt.t * BigInt.t
(** [compute_float c fp] checks that [c] is a float literal
    representable in the format [fp].
    @return a triple [s,e,m] with [s] the sign (true if negative, false if positive),
    [m] the significand (without the hidden bit), and [e] the biased
    exponent.
    @raise NonRepresentableFloat if not representable. *)

val check_float : real_constant -> float_format -> unit
(** [check_float c fp] is the same as [compute_float c fp]
    but does not return any value. *)

val float_format_equal : float_format -> float_format -> bool
