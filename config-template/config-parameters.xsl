<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" exclude-result-prefixes="xd xsl dc fn"
    xmlns:cc="http://creativecommons.org/ns#" xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:dct="http://purl.org/dc/terms/" xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:functx="http://www.functx.com" xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:vann="http://purl.org/vocab/vann/"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    version="3.0">

    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p>Project-level configuration for a model2owl transformation.</xd:p>
            <xd:p>This is a TEMPLATE: copy this folder, edit the values, and point
                <xd:i>config-proxy.xsl</xd:i> at it (or pass its files to the make
                targets). Parameters are grouped by purpose (see the numbered
                sections below and the accompanying README.md). Values written as
                <xd:i>myprefix:*</xd:i> or <xd:i>http://example.org/*</xd:i> are
                placeholders to replace with your own ontology's prefix and URIs.</xd:p>
        </xd:desc>
    </xd:doc>

    <!-- ===================================================================== -->
    <!-- 1. Config-file references (the sibling files in this config folder)    -->
    <!-- ===================================================================== -->
    <xsl:variable name="namespacePrefixes" select="fn:doc('namespaces.xml')"/>
    <xsl:variable name="umlDataTypesMapping" select="fn:doc('umlToXsdDataTypes.xml')"/>
    <xsl:variable name="xsdAndRdfDataTypes" select="fn:doc('xsdAndRdfDataTypes.xml')"/>
    <!-- JSON metadata configuration. The path is overridable via the
         `metadataJsonPath` stylesheet parameter (make targets: METADATA_JSON_PATH);
         the default `metadata.json` is resolved relative to this config file. -->
    <xsl:param name="metadataJsonPath" select="'metadata.json'"/>
    <xsl:variable name="metadataJson" select="fn:json-doc($metadataJsonPath)"/>

    <!-- ===================================================================== -->
    <!-- 2. Namespaces & URI construction                                      -->
    <!-- ===================================================================== -->
    <!-- If true, a bare localSegment (no prefix) is interpreted as :localSegment
         (i.e. in the default/empty-prefix namespace). -->
    <xsl:variable name="defaultNamespaceInterpretation" select="fn:true()"/>
    <!-- Base URIs of YOUR ontology. No trailing delimiter (the delimiter below is added). -->
    <xsl:variable name="base-ontology-uri" select="'http://example.org/ontology'"/>
    <xsl:variable name="base-shape-uri" select="'http://example.org/data-shape'"/>
    <xsl:variable name="base-restriction-uri" select="$base-ontology-uri"/>
    <!-- Delimiter appended to a base URI when it has none (e.g. '#' or '/'). -->
    <xsl:variable name="defaultDelimiter" select="'#'"/>
    <!-- Suffix for sh:NodeShape URIs in the SHACL artefact. -->
    <xsl:variable name="nodeShapeURIsuffix" select="'Shape'"/>
    <!-- Short id of this module; also used in the artefact URIs (…#<moduleReference>). -->
    <xsl:variable name="moduleReference" select="'core'"/>
    <xsl:variable name="shapeArtefactURI"
        select="fn:concat($base-shape-uri,$defaultDelimiter, $moduleReference, '-shape')"/>
    <xsl:variable name="restrictionsArtefactURI"
        select="fn:concat($base-restriction-uri, $defaultDelimiter, $moduleReference, '-restriction')"/>
    <xsl:variable name="coreArtefactURI"
        select="fn:concat($base-ontology-uri, $defaultDelimiter, $moduleReference)"/>

    <!-- ===================================================================== -->
    <!-- 3. Scope / reused-concepts filtering                                  -->
    <!-- ===================================================================== -->
    <!-- The namespace prefix(es) of YOUR ontology's own concepts. Concepts with
         these prefixes are treated as "main" and generated; others are reused
         concepts. Use '' (empty string) if your model's class names carry no prefix. -->
    <xsl:variable name="includedPrefixesList" select="('myprefix')"/>
    <!-- Whether reused (out-of-scope-prefix) concepts are still emitted, per artefact. -->
    <xsl:variable name="generateReusedConceptsSHACL" select="fn:true()"/>
    <xsl:variable name="generateReusedConceptsOWLcore" select="fn:true()"/>
    <xsl:variable name="generateReusedConceptsOWLrestrictions" select="fn:true()"/>
    <xsl:variable name="generateReusedConceptsGlossary" select="fn:true()"/>
    <xsl:variable name="generateReusedConceptsJSONLDcontext" select="fn:true()"/>

    <!-- ===================================================================== -->
    <!-- 4. Attribute -> property typing                                       -->
    <!-- ===================================================================== -->
    <!-- Attribute types that still yield an object property. Add your project's
         identifier datatype(s), e.g. ('myprefix:Identifier', 'rdfs:Literal'). -->
    <xsl:variable name="acceptableTypesForObjectProperties"
        select="('rdfs:Literal')"/>
    <!-- The attribute type whose values come from a controlled list / code list. -->
    <xsl:variable name="controlledListType" select="'myprefix:Code'"/>

    <!-- ===================================================================== -->
    <!-- 5. Accepted UML stereotypes (per element kind)                        -->
    <!-- ===================================================================== -->
    <xsl:variable name="stereotypeValidOnAttributes" select="()"/>
    <xsl:variable name="stereotypeValidOnObjects" select="()"/>
    <xsl:variable name="stereotypeValidOnGeneralisations"
        select="('Disjoint', 'Equivalent', 'Complete')"/>
    <xsl:variable name="stereotypeValidOnAssociations" select="()"/>
    <xsl:variable name="stereotypeValidOnDependencies" select="('Disjoint', 'disjoint', 'join')"/>
    <xsl:variable name="stereotypeValidOnClasses" select="('Abstract')"/>
    <xsl:variable name="stereotypeValidOnDatatypes" select="()"/>
    <xsl:variable name="stereotypeValidOnEnumerations" select="()"/>
    <xsl:variable name="stereotypeValidOnPackages" select="()"/>
    <xsl:variable name="abstractClassesStereotypes" select="('Abstract', 'abstract class', 'abstract')"/>

    <!-- ===================================================================== -->
    <!-- 6. Enumerations -> SKOS                                                -->
    <!-- ===================================================================== -->
    <!-- Transform enumeration items into skos:Concept / skos:ConceptScheme? -->
    <xsl:variable name="enableGenerationOfSkosConcept" select="fn:false()"/>
    <xsl:variable name="enableGenerationOfConceptSchemes" select="fn:false()"/>
    <!-- Tag carrying the constraint level for enumerations. -->
    <xsl:variable name="cvConstraintLevelProperty" select="'myprefix:constraintLevel'"/>

    <!-- ===================================================================== -->
    <!-- 7. Tags, comments, references, status & rdfs:isDefinedBy              -->
    <!-- ===================================================================== -->
    <!-- 7a. Comments / notes -->
    <xsl:variable name="commentsGeneration" select="fn:true()"/>
    <xsl:variable name="commentProperty" select="'skos:editorialNote'"/>
    <xsl:variable name="usageNoteTagName" select="'skos:note'"/>
    <xsl:variable name="customTermLabelTagName" select="'skos:prefLabel'"/>

    <!-- 7b. Tag keys & reference labels -->
    <!-- Tag indicating whether a property is mandatory/optional (else cardinality is used). -->
    <xsl:variable name="mandatoryStatusTagName" select="'cfg:usage'"/>
    <!-- Tag providing reference/reuse links for a class or property. -->
    <xsl:variable name="referenceTagName" select="'dcterms:references'"/>
    <!-- ReSpec labels for the reference/reuse information. -->
    <xsl:variable name="propertyReferenceRespecLabel" select="'Reuse'"/>
    <xsl:variable name="classReferenceRespecLabel" select="'Reference'"/>
    <xsl:variable name="showReferencesInRespec" select="fn:true()"/>
    <!-- Tag names excluded from the output. -->
    <xsl:variable name="excludedTagNamesList" select="($statusProperty, $cvConstraintLevelProperty)"/>

    <!-- 7c. Status filtering -->
    <xsl:variable name="statusProperty" select="'myprefix:status'"/>
    <xsl:variable name="validStatusesList" select="('proposed', 'approved', 'implemented')"/>
    <xsl:variable name="excludedElementStatusesList" select="('proposed', 'approved')"/>
    <xsl:variable name="unspecifiedStatusInterpretation" select="'implemented'"/>

    <!-- 7d. rdfs:isDefinedBy annotation -->
    <!-- Annotate every concept defined in this ontology with rdfs:isDefinedBy
         pointing at the ontology IRI. One flag for the OWL artefacts, one for SHACL.
         Set to fn:false() to suppress (see transformation rules T.08 / T.09). -->
    <xsl:variable name="annotateDefinedConceptsWithOntology" select="fn:true()"/>
    <xsl:variable name="annotateShaclConceptsWithOntology" select="fn:true()"/>

    <!-- ===================================================================== -->
    <!-- 8. Output toggles & misc                                              -->
    <!-- ===================================================================== -->
    <!-- Generate UML Objects and Realisation connectors. -->
    <xsl:variable name="generateObjectsAndRealisations" select="fn:false()"/>
    <!-- Replace rdf:PlainLiteral in SHACL shapes with (xsd:string, rdf:langString). -->
    <xsl:variable name="translatePlainLiteralToStringTypesInSHACL" select="fn:true()"/>
    <!-- Allowed characters for a normalized string. -->
    <xsl:variable name="allowedStrings" select="'^[\w\d-_:]+$'"/>
    <!-- UML versions (XMI namespace URIs) accepted by model2owl. -->
    <xsl:variable name="supportedUmlVersions"
        select="('http://www.omg.org/spec/UML/20131001',
            'https://www.omg.org/spec/UML/20131001',
            'http://www.omg.org/spec/UML/20161101',
            'https://www.omg.org/spec/UML/20161101'
        )"/>
    <!-- Date for dct:issued. Defaults to the current date; for a fixed date use
         select="xs:date('2024-01-01')". -->
    <xsl:variable name="issuedDate" select="format-date(current-date(),'[Y0001]-[M01]-[D01]')"/>

</xsl:stylesheet>
