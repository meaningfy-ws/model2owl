<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:uml="http://www.omg.org/spec/UML/20131001"
    xmlns:xmi="http://www.omg.org/spec/XMI/20131001"
    xmlns:umldi="http://www.omg.org/spec/UML/20131001/UMLDI"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:f="http://https://github.com/costezki/model2owl#"
    xmlns:sh="http://www.w3.org/ns/shacl#"
    xmlns:bibo="http://purl.org/ontology/bibo/"
    xmlns:xsd="http://www.w3.org/2001/XMLSchema"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns:dct="http://purl.org/dc/terms/"
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:skos="http://www.w3.org/2004/02/skos/core#"
    xmlns:vann="http://purl.org/vocab/vann/"
    exclude-result-prefixes="xs math xd xsl uml xmi umldi fn f bibo"
    version="3.0">

    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Mar 21, 2020</xd:p>
            <xd:p><xd:b>Author:</xd:b> lps</xd:p>
            <xd:p>This module constructs the data shape layer of the ontology</xd:p>
        </xd:desc>
    </xd:doc>


    <xsl:import href="common/selectors.xsl"/>
    <xsl:import href="shacl-shape-lib/elements-shacl-shape.xsl"/>
    <xsl:import href="shacl-shape-lib/connectors-shacl-shape.xsl"/>
    <!--<xsl:import href="..config-proxy.xsl"/>-->
    
    
    <xsl:output name="data-shapes-ePO.shapes.rdf" method="xml" encoding="UTF-8" byte-order-mark="no" indent="yes"
        cdata-section-elements="lines"/>
    
    <xd:doc>
        <xd:desc>The main template for OWL core file</xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <rdf:RDF>
            <xsl:call-template name="namespacesDeclaration"/>
            <xsl:call-template name="ontology-header"/>
            <xsl:apply-templates/>
        </rdf:RDF>
    </xsl:template>

    <xd:doc>
        <xd:desc> Ontology header </xd:desc>
    </xd:doc>
    <xsl:template name="ontology-header">
        <owl:Ontology rdf:about="{$shapeArtefactURI}">
            
            <xsl:for-each select="$internalNamespacePrefixes/*:prefixes/*:prefix/@importURI">              
                <owl:imports rdf:resource="{.}"/>
            </xsl:for-each>      
            <owl:imports rdf:resource="{$coreArtefactURI}"/>
            <owl:imports rdf:resource="{$restrictionsArtefactURI}"/>
            
            <dct:title xml:lang="en">
                <xsl:value-of select="$ontologyTitleShapes"/>
            </dct:title>
            <rdfs:label xml:lang="en">
                <xsl:value-of select="$ontologyLabelShapes"/>
            </rdfs:label>
            <dct:publisher>
                <xsl:value-of select="$publisher"/>
            </dct:publisher>
            <dct:description xml:lang="en">
                <xsl:value-of select="$ontologyDescriptionShapes"/>
            </dct:description>
            <rdfs:comment>This version is automatically generated from <xsl:value-of
                    select="tokenize(base-uri(.), '/')[last()]"/> on <xsl:value-of
                    select="format-date(current-date(), '[Y0001]-[M01]-[D01]')"/>
            </rdfs:comment>
            <xsl:for-each select="$seeAlsoResources">
                <rdfs:seeAlso rdf:resource="{.}"/>
            </xsl:for-each>
            <dct:issued rdf:datatype="http://www.w3.org/2001/XMLSchema#date"><xsl:value-of select="$issuedDate"/></dct:issued>
            <dct:created rdf:datatype="http://www.w3.org/2001/XMLSchema#date"><xsl:value-of select="$createdDate"/></dct:created>
            <owl:versionInfo><xsl:value-of select="$versionInfo"/></owl:versionInfo>   
            <owl:incompatibleWith><xsl:value-of select="$incompatibleWith"/></owl:incompatibleWith>
            <owl:versionIRI rdf:resource="{fn:concat($shapeArtefactURI,'-',$versionInfo)}"/>
 <!--           <bibo:status><xsl:value-of select="$ontologyStatus"/></bibo:status>-->
            <owl:priorVersion><xsl:value-of select="fn:concat($shapeArtefactURI,'-',$priorVersion)"/></owl:priorVersion>
            <vann:preferredNamespaceUri><xsl:value-of select="$preferredNamespaceUri"/></vann:preferredNamespaceUri>
            <vann:preferredNamespacePrefix><xsl:value-of select="$preferredNamespacePrefix"/></vann:preferredNamespacePrefix>
            <dct:license><xsl:value-of select="$licenseLiteral"/></dct:license>
            
        </owl:Ontology>
    </xsl:template>

</xsl:stylesheet>