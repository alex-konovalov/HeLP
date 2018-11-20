#############################################################################
##
##                                                               HeLP package
##
##                                 Andreas Bächle, Vrije Universiteit Brussel
##                                        Leo Margolis, Universität Stuttgart
##
#############################################################################


########################################################################################################
########################################################################################################

InstallGlobalFunction(HeLP_ZC, function(GC)
# Argument: an ordinary character table or a group
# Output: true if ZC can be proved using the HeLP method and the data available in GAP or false otherwise. On higher info-levels it prints more information.
local UCT, C, o, op, posords, p, BT_not_available, j, k, T, oldsol, intersol, interintersol, CharTabs, solved, ord, prob, issolvable, isnotpsolvable, result_orders, critical_orders;
if not IsOrdinaryTable(GC) then
  if not IsGroup(GC) then
    Error( "Function HeLP_ZC has to be called with an ordinary character table or a group.");
  else
    if IsNilpotent(GC) then # if the group is nilpotent then ZC is true by [Weiss91]
      Print("Since the given group is nilpotent the Zassenhaus Conjecture holds by a result of Al Weiss.\n");
      return true;
    else
      C := CharacterTable(GC);
      if C = fail then
        Error( "Calculation of the character table of the given group failed.");
      fi;
    fi;
  fi;
else
  if IsNilpotent(GC) then  # if the group belonging to the character table given is nilpotent then ZC is true by [Weiss91]
    Print("Since the given group is nilpotent the Zassenhaus Conjecture holds by a result of Al Weiss.\n");
    return true;
  else
     C := GC;
  fi;
fi;
ord := OrdersClassRepresentatives(C);
o := DuplicateFreeList(ord);
op := Filtered(o, m -> IsPrime(m));
issolvable := IsSolvable(C);
isnotpsolvable := Filtered(op, p -> not IsPSolvableCharacterTable(C, p));
# if the group is p-solvable the p-Brauer table will not provide any additional information (by Fong-Swan-Rukolaine [CR81, 22.1]), so it will not be used
if issolvable then
  posords := Filtered(o, d -> not d = 1);# for solvable groups its known that the orders of torsion units coincide with orders of group elements 
				#[Her08a, The orders of torsion units in integral group rings of finite solvable groups]
else
  posords := Filtered(DivisorsInt(Lcm(o)), k -> not k = 1); #All divisors of the exponent of the group, i.e. the orders to be checked in the case of non-solvable groups
fi;
posords := SortedList(posords);
BT_not_available := [];
CharTabs := [C];    # calculate all character tables of interest, which are availbale in GAP and sort them wrt the smallest character degree
for p in isnotpsolvable do
  T := C mod p;
  if not T = fail then
    Add(CharTabs, T);
  else
    Add(BT_not_available, p);
  fi;
od;
CharTabs := HeLP_SortCharacterTablesByDegreesINTERNAL(CharTabs);
HeLP_CheckCharINTERNAL(Irr(C));
for k in posords do
  Info( HeLP_Info, 2, "Checking order ", k, ".");
  j := 1;
  if IsBound(HeLP_sol[k]) then  # use the given pa's
    Info( HeLP_Info, 3, "  Using the known solutions for elements of order ", k, ".");
    intersol := HeLP_sol[k];
  else				# calculate a finite list of pa's
    Info( HeLP_Info, 3, "  Calculating the solutions for elements of order ", k, ".");
    while not IsBound(intersol) and j <= Size(CharTabs) do
      T := CharTabs[j];
      HeLP_ChangeCharKeepSols(T);
      Info(HeLP_Info, 3, "  Using table ", T, "."); 
      interintersol := HeLP_WithGivenOrderINTERNAL(Irr(T), k);
      if interintersol = "infinite" then
        Error("Unexpected theoretical error.  Please report this to the authors.");
      fi;
      if not interintersol = "non-admissible" then
        intersol := interintersol;
      fi;
      j := j + 1;
    od;
  fi;
  while not HeLP_IsTrivialSolutionINTERNAL(intersol, k, ord) and j <= Size(CharTabs) do
    T := CharTabs[j];		# test with so far not used character tables
    HeLP_ChangeCharKeepSols(T);
    Info(HeLP_Info, 3, "  Using table ", T, "."); 
    interintersol := HeLP_VerifySolutionINTERNAL(T, k, intersol);
    if not interintersol = "non-admissible" then
      intersol := interintersol;
    fi;
    j := j + 1;
  od;
  HeLP_sol[k] := HeLP_WagnerTestINTERNAL(k, intersol, SortedList( Filtered(ord, d -> k mod d = 0 and (not d = 1)) ) );
  if not Size(HeLP_sol[k]) = Size(intersol) then
    Info(HeLP_Info, 4, "  Wagner test for order ", k, " eliminated ", Size(intersol) - Size(HeLP_sol[k]), " possible partial augmentations.");
  fi;
  Unbind(intersol);
od;
result_orders := List(posords, k -> [k, HeLP_IsTrivialSolutionINTERNAL(HeLP_sol[k], k, ord)]);
critical_orders := List(Filtered(result_orders, w -> w[2] = false), v -> v[1]);
if critical_orders <> [] and BT_not_available <> [] then  # not issolvable and 
  Info( HeLP_Info, 1, "The Brauer tables for the following primes are not available: ", Set(BT_not_available), ".");
fi;
if critical_orders <> [] then
  Info( HeLP_Info, 1, "(ZC) can't be solved, using the given data, for the orders: ", critical_orders, ".");
fi;
return critical_orders = [];
end);

 

