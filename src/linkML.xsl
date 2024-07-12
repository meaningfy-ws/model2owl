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
            <xd:p><xd:b>Created on:</xd:b> July 12, 2024</xd:p>
            <xd:p><xd:b>Author:</xd:b> Dragos</xd:p>
            <xd:p>This module transforms OWL ontology to linkML</xd:p>
        </xd:desc>
    </xd:doc>
    
    
    <xsl:import href="linkml/elements-linkml.xsl"/>
    <xsl:import href="../config-proxy.xsl"/>

    <xsl:output method="text" encoding="UTF-8" byte-order-mark="no" indent="yes"
        cdata-section-elements="lines"/>
    
    
    
    <xd:doc>
        <xd:desc>The main template for linkML file</xd:desc>
    </xd:doc>
    <xsl:template match="/">
        <!--        -\-\-\-\-\-\-\- metadata section -\-\-\-\-\-\-\-\-\-\-->
        <xsl:text>id: </xsl:text><xsl:value-of select="$base-ontology-uri"/>
        <xsl:text>&#10;</xsl:text>
        <xsl:text>name: </xsl:text><xsl:value-of select="$ontologyTitleCore"/>
        <xsl:text>&#10;</xsl:text>
        <xsl:text>description: </xsl:text><xsl:value-of select="fn:normalize-space(f:formatDocString($ontologyDescriptionCore))"/>
        <xsl:text>&#10;</xsl:text>
        <!--        -\-\-\-\-\-\-\- prefixes section -\-\-\-\-\-\-\-\-\-\-->
        <xsl:variable name="listOfUsedPrefixes" select="f:getAllNamespacesUsed(root())"/>
        <xsl:text>prefixes: </xsl:text>
        <xsl:text>&#10;</xsl:text>
        <xsl:for-each select="$listOfUsedPrefixes">
            <xsl:variable name="namespace" select="."/>
            <xsl:text>  </xsl:text>
            <xsl:value-of select="fn:concat($namespace,': ')"/>
            <xsl:value-of select="f:getNamespaceValues($namespace, $namespacePrefixes)"/>
            <xsl:text>&#10;</xsl:text>
        </xsl:for-each>
        
        <!--        -\-\-\-\-\-\-\- types section -\-\-\-\-\-\-\-\-\-\-->
        <xsl:text>&#10;types:&#10;  string:&#10;    base: xsd:string&#10;  boolean:&#10;    base: xsd:boolean&#10;  integer:&#10;    base: xsd:integer&#10;</xsl:text>
        <!--        -\-\-\-\-\-\-\- classes section -\-\-\-\-\-\-\-\-\-\-->
        <xsl:text>&#10;classes:&#10;</xsl:text>
        
        <!-- Process all Class elements -->
        <xsl:apply-templates select="//element[@xmi:type='uml:Class']"/>
        <!--        -\-\-\-\-\-\-\- enums section -\-\-\-\-\-\-\-\-\-\-->
        <xsl:text>&#10;enums:&#10;</xsl:text>
        
        <!-- Process all Enumeration elements -->
        <xsl:apply-templates select="//element[@xmi:type='uml:Enumeration']"/>
    </xsl:template>
    

    
</xsl:stylesheet>