; -*- mode: Lisp;-*-

(sources
  /src/
  /spec/
  /doc/notes/)

(doc
  (index /doc/index.md)
  (json-index false)
  (destination /_site/)

  (site
    (title "metis")
    (source-link https://github.com/SquidDev-CC/metis/blob/${commit}/${path}#L${line}))

  (module-kinds
    (notes "Documentation"))

  (library-path /src/))

(at /
  (linters syntax:string-index)

  (lint
    (bracket-spaces
      (call no-space)
      (function-args no-space)
      (parens no-space)
      (table space)
      (index no-space))

    (dynamic-modules metis.math metis.fs)))

(at /src/
  (lint
    (globals
      :max term colours keys fs)))

(at /spec/
  (lint
    (globals
      :max describe expect it pending stub fail sleep keys)))

; Some gross warning ignores - illuaminate really needs comment versions of these.
(at (/src/metis/async.lua) (linters -doc:kind-mismatch))
(at (/doc/notes/usage.md) (linters -doc:malformed-example))