########################################################################################################

InstallGlobalFunction(HeLP_PQ, function(GC)
# Argument: an ordinary character table or a group
# Output: true if PQ can be proved using the HeLP method and the data available in GAP or false otherwise. On higher info-levels it prints more information.
local C, o, op, crit, crit_p, k, oldsol, j, isnotpsolvable, intersol, interintersol, CharTabs, p, BT_not_available, T, ord, result_orders, critical_orders;
if not IsOrdinaryTable(GC) then
  if not IsGroup(GC) then
    Error( "Function HeLP_PQ has to be called with an ordinary character table or a group.");
  else
    if IsSolvable(GC) then # if the group is solvable then PQ has an affirmative answer by [Kimmerle06]
      Print("Since the group is solvable, the Prime Graph Question has an affirmative answer for this group by a result of W. Kimmerle.\n");  
      return true;
    else
      C := CharacterTable(GC);
      if C = fail then
        Error( "Calculation of the character table of the given group failed.");
      fi;
    fi;
  fi;
else
  if IsSolvable(GC) then # if the group belonging to the character table given is solvable then PQ has an affirmative answer by [Kimmerle06]
    Print("Since the group is solvable, the Prime Graph Question has an affirmative answer for this group by a result of W. Kimmerle.\n");  
    return true;
  else
    C := GC;
  fi;
fi;
if IsSolvable(C) then # if the group is solvable then PQ has an affirmative answer by [Kimmerle06]
  Print("Since the group is solvable, the Prime Graph Question has an affirmative answer for this group by a result of W. Kimmerle.\n");  
  return true;
fi;
ord := OrdersClassRepresentatives(C);
o := DuplicateFreeList(ord);
op := Filtered(o, m -> IsPrime(m));
crit_p := [];
crit := [];
# check which edges are missing in the prime graph of G
for j in Combinations(op, 2) do
  if not Product(j) in o then
    Append(crit_p, j);
    Add(crit, Product(j));
  fi;
od;
crit_p := Set(crit_p);
crit := Set(crit);
BT_not_available := [];
# calculate all character tables that are available and of interest and sort them wrt the smallest character degree
CharTabs := [C];
isnotpsolvable := Filtered(op, p -> not IsPSolvableCharacterTable(C, p));
for p in isnotpsolvable do
  T := C mod p;
  if not T = fail then
    Add(CharTabs, T);
  else
    Add(BT_not_available, p);
  fi;
od;
CharTabs := HeLP_SortCharacterTablesByDegreesINTERNAL(CharTabs);
HeLP_CheckCharINTERNAL(Irr(C));
# calcuate the minimal possible solutions for elements of prime order involved in (PQ) and for order p*q
for k in Union(crit_p, crit) do
  Info( HeLP_Info, 2, "Checking order ", k, ".");
  j := 1;
  if IsBound(HeLP_sol[k]) then		# using the given pa's
    Info( HeLP_Info, 3, "  Using the known solutions for elements of order ", k, ".");
    intersol := HeLP_sol[k];
  else					# calculate a finite number of pa's
    Info( HeLP_Info, 3, "  Calculating the solutions for elements of order ", k, ".");
    while not IsBound(intersol) and j <= Size(CharTabs) do
      T := CharTabs[j];
      HeLP_ChangeCharKeepSols(T);
      Info(HeLP_Info, 3, "  Using table ", T, "."); 
      interintersol := HeLP_WithGivenOrderINTERNAL(Irr(T), k);
      if interintersol = "infinite" then
        Error("Unexpected theoretical error.  Please report this to the authors.");
      fi;
      if not interintersol = "non-admissible" then
        intersol := interintersol;
      fi;
      j := j + 1;
    od;
  fi;
  while not HeLP_IsTrivialSolutionINTERNAL(intersol, k, ord) and j <= Size(CharTabs) do
    T := CharTabs[j];			# test with so far not used character tables
    HeLP_ChangeCharKeepSols(T);
    Info(HeLP_Info, 3, "  Using table ", T, "."); 
    interintersol := HeLP_VerifySolutionINTERNAL(T, k, intersol);
    if not interintersol = "non-admissible" then
      intersol := interintersol;
    fi;
    j := j + 1;
  od;
  HeLP_sol[k] := HeLP_WagnerTestINTERNAL(k, intersol, SortedList( Filtered(ord, d -> k mod d = 0 and (not d = 1)) ) );
  if not Size(HeLP_sol[k]) = Size(intersol) then
    Info(HeLP_Info, 4, "  Wagner test for order ", k, " eliminated ", Size(intersol) - Size(HeLP_sol[k]), " possible partial augmentations.");
  fi;
  Unbind(intersol);
od;
result_orders := List(crit, k -> [k, HeLP_IsTrivialSolutionINTERNAL(HeLP_sol[k], k, ord)]);
critical_orders := List(Filtered(result_orders, w -> w[2] = false), v -> v[1]);
if critical_orders <> [] and BT_not_available <> [] then
  Info( HeLP_Info, 1, "The Brauer tables for the following primes are not available: ", Set(BT_not_available), ".");
fi;
if critical_orders <> [] then
  Info( HeLP_Info, 1, "(PQ) can't be solved, using the given data, for the orders: ", critical_orders, ".");
fi;
return critical_orders = [];
end);



