%{

#include <cstdio>
#include <cstring>
#include <algorithm>
#include "semantico.h"
#define ALL(V) V.begin(), V.end()
#define TI(Y) __typeof((Y).begin())
#define FORIT(i, X) for( TI(X) i = X.begin(); i != X.end(); ++i )
#define pb push_back

using namespace std;

extern "C" int yylex();
extern "C" int yyparse();
extern "C" FILE *yyin;
extern int lineNum;
extern string lastToken;
extern bool flagError;

void yyerror(const char *str);
int yylex(void);

bool ok = true;
Element *node;

%}

%union{
    int intValue;
    char charValue;
    string *stringValue;
    VarType varType;
    Element *node;
}

%start Programa

%token <intValue> T_INTCONST
%token <charValue> T_CHARCONST
%token <stringValue> T_STR
%token T_PROGRAM
%token T_RETURN
%token T_READ
%token T_WRITE
%token T_NEWLINE
%token T_IF
%token T_THEN
%token T_ELSE
%token T_WHILE
%token T_EXECUTE
%token <charValue> T_CHAR
%token <intValue> T_INT
%token <stringValue> T_ID
%token T_AND
%token T_OR
%token T_GREATER_EQUAL ">="
%token T_LESS_EQUAL "<="
%token T_EQUAL "=="
%token T_DIFF "!="
%type <node> DeclFuncVar ListaComando
%type <node> DeclFunc 
%type <node> ListaParametros ListaParametrosCont DeclVar ListaDeclVar
%type <node> DeclProg Comando
%type <varType> Tipo
%type <node> Bloco
%type <node> LValueExpr
%type <node> Expr AssignExpr CondExpr OrExpr AndExpr EqExpr DesigExpr AddExpr MulExpr UnExpr PrimExpr
%type <node> ListExpr

%%

Programa:
    DeclFuncVar DeclProg
    {
        //$1 - Statement_List
        //$2 - Statement

        node = new Element();
        node->lineNum = lineNum;
        node->nodeType = BLOCK;
        reverse( ALL($1->list) );
        node->list.pb($1);
        node->list.pb($2);
    };

DeclFuncVar:
    Tipo T_ID DeclVar ';' DeclFuncVar
    {
        //$1 - Tipo
        //$2 - T_ID
        //$3 - DeclVar
        //$4 - ';'
        //$5 - DeclFuncVar

        FORIT(i, $3->list)
            (*i)->varType = $1;

        Element *aux = new Element();
        aux->lineNum = lineNum;
        aux->nodeType = IDENTIFIER;
        aux->name = $2;

        Element *var = new Element();
        var->lineNum = lineNum;
        var->nodeType = VARIABLE;
        var->varType = $1;
        var->id = aux;

        $3->list.pb(var);
        $$ = $5;
        $$->list.pb($3);

    } |
    Tipo T_ID '['T_INTCONST']' DeclVar ';' DeclFuncVar
    {
        //$1 - Tipo
        //$2 - T_ID
        //$3 - '['
        //$4 - T_INTCONST
        //$5 - ']'
        //$6 - DeclVar
        //$7 - ';'
        //$8 - DeclFuncVar

        FORIT(i, $6->list)
            (*i)->varType = $1;

        Element *aux = new Element();
        aux->lineNum = lineNum;
        aux->name = $2;

        Element *var = new Element();
        var->varType = $1;
        var->lineNum = lineNum;
        var->nodeType = ARRAY_VARIABLE;
        var->id = aux;

        $6->list.pb(var);
        $$ = $8;
        $$->list.pb($6);
    } |
    Tipo T_ID DeclFunc DeclFuncVar
    {
        //$1 - Tipo
        //$2 - T_ID
        //$3 - DeclFund
        //$4 - DeclFuncVar

        Element *aux = new Element();
        aux->lineNum = lineNum;
        aux->name = $2;
        $3->id = aux;
        $3->varType = $1;
        $4->list.pb($3);
        $$ = $4;
    } |
    {
        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = LIST_VARIABLE;
    };

