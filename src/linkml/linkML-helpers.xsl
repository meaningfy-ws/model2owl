<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:f="http://https://github.com/costezki/model2owl#"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    exclude-result-prefixes="xs math xd xsl uml xmi fn f"
    xmlns:uml="http://www.omg.org/spec/UML/20131001"
    xmlns:xmi="http://www.omg.org/spec/XMI/20131001" xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:skos="http://www.w3.org/2004/02/skos/core#" xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:foaf="http://xmlns.com/foaf/0.1/" version="3.0">
    
    
<!-- Define the mapping function -->
<xsl:function name="f:mapToLinkMLType" as="xs:string">
    <xsl:param name="type" as="xs:string"/>
    
    <xsl:choose>
        <!-- XSD Data Types -->
        <xsl:when test="$type = 'xsd:anyURI'">Uri</xsl:when>
        <xsl:when test="$type = 'xsd:boolean'">Boolean</xsl:when>
        <xsl:when test="$type = 'xsd:byte'">Integer</xsl:when>
        <xsl:when test="$type = 'xsd:date'">Date</xsl:when>
        <xsl:when test="$type = 'xsd:dateTime'">Datetime</xsl:when>
        <xsl:when test="$type = 'xsd:dateTimeStamp'">Datetime</xsl:when>
        <xsl:when test="$type = 'xsd:time'">Time</xsl:when>
        <xsl:when test="$type = 'xsd:decimal'">Decimal</xsl:when>
        <xsl:when test="$type = 'xsd:double'">Double</xsl:when>
        <xsl:when test="$type = 'xsd:float'">Float</xsl:when>
        <xsl:when test="$type = 'xsd:int'">Integer</xsl:when>
        <xsl:when test="$type = 'xsd:integer'">Integer</xsl:when>
        <xsl:when test="$type = 'xsd:language'">String</xsl:when>
        <xsl:when test="$type = 'xsd:long'">Integer</xsl:when>
        <xsl:when test="$type = 'xsd:Name'">String</xsl:when>
        <xsl:when test="$type = 'xsd:NCName'">String</xsl:when>
        <xsl:when test="$type = 'xsd:NMTOKEN'">String</xsl:when>
        <xsl:when test="$type = 'xsd:negativeInteger'">Integer</xsl:when>
        <xsl:when test="$type = 'xsd:nonNegativeInteger'">Integer</xsl:when>
        <xsl:when test="$type = 'xsd:nonPositiveInteger'">Integer</xsl:when>
        <xsl:when test="$type = 'xsd:normalizedString'">String</xsl:when>
        <xsl:when test="$type = 'xsd:positiveInteger'">Integer</xsl:when>
        <xsl:when test="$type = 'xsd:short'">Integer</xsl:when>
        <xsl:when test="$type = 'xsd:string'">String</xsl:when>
        <xsl:when test="$type = 'xsd:token'">String</xsl:when>
        <xsl:when test="$type = 'xsd:unsignedByte'">Integer</xsl:when>
        <xsl:when test="$type = 'xsd:unsignedInt'">Integer</xsl:when>
        <xsl:when test="$type = 'xsd:unsignedLong'">Integer</xsl:when>
        <xsl:when test="$type = 'xsd:unsignedShort'">Integer</xsl:when>
        
        <!-- RDF Data Types -->
        <xsl:when test="$type = 'rdf:HTML'">String</xsl:when>
        <xsl:when test="$type = 'rdf:XMLLiteral'">String</xsl:when>
        <xsl:when test="$type = 'rdf:langString'">String</xsl:when>
        <xsl:when test="$type = 'rdf:PlainLiteral'">String</xsl:when>
        
        <!-- Default fallback -->
        <xsl:otherwise>String</xsl:otherwise>
    </xsl:choose>
</xsl:function>
    
    
    
</xsl:stylesheet>