#ifndef semantico_h
#define semantico_h
#include <map>
#include <stack>
#include "element_desc.h"
#define pb push_back
#define mp make_pair

using namespace std;

extern Element *node;
extern "C" FILE *yyin;

typedef pair<string, int> si;

map< string, stack<Element*> > symbols;
stack<si> state_stack;
map<string, int> qtdArgs;

struct valueReturning
{
    VarType retValue;
    bool hasReturn;
};

bool checkSemantic( Element *node, int level, valueReturning &ret );

VarType checkType( Element * node )
{
    switch ( node->nodeType )
    {
        case INTEGER:
        case CHAR:
        case STRING:
        {
            //cout << "Entrou INTEGER - CHAR - STRING" << endl;
            return node->varType;
            //cout << "Saiu INTEGER - CHAR - STRING" << endl;
        }
        break;
        case ID_ARRAY:
        {
            //cout << "Entrou ID_ARRAY" << endl;
            string name = *(node->name);
            //cout << name << endl;
            if ( !symbols.count(name) )
            {
                cout << "ERRO SEMANTICO: ARRAY COM NOME [" << name << "] NAO FOI DECLARADO "
                    << "(LINHA " << node->lineNum << ")\n";
                return VAR_ERROR;
            }
            else if ( checkType( node->list[0] ) != VAR_INTEGER )
            {
                cout << "ERRO SEMANTICO: INDICE DO ARRAY [" << name << "] DEVE SER DO TIPO INTEIRO "
                    << " (LINHA " << node->lineNum << ")\n";
                return VAR_ERROR;
            }
            else if ( symbols[name].top()->nodeType != ARRAY_VARIABLE )
            {
                cout << "ERRO SEMANTICO: TIPO DO ARRAY [" << name << "] NAO E ESPERADO "
                    << "(LINHA " << node->lineNum << ")\n"; 
                return VAR_ERROR;
            }
            //cout << "Saiu ID_ARRAY" << endl;
            return symbols[name].top()->varType;
        }
        break;
        case IDENTIFIER:
        {
            //cout << "Entrou IDENTIFIER" << endl;
            string name = *(node->name);
            if ( !symbols.count(name) )
            {
                cout << "ERRO SEMANTICO: IDENTIFICADOR [" << name << "] NAO FOI DECLARADO "
                    << "(LINHA " << node->lineNum << ")\n";
                return VAR_ERROR;
            }
            return symbols[name].top()->varType;
            //cout << "Saiu IDENTIFIER" << endl;
        }
        break;
        case UNARY:
        { 
            //cout << "Entrou UNARY" << endl;
            return checkType( node->list[0] );
            //cout << "Saiu UNARY"  << endl;
        }
        break;
        case BINARY:
        {
            //cout << "Entrou BINARY" << endl;
            VarType va = checkType( node->list[0] );
            VarType vb = checkType( node->list[1] );
            if ( va != vb && va != VAR_ERROR && vb != VAR_ERROR )
            {
                cout << "ERRO SEMANTICO: TIPOS DIFERENTES (LINHA " << node->lineNum << ")\n";
                return VAR_ERROR;
            }
            if ( node->operatorType == DIVIDE && va == VAR_INTEGER && node->list[1]->intValue == 0 )
            {
                cout << "ERRO SEMANTICO: DIVISAO POR ZERO (LINHA " << node->lineNum << ")\n";
                return VAR_ERROR;
            }
            return (( vb == VAR_ERROR ) ? vb : va);
            //cout << "Saiu BINARY" << endl;
        }
        break;
        case TERNARY:
        {
            ///cout << "Entrou TERNARY" << endl;
            VarType va = checkType( node->list[0] );
            VarType vb = checkType( node->list[1] );
            VarType vc = checkType( node->list[2] );
            if ( va == VAR_ERROR || vb == VAR_ERROR || vc == VAR_ERROR ) return VAR_ERROR;
            if ( va != VAR_INTEGER )
            {
                cout << "ERRO SEMANTICO: TIPO INTEIRO ESPERADO EM OPERACOES CONDICIONAIS "
                    << "(LINHA " << node->lineNum << ")\n";
                return VAR_ERROR;
            }
            if ( va != vb )
            {
                cout << "ERRO SEMANTICO: TIPOS DIFERENTES NA OPERACAO "
                    << "(LINHA " << node->lineNum << ")\n";
                return VAR_ERROR;               
            }
            //cout << "Saiu TERNARY" << endl;
            return vb;
        }
        break;
        case ASSIGN:
        {
            //cout << "Entrou ASSIGN" << endl;
            VarType va = checkType( node->list[0] );
            VarType vb = checkType( node->list[1] );
            if ( va == VAR_ERROR || vb == VAR_ERROR ) return VAR_ERROR;
            if ( va != vb )
            {
                cout << va << " " << vb << endl;
                cout << "ERRO SEMANTICO: TIPOS DIFERENTES NA OPERACAO (LINHA " << node->lineNum << ")\n";
                return VAR_ERROR;   
            }
            //cout << "Saiu ASSIGN" << endl;
            return va;
        }
        break;
        case FUNC_CALL:
        {
            //cout << "Entrou FUNC_CALL" << endl;
            string name = *(node->name);
            if ( !symbols.count(name) )
            {
                cout << "ERRO SEMANTICO: FUNCAO [" << name << "] NAO FOI DECLARADA (LINHA " << node->lineNum << ")\n";
                return VAR_ERROR;
            }
            else if ( symbols[name].top()->nodeType != FUNC_DECLARATION )
            {
                cout << "ERRO SEMANTICO: AO DECLARAR A FUNCAO [" << name << "] (LINHA " << node->lineNum << ")\n"; 
                return VAR_ERROR;
            }
            return symbols[name].top()->varType;
            //cout << "Saiu FUNC_CALL" << endl;
        }
        break;
        default:
            return VAR_ERROR;
        break;
    }
}

