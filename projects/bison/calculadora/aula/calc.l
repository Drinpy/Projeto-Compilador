%{
#include "calc.h"
#include <stdlib.h>
void yyerror(char *);
%}

%%
[0-9]+      {yyval = atoi(yytext); return NUM;}
"+"         return MAIS;
"-"         return MENOS;
\n          return ENTER;
[ \t]       ;
.           yyerror("simbolo invalido");
%%
int yywrap(){return 1;}