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
        <xd:desc> Selector to run templates for all element type class</xd:desc>
    </xd:doc>
    <xsl:template match="element[@xmi:type = 'uml:Class']">
        <xsl:call-template name="classDeclaration"/>
    </xsl:template>

    <xd:doc>
        <xd:desc>This is the template the is aplied for a class element
            Example -
            Tender:
                description: A document specifying a tender
                is_a: Document
                attributes:
                    hasElectronicSubmission:
                        description: Indicates if the tender has an electronic submission
                        range: boolean
                        required: false
                    isVariant:
                        description: Indicates if the tender is a variant
                        range: boolean
                        required: false
        </xd:desc>
    </xd:doc>
    <xsl:template name="classDeclaration">
        <xsl:variable name="className" select="./@name"/>
        <xsl:variable name="idref" select="./@xmi:idref"/>
        <xsl:variable name="superclass"
            select="root()//connectors/connector[./properties/@ea_type = 'Generalization'][source/@xmi:idref = $idref]/target/model/@name"/>

        <xsl:variable name="classURI" select="f:buildURIFromElement(.)"/>
        <xsl:variable name="documentation"
            select="replace(fn:normalize-space(f:formatDocString(./properties/@documentation)),':\s+',':')"/>
        <xsl:text>  </xsl:text>
        <xsl:value-of select="fn:concat(fn:substring-after(@name, ':'), ':')"/>
        <xsl:text>&#10;</xsl:text>
        <xsl:text>    class_uri: </xsl:text>
        <xsl:value-of select="$className"/>
        <xsl:text>&#10;</xsl:text>
        <xsl:if test="fn:boolean($superclass)">
            <xsl:choose>
                <xsl:when test="fn:count($superclass) > 1">
                    <xsl:text>    is_a: </xsl:text>
                    <xsl:value-of
                        select="
                            if (fn:contains($superclass[1], ':')) then
                                fn:substring-after($superclass[1], ':')
                            else
                                $superclass[1]"/>
                    <xsl:text>&#10;</xsl:text>
                    <xsl:text>    mixins: </xsl:text>
                    <xsl:text>&#10;</xsl:text>
                    <xsl:for-each select="$superclass[position() > 1]">
                        <xsl:text>      - </xsl:text>
                        <xsl:value-of
                            select="
                                if (fn:contains(., ':')) then
                                    fn:substring-after(., ':')
                                else
                                    ."/>
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
        <xsl:value-of select="$documentation"/>
        <xsl:text>&#10;</xsl:text>
        <!--Variables needed to see if this class has attributes and/or proprieties from connectors-->
        <xsl:variable name="associationsSourceDestinationConnectors"
            select="//connector[properties/@direction = 'Source -&gt; Destination' and source/model[@name = $className] and target/role/@name and properties/@ea_type = 'Association']"/>
        <xsl:variable name="associationsBidirectionalConnectors"
            select="//connector[properties/@direction = 'Bi-Directional' and properties/@ea_type = 'Association' and ((source/model[@name = $className] and target/role/@name) or (target/model[@name = $className] and source/role/@name))]"/>
        <xsl:variable name="dependencyConnectors"
            select="//connector[properties/@ea_type = 'Dependency' and source/model[@name = $className] and target/role/@name]"/>
        <xsl:variable name="attributes" select="./attributes/attribute"/>
        <xsl:if test="fn:count($attributes) > 0 or fn:count($associationsSourceDestinationConnectors) > 0 or fn:count($associationsBidirectionalConnectors) > 0 or fn:count($dependencyConnectors) > 0">
            <xsl:text>    attributes:&#10;</xsl:text>
            
            <xsl:for-each select="$attributes">
                <xsl:call-template name="attributeDeclaration">
                    <xsl:with-param name="attribute" select="."/>
                </xsl:call-template>
                
            </xsl:for-each>
        
        <xsl:for-each select="$associationsSourceDestinationConnectors">
            <xsl:call-template name="proprietiesFromConnectors">
                <xsl:with-param name="connector" select="."/>
                <xsl:with-param name="className" select="$className"/>
            </xsl:call-template>
        </xsl:for-each>
        <xsl:for-each select="$associationsBidirectionalConnectors">
            <xsl:call-template name="proprietiesFromConnectors">
                <xsl:with-param name="connector" select="."/>
                <xsl:with-param name="className" select="$className"/>
            </xsl:call-template>
        </xsl:for-each>
        <xsl:for-each select="$dependencyConnectors">
            <xsl:call-template name="proprietiesFromConnectors">
                <xsl:with-param name="connector" select="."/>
                <xsl:with-param name="className" select="$className"/>
            </xsl:call-template>
        </xsl:for-each>
        </xsl:if>
        <xsl:text>&#10;</xsl:text>
    </xsl:template>



    <xd:doc>
        <xd:desc> This template is for representing an attribute in linkML
        Example -
        isVariant:
            description: Indicates if the tender is a variant
            range: boolean
            required: false
        </xd:desc>
        <xd:param name="attribute"/>
    </xd:doc>
    <xsl:template name="attributeDeclaration">
        <xsl:param name="attribute" as="node()*"/>
        <xsl:variable name="attributeType" select="$attribute/properties/@type"/>
        <xsl:text>      </xsl:text>
        <xsl:value-of
            select="
                if (fn:contains(./@name, ':')) then
                    fn:substring-after(./@name, ':')
                else
                    ./@name"/>
        <xsl:text>:&#10;</xsl:text>
        <xsl:text>        slot_uri: </xsl:text>
        <xsl:value-of select="./@name"/>
        <xsl:text>&#10;</xsl:text>
        <xsl:text>        description: </xsl:text>
        <xsl:value-of select="replace(fn:normalize-space(f:formatDocString(./documentation/@value)),':\s+',':')"/>
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
        <xsl:value-of
            select="
                if ((./bounds/@lower) != '0') then
                    fn:true()
                else
                    fn:false()"/>
        <xsl:text>&#10;</xsl:text>
        <xsl:text>        multivalued: </xsl:text>
        <xsl:value-of
            select="
                if ((./bounds/@upper) = '*') then
                    fn:true()
                else
                    fn:false()"/>
        <xsl:text>&#10;</xsl:text>
    </xsl:template>


    <xd:doc>
        <xd:desc> This template is for representing a property from a connector to a given class name
        Example -
        hasRequirementRequirement:
            slot_uri: cccev:hasRequirement
            range: Requirement
            required: false
            multivalued: true
        </xd:desc>
        <xd:param name="connector"/>
        <xd:param name="className"/>
    </xd:doc>
    <xsl:template name="proprietiesFromConnectors">
        <xsl:param name="connector" as="node()*"/>
        <xsl:param name="className"/>

        <xsl:if test="$connector/source/model/@name = $className">


            <xsl:variable name="targetRoleName" select="$connector/target/role/@name"/>
            <xsl:variable name="range"
                select="
                    if (fn:contains($connector/target/model/@name, ':')) then
                        fn:substring-after($connector/target/model/@name, ':')
                    else
                        $connector/target/model/@name"/>
            <xsl:text>      </xsl:text>
            <xsl:value-of
                select="
                    if (fn:contains($targetRoleName, ':')) then
                        fn:substring-after($targetRoleName, ':')
                    else
                        $targetRoleName"/>
            <xsl:text>:&#10;</xsl:text>
            <xsl:text>        slot_uri: </xsl:text>
            <xsl:value-of select="$targetRoleName"/>
            <xsl:text>&#10;</xsl:text>
            <xsl:if test="$connector/target/documentation/@value">
                <xsl:text>        description: </xsl:text>
                <xsl:value-of
                    select="replace(fn:normalize-space(f:formatDocString($connector/target/documentation/@value)), ':\s+', ':')"/>
                <xsl:text>&#10;</xsl:text>
            </xsl:if>
            <xsl:text>        range: </xsl:text>
            <xsl:value-of
                select="$range"/>


            <xsl:text>&#10;</xsl:text>
            <xsl:text>        required: </xsl:text>
            <xsl:value-of
                select="
                    if ((substring($connector/target/type/@multiplicity, 1, 1)) != '0') then
                        fn:true()
                    else
                        fn:false()"/>
            <xsl:text>&#10;</xsl:text>
            <xsl:text>        multivalued: </xsl:text>
            <xsl:value-of
                select="
                    if ((substring($connector/target/type/@multiplicity, string-length($connector/target/type/@multiplicity), 1)) = ('0', '1')) then
                        fn:false()
                    else
                        fn:true()"/>
            <xsl:text>&#10;</xsl:text>
        </xsl:if>
        <xsl:if test="$connector/target/model/@name = $className and $connector/properties/@direction = 'Bi-Directional'">


            <xsl:variable name="sourceRoleName" select="$connector/source/role/@name"/>
            <xsl:variable name="range"
                select="
                if (fn:contains($connector/source/model/@name, ':')) then
                fn:substring-after($connector/source/model/@name, ':')
                else
                $connector/source/model/@name"/>
            
            <xsl:text>      </xsl:text>
            <xsl:value-of
                select="
                    if (fn:contains($sourceRoleName, ':')) then
                        fn:substring-after($sourceRoleName, ':')
                    else
                        $sourceRoleName"/>
            <xsl:text>:&#10;</xsl:text>
            <xsl:text>        slot_uri: </xsl:text>
            <xsl:value-of select="$sourceRoleName"/>
            <xsl:value-of select="' - '"/>
            <xsl:value-of select="$connector/@xmi:idref"/>
            <xsl:text>&#10;</xsl:text>
            <xsl:if test="$connector/source/documentation/@value">
                <xsl:text>        description: </xsl:text>
                <xsl:value-of select="replace(fn:normalize-space(f:formatDocString($connector/source/documentation/@value)),':\s+',':')"/>
                <xsl:text>&#10;</xsl:text>
            </xsl:if>
            <xsl:text>        range: </xsl:text>
            <xsl:value-of
                select="$range"/>


            <xsl:text>&#10;</xsl:text>
            <xsl:text>        required: </xsl:text>
            <xsl:value-of
                select="
                    if ((substring($connector/source/type/@multiplicity, 1, 1)) != '0') then
                        fn:true()
                    else
                        fn:false()"/>
            <xsl:text>&#10;</xsl:text>
            <xsl:text>        multivalued: </xsl:text>
            <xsl:value-of
                select="
                    if ((substring($connector/source/type/@multiplicity, string-length($connector/source/type/@multiplicity), 1)) = ('0', '1')) then
                        fn:false()
                    else
                        fn:true()"/>
            <xsl:text>&#10;</xsl:text>
        </xsl:if>
    </xsl:template>
    

    <xd:doc>
        <xd:desc>Selector to run templates for all elements type enumeration</xd:desc>
    </xd:doc>
    <xsl:template match="element[@xmi:type = 'uml:Enumeration']">
        <xsl:call-template name="enumerationDeclaration"/>
    </xsl:template>
    
    <xd:doc>
        <xd:desc>This is the template the is aplied for a enumeration element</xd:desc>
        Example:
        applicability:
            description: This table provides a list of the options pertinent to be chosen for a matter concerning the applicability of predefined fields.
            uri: at-voc:applicability
            permissible_values: {}
    </xd:doc>
    <xsl:template name="enumerationDeclaration">
        <xsl:text>  </xsl:text>
        <xsl:value-of
            select="
            if (fn:contains(./@name, ':')) then
            fn:substring-after(./@name, ':')
            else
            ./@name"/>
        <xsl:text>:&#10;    description: </xsl:text>
        <xsl:value-of select="replace(fn:normalize-space(f:formatDocString(./properties/@documentation)),':\s+',':')"/>
        <xsl:text>&#10;    uri: </xsl:text>
        <xsl:value-of select="./@name"/>
        <xsl:text>&#10;    permissible_values:&#10;</xsl:text>
        <xsl:variable name="enumerationAttributes" select="./attributes/attribute"/>
        <xsl:choose>
            <!-- Check if there are attributes -->
            <xsl:when test="count($enumerationAttributes) > 0">
                <xsl:for-each select="$enumerationAttributes">
                    <xsl:text>      </xsl:text>
                    <xsl:value-of select="if (contains(./@name, '.')) then replace(./@name, '\.', '_') else ./@name"/>
                    <xsl:text>:&#10;        description: </xsl:text>
                    <xsl:value-of select="replace(fn:normalize-space(f:formatDocString(./documentation/@value)),':\s+',':')"/>
                    <xsl:text>&#10;</xsl:text>
                </xsl:for-each>
            </xsl:when>
            <xsl:otherwise>
                <xsl:text>      {}&#10;</xsl:text>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    
    


</xsl:stylesheet>