########################################################################################################
########################################################################################################

InstallGlobalFunction(HeLP_AllOrders, function(GC)
# Argument: an ordinary character table or a group
# Output: true if ZC can be proved using the HeLP method and the data available in GAP or false otherwise. On higher info-levels it prints more information.
local UCT, C, o, op, posords, p, BT_not_available, j, k, T, oldsol, intersol, interintersol, CharTabs, solved, ord, prob, issolvable, isnotpsolvable, result_orders, critical_orders;
if not IsOrdinaryTable(GC) then
  if not IsGroup(GC) then
    Error( "Function HeLP_ZC has to be called with an ordinary character table or a group.");
  else
    C := CharacterTable(GC);
    if C = fail then
     Error( "Calculation of the character table of the given group failed.");
    fi;
  fi;
else
   C := GC;
fi;
ord := OrdersClassRepresentatives(C);
o := DuplicateFreeList(ord);
op := Filtered(o, m -> IsPrime(m));
issolvable := IsSolvable(C);
isnotpsolvable := Filtered(op, p -> not IsPSolvableCharacterTable(C, p));
# if the group is p-solvable the p-Brauer table will not provide any additional information (by Fong-Swan-Rukolaine [CR81, 22.1]), so will not be used
if issolvable then
  posords := Filtered(o, d -> not d = 1);# for solvable groups its known that the orders of torsion units coincide with orders of group elements 
				#[Her08, The orders of torsion units in integral group rings of finite solvable groups]
else
  posords := Filtered(DivisorsInt(Lcm(o)), k -> not k = 1); #All divisors of the exponent of the group, i.e. the orders to be checked
fi;
posords := SortedList(posords);
BT_not_available := [];
CharTabs := [C]; # calculate all character tables that are available and sort them wrt the smallest character degree
for p in isnotpsolvable do
  T := C mod p;
  if not T = fail then
    Add(CharTabs, T);
  else
    Add(BT_not_available, p);
  fi;
od;
CharTabs := HeLP_SortCharacterTablesByDegreesINTERNAL(CharTabs);
HeLP_CheckCharINTERNAL(Irr(C));
for k in posords do
  Info( HeLP_Info, 2, "Checking order ", k, ".");
  j := 1;
  if IsBound(HeLP_sol[k]) then  # use the given pa's
    Info( HeLP_Info, 3, "  Using the known solutions for elements of order ", k, ".");
    intersol := HeLP_sol[k];
  else				# calculate a finite list of pa's
    Info( HeLP_Info, 3, "  Calculating the solutions for elements of order ", k, ".");
    while not IsBound(intersol) and j <= Size(CharTabs) do
      T := CharTabs[j];
      HeLP_ChangeCharKeepSols(T);
      Info(HeLP_Info, 3, "  Using table ", T, "."); 
      interintersol := HeLP_WithGivenOrderINTERNAL(Irr(T), k);
      if interintersol = "infinite" then
        Error("Unexpected theoretical error.  Please report this to the authors.");
      fi;
      if not interintersol = "non-admissible" then
        intersol := interintersol;
      fi;
      j := j + 1;
    od;
  fi;
  while not HeLP_IsTrivialSolutionINTERNAL(intersol, k, ord) and j <= Size(CharTabs) do
    T := CharTabs[j];		# test with so far not used character tables
    HeLP_ChangeCharKeepSols(T);
    Info(HeLP_Info, 3, "  Using table ", T, "."); 
    interintersol := HeLP_VerifySolutionINTERNAL(T, k, intersol);
    if not interintersol = "non-admissible" then
      intersol := interintersol;
    fi;
    j := j + 1;
  od;
  HeLP_sol[k] := HeLP_WagnerTestINTERNAL(k, intersol, SortedList( Filtered(ord, d -> k mod d = 0 and (not d = 1)) ) );
  if not Size(HeLP_sol[k]) = Size(intersol) then
    Info(HeLP_Info, 4, "  Wagner test for order ", k, " eliminated ", Size(intersol) - Size(HeLP_sol[k]), " possible partial augmentations.");
  fi;
  Unbind(intersol);
od;
result_orders := List(posords, k -> [k, HeLP_IsTrivialSolutionINTERNAL(HeLP_sol[k], k, ord)]);
critical_orders := List(Filtered(result_orders, w -> w[2] = false), v -> v[1]);
if critical_orders <> [] and BT_not_available <> [] then
  Info( HeLP_Info, 1, "The Brauer tables for the following primes are not available: ", Set(BT_not_available), ".\n");
fi;
if critical_orders <> [] then
  Info( HeLP_Info, 1, "(ZC) can't be solved, using the given data, for the orders: ", critical_orders, ".");
fi;
return critical_orders = [];
end);

 

########################################################################################################