void backtracking( int level )
{
    while ( !state_stack.empty() )
    {
        si at = state_stack.top();
        if ( symbols[at.first].empty() || at.second <= level ) return; 
        state_stack.pop();
        symbols[at.first].pop();
        if ( symbols[at.first].empty() ) symbols.erase(at.first);
    }
}

bool checkNodes( Element *node, int level, valueReturning &ret )
{
    for ( int i = 0; i < node->list.size(); i++ )
    {
        if ( node->list[i]->nodeType == BLOCK )
        {
            bool error = checkSemantic(node->list[i], level + 1, ret);
            backtracking(level);
            if ( error ) return true;
        }
        else if ( checkSemantic(node->list[i], level, ret) ) return true;
    }
    return false;
}

bool checkSemantic( Element *node, int level, valueReturning &ret )
{
    node->level = level;
    switch( node->nodeType )
    {
        case ARRAY_VARIABLE:
        case VARIABLE:
        {
            //cout << "Entrou VARIAVEL - VARIAVEL_ARRAY" << endl;
            string name = "";
            name = *(node->id->name);
            if ( !symbols.count( name ) )
            {
                stack<Element*> temp;
                symbols[name] = temp;
            }
            state_stack.push( mp(name, level) );
            stack<Element*> *at = &symbols[name];

            if ( !(*at).empty() && (*at).top()->level == level )
            {
                cout << "ERRO SEMANTICO: VARIAVEL COM NOME [" << name << "] JA FOI DECLARADA "
                    << "(LINHA " << node->lineNum << ")\n";
                return true;
            }
            (*at).push(node);
            //cout << "Saiu VARIABLE - ARRAY_VARIABLE" << endl;
        }
        break;
        case BLOCK:
        {
            //cout << "Entrou Bloco" << endl;
            if( checkNodes(node, level, ret) ) return true;
            //cout << "Saiu Bloco" << endl;
        }
        break;
        case FUNC_DECLARATION:
        {
            //cout << "Entrou FUNC_DECLARATION" << endl;
            string name = *(node->id->name);
            if ( symbols.count( name ) )
            {
                cout << "ERRO SEMANTICO: NOME [" << name << "] DA FUNCAO JA ESTA SENDO UTILIZADA "
                    << "(LINHA " << node->lineNum << ")\n";
                return true;
            }
            else
            {
                stack<Element*> temp;
                symbols[name] = temp;
                stack<Element*> *at = &symbols[name];
                (*at).push(node);

                qtdArgs[name] = node->list[0]->list.size(); 
                for ( int i = 0; i < node->list[0]->list.size(); i++ )
                {
                    if ( checkSemantic( node->list[0]->list[i], level + 1, ret ) ) return true;
                }
                ret.retValue = node->varType;
                ret.hasReturn = false;
                bool error = checkSemantic(node->list[1], level + 1, ret);
                backtracking(level);
                
                if ( error ) return true;
                if ( ret.retValue != VAR_EMPTY && !ret.hasReturn )
                {
                    cout << "ERRO SEMANTICO: AUSENCIA DE RETORNO (LINHA " << node->lineNum << ")\n";
                    return true;
                }
            }
            //cout << "Saiu FUNC_DECLARATION" << endl;
        }
        break;
        case FUNC_CALL:
        {
            //arrumar aqui
            if ( checkType(node) == VAR_ERROR || checkNodes(node, level, ret) ) return true;
            string name = *(node->name);
            int qtd = qtdArgs[name];

            if ( (!node->list.size() && qtd) || (node->list[0]->list.size() < qtd) )
            {
                cout << "ERRO SEMANTICO: QUANTIDADE DE PARAMETROS PASSADOS PARA A FUNCAO [" << name << "] "
                    << "E MENOR DO QUE O ESPERADO (LINHA " << node->lineNum << ")\n";
                return true;
            }
            if ( (node->list.size() && (node->list[0]->list.size() > qtd)) )
            {
                cout << "ERRO SEMANTICO: QUANTIDADE DE PARAMETROS PASSADOS PARA A FUNCAO [" << name << "] "
                    << "E MAIOR DO QUE O ESPERADO (LINHA " << node->lineNum << ")\n";
                return true;  
            }

        }
        break;
        case RETURN:
        {
            //cout << "Entrou RETURN" << endl;
            ret.hasReturn = true;
            if ( ret.retValue != VAR_EMPTY )
            {
                VarType check = checkType( node->list[0] );
                if ( check != ret.retValue )
                {
                    cout << "ERRO SEMANTICO: RETORNO NAO ESPERADO (LINHA " << node->lineNum << ")\n";
                    return true; 
                }
                else if ( check == VAR_ERROR ) return true;
            }
            else
            {
                cout << "ERRO SEMANTICO: AUSENCIA DE RETORNO NA FUNCAO PRINCIPAL (LINHA " << node->lineNum << ")\n";
                return true;
            }
            if ( checkNodes( node, level, ret) ) return true;
            //cout << "Saiu RETURN" << endl;
        }
        break;
        case IF:
        case ELSE:
        case WHILE:
        {
            //cout << "Entrou IF - ELSE - WHILE" << endl;
            VarType cType = checkType( node->list[ (node->list[0]->nodeType == BLOCK) ? 1 : 0 ] );
            if ( cType != VAR_INTEGER )
            {
                cout << "ERRO SEMANTICO: TIPO INTEIRO ESPERADO EM OPERACOES CONDICIONAIS "
                    << "(LINHA " << node->lineNum << ")\n";
                return true;
            }
            else if ( cType == VAR_ERROR ) return true;
            bool error = checkNodes(node, level + 1, ret);
            backtracking(level);
            if ( error ) return true;
            //cout << "Saiu IF - ELSE - WHILE" << endl;
        }
        break;
        case ID_ARRAY:
        case IDENTIFIER:
        case ASSIGN:
        case UNARY:
        case BINARY:
        case TERNARY:
        {
            //cout << "Entrou BINARY" << endl;
            if ( checkType( node ) == VAR_ERROR || checkNodes(node, level, ret) ) return true;
            //cout << "Saiu BINARY" << endl;
        }
        break;
        case WRITE:
        //cout << "WRITE" << endl;
        case CHAR:
        //cout << "CHAR" << endl;
        case STATEMENT:
        //cout << "STATEMENT" << endl;
        case LIST_VARIABLE:
        //cout << "LIST_VARIABLE" << endl;
        case EXPRESSION:
        //cout << "EXPRESSION" << endl;
        case READ:
        //cout << "READ" << endl;
        case INTEGER:
        //cout << "INTEGER" << endl;
        case EXPRESSION_LIST:
        {
            //cout << "Entrou EXPRESSION_LIST" << endl;
            if ( checkNodes( node, level, ret ) ) return true;
            //cout << "Saiu EXPRESSION_LIST" << endl;
        }
        default:
            return false;
        break;
    }
    return false;
}

bool checkSemantic()
{
    valueReturning v;
    return checkSemantic(node, 0, v) ? true : false;
}

#endif