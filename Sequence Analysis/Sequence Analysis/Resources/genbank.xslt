<?xml version="1.0" encoding="utf-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">


  <xsl:output method="xml" media-type="text/xml" standalone="yes" indent="yes" encoding="utf-8" version="1.0"/>



  <!-- Documents template, all or one  -->

  <xsl:template match="GBSet">
  
    <xsl:element name="giv-frame">
      <xsl:attribute name="name">
        <xsl:text>Genbank Features, </xsl:text>
        <xsl:value-of select='./GBSeq/GBSeq_locus[1]'/> 
      </xsl:attribute>
      <xsl:attribute name="extent"><xsl:value-of select='./GBSeq/GBSeq_length'/></xsl:attribute> 
      <xsl:attribute name="bkg-color">Apricot</xsl:attribute>


      <xsl:element name="giv-panel">
        <xsl:attribute name="label">
          <xsl:value-of select='./GBSeq/GBSeq_primary-accession'/>
          <xsl:text>:</xsl:text>
          <xsl:value-of select='./GBSeq/GBSeq_locus'/>
          <xsl:text>  </xsl:text>
          <xsl:value-of select='./GBSeq/GBSeq_definition'/>
        </xsl:attribute>
        
        <xsl:element name="map-panel">
          <xsl:attribute name="buoyancy">Floating</xsl:attribute>
          <xsl:attribute name="h-gap">0</xsl:attribute>
          <xsl:attribute name="v-gap">3</xsl:attribute>
          <xsl:element name="style-for-type">
            <xsl:attribute name="bar-color">Navy</xsl:attribute>
            <xsl:attribute name="bar-height">4</xsl:attribute>
            <xsl:attribute name="lbl-position">Above</xsl:attribute>
            <xsl:text>GenBank Entry</xsl:text>
          </xsl:element>
          <xsl:element name="element">
            <xsl:attribute name="label">
              <xsl:value-of select='./GBSeq/GBSeq_locus'/>
            </xsl:attribute>
            <xsl:attribute name="type">GenBank Entry</xsl:attribute>
            <xsl:attribute name="from">1</xsl:attribute>
            <xsl:attribute name="to"><xsl:value-of select='./GBSeq/GBSeq_length'/></xsl:attribute>
          </xsl:element>
        </xsl:element>
  
 
        <xsl:element name="map-panel">
          <xsl:attribute name="label">Genebank Features</xsl:attribute>
          <xsl:attribute name="buoyancy">Floating</xsl:attribute>
          <xsl:attribute name="h-gap">0</xsl:attribute>
          <xsl:attribute name="v-gap">3</xsl:attribute>
 
 
          <xsl:element name="style-for-type">
            <xsl:attribute name="bar-color">Magenta</xsl:attribute>
            <xsl:attribute name="bar-height">18</xsl:attribute>
            <xsl:text>gene</xsl:text>
          </xsl:element>

          <xsl:element name="style-for-type">
            <xsl:attribute name="bar-color">Orange</xsl:attribute>
            <xsl:attribute name="bar-height">18</xsl:attribute>
            <xsl:text>CDS</xsl:text>
          </xsl:element>

          <xsl:element name="style-for-type">
            <xsl:attribute name="bar-color">Tomato</xsl:attribute>
            <xsl:attribute name="bar-height">18</xsl:attribute>
            <xsl:text>intron</xsl:text>
          </xsl:element>

          <xsl:element name="style-for-type">
            <xsl:attribute name="bar-color">Green</xsl:attribute>
            <xsl:attribute name="bar-height">18</xsl:attribute>
            <xsl:text>exon</xsl:text>
          </xsl:element>

          <xsl:element name="style-for-type">
            <xsl:attribute name="bar-color">Chocolate</xsl:attribute>
            <xsl:attribute name="bar-height">18</xsl:attribute>
            <xsl:text>sig_peptide</xsl:text>
          </xsl:element>

          <xsl:element name="style-for-type">
            <xsl:attribute name="bar-color">Gold</xsl:attribute>
            <xsl:attribute name="bar-height">18</xsl:attribute>
            <xsl:text>mat_peptide</xsl:text>
          </xsl:element>

          <xsl:element name="style-for-type">
            <xsl:attribute name="bar-color">Blue</xsl:attribute>
            <xsl:attribute name="bar-height">18</xsl:attribute>
            <xsl:text>polyA_signal</xsl:text>
          </xsl:element>

          <xsl:element name="style-for-type">
            <xsl:attribute name="bar-color">Blue</xsl:attribute>
            <xsl:attribute name="bar-height">18</xsl:attribute>
            <xsl:text>polyA_site</xsl:text>
          </xsl:element>

          <xsl:element name="style-for-type">
            <xsl:attribute name="bar-color">Blue</xsl:attribute>
            <xsl:attribute name="bar-height">18</xsl:attribute>
            <xsl:text>variation</xsl:text>
          </xsl:element>

          <xsl:element name="group">
            <xsl:attribute name="label">intron/exons</xsl:attribute>
            <xsl:attribute name="h-gap">0</xsl:attribute>
            <xsl:attribute name="v-gap">5</xsl:attribute>
            <xsl:apply-templates select="./GBSeq/GBSeq_feature-table/GBFeature[./GBFeature_key/text()='intron']/GBFeature_intervals/GBInterval"/>
            <xsl:apply-templates select="./GBSeq/GBSeq_feature-table/GBFeature[./GBFeature_key/text()='exon']/GBFeature_intervals/GBInterval"/>
          </xsl:element>


          <xsl:apply-templates select="./GBSeq/GBSeq_feature-table/GBFeature[./GBFeature_key/text()='gene']/GBFeature_intervals/GBInterval"/>
          <xsl:apply-templates select="./GBSeq/GBSeq_feature-table/GBFeature[./GBFeature_key/text()='CDS']/GBFeature_intervals/GBInterval"/>
          <xsl:apply-templates select="./GBSeq/GBSeq_feature-table/GBFeature[./GBFeature_key/text()='sig_peptide']/GBFeature_intervals/GBInterval"/>
          <xsl:apply-templates select="./GBSeq/GBSeq_feature-table/GBFeature[./GBFeature_key/text()='mat_peptide']/GBFeature_intervals/GBInterval"/>


          <xsl:element name="group">
            <xsl:attribute name="label">poly-A</xsl:attribute>
            <xsl:attribute name="h-gap">0</xsl:attribute>
            <xsl:attribute name="v-gap">5</xsl:attribute>
            <xsl:apply-templates select="./GBSeq/GBSeq_feature-table/GBFeature[./GBFeature_key/text()='polyA_signal']/GBFeature_intervals/GBInterval"/>
            <xsl:apply-templates select="./GBSeq/GBSeq_feature-table/GBFeature[./GBFeature_key/text()='polyA_site']/GBFeature_intervals/GBInterval"/>
          </xsl:element>

          <xsl:element name="group">
            <xsl:attribute name="label">Variation</xsl:attribute>
            <xsl:attribute name="bkg-color">Apricot</xsl:attribute>
            <xsl:attribute name="h-gap">0</xsl:attribute>
            <xsl:attribute name="v-gap">5</xsl:attribute>
            <xsl:apply-templates select="./GBSeq/GBSeq_feature-table/GBFeature[./GBFeature_key/text()='variation']/GBFeature_intervals/GBInterval"/>
          </xsl:element>


        </xsl:element>
        
      </xsl:element>
    </xsl:element>

  </xsl:template>


  <!-- ====================================================================================  -->
 
 
  <xsl:template match="GBInterval">
    <xsl:element name="element">
      <xsl:attribute name="label">
        <xsl:value-of select="../../GBFeature_key"/>
      </xsl:attribute>
      <xsl:attribute name="type">
        <xsl:value-of select="../../GBFeature_key"/>
      </xsl:attribute>
      <xsl:apply-templates select="./GBInterval_from"/>
      <xsl:apply-templates select="./GBInterval_to"/>
      <xsl:apply-templates select="./GBInterval_point"/>
    </xsl:element>
  </xsl:template>

  <xsl:template match="GBInterval_from">
      <xsl:attribute name="from"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <xsl:template match="GBInterval_to">
      <xsl:attribute name="to"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>

  <xsl:template match="GBInterval_point">
      <xsl:attribute name="from"><xsl:value-of select="."/></xsl:attribute>
      <xsl:attribute name="to"><xsl:value-of select="."/></xsl:attribute>
  </xsl:template>


  
</xsl:stylesheet>