InstallGlobalFunction(HeLP_AllOrdersPQ, function(GC)
# Argument: an ordinary character table or a group
# Output: true if PQ can be proved using the HeLP method and the data available in GAP or false otherwise. On higher info-levels it prints more information.
local C, o, op, crit, crit_p, k, oldsol, j, isnotpsolvable, intersol, interintersol, CharTabs, p, BT_not_available, T, ord, result_orders, critical_orders;
if not IsOrdinaryTable(GC) then
  if not IsGroup(GC) then
    Error( "Function HeLP_PQ has to be called with an ordinary character table or a group.");
  else
    C := CharacterTable(GC);
    if C = fail then
      Error( "Calculation of the character table of the given group failed.");
    fi;
  fi;
else
    C := GC;
fi;
ord := OrdersClassRepresentatives(C);
o := DuplicateFreeList(ord);
op := Filtered(o, m -> IsPrime(m));
crit_p := [];
crit := [];
# check which edges are missing in the prime graph of G
for j in Combinations(op, 2) do
  if not Product(j) in o then
    Append(crit_p, j);
    Add(crit, Product(j));
  fi;
od;
crit_p := Set(crit_p);
crit := Set(crit);
BT_not_available := [];
# calculate all character tables that are available and sort them wrt the smallest character degree
CharTabs := [C];
isnotpsolvable := Filtered(op, p -> not IsPSolvableCharacterTable(C, p));
for p in isnotpsolvable do
  T := C mod p;
  if not T = fail then
    Add(CharTabs, T);
  else
    Add(BT_not_available, p);
  fi;
od;
CharTabs := HeLP_SortCharacterTablesByDegreesINTERNAL(CharTabs);
HeLP_CheckCharINTERNAL(Irr(C));
# calcuate the minimal possible solutions for elements of prime order involved in PQ
for k in Union(crit_p, crit) do
  Info( HeLP_Info, 2, "Checking order ", k, ".");
  j := 1;
  if IsBound(HeLP_sol[k]) then		# using the given pa's
    Info( HeLP_Info, 3, "  Using the known solutions for elements of order ", k, ".");
    intersol := HeLP_sol[k];
  else					# calculate a finite number of pa's
    Info( HeLP_Info, 3, "  Calculating the solutions for elements of order ", k, ".");
    while not IsBound(intersol) and j <= Size(CharTabs) do
      T := CharTabs[j];
      HeLP_ChangeCharKeepSols(T);
      Info(HeLP_Info, 3, "  Using table ", T, "."); 
      interintersol := HeLP_WithGivenOrderINTERNAL(Irr(T), k);
      if interintersol = "infinite" then
        Error("Unexpected theoretical error.  Please report this to the authors.");
      fi;
      if not interintersol = "non-admissible" then
        intersol := interintersol;
      fi;
      j := j + 1;
    od;
  fi;
  while not HeLP_IsTrivialSolutionINTERNAL(intersol, k, ord) and j <= Size(CharTabs) do
    T := CharTabs[j];			# test with so far not used character tables
    HeLP_ChangeCharKeepSols(T);
    Info(HeLP_Info, 3, "  Using table ", T, "."); 
    interintersol := HeLP_VerifySolutionINTERNAL(T, k, intersol);
    if not interintersol = "non-admissible" then
      intersol := interintersol;
    fi;
    j := j + 1;
  od;
  HeLP_sol[k] := HeLP_WagnerTestINTERNAL(k, intersol, SortedList( Filtered(ord, d -> k mod d = 0 and (not d = 1)) ) );
  if not Size(HeLP_sol[k]) = Size(intersol) then
    Info(HeLP_Info, 4, "  Wagner test for order ", k, " eliminated ", Size(intersol) - Size(HeLP_sol[k]), " possible partial augmentations.");
  fi;
  Unbind(intersol);
od;
result_orders := List(crit, k -> [k, HeLP_IsTrivialSolutionINTERNAL(HeLP_sol[k], k, ord)]);
critical_orders := List(Filtered(result_orders, w -> w[2] = false), v -> v[1]);
if critical_orders <> [] and BT_not_available <> [] then
  Info( HeLP_Info, 1, "The Brauer tables for the following primes are not available: ", Set(BT_not_available), ".");
fi;
if critical_orders <> [] then
  Info( HeLP_Info, 1, "(PQ) can't be solved, using the given data, for the orders: ", critical_orders, ".");
fi;
return critical_orders = [];
end);



########################################################################################################
########################################################################################################

