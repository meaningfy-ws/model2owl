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
        <xsl:when test="$type = 'xsd:anyURI'">uri</xsl:when>
        <xsl:when test="$type = 'xsd:boolean'">boolean</xsl:when>
        <xsl:when test="$type = 'xsd:byte'">integer</xsl:when>
        <xsl:when test="$type = 'xsd:date'">date</xsl:when>
        <xsl:when test="$type = 'xsd:dateTime'">datetime</xsl:when>
        <xsl:when test="$type = 'xsd:dateTimeStamp'">datetime</xsl:when>
        <xsl:when test="$type = 'xsd:time'">time</xsl:when>
        <xsl:when test="$type = 'xsd:decimal'">decimal</xsl:when>
        <xsl:when test="$type = 'xsd:double'">double</xsl:when>
        <xsl:when test="$type = 'xsd:float'">float</xsl:when>
        <xsl:when test="$type = 'xsd:int'">integer</xsl:when>
        <xsl:when test="$type = 'xsd:integer'">integer</xsl:when>
        <xsl:when test="$type = 'xsd:language'">string</xsl:when>
        <xsl:when test="$type = 'xsd:long'">integer</xsl:when>
        <xsl:when test="$type = 'xsd:Name'">string</xsl:when>
        <xsl:when test="$type = 'xsd:NCName'">string</xsl:when>
        <xsl:when test="$type = 'xsd:NMTOKEN'">string</xsl:when>
        <xsl:when test="$type = 'xsd:negativeinteger'">integer</xsl:when>
        <xsl:when test="$type = 'xsd:nonNegativeinteger'">integer</xsl:when>
        <xsl:when test="$type = 'xsd:nonPositiveinteger'">integer</xsl:when>
        <xsl:when test="$type = 'xsd:normalizedstring'">string</xsl:when>
        <xsl:when test="$type = 'xsd:positiveinteger'">integer</xsl:when>
        <xsl:when test="$type = 'xsd:short'">integer</xsl:when>
        <xsl:when test="$type = 'xsd:string'">string</xsl:when>
        <xsl:when test="$type = 'xsd:token'">string</xsl:when>
        <xsl:when test="$type = 'xsd:unsignedByte'">integer</xsl:when>
        <xsl:when test="$type = 'xsd:unsignedInt'">integer</xsl:when>
        <xsl:when test="$type = 'xsd:unsignedLong'">integer</xsl:when>
        <xsl:when test="$type = 'xsd:unsignedShort'">integer</xsl:when>
        
        <!-- RDF Data Types -->
        <xsl:when test="$type = 'rdf:HTML'">string</xsl:when>
        <xsl:when test="$type = 'rdf:XMLLiteral'">string</xsl:when>
        <xsl:when test="$type = 'rdf:langstring'">string</xsl:when>
        <xsl:when test="$type = 'rdf:PlainLiteral'">string</xsl:when>
        
        <!-- Default fallback -->
        <xsl:otherwise>string</xsl:otherwise>
    </xsl:choose>
</xsl:function>
    
    
    
</xsl:stylesheet>