# QyrexObf para GitHub Pages

Este proyecto es 100% estático: `index.html` funciona sin Node.js.

## Publicar

1. Sube `index.html` a la raíz de un repositorio.
2. Ve a **Settings → Pages**.
3. En **Build and deployment → Source** elige **Deploy from a branch**.
4. Selecciona `main` y `/ (root)` y guarda.
5. GitHub publicará el sitio en `https://<usuario>.github.io/<repositorio>/`.

GitHub Pages sirve archivos estáticos; no ejecuta un servidor Node ni crea archivos nuevos en el repositorio cuando pulsas el botón del navegador.

## Partes

El generador divide tu Luau, codifica cada parte en QYREX y muestra los nombres exactos que deben existir en el repositorio:

`qyrex/<id>/001.txt`
`qyrex/<id>/002.txt`
`...

Descarga cada parte desde la página y súbela a esa ruta en GitHub. Después usa el loader generado. Su base RAW debe apuntar al directorio `qyrex` de tu repositorio.