InstallGlobalFunction(HeLP_WithGivenOrder , function(arg)
# arguments: arg[1] is a character table or a list of class functions
# arg[2] is the order of the unit in question
# output: Result obtainable using the HeLP method for the characters given in arg[1] for units of order arg[2]. The result is stored also in HeLP_sol[k]
local C, k, properdivisors, d, pa, npa, asol, UCT, primediv, p, act_pa, intersol;
if IsCharacterTable(arg[1]) then
  C := Irr(arg[1]);
elif IsList(arg[1]) then
  C := arg[1];
else
  Error("The first argument of HeLP_WithGivenOrder has to be a character table or a list of class functions.");
fi;
k := arg[2];
UCT := UnderlyingCharacterTable(C[1]);
if IsBrauerTable(UCT) and not Gcd(k, UnderlyingCharacteristic(UCT)) = 1 then
  Print("HeLP can't be applied in this case as the characteristic of the Brauer table divides the order of the unit in question.\n");
  return;
fi;
if not Lcm(OrdersClassRepresentatives(UCT)) mod k = 0 then
  Print("There is no unit of order ", k, " in ZG as it does not divide the exponent of the group G.\n");
  return [ ];
fi;
HeLP_CheckCharINTERNAL(C);
intersol := HeLP_WithGivenOrderINTERNAL(C, k);
if intersol = "infinite" then
  Info( HeLP_Info, 1, "The given data admit infinitely many solutions for elements of order ", k, ".");
  return;
elif intersol = "non-admissible" then
  Error("This should not happen! Call the authors.");
else
  HeLP_sol[k] := intersol;
  Info( HeLP_Info, 1, "Number of solutions for elements of order ", k, ": ", Size(HeLP_sol[k]), "; stored in HeLP_sol[", k, "].");
  return HeLP_sol[k];
fi;
end);

########################################################################################################

InstallGlobalFunction(HeLP_WithGivenOrderAndPA, function(arg)
# arguments: arg[1] is a character table or a list of class functions
# arg[2] is the order of the unit in question
# arg[3] partial augmentations of the powers
local C, k, divisors, W, UCT, intersol;
if IsCharacterTable(arg[1]) then
  C := Irr(arg[1]);
elif IsList(arg[1]) then
  C := arg[1];
else
  Error("The first argument of HeLP_WithGivenOrderAndPA has to be a character table or a list of characters.");
fi;
k := arg[2];
UCT := UnderlyingCharacterTable(C[1]);
if IsBrauerTable(UCT) and not Gcd(k, UnderlyingCharacteristic(UCT)) = 1 then
  Print("HeLP can't be applied in this case as the characteristic of the Brauer table divides the order of the unit in question.\n");
  return;
fi;
if not IsPosInt(Lcm(OrdersClassRepresentatives(UCT))/k) then
    Print("There is no unit of order ", k, " in ZG as it does not divide the exponent ", Lcm(OrdersClassRepresentatives(UCT)), " of the group G.\n");
    return [];
fi;
HeLP_CheckCharINTERNAL(C);
divisors := DivisorsInt(k);
W := HeLP_MakeSystemINTERNAL(C, k, UCT, arg[3]);
intersol := HeLP_TestSimplifiedSystemINTERNAL(W[1], W[2], k, arg[3]);
if intersol = "infinite" then
  Info( HeLP_Info, 1, "The given data admit infinitely many solutions for elements of order ", k, "."); 
  return;
else
  Info(HeLP_Info, 1,  "Number of solutions for elements of order ", k, " with these partial augmentations for the powers: ", Size(intersol), ".");
  return intersol;
fi;
end);


########################################################################################################

InstallGlobalFunction(HeLP_WithGivenOrderSConstant, function(arg)
## HeLP_WithGivenOrderSConstant(C, s, t)
## C a character table or a collection of class functions
## s, t rational primes
## tests which partial augmentations for elements of order s*t are admissable using those characters from C that are s-constant
local C, s, t, chars, W, UCT, paq, spq, o, tintersol, intersol;
if IsCharacterTable(arg[1]) then
  C := Irr(arg[1]);
elif IsList(arg[1]) then
  C := arg[1];
else
  Error("The first argument of HeLP_WithGivenOrderSConstant has to be a character table or a list of class functions.");
fi;
s := arg[2];
t := arg[3];
UCT := UnderlyingCharacterTable(C[1]);
HeLP_CheckCharINTERNAL(C);
if not (IsPosInt(s) and IsPosInt(t) and IsPrime(s) and IsPrime(t)) or s = t then
  Error("HeLP_WithGivenOrderSConstant can only deal with arguments a list of characters and two different positive rational primes.\n");
fi;
o := OrdersClassRepresentatives(UCT);
if Size(Positions(o, s)) = 0 then
  Print("There are no elements of order ", s, " in G.\n");
  return;
fi;
if Size(Positions(o, t)) = 0 then
  Print("There are no elements of order ", t, " in G.\n");
  return;
fi;
if Size(Positions(o, s*t)) <> 0 then
  Print("There are elements of order ", s*t, " in G.\n");
  return;
fi;
if not IsBound(HeLP_sol[t]) then 
  Info( HeLP_Info, 2, "  Partial augmentations for elements of order ", t, " not yet calculated.  Restart for this order.");
  tintersol := HeLP_WithGivenOrderINTERNAL(C, t);
  if tintersol = "infinite" then
    Print("Solutions for elements of order ", t, " were not calculated.  When using the characters given in the first argument, there are infinitely many solutions for elements of order ", t, ".\n");
    Print("Calculate first a finite list for elements of order ", t, ".\n");
    return;   
  else 
    HeLP_sol[t] := tintersol;
  fi;
fi;
chars := HeLP_SConstantCharactersINTERNAL(Filtered(C, c -> not Set(ValuesOfClassFunction(c)) = [1]),  s, UCT);
if chars = [] then
  Print("There are no non-trivial irreducible ", s, "-constant characters in the list given.");
  return;
fi;
Info( HeLP_Info, 3, "  Number of non-trivial ", s, "-constant characters in the list: ", Size(chars), ".");
spq := [];
for paq in HeLP_sol[t] do
  if InfoLevel(HeLP_Info) >= 4 then
    Print("#I      Testing possibility ", Position(HeLP_sol[t], paq), "/", Size(HeLP_sol[t]), ".\r");
  fi;
  # Workaround to use carriage return in InfoLevel
  W := HeLP_MakeSystemSConstantINTERNAL(chars, s, t, UCT, paq[1]);
  intersol := HeLP_TestSimplifiedSystemINTERNAL(W[1], W[2], s*t, [[1], paq[1]]);
  if intersol = "infinite" then
    Print("The given data admits infinitely many solutions.\n");
    return "infinite";
  else 
    Append(spq, intersol);
  fi;
od;
if InfoLevel(HeLP_Info) >= 4 then
  Print("                                                                              \r");
fi;
if spq = [] then
  HeLP_sol[s*t] := [];			# if by using s-constant characters the existence of elements of order s*t can be excluded, this is stored in the global variable HeLP_sol
fi;
return List(spq, x -> x{[2,3]});	# {[2,3]} -> don't return the "fake" p.a. for elements of order s
end);


