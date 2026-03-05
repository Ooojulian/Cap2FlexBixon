/* ejercicio2.l - Solución al Ejercicio 2 (Capítulo 2) */
%option noyywrap nodefault yylineno case-insensitive

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>    /* Necesario para tolower() */
#include <strings.h>  /* Necesario para strcasecmp() en sistemas POSIX */

struct symbol {       /* Estructura para una palabra */
  char *name;
  struct ref *reflist;
};

struct ref {          /* Estructura para las referencias de líneas */
  struct ref *next;
  char *filename;
  int flags;
  int lineno;
};

/* Tabla de símbolos simple de tamaño fijo */
#define NHASH 9997
struct symbol symtab[NHASH];

struct symbol *lookup(char*);
void addref(int, char*, char*,int);
void printrefs(void);

char *curfilename; /* Nombre del archivo de entrada actual */
%}

%%
 /* Reglas para ignorar palabras comunes (artículos, preposiciones, etc.) */
a |
an |
and |
are |
as |
at |
be |
but |
for |
in |
is |
it |
of |
on |
or |
that |
the |
this |
to      /* ignorar */

 /* Atrapa palabras y llama a addref */
[a-z]+(\'(s|t))?    { addref(yylineno, curfilename, yytext, 0); }
.|\n                /* ignorar todo lo demás (puntuación, números) */
%%

/* --- INICIO DEL CÓDIGO C --- */

/* Modificación 1: usar tolower() en el cálculo del hash */
static unsigned
symhash(char *sym)
{
  unsigned int hash = 0;
  unsigned c;
  while(c = *sym++) hash = hash*9 ^ tolower(c);
  return hash;
}

/* Función para buscar (o crear) un símbolo en la tabla */
struct symbol *
lookup(char* sym)
{
  struct symbol *sp = &symtab[symhash(sym)%NHASH];
  int scount = NHASH;

  while(--scount >= 0) {
    /* Modificación 2: usar strcasecmp en lugar de strcmp */
    if(sp->name && !strcasecmp(sp->name, sym)) return sp;

    if(!sp->name) { /* nueva entrada */
      sp->name = strdup(sym);
      sp->reflist = 0;
      return sp;
    }
    if(++sp >= symtab+NHASH) sp = symtab; /* intenta la siguiente entrada */
  }
  fputs("symbol table overflow\n", stderr);
  abort(); /* la tabla está llena */
}

/* Función para agregar una referencia de línea a una palabra */
void
addref(int lineno, char *filename, char *word, int flags)
{
  struct ref *r;
  struct symbol *sp = lookup(word);

  /* no hacer duplicados si la palabra aparece varias veces en la misma línea */
  if(sp->reflist &&
     sp->reflist->lineno == lineno &&
     sp->reflist->filename == filename) return;

  r = malloc(sizeof(struct ref));
  if(!r) {fputs("out of space\n", stderr); abort(); }
  r->next = sp->reflist;
  r->filename = filename;
  r->lineno = lineno;
  r->flags = flags;
  sp->reflist = r;
}

/* Modificación 3: usar strcasecmp para ordenar alfabéticamente de forma segura */
static int
symcompare(const void *xa, const void *xb)
{
  const struct symbol *a = xa;
  const struct symbol *b = xb;

  if(!a->name) {
    if(!b->name) return 0; /* ambos vacíos */
    return 1;              /* poner vacíos al final */
  }
  if(!b->name) return -1;
  return strcasecmp(a->name, b->name);
}

/* Imprimir el reporte final de concordancia */
void
printrefs()
{
  struct symbol *sp;
  qsort(symtab, NHASH, sizeof(struct symbol), symcompare); /* ordena la tabla */

  for(sp = symtab; sp->name && sp < symtab+NHASH; sp++) {
    char *prevfn = NULL;
    struct ref *rp = sp->reflist;
    struct ref *rpp = 0; 
    struct ref *rpn;

    /* Invierte la lista de referencias para que queden en orden cronológico */
    do {
      rpn = rp->next;
      rp->next = rpp;
      rpp = rp;
      rp = rpn;
    } while(rp);

    /* Imprime la palabra y sus líneas */
    printf("%10s", sp->name);
    for(rp = rpp; rp; rp = rp->next) {
      if(rp->filename == prevfn) {
        printf(" %d", rp->lineno);
      } else {
        printf(" %s:%d", rp->filename, rp->lineno);
        prevfn = rp->filename;
      }
    }
    printf("\n");
  }
}

/* Función principal */
int main(int argc, char **argv)
{
  int i;

  if(argc < 2) { /* si no hay archivos, lee de la entrada estándar */
    curfilename = "(stdin)";
    yylineno = 1;
    yylex();
  } else {
    for(i = 1; i < argc; i++) {
      FILE *f = fopen(argv[i], "r");
      if(!f) {
        perror(argv[i]);
        return (1);
      }
      curfilename = argv[i];
      yyrestart(f);
      yylineno = 1;
      yylex();
      fclose(f);
    }
  }
  printrefs(); /* Llama a imprimir al terminar de leer todo */
  return 0;
}