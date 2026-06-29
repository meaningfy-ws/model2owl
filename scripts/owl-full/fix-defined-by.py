#!/usr/bin/env python3
"""
Rewrite rdfs:isDefinedBy values in an OWL/RDF file that don't point to the
given full-artefact URI.  Parses the file without resolving owl:imports (rdflib
does not fetch imports automatically), rewrites in-place only when at least one
triple was changed, and exits 0 in both cases.
"""
import sys
from rdflib import Graph, URIRef
from rdflib.namespace import RDFS


def main():
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <owl-file> <full-uri>", file=sys.stderr)
        sys.exit(1)

    owl_path, full_uri_str = sys.argv[1], sys.argv[2]
    full_uri = URIRef(full_uri_str)

    g = Graph()
    g.parse(owl_path)

    stale = [
        (s, o)
        for s, p, o in g.triples((None, RDFS.isDefinedBy, None))
        if o != full_uri
    ]

    if not stale:
        print("    rdfs:isDefinedBy already correct or absent; file unchanged")
        return

    for s, o in stale:
        g.remove((s, RDFS.isDefinedBy, o))
        g.add((s, RDFS.isDefinedBy, full_uri))

    g.serialize(destination=owl_path, format="xml")
    print(f"    rewrote {len(stale)} rdfs:isDefinedBy triple(s) to <{full_uri_str}>")


if __name__ == "__main__":
    main()