########################################################################################################

InstallGlobalFunction(HeLP_AddGaloisCharacterSums, function(C)
## HeLP_AddGaloisCharacterSums(C)
##  C a character table of a group
##  returns a list of sums of Galois conjugate characters
local gm, galoisfams, i;
if not IsOrdinaryTable(C) then
  Error("The argument of HeLP_AddGaloisCharacterSums has to be an ordinary character table.");
fi;
gm := GaloisMat(Irr(C)).galoisfams;
galoisfams :=[];
for i in [1..Size(gm)] do
  if gm[i] = 1 then
    Add(galoisfams, [i]);
  elif IsList(gm[i]) then
    Add(galoisfams, gm[i][1]);
  fi;
od;
return DuplicateFreeList(Concatenation(List(galoisfams, x -> Sum(Irr(C){x})), Irr(C)));
end);

########################################################################################################

InstallGlobalFunction(HeLP_ChangeCharKeepSols, function(CT)
# Arguments: a character table
# Output: nothing
# Changes the user character table to the one given as argument without doing any checks
Info(HeLP_Info, 5, "WARNING: Change used character table without checking if the character tables have the same underlying groups and the ordering of the conjugacy classes are the same!");
MakeReadWriteGlobal("HeLP_CT");  
UnbindGlobal("HeLP_CT");
BindGlobal("HeLP_CT", CT);
end);

##############################################################################################################

InstallGlobalFunction(HeLP_Reset, function()
# Arguments: none
# output: none
# Delets all values calculated so far and rests the varaibles to the inital value
MakeReadWriteGlobal("HeLP_CT");  
UnbindGlobal("HeLP_CT");
BindGlobal("HeLP_CT", CharacterTable(SmallGroup(1,1)));
HeLP_sol := [[[[1]]]];     
end);



##########################################################################################################

InstallGlobalFunction(HeLP_MultiplicitiesOfEigenvalues, function(chi, k, paraugs)
## HeLP_MultiplicitiesOfEigenvalues(chi, k, paraugs)
## chi a character, k the order of the unit u in question, paraugs a list of partial augmentations of u^d (d|k) in ascending order of the elements starting with the partial augmentation of u^k
## returns a list with the mutliplicities of the eigenvalues E(k)^l, l=0, 1, ..., k-1 starting with 
local pdivisors, d, e, T, a, o, posconk, poscondiv, poscondivd, mu, pas;
pdivisors := Filtered(DivisorsInt(k), n -> not (n=k));
o := OrdersClassRepresentatives(UnderlyingCharacterTable(chi));
poscondiv := [];
posconk := [];
if k = 1 then
  pas := paraugs;
else
  pas := Concatenation([[1]], paraugs);   # add partial augmentation of u^k = 1
fi;
for d in pdivisors do
    # determine on which conjugacy classes the unit and its powers might have non-trivial partial augmentations
    if d = 1 then
       Add(poscondiv, Positions(o, 1));
    else
      poscondivd := [];
      for e in Filtered(DivisorsInt(d), f -> not (f = 1)) do
         Append(poscondivd, Positions(o, e));
      od;
      Add(poscondiv, poscondivd);
      Append(posconk, Positions(o, d));
    fi;
od;
Append(posconk, Positions(o, k));
T := 1/k*HeLP_MakeCoefficientMatrixCharINTERNAL(chi, k, posconk);
a := 1/k*HeLP_MakeRightSideCharINTERNAL(chi, k, pdivisors, poscondiv, pas{[1..Size(pas)-1]});
mu := T*pas[Size(pas)] + a;
#tests if the eigenvalues sum up to the correct character value; remove this test later
if not (mu*List([0..k-1], j -> E(k)^j) = chi{posconk}*pas[Size(pas)]) then
  Print("Multiplicities don't give the charactervalue!", mu*List([0..k-1], j -> E(k)^j), chi{posconk}*pas[Size(pas)]);
fi;
return T*pas[Size(pas)] + a;
end);

##############################################################################################################

