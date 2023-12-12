<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:fn="http://www.w3.org/2005/xpath-functions"
    exclude-result-prefixes="xs math xd xsl uml xmi umldi dc fn f functx"
    xmlns:uml="http://www.omg.org/spec/UML/20131001"
    xmlns:xmi="http://www.omg.org/spec/XMI/20131001"
    xmlns:umldi="http://www.omg.org/spec/UML/20131001/UMLDI"
    xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:dct="http://purl.org/dc/terms/"
    xmlns:skos="http://www.w3.org/2004/02/skos/core#"  xmlns:functx="http://www.functx.com" 
    xmlns:f="http://https://github.com/costezki/model2owl#" version="3.0">
    
    <xsl:import href="../common/utils.xsl"/>
    <xsl:import href="../common/formatters.xsl"/>
    
    
    <xsl:template name="classDetails">
        <xsl:variable name="className" select="./@name"/>
        <xsl:variable name="classURI" select="f:buildURIFromElement(.)"/>
        <xsl:variable name="documentation" select="fn:normalize-space(f:formatDocStringForJson(./properties/@documentation))"/>
        
        <xsl:text>{&#xA;</xsl:text>
        "uri": "<xsl:value-of select="$classURI"/>",&#xA;
        "name": "<xsl:value-of select="$className"/>",&#xA;
        "label": {&#xA;    "en": "<xsl:value-of select="f:lexicalQNameToWords($className)"/>"&#xA;  },&#xA;
        "description": {&#xA;    "en": "<xsl:value-of select="fn:normalize-space(f:formatDocStringForJson(./properties/@documentation))"/>"&#xA;  },&#xA;
        "usage": {&#xA;    "en": "<xsl:value-of select="fn:normalize-space(f:formatDocStringForJson(./properties/@documentation))"/>"&#xA;  },&#xA;
        "parents": <xsl:call-template name="classParents"><xsl:with-param name="classElement" select="."/></xsl:call-template>,&#xA;
        "properties": [
        <xsl:variable name="proprietiesFromAttributes" as="item()*">
        <xsl:call-template name="classProprietiesFromAttributes"><xsl:with-param name="classElement" select="."/></xsl:call-template>
        </xsl:variable>
        
         <xsl:variable name="proprietiesFromAssociations" as="item()*">
        <xsl:call-template name="classProprietiesFromAssociations"><xsl:with-param name="classElement" select="."/></xsl:call-template>
        </xsl:variable>
                
        <xsl:variable name="proprietiesFromDependencies" as="item()*">
            <xsl:call-template name="classProprietiesFromDependencies"><xsl:with-param name="classElement" select="."/></xsl:call-template>
        </xsl:variable>

        <xsl:if test="fn:boolean($proprietiesFromAttributes)">
            <xsl:value-of select="$proprietiesFromAttributes" />
            </xsl:if>
        <xsl:if test="fn:boolean($proprietiesFromAssociations) and fn:boolean($proprietiesFromAttributes)">
                <xsl:text>,</xsl:text>
            </xsl:if>
        <xsl:if test="fn:boolean($proprietiesFromAssociations)">
            <xsl:value-of select="$proprietiesFromAssociations" />
            </xsl:if>
        <xsl:if test="(fn:boolean($proprietiesFromDependencies) and fn:boolean($proprietiesFromAttributes)) or (fn:boolean($proprietiesFromDependencies) and fn:boolean($proprietiesFromAssociations))">
                <xsl:text>,</xsl:text>
            </xsl:if>
        <xsl:if test="fn:boolean($proprietiesFromDependencies)">
            <xsl:value-of select="$proprietiesFromDependencies" />
            </xsl:if>            
        ]
        <xsl:text>}</xsl:text>
        

        
    </xsl:template>
    
    <xsl:template name="classParents">
        <xsl:param name="classElement"/>
        <xsl:variable name="classParentsNames"
            select="root($classElement)//connector[properties/@ea_type = 'Generalization' and source[model/@type = 'Class' and model/@name = $classElement/@name] and target[model/@type = 'Class']]/target/model/@name"
        />
        <xsl:text>[</xsl:text>
        <xsl:for-each select="$classParentsNames">
            <xsl:text>{</xsl:text>
            "uri": "<xsl:value-of select="f:buildURIfromLexicalQName(.)"/>",&#xA;
            "name": "<xsl:value-of select="."/>",&#xA;
            "label": {&#xA;    "en": "<xsl:value-of select="f:lexicalQNameToWords(.)"/>"&#xA;  }&#xA;
            <xsl:text>}</xsl:text>
            <xsl:if test="position() != last()">
                <xsl:text>,&#xA;</xsl:text>
            </xsl:if>
        </xsl:for-each>
        <xsl:text>]</xsl:text>
        
        
    </xsl:template>
    
    <xsl:template name="classProprietiesFromAttributes">
        <xsl:param name="classElement"/>
        <xsl:variable name="classAtributtes" select="$classElement/attributes/attribute"/>
        <xsl:if test="fn:count($classAtributtes) > 0">
            <xsl:for-each select="$classAtributtes">
                <xsl:text>{&#xA;</xsl:text>
                "uri": "<xsl:value-of select="f:buildURIfromLexicalQName(./@name)"/>",&#xA;
                "name": "<xsl:value-of select="./@name"/>",&#xA;
                "label": {&#xA;    "en": "<xsl:value-of select="f:lexicalQNameToWords(./@name)"/>"&#xA;},&#xA;
                "description": {&#xA;    "en": "<xsl:value-of select="fn:normalize-space(f:formatDocStringForJson(./documentation/@value))"/>"&#xA; },&#xA;
                "usage": {&#xA; },&#xA;
                "domain": [
                {&#xA; 
                "uri": "<xsl:value-of select="f:buildURIfromLexicalQName($classElement/@name)"/>",&#xA;
                "name": "<xsl:value-of select="$classElement/@name"/>"&#xA;
                }
                ],&#xA;
                "range": [
                {&#xA; 
                "uri": "<xsl:value-of select="f:buildURIfromLexicalQName(./properties/@type)"/>",&#xA;
                "name": "<xsl:value-of select="./properties/@type"/>"&#xA;
                }
                ],&#xA;
                "cardinality": "<xsl:value-of select="fn:concat(./bounds/@lower,'..',./bounds/@upper)"/>"
                <xsl:text>}</xsl:text>
                <xsl:if test="position() != last()">
                    <xsl:text>,&#xA;</xsl:text>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="classProprietiesFromAssociations">
        <xsl:param name="classElement"/>
        <xsl:variable name="associations"
            select="root($classElement)//connector[properties/@ea_type = 'Association' and source[model/@type = 'Class' and model/@name = $classElement/@name] and target[model/@type = 'Class']]"
        />
        <xsl:if test="fn:count($associations) > 0">

            <xsl:for-each select="$associations">
                <xsl:text>{&#xA;</xsl:text>
                "uri": "<xsl:value-of select="f:buildURIfromLexicalQName(./target/role/@name)"/>",&#xA;
                "name": "<xsl:value-of select="./target/role/@name"/>",&#xA;
                "label": {&#xA;    "en": "<xsl:value-of select="f:lexicalQNameToWords(./target/role/@name)"/>"&#xA;},&#xA;
                "description": {&#xA;    "en": "<xsl:value-of select="fn:normalize-space(f:formatDocStringForJson(./target/documentation/@value))"/>"&#xA; },&#xA;
                "usage": {&#xA; },&#xA;
                "domain": [
                {&#xA; 
                "uri": "<xsl:value-of select="f:buildURIfromLexicalQName(./source/model/@name)"/>",&#xA;
                "name": "<xsl:value-of select="./source/model/@name"/>"&#xA;
                }
                ],&#xA;
                "range": [
                {&#xA; 
                "uri": "<xsl:value-of select="f:buildURIfromLexicalQName(./target/model/@name)"/>",&#xA;
                "name": "<xsl:value-of select="./target/model/@name"/>"&#xA;
                }
                ],&#xA;
                "cardinality": "<xsl:value-of select="./target/type/@multiplicity"/>"
                <xsl:text>}</xsl:text>
                <xsl:if test="position() != last()">
                    <xsl:text>,&#xA;</xsl:text>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>
        
    </xsl:template>
    
    <xsl:template name="classProprietiesFromDependencies">
        <xsl:param name="classElement"/>
        <xsl:variable name="dependencies"
            select="root($classElement)//connector[properties/@ea_type = 'Dependency' and source[model/@type = 'Class' and model/@name = $classElement/@name] and target[model/@type = 'Enumeration']]"
        />
        <xsl:if test="fn:count($dependencies) > 0">            
            <xsl:for-each select="$dependencies">
                <xsl:text>{&#xA;</xsl:text>
                "uri": "<xsl:value-of select="f:buildURIfromLexicalQName(./target/role/@name)"/>",&#xA;
                "name": "<xsl:value-of select="./target/role/@name"/>",&#xA;
                "label": {&#xA;    "en": "<xsl:value-of select="f:lexicalQNameToWords(./target/role/@name)"/>"&#xA;},&#xA;
                "description": {&#xA;    "en": "<xsl:value-of select="fn:normalize-space(f:formatDocStringForJson(./target/documentation/@value))"/>"&#xA; },&#xA;
                "usage": {&#xA; },&#xA;
                "domain": [
                {&#xA; 
                "uri": "<xsl:value-of select="f:buildURIfromLexicalQName(./source/model/@name)"/>",&#xA;
                "name": "<xsl:value-of select="./source/model/@name"/>"&#xA;
                }
                ],&#xA;
                "range": [
                {&#xA; 
                "uri": "<xsl:value-of select="f:buildURIfromLexicalQName('skos:Concept')"/>",&#xA;
                "name": "<xsl:value-of select="'skos:Concept'"/>"&#xA;
                }
                ],&#xA;
                "cardinality": "<xsl:value-of select="./target/type/@multiplicity"/>"
                <xsl:text>}</xsl:text>
                <xsl:if test="position() != last()">
                    <xsl:text>,&#xA;</xsl:text>
                </xsl:if>
            </xsl:for-each>
        </xsl:if>
        
    </xsl:template>
    
        
    
    
    
</xsl:stylesheet>