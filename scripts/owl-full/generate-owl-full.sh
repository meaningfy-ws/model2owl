#!/bin/bash
#
# Consolidates the OWL core and OWL restrictions artefacts into a single,
# self-contained OWL-full ontology (an alternative form of the ontology, the two
# OWL artefacts merged for the user's convenience).
#
# This is the heavy lifting behind the `owl-full` Makefile target (delegated here
# to keep the target thin). The flag guard (generateOWLFull) and the generation /
# existence of the core & restrictions inputs are handled by the Makefile; this
# script assumes the inputs already exist.
#
# How the "smart" (non-textual) merge works:
#   * A dedicated owl:Ontology header is generated first (src/full-header.xsl) and
#     passed as the FIRST ROBOT input. With `--include-annotations false` only the
#     first input's ontology annotations survive, so the consolidated artefact
#     carries a single coherent header (not the two contradictory core/restrictions
#     headers).
#   * `robot merge` drops the internal restrictions->core owl:imports automatically
#     (core is itself a merge input); `--collapse-import-closure false` keeps any
#     external imports as imports instead of inlining them.
#   * The catalog (the restrictions catalog) resolves the internal #core import to
#     the local core file so ROBOT does not reach out to the web.
#   * The ontology IRI is pinned to FULL_URI via `robot annotate`.
#
# All inputs are passed as environment variables (see the required list below).
set -euo pipefail

: "${MODEL2OWL_FOLDER:?}"   # repo root (to call back into make for conversions)
: "${SAXON:?}"              # path to saxon.jar
: "${ROBOT:?}"              # path to robot.jar
: "${XMI_INPUT_FILE_PATH:?}"
: "${ENRICHED_NAMESPACES_XML_PATH:?}"
: "${IMPORTS_XML_FILE_PATH:?}"
: "${FULL_URI:?}"           # ontology IRI for the consolidated artefact
: "${CORE_OWL:?}"           # existing OWL core .owl input
: "${RESTR_OWL:?}"          # existing OWL restrictions .owl input
: "${CATALOG:?}"            # restrictions catalog (maps #core -> local core .owl)
: "${FULL_OWL:?}"           # output .owl (OWL API flavor)
: "${FULL_RDF:?}"           # output .rdf (RDF/XML)
: "${FULL_TTL:?}"           # output .ttl (Turtle)
: "${HEADER_RDF:?}"         # temp file for the generated dedicated header
: "${RDF_XML_MIME_TYPE:?}"
: "${TURTLE_MIME_TYPE:?}"
# Optional: SAXON_METADATA_PARAM (e.g. metadataJsonPath="..."); CLEANUP_FILES
SAXON_METADATA_PARAM=${SAXON_METADATA_PARAM:-}
CLEANUP_FILES=${CLEANUP_FILES:-}

for f in "$CORE_OWL" "$RESTR_OWL" "$CATALOG"; do
    if [ ! -f "$f" ]; then
        echo "Error: required input not found: $f" >&2
        echo "Run 'make owl-core' and 'make owl-restrictions' (same OUTPUT_FOLDER_PATH) first." >&2
        exit 1
    fi
done

echo "==> [owl-full] generating the dedicated consolidated ontology header"
# shellcheck disable=SC2086
java -jar "$SAXON" -s:"$XMI_INPUT_FILE_PATH" -xsl:"$MODEL2OWL_FOLDER/src/full-header.xsl" \
    -o:"$HEADER_RDF" \
    enrichedNamespacesPath="$ENRICHED_NAMESPACES_XML_PATH" $SAXON_METADATA_PARAM \
    importsPath="$IMPORTS_XML_FILE_PATH"

echo "==> [owl-full] merging core + restrictions into the consolidated artefact"
java -jar "$ROBOT" merge \
        --collapse-import-closure false \
        --catalog "$CATALOG" \
        --include-annotations false \
        -i "$HEADER_RDF" \
        -i "$CORE_OWL" \
        -i "$RESTR_OWL" \
    annotate --ontology-iri "$FULL_URI" \
    --output "$FULL_OWL"

