module type SET = sig
  type elt
  type t

  val empty : t
  val insert : elt -> t -> t
  val member : elt -> t -> bool
  val remove : elt -> t -> t
  val elements : t -> elt list
end

module type COMP= sig 

  type t
  val (<):t->t->bool
  val (>):t->t->bool
  val (=):t->t->bool
   val string_of_t : t -> string
end

module Set(C:COMP) :SET
with type elt=C.t with type t=C.t list=
  
struct 
type elt=C.t
type t=elt list
  let empty = []
  
  let rec insert elt t = 
    match t with 
    | []->[elt]
    | h::t1-> if C.(<) h elt then h::insert elt t1  else if C.(>) h elt then elt::t else t
    
  let rec member elt t = 
    match t with 
    | []->false
    | h::t1-> if C.(=) h elt then true else if C.(<) h elt then member elt t1 else false
  
    let rec remove elt t = 
    match t with 
    | []->[]
    | h::t1-> if C.(=) h elt then t1 else if C.(<) h elt then h::remove elt t1 else t
  
  
  let elements t=t

end

module IntComp: (COMP with type t=int) =
struct

  type t=int
  let (<)=(<)
  let (>)=(>)
  let (=)=(=)
   let string_of_t =string_of_int
end

module IntSet=Set(IntComp)

module StringComp: (COMP with type t=string) =
struct

  type t=string
  let (<)=(<)
  let (>)=(>)
  let (=)=(=)
   let string_of_t s=s
end

module StringSet=Set(StringComp)
type date={day:int;month:int;year:int}
module DateComp: (COMP with type t=date) =
struct

  type t=date
  let compare d1 d2 =
    if d1.year <> d2.year then Int.compare d1.year d2.year
    else if d1.month <> d2.month then Int.compare d1.month d2.month
    else Int.compare d1.day d2.day
  let (<) d1 d2= compare d1 d2<0
  let (>) d1 d2=compare d1 d2>0
  
  let (=) d1 d2=compare d1 d2=0
   let string_of_t d=(string_of_int d.day ) ^ ": " ^ (string_of_int d.month ) ^ ": " ^ (string_of_int d.year )
end

module DateSet=Set(DateComp)


let () =
  let open IntSet in
  let s = insert 2 (insert 2 (insert 1 (insert 3 empty))) in
  List.iter (Printf.printf "%d ") (elements s);
  print_newline ();
  Printf.printf "Member 2? %b\n" (member 2 s);

  let open StringSet in
  let s =
    insert "banana"
      (insert "apple"
        (insert "banana"
          (insert "cherry" empty)))
  in
  List.iter (fun x -> Printf.printf "%s " x) (elements s);
  print_newline ();
  Printf.printf "Member \"apple\"? %b\n" (member "apple" s);
  Printf.printf "Member \"grape\"? %b\n" (member "grape" s);

  let open DateSet in
  let d1 = {day =5;month=6;year= 2023} in
  let d2 = {day =1;month=1;year= 2022} in
  let d3 = {day =15;month=8;year= 2023} in
  let d4 = {day =5;month=6;year= 2023} in  (* duplicate *)

  let s =
    insert d1
      (insert d2
        (insert d3
          (insert d4 empty)))
  in
  List.iter
    (fun d -> Printf.printf "%s " (DateComp.string_of_t d))
    (elements s);
  print_newline ();
  Printf.printf "Member 5/6/2023? %b\n" (member d1 s)

