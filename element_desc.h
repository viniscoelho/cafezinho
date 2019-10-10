#ifndef element_desc_h
#define element_desc_h
#include <iostream>
#include <string>
#include <vector>

using namespace std;

typedef enum {
    SUM,
    SUB,
    MULTIPLY,
    DIVIDE,
    EQUAL,
    DIFFERENT,
    MINOR,
    MORE,
    NEGATIVE,
    REST,
    NEGATE,
    AND,
    OR,
    CONDITIONAL,
    LESS_EQUAL,
    GREATER_EQUAL
} Operator;

typedef enum {
    VAR_EMPTY,
    VAR_INTEGER,
    VAR_ERROR,
    VAR_CHAR,
    VAR_STRING
} VarType;

typedef enum {
    ASSIGN,
    IDENTIFIER,
    STATEMENT,
    ID_ARRAY,
    IF,
    ELSE,
    WHILE,
    UNARY,
    BINARY,
    TERNARY,
    BLOCK,
    DECLARATION,
    FUNC_DECLARATION,
    FUNC_CALL,
    VARIABLE,
    ARRAY_VARIABLE,
    LIST_VARIABLE,
    INTEGER,
    CHAR,
    STRING,
    NEW_LINE,
    READ,
    WRITE,
    START,
    EMPTY,
    RETURN,
    EXPRESSION,
    EXPRESSION_LIST
} NodeType;

struct Element {
    vector<Element*> list;
    int lineNum, intValue, level;
    char charValue;
    string* name;
    Operator operatorType;
    NodeType nodeType;
    VarType varType;
    Element* id;

    //constructor
    Element()
    {
        name = new string("");
        intValue = -1;
    }
};

#endif