echo "==> [owl-full] rewriting rdfs:isDefinedBy to fullArtefactURI (if present)"
# The OWL core artefact annotates every term with rdfs:isDefinedBy pointing to
# the core IRI. After the merge that IRI is wrong for the consolidated artefact.
# robot query --catalog resolves all imports via the catalog (including the adms
# workaround in robot-catalog.xsl) so external imports don't cause fetch failures.
# Guards with an ASK so the file is left unchanged when nothing needs rewriting.
defined_by_ask=$(mktemp --suffix=.sparql)
defined_by_ask_out=$(mktemp --suffix=.csv)
printf 'ASK { ?x <http://www.w3.org/2000/01/rdf-schema#isDefinedBy> ?y . FILTER(?y != <%s>) }' \
    "$FULL_URI" > "$defined_by_ask"
java -jar "$ROBOT" query \
    --input "$FULL_OWL" \
    --catalog "$CATALOG" \
    --query "$defined_by_ask" "$defined_by_ask_out"
ask_result=$(tail -1 "$defined_by_ask_out")
rm -f "$defined_by_ask" "$defined_by_ask_out"
if [ "$ask_result" = "true" ]; then
    defined_by_update=$(mktemp --suffix=.ru)
    cat > "$defined_by_update" << SPARQL
PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
DELETE { ?x rdfs:isDefinedBy ?old }
INSERT { ?x rdfs:isDefinedBy <${FULL_URI}> }
WHERE  { ?x rdfs:isDefinedBy ?old . FILTER(?old != <${FULL_URI}>) }
SPARQL
    defined_by_tmp=$(mktemp --suffix=.owl)
    java -jar "$ROBOT" query \
        --input "$FULL_OWL" \
        --catalog "$CATALOG" \
        --update "$defined_by_update" \
        --output "$defined_by_tmp"
    mv "$defined_by_tmp" "$FULL_OWL"
    rm -f "$defined_by_update"
else
    echo "    no rdfs:isDefinedBy values to rewrite; file unchanged"
fi

echo "==> [owl-full] writing RDF/XML and Turtle serializations"
make -C "$MODEL2OWL_FOLDER" convert-between-serialization-formats \
    INPUT_FORMAT="$RDF_XML_MIME_TYPE" OUTPUT_FORMAT="$RDF_XML_MIME_TYPE" \
    FILE_PATH="$FULL_OWL" OUTPUT_FILE_PATH="$FULL_RDF"
make -C "$MODEL2OWL_FOLDER" convert-between-serialization-formats \
    INPUT_FORMAT="$RDF_XML_MIME_TYPE" OUTPUT_FORMAT="$TURTLE_MIME_TYPE" \
    FILE_PATH="$FULL_OWL" OUTPUT_FILE_PATH="$FULL_TTL"

echo "==> [owl-full] validating the consolidated artefact (structural parse via rdflib)"
make -C "$MODEL2OWL_FOLDER" validate-rdf-file-rdflib FILE_TO_VALIDATE_PATH="$FULL_RDF"

# Remove the temp header (always ours) and only the core/restrictions intermediates
# that THIS run generated (CLEANUP_FILES, set by the Makefile). Pre-existing,
# caller-owned core/restrictions files are deliberately left untouched.
rm -f "$HEADER_RDF"
if [ -n "${CLEANUP_FILES// /}" ]; then
    echo "==> [owl-full] removing the core/restrictions intermediates generated by this run"
    rm -f $CLEANUP_FILES
else
    echo "==> [owl-full] keeping pre-existing core/restrictions artefacts (not generated by this run)"
fi

echo "==> [owl-full] done. Consolidated artefact:"
ls -lh "$FULL_OWL" "$FULL_RDF" "$FULL_TTL"
