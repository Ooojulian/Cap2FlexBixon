/* ejercicio3.l - Solución al Ejercicio 3 (Capítulo 2) */
%option noyywrap nodefault yylineno case-insensitive

%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <strings.h>

struct symbol {
  char *name;
  struct ref *reflist;
};

struct ref {
  struct ref *next;
  char *filename;
  int flags;
  int lineno;
};

/* --- VARIABLES GLOBALES PARA LA TABLA DINÁMICA --- */
int nhash = 5; /* Empezamos con una tabla MUY pequeña para forzar el rehash */
int syms_used = 0; /* Contador de símbolos actuales */
struct symbol *symtab = NULL; /* Puntero a la tabla dinámica */

struct symbol *lookup(char*);
void addref(int, char*, char*,int);
void printrefs(void);

char *curfilename;
%}

%%
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
to      /* ignorar palabras comunes */

[a-z]+(\'(s|t))?    { addref(yylineno, curfilename, yytext, 0); }
.|\n                /* ignorar */
%%

/* --- INICIO DEL CÓDIGO C --- */

static unsigned
symhash(char *sym)
{
  unsigned int hash = 0;
  unsigned c;
  while(c = *sym++) hash = hash*9 ^ tolower(c);
  return hash;
}

/* Lógica de REHASHING: Crea una tabla más grande y mueve los datos */
void rehash() {
    int old_nhash = nhash;
    struct symbol *old_symtab = symtab;

    /* Doblamos el tamaño y sumamos 1 para mantenerlo impar */
    nhash = nhash * 2 + 1; 
    symtab = calloc(nhash, sizeof(struct symbol));
    if(!symtab) { perror("Error al asignar memoria en rehash"); exit(1); }

    /* Reubicar las entradas viejas en la nueva tabla */
    for (int i = 0; i < old_nhash; i++) {
        if (old_symtab[i].name) {
            struct symbol *sp = &symtab[symhash(old_symtab[i].name) % nhash];
            while (sp->name) {
                if (++sp >= symtab + nhash) sp = symtab;
            }
            *sp = old_symtab[i]; /* Copia la estructura (nombre y referencias) */
        }
    }
    free(old_symtab); /* Liberar la memoria de la tabla vieja */
}

struct symbol *
lookup(char* sym)
{
  /* Inicializar la tabla la primera vez */
  if (!symtab) {
      symtab = calloc(nhash, sizeof(struct symbol));
      if(!symtab) { perror("Error de memoria inicial"); exit(1); }
  }

  /* Si la tabla está llena al 75% o más, hacemos rehash ANTES de insertar */
  if (syms_used >= (nhash * 3) / 4) {
      rehash();
  }

  struct symbol *sp = &symtab[symhash(sym) % nhash];
  int scount = nhash;

  while(--scount >= 0) {
    if(sp->name && !strcasecmp(sp->name, sym)) return sp;

    if(!sp->name) { 
      sp->name = strdup(sym);
      sp->reflist = 0;
      syms_used++; /* Aumentamos el contador de uso */
      return sp;
    }
    if(++sp >= symtab + nhash) sp = symtab; 
  }
  
  /* Esto ya nunca debería ejecutarse gracias al rehash dinámico */
  fputs("symbol table overflow\n", stderr);
  abort(); 
}

void
addref(int lineno, char *filename, char *word, int flags)
{
  struct ref *r;
  struct symbol *sp = lookup(word);

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

static int
symcompare(const void *xa, const void *xb)
{
  const struct symbol *a = xa;
  const struct symbol *b = xb;

  if(!a->name) {
    if(!b->name) return 0;
    return 1;
  }
  if(!b->name) return -1;
  return strcasecmp(a->name, b->name);
}

void
printrefs()
{
  struct symbol *sp;
  
  /* Se ordena usando el tamaño actual 'nhash' */
  qsort(symtab, nhash, sizeof(struct symbol), symcompare); 

  /* Se itera usando el tamaño actual 'nhash' */
  for(sp = symtab; sp->name && sp < symtab + nhash; sp++) {
    char *prevfn = NULL;
    struct ref *rp = sp->reflist;
    struct ref *rpp = 0; 
    struct ref *rpn;

    do {
      rpn = rp->next;
      rp->next = rpp;
      rpp = rp;
      rp = rpn;
    } while(rp);

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

int main(int argc, char **argv)
{
  int i;
  if(argc < 2) { 
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
  printrefs(); 
  /* Buena práctica: liberar la tabla dinámica al terminar */
  if (symtab) free(symtab);
  return 0;
}