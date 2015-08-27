%{

#include <cstdio>
#include <cstdlib>
#include <cstring>
#define YY_DECL extern "C" int yylex()
#include "element_desc.h"
#include "sintatico.h"

using namespace std;

extern void yyerror(const char *str); 

int lineNum = 1;
bool flagError = false;
string lastToken = "";
string buffer = "";
char str[(1 << 10)];

%}

DIGIT   [0-9]
CHAR    [a-zA-Z]
ID      [_a-zA-Z][_a-zA-Z0-9]*

%%

{DIGIT}+ {
    lastToken = yytext;
    yylval.intValue = int(yytext[0] - '0');
    return T_INTCONST;
}

"/*" {
        char pos;
        while( true )
        {
            pos = yyinput();
            while ( pos != '*' && pos != YY_NULL )
            {
                pos = yyinput();
            }
            if ( pos == '*' )
            {
                while ( pos == '*' && pos != YY_NULL ) pos = yyinput();
                if ( pos == '/' ) break;
            }
            if ( pos == YY_NULL )
            {
                string message = "ERRO: COMENTARIO NAO TERMINA (LINHA ";
                message += to_string(lineNum);
                message += ")";
                flagError = true;
                yyerror((char*)message.c_str());
                break;
            }
        }
    }

"\"" {
        buffer = "";
        while ( true )
        {
            char pos = yyinput();
            while ( pos != '\"' && pos != '\n' && pos != '\\' && pos != YY_NULL )
            {
                buffer += pos;
                pos = yyinput();
            }
            
            if ( pos == YY_NULL || pos == '\n' )
            {
                string message = "ERRO: EXCESSO DE CARACTERES (LINHA ";
                message += to_string(lineNum);
                message += ")";
                flagError = true;
                yyerror((char*)message.c_str());
                break;
            }
            else if ( pos == '\\')
            {
                pos = yyinput();
                if ( pos != YY_NULL ) buffer += pos;
                else
                {
                    string message = "ERRO: EXCESSO DE CARACTERES (LINHA ";
                    message += to_string(lineNum);
                    message += ")";
                    flagError = true;
                    yyerror((char*)message.c_str());
                    break;
                }
            }
            else if ( pos == '\"' )
            {
                lastToken = buffer;
                return T_STR;
            }
        }
    }

"\'" {
        char pos = yyinput();
        int next;
        if ( pos == '\'' )
        {
            string message = "ERRO: CONSTANTE DE CARACTERE VAZIO (LINHA ";
            message += to_string(lineNum);
            message += ")";
            yyerror((char*)message.c_str());
        }
        else
        {
            next = yyinput(); 
            if ( next == 92 )
            {
                next = yyinput();
                if ( next == 39 )
                {
                    lastToken = "\\";
                    return T_CHARCONST;
                }
            }
            else if ( next == 39 )
            {
                lastToken = "'";
                return T_CHARCONST;
            }
            flagError = true;
            string message = "ERRO: CONSTANTE DE CARACTERE COM MULTIPLOS CARACTERES (LINHA ";
            message += to_string(lineNum);
            message += ")";
            yyerror((char*)message.c_str());
        }
    }

"["         { lastToken = "["; return lastToken[0]; }

"]"         { lastToken = "]"; return lastToken[0]; }

"("         { lastToken = "("; return lastToken[0]; }

")"         { lastToken = ")"; return lastToken[0]; }

"="         { lastToken = "="; return lastToken[0]; }

"!="        { lastToken = "!"; return T_DIFF; }

"=="        { lastToken = "=="; return T_EQUAL; }

"<="        { lastToken = "<="; return T_LESS_EQUAL; }

">="        { lastToken = ">="; return T_GREATER_EQUAL; }

"<"         { lastToken = "<"; return lastToken[0]; }

">"         { lastToken = ">"; return lastToken[0]; }

","         { lastToken = ","; return lastToken[0]; }

"{"         { lastToken = "{"; return lastToken[0]; }

"}"         { lastToken = "}"; return lastToken[0]; }

"!"         { lastToken = "!"; return lastToken[0]; }

"?"         { lastToken = "?"; return lastToken[0]; }

":"         { lastToken = ":"; return lastToken[0]; }

"*"         { lastToken = "*"; return lastToken[0]; }

"%"         { lastToken = "%"; return lastToken[0]; }

"/"         { lastToken = "/"; return lastToken[0]; }

"-"         { lastToken = "-"; return lastToken[0]; }

"+"         { lastToken = "+"; return lastToken[0]; }

";"         { lastToken = ";"; return lastToken[0]; }

"programa"  { lastToken = "programa"; return T_PROGRAM; }

"car"       { lastToken = "car"; return T_CHAR; }

"int"       { lastToken = "int"; return T_INT; }

"retorne"   { lastToken = "retorne"; return T_RETURN; }

"leia"      { lastToken = "leia"; return T_READ; }

"escreva"   { lastToken = "escreva"; return T_WRITE; }

"novalinha" { lastToken = "novalinha"; return T_NEWLINE; }

"se"        { lastToken = "se"; return T_IF; }

"entao"     { lastToken = "entao"; return T_THEN; }

"senao"     { lastToken = "senao"; return T_ELSE; }

"enquanto"  { lastToken = "enquanto"; return T_WHILE; }

"execute"   { lastToken = "execute"; return T_EXECUTE; }

"e"         { lastToken = "e"; return T_AND; }

"ou"        { lastToken = "ou"; return T_OR; }

{ID}+       { lastToken = yytext; yylval.stringValue = new string(yytext); return T_ID; }

\n          lineNum++;

[ \t]+  ;

.   {
        string message = "ERRO: CARACTERE INVALIDO (LINHA ";
        message += to_string(lineNum);
        message += ")";
        flagError = true;
        yyerror((char*) message.c_str());
    }

%%