DeclProg :
    T_PROGRAM Bloco
    {
        //$1 - T_PROGRAM
        //#2 - Bloco

        Element *aux = new Element();
        aux->nodeType = IDENTIFIER;
        aux->name = new string("Programa");
        aux->lineNum = lineNum;

        Element *var = new Element();
        var->lineNum = lineNum;
        var->nodeType = EMPTY;

        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = FUNC_DECLARATION;
        $$->id = aux;
        $$->list.pb(var);
        $$->list.pb($2);
        $$->varType = VAR_EMPTY;
    };
    
DeclVar :
    ',' T_ID DeclVar
    {
        //$1 - ','
        //$2 - T_ID
        //$3 - DeclVar

        Element *aux = new Element();
        aux->lineNum = lineNum;
        aux->nodeType = IDENTIFIER;
        aux->name = $2;

        Element *var = new Element();
        var->lineNum = lineNum;
        var->nodeType = VARIABLE;
        var->id = aux;
        $$ = $3;
        $$->list.pb(var);

    } |
    ',' T_ID '['T_INTCONST']' DeclVar
    {
        //$1 - ','
        //$2 - T_ID
        //$3 - '['
        //$4 - T_INTCONST
        //$5 - ']'
        //$6 - DeclVar

        Element *aux = new Element();
        aux->lineNum = lineNum;
        aux->nodeType = IDENTIFIER;
        aux->name = $2;

        Element *var = new Element();
        var->lineNum = lineNum;
        var->nodeType = ARRAY_VARIABLE;
        var->id = aux;

        $$ = $6;
        $$->list.pb(var);
    } |
    {
        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = LIST_VARIABLE;
    };

DeclFunc :
    '('ListaParametros')' Bloco
    {
        //$1 - '('
        //$2 - ListaParametros
        //$3 - ')'
        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = FUNC_DECLARATION;
        $$->list.pb($2);
        $$->list.pb($4);
    };

ListaParametros :
    ListaParametrosCont
    {
        $$ = $1;
    } |
    {
        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = EMPTY;
    };


ListaParametrosCont :
    Tipo T_ID
    {
        //$1 - Tipo
        //$2 - T_ID

        Element *aux = new Element();
        aux->lineNum = lineNum;
        aux->nodeType = IDENTIFIER;
        aux->name = $2;

        Element *var = new Element();
        var->lineNum = lineNum;
        var->nodeType = VARIABLE;
        var->varType = $1;
        var->id = aux;

        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = LIST_VARIABLE;
        $$->list.pb(var);
    } |
    Tipo T_ID '['']'
    {
        //$1 - Tipo
        //$2 - T_ID
        //$3 - '['
        //$4 - ']'

        Element *aux = new Element();
        aux->lineNum = lineNum;
        aux->nodeType = IDENTIFIER;
        aux->name = $2;

        Element *var = new Element();
        var->lineNum = lineNum;
        var->nodeType = ARRAY_VARIABLE;
        var->varType = $1;
        var->id = aux;

        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = LIST_VARIABLE;
        $$->list.pb(var);

    } |
    Tipo T_ID ',' ListaParametrosCont
    {
        //$1 - Tipo
        //$2 - T_ID
        //$3 - ','
        //$4 - ListaParametrosCont

        Element *aux = new Element();
        aux->lineNum = lineNum;
        aux->nodeType = IDENTIFIER;
        aux->name = $2;

        Element *var = new Element();
        var->lineNum = lineNum;
        var->nodeType = VARIABLE;
        var->varType = $1;
        var->id = aux;

        $4->list.push_back(var);
        $$ = $4;
    } |
    Tipo T_ID '['']' ',' ListaParametrosCont
    {
        //$1 - Tipo
        //$2 - T_ID
        //$3 - '['
        //$4 - ']'
        //$5 - ','
        //$6 - ListaParametrosCont

        Element *aux = new Element();
        aux->lineNum = lineNum;
        aux->nodeType = IDENTIFIER;
        aux->name = $2;

        Element *var = new Element();
        var->lineNum = lineNum;
        var->nodeType = ARRAY_VARIABLE;
        var->varType = $1;
        var->id = aux;

        $6->list.pb(var);
        $$ = $6;
    };

