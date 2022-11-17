%{
#include "lexico.c"
%}

%token NUM
%token MAIS
%token MENOS
%token ENTER

%start comando

%%
comando : expr ENTER;
    | ;

expr : NUM
    | expr MAIS expr
    | expr MENOS expr
    ;
%%

void yyerror (char *s){
    printf("ERROR: %s\n\n", s);
    exit(10);
}

int mains(void) {
    yyparse();
}

int main (void){
    if yyparse()
        puts("aceita!");
    else
        puts("rejeita!")
}