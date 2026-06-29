<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:f="http://https://github.com/costezki/model2owl#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns:dct="http://purl.org/dc/terms/"
    xmlns:vann="http://purl.org/vocab/vann/"
    exclude-result-prefixes="xs xd xsl fn f"
    version="3.0">

    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p>Emits ONLY the owl:Ontology header for the consolidated OWL-full
                artefact (no axioms). It is merged, as the first ROBOT input, with the
                core and restrictions OWL files so that its single, coherent header wins
                (see scripts/owl-full/generate-owl-full.sh). The ontology IRI is the
                configurable <xd:i>fullArtefactURI</xd:i> (defaults to the canonical
                base-ontology-uri).</xd:p>
            <xd:p>Metadata follows the same centralised template as the other artefacts
                (f:ontologyMetadataHeader in common/utils.xsl). The full-specific keys
                are OPTIONAL: when a *Full metadata key is blank/absent the header falls
                back to the corresponding *Core key, so users are not forced to provide a
                dedicated metadata set.</xd:p>
        </xd:desc>
    </xd:doc>

    <xsl:import href="common/utils.xsl"/>

    <xsl:output method="xml" encoding="UTF-8" byte-order-mark="no" indent="yes"/>

    <xd:doc>
        <xd:desc>Resolve a full-specific metadata key, falling back to the core key when
            the full value is absent/blank.</xd:desc>
        <xd:param name="fullKey">The *Full metadata key.</xd:param>
        <xd:param name="coreKey">The *Core metadata key used as fallback.</xd:param>
    </xd:doc>
    <xsl:function name="f:fullMetadataKey" as="xs:string">
        <xsl:param name="fullKey" as="xs:string"/>
        <xsl:param name="coreKey" as="xs:string"/>
        <xsl:sequence
            select="if (exists(f:getMetadataValue($fullKey))) then $fullKey else $coreKey"/>
    </xsl:function>

    <xd:doc>
        <xd:desc>The main template: the consolidated ontology header.</xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <rdf:RDF>
            <xsl:call-template name="namespacesDeclaration"/>
            <owl:Ontology rdf:about="{$fullArtefactURI}">
                <!-- External imports only: the union of the shared (all), core and
                     restrictions import groups. The internal core<->restrictions
                     cross-imports are intentionally never emitted (the two layers are
                     consolidated into this single artefact). -->
                <xsl:for-each select="$urisToBeImported/*:imports/*:all/*:import/@uri">
                    <owl:imports rdf:resource="{.}"/>
                </xsl:for-each>
                <xsl:for-each select="$urisToBeImported/*:imports/*:core/*:import/@uri">
                    <owl:imports rdf:resource="{.}"/>
                </xsl:for-each>
                <xsl:for-each select="$urisToBeImported/*:imports/*:restrictions/*:import/@uri">
                    <owl:imports rdf:resource="{.}"/>
                </xsl:for-each>

                <xsl:call-template name="ontologyMetadataHeader">
                    <xsl:with-param name="titleKey"
                        select="f:fullMetadataKey('ontologyTitleFull', 'ontologyTitleCore')"/>
                    <xsl:with-param name="labelKey"
                        select="f:fullMetadataKey('ontologyLabelFull', 'ontologyLabelCore')"/>
                    <xsl:with-param name="descriptionKey"
                        select="f:fullMetadataKey('ontologyDescriptionFull', 'ontologyDescriptionCore')"/>
                    <xsl:with-param name="artefactURI" select="$fullArtefactURI"/>
                </xsl:call-template>
            </owl:Ontology>
        </rdf:RDF>
    </xsl:template>

</xsl:stylesheet>