Bloco :
    '{' ListaDeclVar ListaComando '}'
    {
        //$1 - '{'
        //$2 - ListaDeclVar
        //$3 - ListaComando
        //$4 - '}'

        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = BLOCK;

        reverse( ALL($3->list) );
        reverse( ALL($2->list) );
       
        $$->list.pb( $2 );
        $$->list.pb( $3 );
    } |
    '{' ListaDeclVar '}'
    {
        //$1 - '{'
        //$2 - ListaDeclVar
        //$3 - '}'

        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = BLOCK;

        reverse( ALL($2->list) );        
        $$->list.pb( $2 );
    };

ListaDeclVar:
    Tipo T_ID DeclVar ';' ListaDeclVar
    {
        //$1 - Tipo
        //$2 - T_ID
        //$3 - DeclVar
        //$4 - ';'
        //$5 - ListaDeclVar

        FORIT(i,$3->list)
            (*i)->varType = $1;
        
        Element *aux = new Element();
        aux->lineNum = lineNum;
        aux->nodeType = IDENTIFIER;
        aux->name = $2;

        Element *var = new Element();
        var->lineNum = lineNum;
        var->nodeType = VARIABLE;
        var->varType = $1;
        var->id = aux;

        $3->list.pb(var);
        $$ = $5;
        $$->list.pb( $3 );
    } |
    Tipo T_ID '['T_INTCONST']' DeclVar ';' ListaDeclVar
    {
        //$1 - Tipo
        //$2 - T_ID
        //$3 - '['
        //$4 - INTCONST
        //$5 - ']'
        //$6 - DeclVar
        //$7 - ';'
        //$8 - ListaDeclVar

        FORIT(i,$6->list)
            (*i)->varType = $1;

        Element *aux = new Element();
        aux->lineNum = lineNum;
        aux->nodeType = IDENTIFIER;
        aux->name = $2;

        Element *var = new Element();
        var->lineNum = lineNum;
        var->nodeType = ARRAY_VARIABLE;
        var->varType = $1;
        var->id = aux;

        $6->list.pb(var);
        $$ = $8;
        $$->list.pb( $6 );
    } |
    {
        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = LIST_VARIABLE;
    };

Tipo :
    T_INT{
        $$ = VAR_INTEGER;
    } | 
    T_CHAR{
        $$ = VAR_CHAR;
    };

ListaComando: 
    ListaDeclVar ListaComando
    {
        //$1 - ListaDeclVar
        //$2 - ListaComando

        $$ = $2;
        $$->list.pb( $1 );
    } |
    Comando 
    {
        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = STATEMENT;
        $$->list.pb( $1 );
    } |
    Comando ListaComando
    {
        //$1 - Comando
        //$2 - ListaComando

        $$ = $2;
        $$->list.pb( $1 );
    };

Comando:
    ';'
    {
        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = STATEMENT;
    } |
    Expr ';'
    {
        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = EXPRESSION;
        $$->list.pb( $1 );        
    } |
    T_RETURN Expr ';'
    {
        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = RETURN;
        $$->list.pb( $2 );
    } |
    T_READ LValueExpr ';'
    {
        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = READ;
        $$->list.pb( $2 );
    } |
    T_WRITE T_STR ';'
    {
        Element *aux = new Element();
        aux->lineNum = lineNum;
        aux->nodeType = STRING;
        aux->name = $2;

        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = WRITE;
        $$->varType = VAR_CHAR;
        $$->list.pb(aux);
    } |
    T_WRITE Expr ';'
    {
        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = WRITE;
        $$->varType = VAR_INTEGER;
        $$->list.pb( $2 );
    } |
    T_NEWLINE ';'
    {
        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = NEW_LINE;
    } |
    T_IF '(' Expr ')' T_THEN Comando
    {
        //$1 - T_IF
        //$2 - '('
        //$3 - Expr
        //$4 - ')'
        //$5 - T_THEN
        //$6 - Comando

        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = IF;
        $$->list.pb( $3 );
        $$->list.pb( $6 );
    } |
    T_IF '(' Expr ')' T_THEN Comando T_ELSE Comando
    {
        //$1 - T_IF
        //$2 - '('
        //$3 - Expr
        //$4 - ')'
        //$5 - T_THEN
        //$6 - Comando
        //$7 - T_ELSE
        //$8 - Comando

        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = ELSE;
        $$->list.pb($3);
        $$->list.pb($6);
        $$->list.pb($8);
    } |
    T_WHILE '(' Expr ')' T_EXECUTE Comando
    {
        //$1 - T_WHILE
        //$2 - '('
        //$3 - Expr
        //$4 - ')'
        //$5 - T_EXECUTE
        //$6 - Comando

        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = WHILE;
        $$->list.pb( $3 );
        $$->list.pb( $6 );
    } |
    Bloco
    {
        $$ = $1;
    };

