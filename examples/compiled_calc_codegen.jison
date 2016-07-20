//
// Stage 2(B) parser: 'The Back End = The Code Generator (Compiler Style)'
//
// TODO!
//
// See also the compiled_calc_exec source file: this is the alternative
// back-end which 'object code' output a working JavaScript sourcecode (!) representing 
// the formula, hence this is the *COMPILER* variant of that
// compile_calc_exec interpreter!
//
// The AST is stored in an array and since the AST acts as the INTERFACE
// between front-end and backend of the compiler/engine, its precise format
// is known to both 'parsers': the compile_calc_parse front-end and this
// back-end, plus additional back-ends which feed off the same AST for
// different purposes.
//
// This 'Pretty Printer' is designed to be FAST, hence the AST stream has been
// constructed the way it is, using a Polish Notation simile: this takes
// the fewest AST nodes and the fewest number of grammar rules to express 
// the entire formula calculation power.
//
// We also assume the AST is always valid (errors can be encoded in there, but
// we will exit HARD when your front-end screwed up the AST 'internal structure'
// in any way!), the result of which is that we now have enabled jison to 
// recognize the absence of all and any error checking and reporting facilities,
// which our JISON takes as an opportunity to create a severely stripped down,
// FAST grammar parser, hence a very fast 'tree walker'.
//
// Of course, the usual process is to write such a 'tree walker' by hand,
// but I want to showcase the concept here and there's something to say for
// readability as now AST format and actions performed on the atoms is 
// nicely separated! :-)
//
// ---
//
// A crucial detail is the use of the `%import` jison feature which allows
// us to import the symbol table generated by jison as part of the front-end
// parser engine: that way we have a guaranteed good set of token #IDs which we
// can use at both ends of the AST stream interface: this allows us to use 
// the other JISON feature which is `#<name>` in the action blocks everywhere:
// this will be expanded into the numeric ID of the given token by jison,
// saving us from having to generate and maintain a separate table of IDs
// for our AST objects!
//
// ---
//
// Note that the grammar is identical to the compile_calc_exec one: it's
// the ACTIONS which differ greatly!
//


%import symbols  "./output/compiled_calc/compiled_calc_parse.js"



%token      NUM                         // Simple double precision number  
%token      VAR FUNCTION PROCEDURE      // Variable and Function            
%token      CONSTANT                    // Predefined Constant Value, e.g. PI or E
%token      ERROR                       // Mark error in statement

%token      END                         // token to mark the end of a function argument list in the output token stream


%nonassoc  '='
%nonassoc  '-' '+'
%nonassoc  '*' '/' '%'
%nonassoc  POWER  
%nonassoc  '!'
%nonassoc  UMINUS     /* Negation--unary minus */
%nonassoc  UPLUS      /* unary plus */
%nonassoc  PERCENT    /* unary plus */

/* Grammar follows */

%start input


%parse-param globalSpace        // extra function parameter for the generated parse() API; we use this one to pass in a reference to our workspace for the functions to play with.



%%


input:   
  ε                             /* empty */
                                {
                                  $$ = [];
                                }
| input line
                                {
                                  $input.push($line);
				  $$ = $input;
                                }
;

line:
  exp  
                                { 
                                  console.log('expression result value: ', $exp); 
                                  $$ = $exp;
                                }
;

exp:
  NUM        
                                { $$ = $NUM; }
| CONSTANT        
                                { $$ = $CONSTANT; }
| VAR        
                                { $$ = yy.variables[$VAR]; }
| '=' VAR exp 
                                { $$ = yy.variables[$VAR] = $exp; }
| PROCEDURE 
                                { $$ = $PROCEDURE(globalSpace); }
| FUNCTION arglist END  
                                /* we MUST have that END token in the AST token stream as otherwise we get confused 
                                   (= *ambiguous grammar!*) whether one of those `exp` expressions in there maybe
                                   shouldn't have been the expression that's on **the next line** (i.e. *not part of
                                   this particular calculus expression*): this is because we don't store an 
                                   'end of expression' token between expression lines up there in the `input = (line)*`
                                   rule in the parser=AST token stream producer.
                                */
                                { $$ = $FUNCTION.apply(globalSpace, $arglist); }
| '+' exp exp         
                                { $$ = $exp1 + $exp2; }
| '-' exp exp         
                                { $$ = $exp1 - $exp2; }
| '*' exp exp         
                                { $$ = $exp1 * $exp2; }
| '/' exp exp         
                                { $$ = $exp1 / $exp2; }
| '%' exp exp         
                                { $$ = $exp1 % $exp2; }
| UMINUS exp 
                                { $$ = -$exp; }
| UPLUS exp
                                { $$ = +$exp; }
| POWER exp exp         
                                { $$ = Math.pow($exp1, $exp2); }
| '!' exp 
                                { $$ = yy.functions['factorial']($exp); }
| PERCENT exp 
                                { $$ = $exp / 100; }
;

arglist:
  exp
                                { $$ = [$exp]; }
| arglist exp
                                { $$ = $arglist.push($exp); }
;

/* End of grammar */


%%
