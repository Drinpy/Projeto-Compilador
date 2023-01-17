%{
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "lexico.c"
#include "utils.c"
int contaVar;       // conta o número de variáveis
int rotulo = 0;     // marcar lugares no código
%}

%token T_PROGRAMA
%token T_INICIO
%token T_FIM
%token T_LEIA
%token T_ESCREVA
%token T_SE
%token T_ENTAO
%token T_SENAO
%token T_FIMSE
%token T_ENQUANTO
%token T_FACA
%token T_FIMENQUANTO
%token T_INTEIRO
%token T_LOGICO
%token T_MAIS
%token T_MENOS
%token T_VEZES
%token T_DIV
%token T_MAIOR
%token T_MENOR
%token T_IGUAL
%token T_E 
%token T_OU 
%token T_NAO
%token T_ABRE
%token T_FECHA
%token T_ATRIBUICAO
%token T_V 
%token T_F 
%token T_IDENTIFICADOR
%token T_NUMERO

%start programa

%left T_E T_OU
%left T_IGUAL
%left T_MAIOR T_MENOR
%left T_MAIS T_MENOS
%left T_VEZES T_DIV

%%

programa 
    : cabecalho 
        { contaVar = 0; }
    variaveis 
        {
            mostraTabela();
            empilhar(contaVar); 
            if (contaVar) 
                fprintf(yyout,"\tAMEM\t%d\n", contaVar); 
        }
    T_INICIO lista_comandos T_FIM
        { 
            int conta = desempilha();
            if (conta)
                fprintf(yyout, "\tDMEM\t%d\n", conta); 
            fprintf(yyout, "\tFIMP\n");
        }
    ;

cabecalho
    : T_PROGRAMA T_IDENTIFICADOR
        { fprintf(yyout,"\tINPP\n"); }
    ;

variaveis
    : /* vazio */
    | declaracao_variaveis
    ;

declaracao_variaveis
    : tipo lista_variaveis declaracao_variaveis
    | tipo lista_variaveis
    ;

tipo 
    : T_LOGICO
    | T_INTEIRO
    ;

lista_variaveis
    : lista_variaveis T_IDENTIFICADOR 
        {  
            strcpy(elemTab.id, atomo);
            elemTab.end = contaVar;
            insereSimbolo(elemTab);
            contaVar++;            
        }
    | T_IDENTIFICADOR
        { 
            strcpy(elemTab.id, atomo);
            elemTab.end = contaVar;
            insereSimbolo(elemTab);
            contaVar++;               
        }
    ;

lista_comandos
    : /* vazio */
    | comando lista_comandos
    ;

comando 
    : entrada_saida
    | repeticao
    | selecao
    | atribuicao 
    ;

entrada_saida
    : leitura
    | escrita
    ;

leitura 
    : T_LEIA T_IDENTIFICADOR
        { 
            int pos = buscaSimbolo(atomo);         
            fprintf(yyout,"\tLEIA\n\tARZG\t%d\n", tabSimb[pos].end); 
        }
    ;

escrita 
    : T_ESCREVA expressao
        { fprintf(yyout,"\tESCR\n"); }
    ;

repeticao
    : T_ENQUANTO 
        { 
            fprintf(yyout,"L%d\tNADA\n", ++rotulo);     // L de label 
            empilhar(rotulo);
        } 
    expressao T_FACA 
        { 
            fprintf(yyout,"\tDSVF\tL%d\n", ++rotulo); 
            empilhar(rotulo);
        }
    lista_comandos 
    T_FIMENQUANTO
        { 
            int rot1 = desempilha();
            int rot2 = desempilha();
            fprintf(yyout,"\tDSVS\tL%d\nL%d\tNADA\n", rot2, rot1); 
            fprintf(yyout,"L%d\tNADA\n", rot1);
        }
    ;

selecao
    : T_SE expressao T_ENTAO 
        { 
            fprintf(yyout,"\tDSVF\tL%d\n", ++rotulo); 
            empilhar(rotulo);
        }
    lista_comandos T_SENAO
        { 
            int rot = desempilha();
            fprintf(yyout,"\tDSVS\tL%d\n", ++rotulo); 
            fprintf(yyout,"L%d\tNADA\n", rot); 
            empilhar(rotulo);
        }
    lista_comandos T_FIMSE
        { 
            int rot = desempilha();
            fprintf(yyout,"L%d\tNADA\n", rot); 
        }
    ;

atribuicao
    : T_IDENTIFICADOR
        {
            int pos = buscaSimbolo(atomo);
            empilhar(pos);
        }
    T_ATRIBUICAO expressao
        { 
            int pos = desempilha();
            fprintf(yyout,"\tARZG\t%d\n", tabSimb[pos].end); 
        }
    ;

expressao
    : expressao T_VEZES expressao
        { fprintf(yyout,"\tMULT\n"); }
    | expressao T_DIV expressao
        { fprintf(yyout,"\tDIVI\n"); }
    | expressao T_MAIS expressao
        { fprintf(yyout,"\tSOMA\n"); }
    | expressao T_MENOS expressao
        { fprintf(yyout,"\tSUBT\n"); }
    | expressao T_MAIOR expressao
        { fprintf(yyout,"\tCMMA\n"); }
    | expressao T_MENOR expressao
        { fprintf(yyout,"\tCMME\n"); }
    | expressao T_IGUAL expressao
        { fprintf(yyout,"\tCMIG\n"); }
    | expressao T_E expressao
        { fprintf(yyout,"\tCONJ\n"); }
    | expressao T_OU expressao
        { fprintf(yyout,"\tDISJ\n"); }
    | termo
    ;

termo
    : T_IDENTIFICADOR
        {
            int pos = buscaSimbolo(atomo);
            fprintf(yyout,"\tCRVG\t%d\n", tabSimb[pos].end); 
            
        }
    | T_NUMERO
        { fprintf(yyout,"\tCRCT\t%s\n", atomo); }
    | T_V
        { fprintf(yyout,"\tCRCT\t1\n"); }
    | T_F
        { fprintf(yyout,"\tCRCT\t0\n"); }
    | T_NAO termo
        { fprintf(yyout,"\tNEGA\n"); }
    | T_ABRE expressao T_FECHA
    ;

%%

int main (int argc, char *argv[]) {
    char *p, nameIn[100], nameOut[100]; // duas variáveis para guardar os nomes de saida e entrada
    argv++;
    if (argc < 2) {
        puts("\n Compilador Simples");
        puts("\n\tUso:./simples <NOME>[.simples]\n\n");
        exit(10);
    }
    p = strstr(argv[0], ".simples"); //função que procura uma string na string e posiciona no início
    if (p) *p = 0;
    strcpy(nameIn, argv[0]);
    strcat(nameIn, ".simples");
    strcpy(nameOut, argv[0]);
    strcat(nameOut, ".mvs");
    yyin = fopen (nameIn, "rt");
    if (!yyin) {
        puts("Programa fonte não encontrado!");
        exit(20);
    }
    yyout = fopen(nameOut, "wt");
    yyparse();
    puts ("Programa ok!");
}
