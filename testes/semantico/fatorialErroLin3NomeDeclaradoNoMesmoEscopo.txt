/* Este  e um programa com ERRO */
car fatorial(int n){
        int n;
	se (n==0)
	entao
		retorne 1;
	senao
		retorne n* fatorial(n-1); /* Erro de tipo*/
}

programa {
	int n;
	n = 1-0;
	enquanto (n>0) execute {
       		escreva "digite um numero";
       		novalinha;
       		leia n;    
	}	
	escreva "O fatorial de ";
	escreva n;
        	escreva " e: ";
	escreva fatorial(n);
	novalinha;
}