InstallGlobalFunction(HeLP_CharacterValue, function(chi, k, paraug)
## HeLP_CharacterValue(chi, k, paraug)
## chi a character, k the order of the unit u in question, paraug a list of the partial augmentations of u
## returns a list with the mutliplicities of the eigenvalues E(k)^l, l=0, 1, ..., k-1 starting with 
local pdivisors, d, o, posconk;
o := OrdersClassRepresentatives(UnderlyingCharacterTable(chi));
if k = 1 then
  posconk := Positions(o, 1);
else
  pdivisors := Filtered(DivisorsInt(k), n -> not (n=1));
  posconk := [];
  for d in pdivisors do
    # determine on which conjugacy classes the unit and its powers might have non-trivial partial augmentations
      Append(posconk, Positions(o, d));
  od;
fi;
return chi{posconk}*paraug;
end);


##############################################################################################################

InstallGlobalFunction(HeLP_WagnerTest, function(arg)
## Arguments: order of unit [list of possible partial augmentations for units of this order, ordinary character table]
## Output: list of possible partial augmentations for units of this order after applying the Wagner test
local k, list_paraugs, o, pd, fac, filtered_solutions, p, s, v, pexp, i, pos;
if Size(arg) = 1 and IsPosInt(arg[1]) then
  # one argument: the order of the units
  k := arg[1];
  if IsBound(HeLP_sol[k]) then
    list_paraugs := HeLP_sol[k];
  else 
    Error("The solutions for elements of order ", k, " are not yet calculated.");
  fi;
  o := SortedList( Filtered(OrdersClassRepresentatives(HeLP_CT), d -> k mod d = 0 and (not d = 1)) );
  # o contains the orders of elements in conjugacy classes relevant for elements of order k
elif Size(arg) = 3 and (IsPosInt(arg[1]) and IsList(arg[2]) and IsOrdinaryTable(arg[3])) then
  # three arguments: the order of the units, the pa's to check and the ordinary character table -- only its head is used
  k := arg[1];  
  list_paraugs := arg[2];
  o := SortedList( Filtered(OrdersClassRepresentatives(arg[3]), d -> k mod d = 0 and (not d = 1)) );
  # o contains the orders of elements in conjugacy classes relevant for elements of order k
else
  Error("The arguments of HeLP_WagnerTest have to be either the order of the units in question or the order, the solutions to test and a character table   ");
fi;
pd := PrimeDivisors(k);
fac := FactorsInt(k);
pexp:=[];
for p in pd do
  Add(pexp, Size(Positions(fac,p)));
od;
filtered_solutions := [];
if IsPrimePowerInt(k) then
  for v in list_paraugs do
    s := true;
    for i in [1..pexp[1]-1] do
      pos := Positions(o, p^i); 
      if not Sum(v[Size(v)]{pos}) mod p = 0 then
        s := false;
        break;  
       fi;
    od;
    if s then
    Add(filtered_solutions, v);
    fi;  
  od;
else
  for v in list_paraugs do
    s := true; 
    for p in pd do 
      for i in [1..pexp[Position(pd,p)]] do
        pos := Positions(o, p^i); 
        if not Sum(v[Size(v)]{pos}) mod p = 0 then
          s := false;
          break;  
        fi;
      od;
    od;
    if s then
      Add(filtered_solutions, v);
    fi; 
  od;
fi;
return filtered_solutions;
end);


##############################################################################################################

InstallGlobalFunction(HeLP_VerifySolution, function(arg)
# Arguemnts: character table or list of class functions, an order k [list of partial augmentations]
# returns a list of admissable pa's or nothing (if there can not be a unit of that order for theoretical reasons or the method can not be applied)
# checks which of the pa's in HeLP_sol[k] (if there are 2 arguments given) or the pa's in the third  argument fulfill the HeLP-constraints
# from the class functions in the first argument
local C, k, list_paraugs, chars, W, npa, asol, UCT, mu, pa, NumArg;
C := arg[1];
k := arg[2];
NumArg := 3;
if Size(arg) = 3 then
  list_paraugs := arg[3];
elif Size(arg) = 2 and IsBound(HeLP_sol[k]) then
  list_paraugs := HeLP_sol[k];
  NumArg := 2;
else
  Error("HeLP_sol[", k,"] is not bound and there is no third argument given.");  
fi;
if IsCharacterTable(C) then
  chars := Irr(C);
elif IsList(C) then
  chars := C;
else
  Error("The first argument of HeLP_VerifySolution has to be a character table or a list of class functions.");
fi;
UCT := UnderlyingCharacterTable(chars[1]);
if IsBrauerTable(UCT) and Gcd(k, UnderlyingCharacteristic(UCT)) > 1 then
  Print("HeLP can't be applied in this case as the characteristic of the Brauer table divides the order of the unit in question.\n");
  return "non-admissible";
fi;
if not Lcm(OrdersClassRepresentatives(UCT)) mod k = 0 then
  Print("There is no unit of order ", k, " in ZG as it does not divide the exponent of the group G.\n");
  return [];
fi;
asol := [];    # stores the solutions which fulfill the conditions of the HeLP equations
for pa in list_paraugs do
  W := HeLP_MakeSystemINTERNAL(chars, k, UCT, pa{[1..Size(pa)-1]});
  mu := W[1]*pa[Size(pa)] + W[2];
  if HeLP_IsIntVectINTERNAL(mu) and not false in List(mu, x -> SignInt(x) > -1) then
    Add(asol, pa);
  fi;
od;
if NumArg = 2 then
  HeLP_sol[k] := asol;
fi;
return asol;
end);



