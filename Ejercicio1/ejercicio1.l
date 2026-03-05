/* ejercicio1.l - Solución al Ejercicio 1 (Capítulo 2) */
%option noyywrap
%x IFILE

%{
  #include <stdio.h>
  #include <stdlib.h>

  /* Estructura para manejar el anidamiento de archivos (stack) */
  struct bufstack {
    struct bufstack *prev;  /* archivo anterior */
    YY_BUFFER_STATE bs;     /* buffer guardado */
    int lineno;             /* número de línea guardado */
    char *filename;         /* nombre de este archivo */
    FILE *f;                /* archivo actual */
  } *curbs = 0;

  char *curfilename;        /* nombre del archivo de entrada actual */

  int newfile(char *fn);
  int popfile(void);
%}

%%

 /* Detecta el inicio de un include y cambia al estado IFILE */
^"#"[ \t]*include[ \t]*[\"<] { BEGIN IFILE; }

 /* Procesa el nombre del archivo dentro del include */
<IFILE>[^ \t\n\">]+ { 
  { int c;
    while((c = input()) && c != '\n') ;
  }
  yylineno++;
  if(!newfile(yytext))
    yyterminate(); /* si no existe el archivo, termina */
  BEGIN INITIAL;
}

 /* Manejo de errores si el include está mal escrito */
<IFILE>.|\n { 
  fprintf(stderr, "%4d bad include line\n", yylineno);
  yyterminate();
}

 /* Cuando llega al fin de un archivo, saca el anterior del stack */
<<EOF>> { if(!popfile()) yyterminate(); }

 /* --- INICIO DE LÓGICA DEL EJERCICIO 1 --- */

 /* Imprime el número de línea si la línea NO empieza con # */
^[^#\n]+ { fprintf(yyout, "%4d %s", yylineno, yytext); }

 /* Si empieza con # pero NO fue atrapado por la regla del include 
    (gracias a la regla del "longest match"), imprime la línea */
^"#"     { fprintf(yyout, "%4d %s", yylineno, yytext); }

 /* Atrapa bloques grandes de texto en medio de la línea */
[^#\n]+  { ECHO; }

 /* Imprime cualquier otro '#' suelto en el texto */
"#"      { ECHO; }

 /* Manejo de líneas vacías (salto de línea al principio de la línea) */
^\n      { fprintf(yyout, "%4d %s", yylineno++, yytext); }

 /* Otros saltos de línea normales */
\n       { ECHO; yylineno++; }

 /* --- FIN DE LÓGICA DEL EJERCICIO 1 --- */

%%

int main(int argc, char **argv)
{
  if(argc < 2) {
    fprintf(stderr, "need filename\n");
    return 1;
  }
  if(newfile(argv[1]))
    yylex();

  return 0;
}

int newfile(char *fn)
{
  FILE *f = fopen(fn, "r");
  struct bufstack *bs = malloc(sizeof(struct bufstack));
  
  if(!f) { perror(fn); return 0; }
  if(!bs) { perror("malloc"); exit(1); }
  
  /* guarda el estado actual */
  if(curbs) curbs->lineno = yylineno;
  bs->prev = curbs;
  
  /* configura la nueva entrada */
  bs->bs = yy_create_buffer(f, YY_BUF_SIZE);
  bs->f = f;
  bs->filename = fn;
  yy_switch_to_buffer(bs->bs);
  curbs = bs;
  yylineno = 1;
  curfilename = fn;
  return 1;
}

int popfile(void)
{
  struct bufstack *bs = curbs;
  struct bufstack *prevbs;
  
  if(!bs) return 0;
  
  /* elimina la entrada actual */
  fclose(bs->f);
  yy_delete_buffer(bs->bs);
  
  /* regresa al archivo anterior */
  prevbs = bs->prev;
  free(bs);
  if(!prevbs) return 0;
  
  yy_switch_to_buffer(prevbs->bs);
  curbs = prevbs;
  yylineno = curbs->lineno;
  curfilename = curbs->filename;
  return 1;
}