Expr:
    AssignExpr
    {
        $$ = $1;
    };

AssignExpr:
    CondExpr
    {
        $$ = $1;
    } |
    LValueExpr '=' AssignExpr
    {
        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = ASSIGN;
        $$->list.pb( $1 );
        $$->list.pb( $3 );
    };

CondExpr:
    OrExpr
    {
        $$ = $1;
    } |
    OrExpr '?' Expr ':' CondExpr
    {
        //$1 - OrExpr
        //$2 - '?'
        //$3 - Expr
        //$4 - ':'
        //$5 - CondExpr

        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = TERNARY;
        $$->operatorType = CONDITIONAL;
        $$->list.pb( $1 );
        $$->list.pb( $3 );
        $$->list.pb( $5 );
    };

OrExpr:
    OrExpr T_OR AndExpr
    {
        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = BINARY;
        $$->operatorType = OR;
        $$->list.pb( $1 );
        $$->list.pb( $3 );
    } |
    AndExpr
    {
        $$ = $1; 
    };

AndExpr:
    AndExpr T_AND EqExpr
    {
        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = BINARY;
        $$->operatorType = AND;
        $$->list.pb( $1 );
        $$->list.pb( $3 );
    } |
    EqExpr
    {
        $$ = $1; 
    };

EqExpr:
    EqExpr T_EQUAL DesigExpr
    {
        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = BINARY;
        $$->operatorType = EQUAL;
        $$->list.pb( $1 );
        $$->list.pb( $3 );
    } |
    EqExpr T_DIFF DesigExpr
    {
        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = BINARY;
        $$->operatorType = DIFFERENT;
        $$->list.pb( $1 );
        $$->list.pb( $3 );
    } |
    DesigExpr
    {
        $$ = $1;
    };

DesigExpr:
    DesigExpr '<' AddExpr
    {
        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = BINARY;
        $$->operatorType = MINOR;
        $$->list.pb( $1 );
        $$->list.pb( $3 );
    } |
    DesigExpr '>' AddExpr
    {
        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = BINARY;
        $$->operatorType = MORE;
        $$->list.pb( $1 );
        $$->list.pb( $3 );
    } |
    DesigExpr T_GREATER_EQUAL AddExpr
    {
        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = BINARY;
        $$->operatorType = GREATER_EQUAL;
        $$->list.pb( $1 );
        $$->list.pb( $3 );
    } |
    DesigExpr T_LESS_EQUAL AddExpr
    {
        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = BINARY;
        $$->operatorType = LESS_EQUAL;
        $$->list.pb( $1 );
        $$->list.pb( $3 );
    } |
    AddExpr
    {
        $$ = $1;
    };

AddExpr:
    AddExpr '+' MulExpr
    {
        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = BINARY;
        $$->operatorType = SUM;
        $$->list.pb( $1 );
        $$->list.pb( $3 );
    } |
    AddExpr '-' MulExpr
    {
        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = BINARY;
        $$->operatorType = SUB;
        $$->list.pb( $1 );
        $$->list.pb( $3 );
    } |
    MulExpr
    {
        $$ = $1;
    };

