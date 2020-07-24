; -*- mode: Lisp;-*-

(sources
  /src/)


(doc
  (title "metis")
  ; (source-link https://github.com/SquidDev-CC/metis/blob/${commit}/${path}#L${line})

  (library-path /src/))

(at /
  (linters syntax:string-index)

  (lint
    (bracket-spaces
      (call no-space)
      (function-args no-space)
      (parens no-space)
      (table space)
      (index no-space))))