##############################################################################################################
InstallGlobalFunction(HeLP_FindAndVerifySolution, function(C, k)
# Arguemnts: character table or list of class functions and an order k
# returns a list of admissable pa's or "infinite"
# Does the same as HeLP_WithGivenOrder but does not build up the system with all information at once, but rather class function by class function.
# If one class function is not enough to obtain a finite number of solutions it tests with 2, 3, ... class functions.
# As soon as there is a finite number of solution the function uses HeLP_Verify solution to check which of the solutions fulfill the constraints of all class functions given
local chars, UCT, t, D, d, j, S, intersol;
if IsCharacterTable(C) then
  chars := Irr(C);
elif IsList(C) then
  chars := C;
else
  Error("The first argument of HeLP_FindAndVerifySolution has to be a character table or a list of class functions.");
fi;
UCT := UnderlyingCharacterTable(chars[1]);
if IsBrauerTable(UCT) and not Gcd(k, UnderlyingCharacteristic(UCT)) = 1 then
  Print("HeLP can't be applied in this case as the characteristic of the Brauer table divides the order of the unit in question.\n");
  return;
fi;
if not Lcm(OrdersClassRepresentatives(UCT)) mod k = 0 then
  Print("There is no unit of order ", k, " in ZG as it does not divide the exponent of the group G.\n");
  return [];
fi;
HeLP_CheckCharINTERNAL(chars);
D := DuplicateFreeList(Filtered(chars, c -> not Set(ValuesOfClassFunction(c)) = [1]));
for d in Filtered(DivisorsInt(k), e -> not (e = 1 or e = k)) do
  if not IsBound(HeLP_sol[d]) then
    if HeLP_FindAndVerifySolution(D, d) = "infinite" then
      Print("There are infinitely many solutions for elements of order ", d, ", HeLP stopped.  Try with more characters.\n");
      return "infinite";
    fi;
  fi; 
od;
for j in [1..Size(D)] do
  S := Combinations([1..Size(D)], j);
  for t in S do
    if InfoLevel(HeLP_Info) >= 4 then
      Print("#I  Checking order ", k, " with possibility [", j, ":", Position(S,t), "]             \n");
    fi;
    intersol := HeLP_WithGivenOrderINTERNAL(D{t}, k);
    if not intersol = "infinite" then 
      break;
    fi;
  od;
  if not intersol = "infinite" then
    break;
  fi;
od;
if intersol = "infinite" then
  return "infinite";
else
  if InfoLevel(HeLP_Info) >= 4 then
    Print("#I  Checking whether the solution for order fulfil the constraints from the other characters.      \r");
  fi;
  intersol := HeLP_VerifySolution(D, k, intersol);
  HeLP_sol[k] := intersol;
  Info( HeLP_Info, 1, "Number of solutions for elements of order ", k, ": ", Size(HeLP_sol[k]), "; stored in HeLP_sol[", k, "].");
  return intersol;
fi;
end);


##############################################################################################################
InstallGlobalFunction(HeLP_PrintSolution, function(arg)
# Arguments: empty or order k for which the pa's should be printed
# return: nothing
# prints the solutions in a 'prety' way
local k, posdiv, w1, w2, w3, d, orders_calculated;
if arg = [] then
  # if there are no arguments the function prints all the solutions which were calculated so far
  orders_calculated := Filtered([1..Length(HeLP_sol)], y -> IsBound(HeLP_sol[y]) and not y = 1);
  for k in orders_calculated do
    HeLP_PrintSolution(k);
  od;
elif IsInt(arg[1]) then
  # prints the pa's for elements of order k
  k := arg[1];
  if IsBound(HeLP_sol[k]) then
    if HeLP_sol[k] = [] then
      Print("There are no admissible partial augmentations for elements of order ", k, ".\n");
    else
      w1 := [];
      w2 := [];
      w3 := [];
      if k = 1 then
        Add(w1, k);
        Add(w2, ClassNames(HeLP_CT){Positions(OrdersClassRepresentatives(HeLP_CT), 1)});
        Add(w3, "---");
        PrintArray(Concatenation([w1], [w2], [w3], HeLP_sol[k]));       
      else
        posdiv := Filtered(DivisorsInt(k), e -> not e = 1);
        for d in posdiv do
          if not d = k then 
            Add(w1, Concatenation("u^", String(k/d)));
          else
            Add(w1, "u");
          fi;
          Add(w2, Concatenation(List(Filtered(DivisorsInt(d), e -> e <> 1),
                  f -> ClassNames(HeLP_CT){Positions(OrdersClassRepresentatives(HeLP_CT), f)})));
          Add(w3, "---");
        od;
        Print("Solutions for elements of order ", k, ":\n");
        PrintArray(Concatenation([w1], [w2], [w3], HeLP_sol[k]));
      fi;     
    fi;
  else
    Print("Solutions for order ", k, " are not yet calculated.\n");      
  fi;
fi;
end);


#E