MulExpr:
    MulExpr '*' UnExpr
    {
        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = BINARY;
        $$->operatorType = MULTIPLY;
        $$->list.pb( $1 );
        $$->list.pb( $3 );
    } | 
    MulExpr '/' UnExpr
    {
        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = BINARY;
        $$->operatorType = DIVIDE;
        $$->list.pb( $1 );
        $$->list.pb( $3 );
    } |
    MulExpr '%' UnExpr
    {
        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = BINARY;
        $$->operatorType = REST;
        $$->list.pb( $1 );
        $$->list.pb( $3 );
    } |
    UnExpr
    {
        $$ = $1;
    };

UnExpr:
    '-'PrimExpr
    {
        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = UNARY;
        $$->operatorType = NEGATIVE;
        $$->list.pb( $2 ); 
    } |
    '!'PrimExpr
    {
        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = UNARY;
        $$->operatorType = NEGATE;
        $$->list.pb( $2 ); 
    } |
    PrimExpr
    {
        $$ = $1;
    };

LValueExpr:
    T_ID '[' Expr ']'
    {
        $$ = new Element();
        $$->lineNum = lineNum;;
        $$->nodeType = ID_ARRAY;
        $$->name = $1;
        $$->list.pb( $3 ); 
    } |
    T_ID
    {
        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = IDENTIFIER;
        $$->name = $1;
    };

PrimExpr:
    T_ID '(' ListExpr ')'
    {
        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = FUNC_CALL;

        reverse( ALL($3->list) ); 
        
        $$->list.pb( $3 );
        $$->name = $1;
    } |
    T_ID '(' ')'
    {
        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = FUNC_CALL;
        $$->name = $1;
    } |
    T_ID '[' Expr ']'
    {
        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = ID_ARRAY;
        $$->name = $1;
        $$->list.pb( $3 );  
    } |
    T_ID
    {
        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = IDENTIFIER;
        $$->name = $1;
    } |
    T_CHARCONST
    {
        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = CHAR;
        $$->varType = VAR_CHAR;
        $$->charValue = $1;
    } |
    T_INTCONST
    {
        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = INTEGER;
        $$->varType = VAR_INTEGER;
        $$->intValue = $1;
    } |
    '(' Expr ')'
    {
        $$ = $2;
    };

ListExpr:
    AssignExpr
    {
        $$ = new Element();
        $$->lineNum = lineNum;
        $$->nodeType = EXPRESSION_LIST;
        $$->list.pb( $1 );
    } |
    ListExpr ',' AssignExpr
    {
        $$ = $1;
        $$->list.pb( $3 );
    };
%%

void yyerror( const char *str )
{
    if ( flagError ) cout << str << "\n";
    else cout << "ERRO SINTATICO EM " << lastToken << " (LINHA " << lineNum << ")\n";
    flagError = false;
    ok = false;
    exit(1);
}


int main(int argc, char *argv[])
{ 
    if ( argc != 2 )
    {
        flagError = true;
        yyerror("PARA EXECUTAR O PROGRAMA, DIGITE: ./cafezinho nome_arquivo_entrada");
        return -1;
    }
    
    FILE *f;
    if ( (f = fopen(argv[1], "r")) == NULL )
    {
        flagError = true;
        yyerror("NAO FOI POSSIVEL ABRIR O ARQUIVO.");
        return -1;
    }
    
    yyin = f;
    do
    {
        yyparse();
    }while ( !feof(yyin) );

    if ( ok == true )
    {
        cout << ( !checkSemantic() ? "NENHUM ERRO ENCONTRADO!\n" : "");
        /*map< string, stack<Element*> >::iterator it;
        for ( it = symbols.begin(); it != symbols.end(); it++ )
        {
            cout << it->first << " " << it->second.top()->varType << endl;
            stack<Element*> st = it->second;
            while ( !st.empty() )
            {
                Element* a = st.top();
                st.pop();
            }
        }*/
    }
    
    return 0;
}