; -*- mode: Lisp;-*-

(sources
  /src/
  /spec/)

(doc
  (library-path /src/)

  (title "metis")
  (source-link https://github.com/SquidDev-CC/metis/blob/${commit}/${path}#L${line})
  (index /doc/index.md)
  (json-index false))

(at /
  (linters syntax:string-index)

  (lint
    (bracket-spaces
      (call no-space)
      (function-args no-space)
      (parens no-space)
      (table space)
      (index no-space))

    (dynamic-modules metis.math)))

(at /src/
  (lint
    (globals
      :max term colours keys colors http textutils fs settings read write print)))

(at /spec/
  (lint
    (globals
      :max describe expect it pending stub fail sleep keys fs textutils)))
