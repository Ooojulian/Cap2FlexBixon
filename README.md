# Ejercicios de Análisis Léxico con Flex - Capítulo 2

Este repositorio contiene las soluciones a una serie de ejercicios prácticos utilizando **Flex** (Fast Lexical Analyzer Generator) en C. Los ejercicios exploran conceptos fundamentales del análisis léxico, desde el manejo de buffers múltiples hasta la implementación de tablas de símbolos para referencias cruzadas.

## 📂 Contenido del Proyecto

El proyecto se divide en tres ejercicios principales:

### Ejercicio 1: Manejo de Archivos Anidados (`ejercicio1.l`)
Implementa un analizador que detecta directivas `#include` para abrir y procesar archivos de manera anidada (usando una pila de buffers `bufstack`).
* **Características:** Cambia entre archivos de entrada dinámicamente, cuenta las líneas de código y maneja errores si el archivo incluido no existe.
* **Archivos de prueba:** Se puede probar junto con `incluido.txt`.

### Ejercicio 2: Referencias Cruzadas con Tabla Estática (`ejercicio2.l`)
Construye un generador de referencias cruzadas que lee un texto e imprime una lista alfabética de las palabras encontradas, junto con los números de línea donde aparecen.
* **Características:** Ignora palabras comunes (artículos, preposiciones) y utiliza una tabla hash de **tamaño fijo** (`NHASH 9997`).
* **Archivos de prueba:** Funciona perfectamente con `texto.txt`.

### Ejercicio 3: Referencias Cruzadas con Tabla Dinámica (`ejercicio3.l`)
Mejora el Ejercicio 2 al implementar una tabla de símbolos de **tamaño variable**.
* **Características:** Comienza con una tabla muy pequeña (`nhash = 5`) para forzar la colisión y utiliza la técnica de *Rehashing* (reasignación de memoria y reubicación de elementos) cuando la tabla se llena. 

---

## 🧠 Teoría: Chaining vs. Rehashing
En el contexto de la tabla de símbolos dinámica (Ejercicio 3), surgen dos técnicas estándar para manejar tablas de tamaño variable: **Encadenamiento (Chaining)** y **Rehashing**. 

**¿Cuál de las dos técnicas hace más complicado producir la referencia cruzada?**
La respuesta es el **Chaining**. 
En nuestro programa, la función `printrefs()` ordena la tabla alfabéticamente usando la función estándar de C `qsort()`. Esto requiere que todos los elementos estén en un bloque de memoria continuo (un arreglo). 
* Si usamos **Rehashing**, seguimos teniendo un arreglo continuo (mediante `realloc`) y `qsort()` funciona directamente. 
* Si usáramos **Chaining**, los datos estarían dispersos en nodos de listas enlazadas en la memoria, lo que nos obligaría a extraer todos los elementos y copiarlos a un arreglo temporal antes de poder ordenarlos.

---

## 🚀 Cómo compilar y ejecutar

Para compilar cualquiera de los ejercicios, necesitas tener instalados `flex` y `gcc`. Los pasos generales son:

1. Generar el código C con Flex:
   ```bash
   flex ejercicioX.l
