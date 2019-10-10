# Para compilar no OSX, mude o parametro -lfl para -ll
# Levei um tempinho ate descobrir o motivo de nao realizar a linkagem no meu notebook :)

all: lexico.c sintatico.c sintatico.h
	g++ sintatico.c lexico.c -ll -o cafezinho -g

sintatico.c sintatico.h: sintatico.y
	bison -d sintatico.y -o sintatico.c

lex.yy.c: lexico.l sintatico.tab.h
	flex lexico.l -o lexico.c

clean: rm *.o
