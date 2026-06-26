<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xd="http://www.oxygenxml.com/ns/doc/xsl"
    xmlns:f="http://https://github.com/costezki/model2owl#"
    exclude-result-prefixes="xs xd f"
    version="3.0">

    <xd:doc scope="stylesheet">
        <xd:desc>
            <xd:p>Bridge that lets the Makefile read a single value out of the active
                project configuration (resolved through config-proxy.xsl, so it honours
                whatever config a project has wired in). Invoke with the initial template
                <xd:i>main</xd:i> and a <xd:i>key</xd:i> parameter, e.g.
                <xd:pre>saxon -it:main -xsl:src/xml/emit-config-value.xsl key=generateOWLFull</xd:pre>
                It prints just the value (no markup) so it can be captured with $(shell ...).</xd:p>
        </xd:desc>
    </xd:doc>

    <xsl:import href="../../config-proxy.xsl"/>

    <xsl:output method="text" encoding="UTF-8"/>

    <xsl:param name="key" as="xs:string" select="''"/>

    <xsl:template name="main">
        <xsl:choose>
            <xsl:when test="$key = 'generateOWLFull'">
                <xsl:value-of select="$generateOWLFull"/>
            </xsl:when>
            <xsl:when test="$key = 'fullArtefactURI'">
                <xsl:value-of select="$fullArtefactURI"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:message terminate="yes"
                    select="concat('emit-config-value: unknown config key ''', $key, '''')"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>

</xsl:stylesheet>
