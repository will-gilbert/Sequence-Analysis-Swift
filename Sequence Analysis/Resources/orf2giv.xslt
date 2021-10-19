<?xml version="1.0" encoding="utf-8"?>

<!-- https://www.freeformatter.com/xsl-transformer.html -->

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">


  <xsl:output method="xml" media-type="text/xml" indent="yes" encoding="utf-8" version="1.0"/>



  <!-- Documents template, all or one  -->

  <xsl:template match="ORF">
    <xsl:variable name='length' select='@length'/>

    <xsl:element name="giv-frame">
      <xsl:attribute name="name">
        <xsl:text>ORF Analysis</xsl:text>
      </xsl:attribute>

      <xsl:apply-templates select="frame">
        <xsl:with-param name="length" select="$length"/>
      </xsl:apply-templates>

    </xsl:element>

  </xsl:template>


  <!-- Each Document is processed here, this is where you can specify the order  -->
 
  <xsl:template match="frame">
    <xsl:param name="length"/>

    <xsl:element name="giv-panel">
      <xsl:attribute name="label"><xsl:value-of select="@label"/></xsl:attribute>
      <xsl:attribute name="toggle-btn">false</xsl:attribute>

      <xsl:element name="map-panel">
        <xsl:attribute name="extent"><xsl:value-of select="$length"/></xsl:attribute>
         <xsl:attribute name="bkg-color">Peach</xsl:attribute>
         <xsl:attribute name="buoyancy">Floating</xsl:attribute>
         <xsl:attribute name="h-gap">2</xsl:attribute>
         <xsl:attribute name="v-gap">2</xsl:attribute>

        <!-- Element style for this map panel -->

        <xsl:element name="style-for">
          <xsl:attribute name="bar-color">Navy</xsl:attribute>
          <xsl:attribute name="bar-height">10</xsl:attribute>
          <xsl:attribute name="lbl-position">Inside</xsl:attribute>
          <xsl:attribute name="font-size">10</xsl:attribute>
          <xsl:text>Start Codon</xsl:text>
        </xsl:element>

        <xsl:element name="style-for">
          <xsl:attribute name="bar-color">Magenta</xsl:attribute>
          <xsl:attribute name="bar-height">10</xsl:attribute>
          <xsl:attribute name="lbl-position">Inside</xsl:attribute>
          <xsl:attribute name="font-size">10</xsl:attribute>
          <xsl:text>Stop Codon</xsl:text>
        </xsl:element>


        <!-- Process start-codon elements -->
        <xsl:apply-templates select="start-codon"/>
        <xsl:apply-templates select="stop-codon"/>

      </xsl:element>

      <xsl:element name="map-panel">
        <xsl:attribute name="extent"><xsl:value-of select="$length"/></xsl:attribute>
         <xsl:attribute name="bkg-color">Peach</xsl:attribute>
         <xsl:attribute name="buoyancy">Floating</xsl:attribute>
         <xsl:attribute name="h-gap">2</xsl:attribute>
         <xsl:attribute name="v-gap">2</xsl:attribute>

        <!-- Element style for this map panel -->

        <xsl:element name="style-for">
          <xsl:attribute name="bar-color">Green</xsl:attribute>
          <xsl:attribute name="bar-height">8</xsl:attribute>
          <xsl:attribute name="lbl-position">Below</xsl:attribute>
          <xsl:attribute name="font-size">10</xsl:attribute>
          <xsl:text>Forward Frame ORF</xsl:text>
        </xsl:element>

        <xsl:element name="style-for">
          <xsl:attribute name="bar-color">Red</xsl:attribute>
          <xsl:attribute name="bar-height">8</xsl:attribute>
          <xsl:attribute name="lbl-position">Below</xsl:attribute>
          <xsl:attribute name="font-size">10</xsl:attribute>
          <xsl:text>Reverse Frame ORF</xsl:text>
        </xsl:element>

        <!-- Process Child elements -->
        <xsl:apply-templates select="orf"/>

      </xsl:element>

    </xsl:element>

  </xsl:template>

  <xsl:template match="peptide">
    <xsl:element name="element">
      <xsl:attribute name="name">Peptide <xsl:value-of select="@from"/>-<xsl:value-of select="@to"/></xsl:attribute>
      <xsl:attribute name="type">peptide</xsl:attribute>
      <xsl:attribute name="from"><xsl:value-of select="@from"/></xsl:attribute>
      <xsl:attribute name="to"><xsl:value-of select="@to"/></xsl:attribute>
    </xsl:element>
  </xsl:template>

  <xsl:template match="start-codon">
    <xsl:element name="element">
      <xsl:attribute name="label"><xsl:value-of select="@codon"/></xsl:attribute>
      <xsl:attribute name="type">Start Codon</xsl:attribute>
      <xsl:attribute name="from"><xsl:value-of select="@at"/></xsl:attribute>
      <xsl:attribute name="to"><xsl:value-of select="@at + 2"/></xsl:attribute>
    </xsl:element>
  </xsl:template>

  <xsl:template match="stop-codon">
    <xsl:element name="element">
      <xsl:attribute name="label"><xsl:value-of select="@codon"/></xsl:attribute>
      <xsl:attribute name="type">Stop Codon</xsl:attribute>
      <xsl:attribute name="from"><xsl:value-of select="@at"/></xsl:attribute>
      <xsl:attribute name="to"><xsl:value-of select="@at + 2"/></xsl:attribute>
    </xsl:element>
  </xsl:template>

  <xsl:template match="orf">
    <xsl:element name="element">
      <xsl:attribute name="name">ORF <xsl:value-of select="@from"/>-<xsl:value-of select="@to"/></xsl:attribute>
      <xsl:attribute name="type">Forward Frame ORF</xsl:attribute>
      <xsl:attribute name="from"><xsl:value-of select="@from"/></xsl:attribute>
      <xsl:attribute name="to"><xsl:value-of select="@to"/></xsl:attribute>
    </xsl:element>
  </xsl:template>


</xsl:stylesheet>


