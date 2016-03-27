#!/bin/sh
TMP=`mktemp`
ocamlfind ocamlc -package js_of_ocaml -package js_of_ocaml.syntax -syntax camlp4o -linkpkg -o $TMP $1
js_of_ocaml $TMP -o $2
rm $TMP



