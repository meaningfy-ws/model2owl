<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:math="http://www.w3.org/2005/xpath-functions/math"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl" xmlns:fn="http://www.w3.org/2005/xpath-functions"
    exclude-result-prefixes="xs math xd xsl uml xmi umldi dc fn"
    xmlns:uml="http://www.omg.org/spec/UML/20131001"
    xmlns:xmi="http://www.omg.org/spec/XMI/20131001"
    xmlns:umldi="http://www.omg.org/spec/UML/20131001/UMLDI"
    xmlns:dc="http://www.omg.org/spec/UML/20131001/UMLDC" xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#" xmlns:dct="http://purl.org/dc/terms/"
    xmlns:f="http://https://github.com/costezki/model2owl#"
    xmlns:skos="http://www.w3.org/2004/02/skos/core#" version="3.0">
    <xsl:output method="text" indent="yes" media-type="application/json"/>
    <xsl:strip-space elements="*"/>
    
    <xsl:import href="rspec/rspec-generation.xsl"/>
    <xsl:import href="common/checkers.xsl"/>
 
    
    <!-- Match the root element -->
    <xsl:template match="/">
        <xsl:text>{&#xA;</xsl:text>
        <xsl:call-template name="metadata"/>
        <xsl:text>,&#xA;</xsl:text>
        <xsl:call-template name="usedPrefixes"/>
        <xsl:text>,&#xA;</xsl:text>
        "classes" : [
        <xsl:apply-templates select="/xmi:XMI/xmi:Extension/elements"/>
        ]
        <xsl:text>}</xsl:text>
    </xsl:template>
    
    <xsl:template match="element[@xmi:type = 'uml:Class']">
        <xsl:call-template name="classDetails"/>
        <xsl:if test="following-sibling::element[@xmi:type = 'uml:Class']">
            <xsl:text>,&#xA;</xsl:text>
        </xsl:if>
    </xsl:template>
    
    <xsl:template name="usedPrefixes">
        <xsl:variable name="prefixes" select="f:getAllNamespacesUsed(root(.))"/>
        "prefixes" : [
        <xsl:for-each select="$prefixes">
            <xsl:variable name="prefix" select="."/>
            <xsl:text>{&#xA;</xsl:text>
            "uri": "<xsl:value-of select="$namespacePrefixes/*:prefixes/*:prefix/@value[../@name = $prefix]"/>",&#xA;
            "name": "<xsl:value-of select="$prefix"/>"&#xA;
            <xsl:text>}</xsl:text>
            <xsl:if test="position() != last()">
                <xsl:text>,&#xA;</xsl:text>
            </xsl:if>
        </xsl:for-each>
        ]
    </xsl:template>
    
    
    <xsl:template name="metadata">
        "metadata" : {

        "title": "<xsl:value-of select="$ontologyTitleCore"/>",&#xA;
        "uri": "<xsl:value-of select="$preferredNamespaceUri"/>",&#xA;
        "issued": "<xsl:value-of select="$issuedDate"/>",&#xA;
        "baseURI": "<xsl:value-of select="$preferredNamespaceUri"/>",&#xA;
        "feedbackurl": "<xsl:value-of select="$feedbackURL"/>",&#xA;
        "description": "<xsl:value-of select="fn:normalize-space(f:formatDocStringForJson($respecDescription))"/>",&#xA;
        "github" : "<xsl:value-of select="$githubURL"/>",&#xA;
        "authors" : [<xsl:value-of select="for $author in $authors return if ($author = $authors[last()]) then concat('&quot;',$author,'&quot;') else concat('&quot;',$author,'&quot;', ',')"/>],&#xA;
        "editors" : [<xsl:value-of select="for $editor in $editors return if ($editor = $editors[last()]) then concat('&quot;',$editor,'&quot;') else concat('&quot;',$editor,'&quot;', ',')"/>]&#xA;
        }
    </xsl:template>
    
    
    
</xsl:stylesheet>
