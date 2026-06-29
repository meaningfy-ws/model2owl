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
    xmlns:skos="http://www.w3.org/2004/02/skos/core#"
    xmlns:f="http://https://github.com/costezki/model2owl#" version="3.0">

    <xsl:import href="../common/checkers.xsl"/>
    <xsl:import href="utils-html-conventions.xsl"/>

    <!-- Reference to the documentation page on UML constructs model2owl does not transform.
         Shared by the unsupported connector / element / modifier / construct warnings below and
         kept module-scoped so the host/path is changed in one place. -->
    <xsl:variable name="unsupportedConstructsRefLabel" as="xs:string"
        select="'unsupported UML constructs'"/>
    <xsl:variable name="unsupportedConstructsRefLink" as="xs:string"
        select="'&lt;a href=&quot;https://meaningfy-ws.github.io/model2owl-docs-gh-pages/public-review/uml/unsupported-uml-constructs.html#sec:unsupported-uml-constructs&quot; target=&quot;_blank&quot;&gt;Unsupported UML constructs&lt;/a&gt;'"/>

    <xd:doc>
        <xd:desc>Applying general conventions templates </xd:desc>
    </xd:doc>

    <xsl:template name="generalConventions">
        <xsl:variable name="root" select="root()"/>
        
        <xsl:if test="$reportType = 'HTML'">
           <h1 id="generalConventions">General conventions</h1> 
        </xsl:if>
 
        <xsl:variable name="generalChecks" as="item()*">
            <xsl:call-template name="connectorTypes">
                <xsl:with-param name="root" select="$root"/>
            </xsl:call-template>
            <xsl:call-template name="elementTypes">
                <xsl:with-param name="root" select="$root"/>
            </xsl:call-template>
            <xsl:call-template name="modifierTypes">
                <xsl:with-param name="root" select="$root"/>
            </xsl:call-template>
            <xsl:call-template name="unsupportedConstructs">
                <xsl:with-param name="root" select="$root"/>
            </xsl:call-template>
            <xsl:call-template name="undefinedPrefixes">
                <xsl:with-param name="root" select="$root"/>
            </xsl:call-template>
        </xsl:variable>
        <xsl:if test="boolean($generalChecks)">
            <xsl:copy-of select="$generalChecks"/>
        </xsl:if>
    </xsl:template>



    <xd:doc>
        <xd:desc>[general-connector-type-1] Only associations, dependecies, generalisations and
            realisation connectors are supported. </xd:desc>
        <xd:param name="root"/>
    </xd:doc>
    <xsl:template name="connectorTypes">
        <xsl:param name="root"/>
        <xsl:variable name="usedConnectorTypes"
            select="fn:distinct-values($root//connectors/connector/properties/@ea_type)"/>
        <xsl:variable name="supportedConnectorTypes"
            select="('Association', 'Dependency', 'Generalization', 'Realisation')"/>
        <xsl:variable name="unsupportedConnectorTypes"
            select="$usedConnectorTypes[not(. = $supportedConnectorTypes)]"/>
        <xsl:sequence
            select="
                if (count($unsupportedConnectorTypes) > 0) then
                    f:generateFormattedWarningMessage('Model2owl supports association, dependency, generalisation and realisation connectors. The following connector types were found in the model and are not transformed. For guidance, see the documentation on unsupported UML constructs', $unsupportedConnectorTypes,
                    '//connectors/connector/properties/@ea_type',
                    'general-connector-type-1',
                    $unsupportedConstructsRefLabel,
                    $unsupportedConstructsRefLink
                    )
                else
                    ()
                "
        />
    </xsl:template>


    <xd:doc>
        <xd:desc>[general-element-type-2] Only Class, Package, Datatype, Enumeration, and Object
            elements are supported </xd:desc>
        <xd:param name="root"/>
    </xd:doc>
    <xsl:template name="elementTypes">
        <xsl:param name="root"/>
        <xsl:variable name="usedElementTypes"
            select="fn:distinct-values($root//elements/element/@xmi:type)"/>
        <xsl:variable name="supportedElementTypes"
            select="('uml:Class', 'uml:Enumeration', 'uml:DataType', 'uml:Package', 'uml:Object')"/>
        <!-- EA-internal artefacts (e.g. the ProxyConnector spines of n-ary associations and
             association classes) are an internal representation detail, not user-authored
             constructs, so they are not reported as unsupported. -->
        <xsl:variable name="ignoredInternalElementTypes" select="('uml:ProxyConnector')"/>
        <xsl:variable name="unsupportedElementTypes"
            select="$usedElementTypes[not(. = $supportedElementTypes) and not(. = $ignoredInternalElementTypes)]"/>
        <!-- A uml:Association *element* (as opposed to a binary association connector) is an
             n-ary association; label it as such for clarity. -->
        <xsl:variable name="unsupportedElementTypesDisplay" as="xs:string*"
            select="
                for $type in $unsupportedElementTypes
                return
                    if ($type = 'uml:Association') then
                        'uml:Association (n-ary association)'
                    else
                        $type"/>
        <xsl:sequence
            select="
                if (count($unsupportedElementTypes) > 0) then
                    f:generateFormattedWarningMessage('Model2owl supports Class, Package, Datatype, Enumeration, and Object elements. The following element types were found in the model and are not transformed. For guidance, see the documentation on unsupported UML constructs', $unsupportedElementTypesDisplay,
                    '//elements/element/@xmi:type',
                    'general-element-type-2',
                    $unsupportedConstructsRefLabel,
                    $unsupportedConstructsRefLink
                    )
                else
                    ()
                "
        />
    </xsl:template>



    <xd:doc>
        <xd:desc>[general-modifier-type-4] UML attribute / generalisation-set modifiers
            ({id}, {complete}) are not transformed. {disjoint} IS transformed (OWL
            disjointness in owl-restrictions) and is no longer reported here. Reports which
            kinds occur at least once in the model (presence only, not each occurrence). </xd:desc>
        <xd:param name="root"/>
    </xd:doc>
    <xsl:template name="modifierTypes">
        <xsl:param name="root"/>
        <xsl:variable name="foundModifiers" as="xs:string*">
            <xsl:if
                test="$root//attributes/attribute/xrefs[contains(@value, 'isID@ENDNAME;@TYPE=Boolean@ENDTYPE;@VALU=1')]">
                <xsl:sequence select="'{id}'"/>
            </xsl:if>
            <xsl:if
                test="$root//connectors/connector[properties/@ea_type = 'Generalization']/xrefs[contains(@value, 'IsCovering=1')]">
                <xsl:sequence select="'{complete}'"/>
            </xsl:if>
        </xsl:variable>
        <xsl:sequence
            select="
                if (count($foundModifiers) > 0) then
                    f:generateFormattedWarningMessage('Model2owl does not transform UML attribute or generalisation-set modifiers. The following were found in the model and carry no meaning in the generated artefacts. For guidance, see the documentation on unsupported UML constructs', $foundModifiers,
                    '//attributes/attribute/xrefs/@value | //connectors/connector/xrefs/@value',
                    'general-modifier-type-4',
                    $unsupportedConstructsRefLabel,
                    $unsupportedConstructsRefLink
                    )
                else
                    ()"
        />
    </xsl:template>

    <xd:doc>
        <xd:desc>[general-construct-type-5] UML constructs that surface as supported element /
            connector types but are not transformed (association class, qualified association).
            Reports presence only, not each occurrence. </xd:desc>
        <xd:param name="root"/>
    </xd:doc>
    <xsl:template name="unsupportedConstructs">
        <xsl:param name="root"/>
        <xsl:variable name="foundConstructs" as="xs:string*">
            <xsl:if test="$root//connectors/connector[extendedProperties/@associationclass != '']">
                <xsl:sequence select="'association class'"/>
            </xsl:if>
            <xsl:if test="$root//connectors/connector[.//qualifiers/qualifier]">
                <xsl:sequence select="'qualified association'"/>
            </xsl:if>
        </xsl:variable>
        <xsl:sequence
            select="
                if (count($foundConstructs) > 0) then
                    f:generateFormattedWarningMessage('Model2owl does not transform the following UML constructs found in the model. For guidance, see the documentation on unsupported UML constructs', $foundConstructs,
                    '//connectors/connector',
                    'general-construct-type-5',
                    $unsupportedConstructsRefLabel,
                    $unsupportedConstructsRefLink
                    )
                else
                    ()"
        />
    </xsl:template>

    <xd:doc>
        <xd:desc>[general-prefix-3] The prefixes $[list of undefined prefixes] are not defined.
            All used namespaces shall be defined ("prefix" = "base URI"), including the default one
            (""="base URI"). </xd:desc>
        <xd:param name="root"/>
    </xd:doc>
    <xsl:template name="undefinedPrefixes">
        <xsl:param name="root"/>
        <xsl:variable name="listOfUsedPrefixes" select="f:getAllNamespacesUsed($root)"/>
        <xsl:variable name="areAllPrefixesDefined"
            select="f:isAllNamespacesDefined($listOfUsedPrefixes)"/>
        <xsl:sequence
            select="
                if ($areAllPrefixesDefined instance of xs:boolean) then
                    ()
                else
                    f:generateFormattedErrorMessage(fn:concat('Not all prefixes ',
                    ' are defined. All used namespaces shall be defined (prefix = base URI), including the default one. Here is the list of undefined prefixes'), $areAllPrefixesDefined,
                    path($root),
                    'general-prefix-3',
                    'CMC-R5',
                    '&lt;a href=&quot;https://semiceu.github.io/style-guide/1.0.0/gc-conceptual-model-conventions.html#sec:cmc-r5&quot; target=&quot;_blank&quot;&gt;CMC-R5&lt;/a&gt;'
                    )"
        />
    </xsl:template>


</xsl:stylesheet>