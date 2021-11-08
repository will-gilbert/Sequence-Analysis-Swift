<?xml version="1.0" encoding="utf-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

  <xsl:output method="xml" media-type="text/xml" indent="yes" encoding="utf-8" version="1.0"/>

  <xsl:template match="PATTERN">

    <xsl:element name="giv-frame">
      <xsl:attribute name="name">
        <xsl:value-of select="@sequence"/>
      </xsl:attribute>
      
      <xsl:attribute name="extent">
        <xsl:value-of select="@length"/>
      </xsl:attribute>
      
      <xsl:attribute name="bkg-color">
        <xsl:text>Peach</xsl:text>
      </xsl:attribute>

      <xsl:apply-templates select="pattern"/>

    </xsl:element>

  </xsl:template>


  <!-- Each Document is processed here, this is where you can specify the order  -->
 
  <xsl:template match="pattern">

    <xsl:element name="giv-panel">
      <xsl:attribute name="label"><xsl:value-of select="@regex"/></xsl:attribute>
      <xsl:attribute name="count"><xsl:value-of select="@count"/></xsl:attribute>

      <xsl:element name="map-panel">
        <xsl:attribute name="buoyancy">Floating</xsl:attribute>
        <xsl:attribute name="h-gap">0</xsl:attribute>
        <xsl:attribute name="v-gap">2</xsl:attribute>
        
        <xsl:element name="style-for-type">
          <xsl:attribute name="bar-color">Blue Gray</xsl:attribute>
          <xsl:attribute name="bar-height">16</xsl:attribute>
          <xsl:attribute name="lbl-position">Inside</xsl:attribute>
          <xsl:attribute name="font-size">10</xsl:attribute>
          <xsl:text>Match</xsl:text>
        </xsl:element>

        <xsl:apply-templates select="match"/>

      </xsl:element>
    </xsl:element>

  </xsl:template>

  <xsl:template match="match">
    <xsl:element name="element">
      <xsl:attribute name="label"><xsl:value-of select="@label"/></xsl:attribute>
      <xsl:attribute name="type">Match</xsl:attribute>
      <xsl:attribute name="from"><xsl:value-of select="@from"/></xsl:attribute>
      <xsl:attribute name="to"><xsl:value-of select="@to"/></xsl:attribute>
    </xsl:element>
  </xsl:template>


</xsl:stylesheet>



