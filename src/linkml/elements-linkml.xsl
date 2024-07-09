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

    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p><xd:b>Created on:</xd:b> Mar 21, 2020</xd:p>
            <xd:p><xd:b>Author:</xd:b> lps</xd:p>
            <xd:p>This module defines how selected XMI elements are transformed into OWL2
                statements</xd:p>
        </xd:desc>
    </xd:doc>


    <xsl:import href="../common/formatters.xsl"/>
    <xsl:import href="../common/checkers.xsl"/>
    <xsl:import href="linkML-helpers.xsl"/>

    <xsl:output method="adaptive" encoding="UTF-8" byte-order-mark="no" indent="yes"
        cdata-section-elements="lines"/>

   




    <xd:doc>
        <xd:desc> Selector to run core layer transformation rules for classes</xd:desc>
    </xd:doc>
    <xsl:template match="element[@xmi:type = 'uml:Class']">
            <xsl:call-template name="classDeclaration"/>
    </xsl:template>

    <xd:doc>
        <xd:desc></xd:desc>
    </xd:doc>
    <xsl:template name="classDeclaration">
        <xsl:variable name="className" select="./@name"/>
        <xsl:variable name="idref" select="./@xmi:idref"/>
        <xsl:variable name="superclass" select="root()//connectors/connector[./properties/@ea_type = 'Generalization'][source/@xmi:idref=$idref]/target/model/@name"/>

        <xsl:variable name="classURI" select="f:buildURIFromElement(.)"/>
        <xsl:variable name="documentation" select="fn:normalize-space(f:formatDocString(./properties/@documentation))"/>
        <xsl:text>  </xsl:text>
        <xsl:value-of select="fn:concat(fn:substring-after(@name,':'), ':')"/>
        <xsl:text>&#10;</xsl:text>
        <xsl:text>    class_uri: </xsl:text><xsl:value-of select="$className"/>
        <xsl:text>&#10;</xsl:text>
        <xsl:if test="fn:boolean($superclass)">
            <xsl:choose>
                <xsl:when test="fn:count($superclass) > 1">
                    <xsl:text>    is_a: </xsl:text>
                    <xsl:value-of select="if (fn:contains($superclass[1], ':')) then fn:substring-after($superclass[1], ':') else $superclass[1]"/>
                    <xsl:text>&#10;</xsl:text>
                    <xsl:text>    mixins: </xsl:text>
                    <xsl:text>&#10;</xsl:text>
                    <xsl:for-each select="$superclass[position() > 1]"><xsl:text>      - </xsl:text><xsl:value-of select="if (fn:contains(., ':')) then fn:substring-after(., ':') else ."/>
                        <xsl:text>&#10;</xsl:text>
                        
                    </xsl:for-each>
                </xsl:when>
                <xsl:otherwise>
                    <xsl:text>    is_a: </xsl:text>
                    <xsl:value-of select="fn:substring-after($superclass, ':')"/>
                    <xsl:text>&#10;</xsl:text>
                </xsl:otherwise>
            </xsl:choose>

        </xsl:if>
        <xsl:text>    description: </xsl:text>
        <xsl:value-of select="fn:normalize-space(properties/@documentation)"/>
        <xsl:text>&#10;</xsl:text>
        <xsl:text>    attributes:&#10;</xsl:text>
        <xsl:apply-templates select="attributes/attribute"/>
    </xsl:template>
    

    
    <xsl:template match="attribute">
        <xsl:variable name="attributeType" select="./properties/@type"/>
        <xsl:text>      </xsl:text>
        <xsl:value-of select="if (fn:contains(./@name, ':')) then fn:substring-after(./@name, ':') else ./@name"/>
        <xsl:text>:&#10;</xsl:text>
        <xsl:text>        slot_uri: </xsl:text>
        <xsl:value-of select="./@name"/>
        <xsl:text>&#10;</xsl:text>
        <xsl:text>        description: </xsl:text>
        <xsl:value-of select="fn:normalize-space(./documentation/@value)"/>
        <xsl:text>&#10;</xsl:text>
        <xsl:text>        range: </xsl:text>
        <xsl:choose>
            <xsl:when test="boolean($attributeType)">
                 <xsl:value-of select="f:mapToLinkMLType($attributeType)"/>
            </xsl:when>
            <xsl:otherwise>String</xsl:otherwise>
        </xsl:choose>
       
        <xsl:text>&#10;</xsl:text>
        <xsl:text>        required: </xsl:text>
        <xsl:value-of select="if ((./bounds/@lower) != '0') then fn:true() else fn:false()"/>
        <xsl:text>&#10;</xsl:text>
        <xsl:text>        multivalued: </xsl:text>
        <xsl:value-of select="if((./bounds/@upper) = '*') then fn:true() else fn:false()"/>
        <xsl:text>&#10;</xsl:text>
<!--        <xsl:if test="@required='false'">
            <xsl:text>&#10;</xsl:text>
            <xsl:text>        required: false&#10;</xsl:text>
        </xsl:if>-->
    </xsl:template>








</xsl:stylesheet>