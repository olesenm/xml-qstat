<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE stylesheet [
<!ENTITY  newline "<xsl:text>&#x0a;</xsl:text>">
<!ENTITY  space   "<xsl:text>&#x20;</xsl:text>">
]>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.w3.org/1999/xhtml"
>
<!--
Copyright (c) 2009-2012 Mark Olesen

License
    This file is part of xml-qstat.

    xml-qstat is free software: you can redistribute it and/or modify it under
    the terms of the GNU Affero General Public License as published by the
    Free Software Foundation, either version 3 of the License,
    or (at your option) any later version.

    xml-qstat is distributed in the hope that it will be useful, but
    WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
    or FITNESS FOR A PARTICULAR PURPOSE.
    See the GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with xml-qstat. If not, see <http://www.gnu.org/licenses/>.

Description
    Logo and uniform naviation buttons that can be customized as required
-->

<!-- ======================= Imports / Includes =========================== -->
<!-- Include our templates -->
<xsl:include href="xmlqstat-templates.xsl"/>

<!-- ======================= Internal Parameters ========================== -->

<!-- ========================= Named Templates ============================ -->

<!--
   | define a standard (corporate, institutional) logo to use
   | - extract @src, @href and @height or @width attributes
-->
<xsl:template name="topLogo">
  <xsl:param name="config-file" select="'../config/config.xml'"/>
  <xsl:param name="relPath" />

  <xsl:variable
      name="topLogo"
      select="document($config-file)/config/topLogo"
      />

  &newline;
  <xsl:comment> standard (corporate/institutional) logo </xsl:comment>
  &newline;

  <div class="topLogo" style="clear:both; text-align:left;">
  <p>
    <xsl:element name="a">
      <!-- a href -->
      <xsl:if test="$topLogo/@href">
        <xsl:attribute name="href">
          <xsl:value-of select="$topLogo/@href"/>
        </xsl:attribute>
      </xsl:if>

      <xsl:element name="img">
        <!-- img src -->
        <xsl:attribute name="src">
          <xsl:if test="$relPath"><xsl:value-of select="$relPath"/></xsl:if>
          <xsl:choose>
          <xsl:when test="$topLogo/@src">
            <xsl:value-of select="$topLogo/@src"/>
          </xsl:when>
          <xsl:otherwise>config/logo.png</xsl:otherwise>
          </xsl:choose>
        </xsl:attribute>

        <!-- img alt -->
        <xsl:attribute name="alt">Web-based status monitoring of GridEngine clusters</xsl:attribute>
        <xsl:attribute name="border">0</xsl:attribute>

        <!-- img height -->
        <xsl:if test="$topLogo/@height">
          <xsl:attribute name="height">
            <xsl:value-of select="$topLogo/@height" />
          </xsl:attribute>
        </xsl:if>
        <!-- img width -->
        <xsl:if test="$topLogo/@width">
          <xsl:attribute name="width">
            <xsl:value-of select="$topLogo/@width" />
          </xsl:attribute>
        </xsl:if>
      </xsl:element>
    </xsl:element>
  </p>
  </div>
  &newline;

</xsl:template>


<!-- define top menu bar for navigation
     this version is optimized for use with qlicserver cache files
-->
<xsl:template name="topMenu">
  <xsl:param name="config-file" select="document('../config/config.xml')" />
  <xsl:param name="clusterName" />
  <xsl:param name="jobinfo" />
  <xsl:param name="urlExt" />

  <xsl:variable name="configNode"  select="document($config-file)/config"/>
  <xsl:variable name="clusterNode" select="$configNode/clusters/cluster[@name=$clusterName]" />

  <!--
     | enable/disable qhost buttons depending on local settings
     | default (for a missing entry) is enabled
     -->
  <xsl:variable name="useQHOST">
    <xsl:call-template name="use-qhost">
      <xsl:with-param name="config-file"     select="$config-file" />
      <xsl:with-param name="clusterName"     select="$clusterName" />
      <xsl:with-param name="feature-default" select="'true'" />
    </xsl:call-template>
  </xsl:variable>

  <!--
     | enable/disable qlicserver button depending on local settings
     | default (for a missing entry) is disabled
     -->
  <xsl:variable name="useQLICSERVER">
    <xsl:call-template name="use-qlicserver">
      <xsl:with-param name="config-file"     select="$config-file" />
      <xsl:with-param name="clusterName"     select="$clusterName" />
      <xsl:with-param name="feature-default" select="'false'" />
    </xsl:call-template>
  </xsl:variable>

  <div id="menu">
    <xsl:element name="a">
      <xsl:attribute name="title">cluster listing</xsl:attribute>
      <xsl:attribute name="href">
        <xsl:text>../../</xsl:text>
        <xsl:if test="string-length($urlExt)">index.xml</xsl:if>
      </xsl:attribute>
      <xsl:attribute name="class">leftSpace</xsl:attribute>
      <img
        src="css/screen/icons/house.png"
        alt="[home]"
      />
    </xsl:element>

    <!-- jobs -->
    <img alt=" | " src="css/screen/icon_divider.png" />
    <xsl:element name="a">
      <xsl:attribute name="title">jobs</xsl:attribute>
      <xsl:attribute name="href">jobs<xsl:value-of
        select="$urlExt"/></xsl:attribute>
      <img
        src="css/screen/icons/lorry_flatbed.png"
        alt="[jobs]"
      />
    </xsl:element>

  <xsl:if test="$useQHOST = 'true'">
    <!-- queues?view=summary -->
    <img alt=" | " src="css/screen/icon_divider.png" />
    <xsl:element name="a">
      <xsl:attribute name="title">queue summary</xsl:attribute>
      <xsl:attribute name="href">queues<xsl:value-of
        select="$urlExt"/>?view=summary</xsl:attribute>
      <img
        src="css/screen/icons/sum.png"
        alt="[queues summary]"
      />
    </xsl:element>

    <!-- queues?view=free -->
    <img alt=" | " src="css/screen/icon_divider.png" />
    <xsl:element name="a">
      <xsl:attribute name="title">queue free</xsl:attribute>
      <xsl:attribute name="href">queues<xsl:value-of
        select="$urlExt"/>?view=free</xsl:attribute>
      <img
        src="css/screen/icons/tick.png"
        alt="[queues free]"
      />
    </xsl:element>

    <!-- queues?view=warn -->
    <img alt=" | " src="css/screen/icon_divider.png" />
    <xsl:element name="a">
      <xsl:attribute name="title">queue warn</xsl:attribute>
      <xsl:attribute name="href">queues<xsl:value-of
        select="$urlExt"/>?view=warn</xsl:attribute>
      <img
        src="css/screen/icons/error.png"
        alt="[warn queues]"
      />
    </xsl:element>

    <!-- queues -->
    <img alt=" | " src="css/screen/icon_divider.png" />
    <xsl:element name="a">
      <xsl:attribute name="title">queue instances</xsl:attribute>
      <xsl:attribute name="href">queues<xsl:value-of
        select="$urlExt"/></xsl:attribute>
      <img
        src="css/screen/icons/shape_align_left.png"
        alt="[queues]"
      />
    </xsl:element>
  </xsl:if>

  <xsl:if test="$useQLICSERVER = 'true'">
    <!-- resources -->
    <img alt=" | " src="css/screen/icon_divider.png" />
    <xsl:element name="a">
      <xsl:attribute name="title">resources</xsl:attribute>
      <xsl:attribute name="href">resources<xsl:value-of
        select="$urlExt"/></xsl:attribute>
      <img
        src="css/screen/icons/database_key.png"
        alt="[resources]"
      />
    </xsl:element>
  </xsl:if>

    <!-- jobinfo: toggle between more/less views -->
    <img alt=" | " src="css/screen/icon_divider.png" />
    <xsl:choose>
    <xsl:when test="$jobinfo = 'less'">
      <xsl:element name="a">
        <xsl:attribute name="title">jobs</xsl:attribute>
        <xsl:attribute name="href">jobs<xsl:value-of
          select="$urlExt"/></xsl:attribute>
        <img
          src="css/screen/icons/magnifier_zoom_out.png"
          alt="[jobs]"
        />
      </xsl:element>
    </xsl:when>
    <xsl:otherwise>
      <xsl:element name="a">
        <xsl:attribute name="title">job details</xsl:attribute>
        <xsl:attribute name="href">jobinfo<xsl:value-of
          select="$urlExt"/></xsl:attribute>
        <img
          src="css/screen/icons/magnifier_zoom_in.png"
          alt="[job details]"
        />
      </xsl:element>
    </xsl:otherwise>
    </xsl:choose>

    <img alt=" | " src="css/screen/icon_divider.png" />
    <a href="http://olesenm.github.com/xml-qstat/index.html"
        title="about"><img
        src="css/screen/icons/information.png"
        alt="[about]"
    /></a>

    <img alt=" | " src="css/screen/icon_divider.png" />
    <a href="" title="reload"><img
        src="css/screen/icons/arrow_refresh_small.png"
        alt="[reload]"
    /></a>
  </div>
</xsl:template>


<!-- define top menu bar for navigation
     this version is for the traditional xmlqstat navigation
     (using qstat -f output)
-->
<xsl:template name="qstatfMenu">
  <xsl:param name="config-file" select="document('../config/config.xml')" />
  <xsl:param name="clusterName" />
  <xsl:param name="clusterSuffix" />
  <xsl:param name="jobinfo" />
  <xsl:param name="urlExt" />

  <xsl:variable name="configNode"  select="document($config-file)/config"/>
  <xsl:variable name="clusterNode" select="$configNode/clusters/cluster[@name=$clusterName]" />

  <!--
     | enable/disable qlicserver button depending on local settings
     | default (for a missing entry) is disabled
     -->
  <xsl:variable name="useQLICSERVER">
    <xsl:call-template name="use-qlicserver">
      <xsl:with-param name="config-file"     select="$config-file" />
      <xsl:with-param name="clusterName"     select="$clusterName" />
      <xsl:with-param name="feature-default" select="'false'" />
    </xsl:call-template>
  </xsl:variable>

  <div id="menu">
    <xsl:element name="a">
      <xsl:attribute name="title">cluster listing</xsl:attribute>
      <xsl:attribute name="href">
        <xsl:text>./</xsl:text>
        <xsl:if test="string-length($urlExt)">index.xml</xsl:if>
      </xsl:attribute>
      <xsl:attribute name="class">leftSpace</xsl:attribute>
      <img
        src="css/screen/icons/house.png"
        alt="[home]"
      />
    </xsl:element>

    <img alt=" | " src="css/screen/icon_divider.png" />
    <xsl:element name="a">
      <xsl:attribute name="title">jobs</xsl:attribute>
      <xsl:attribute name="href">jobs<xsl:value-of select="$clusterSuffix"/>
        <xsl:value-of select="$urlExt"/>
      </xsl:attribute>
      <img
        src="css/screen/icons/lorry.png"
        alt="[jobs]"
      />
    </xsl:element>

    <!-- queues?view=summary -->
    <img alt=" | " src="css/screen/icon_divider.png" />
    <xsl:element name="a">
      <xsl:attribute name="title">queue summary</xsl:attribute>
      <xsl:attribute name="href">queues<xsl:value-of select="$clusterSuffix"/>
        <xsl:value-of select="$urlExt"/>?view=summary</xsl:attribute>
      <img
        src="css/screen/icons/sum.png"
        alt="[queues summary]"
      />
    </xsl:element>

    <!-- queues?view=free -->
    <img alt=" | " src="css/screen/icon_divider.png" />
    <xsl:element name="a">
      <xsl:attribute name="title">queue free</xsl:attribute>
      <xsl:attribute name="href">queues<xsl:value-of select="$clusterSuffix"/>
        <xsl:value-of select="$urlExt"/>?view=free</xsl:attribute>
      <img
        src="css/screen/icons/tick.png"
        alt="[queues free]"
      />
    </xsl:element>

    <!-- queues?view=warn -->
    <img alt=" | " src="css/screen/icon_divider.png" />
    <xsl:element name="a">
      <xsl:attribute name="title">queue warn</xsl:attribute>
      <xsl:attribute name="href">queues<xsl:value-of select="$clusterSuffix"/>
        <xsl:value-of select="$urlExt"/>?view=warn</xsl:attribute>
      <img
        src="css/screen/icons/error.png"
        alt="[warn queues]"
      />
    </xsl:element>

    <img alt=" | " src="css/screen/icon_divider.png" />
    <xsl:element name="a">
      <xsl:attribute name="title">queue instances</xsl:attribute>
      <xsl:attribute name="href">queues<xsl:value-of select="$clusterSuffix"/>
        <xsl:value-of select="$urlExt"/>
      </xsl:attribute>
      <img
        src="css/screen/icons/shape_align_left.png"
        alt="[queue instances]"
      />
    </xsl:element>

    <img alt=" | " src="css/screen/icon_divider.png" />
    <xsl:element name="a">
      <xsl:attribute name="title">cluster report</xsl:attribute>
      <xsl:attribute name="href">report<xsl:value-of select="$clusterSuffix"/>
        <xsl:value-of select="$urlExt"/>
      </xsl:attribute>
      <img
        src="css/screen/icons/report.png"
        alt="[cluster report]"
      />
    </xsl:element>

  <xsl:if test="$useQLICSERVER = 'true'">
    <!-- resources -->
    <img alt=" | " src="css/screen/icon_divider.png" />
    <xsl:element name="a">
      <xsl:attribute name="title">resources</xsl:attribute>
      <xsl:attribute name="href">resources<xsl:value-of select="$clusterSuffix"/>
        <xsl:value-of select="$urlExt"/>
      </xsl:attribute>
      <img
        src="css/screen/icons/database_key.png"
        alt="[resources]"
      />
    </xsl:element>
  </xsl:if>

    <!-- jobinfo: toggle between more/less views -->
    <img alt=" | " src="css/screen/icon_divider.png" />
    <xsl:choose>
    <xsl:when test="$jobinfo = 'less'">
      <xsl:element name="a">
        <xsl:attribute name="title">jobs</xsl:attribute>
        <xsl:attribute name="href">jobs<xsl:value-of select="$clusterSuffix"/>
          <xsl:value-of select="$urlExt"/>
        </xsl:attribute>
        <img
          src="css/screen/icons/magnifier_zoom_out.png"
          alt="[jobs]"
        />
      </xsl:element>
    </xsl:when>
    <xsl:otherwise>
      <xsl:element name="a">
        <xsl:attribute name="title">job details</xsl:attribute>
        <xsl:attribute name="href">jobinfo<xsl:value-of select="$clusterSuffix"/>
          <xsl:value-of select="$urlExt"/>
        </xsl:attribute>
        <img
          src="css/screen/icons/magnifier_zoom_in.png"
          alt="[jobs]"
        />
      </xsl:element>
    </xsl:otherwise>
    </xsl:choose>

    <img alt=" | " src="css/screen/icon_divider.png" />
    <a href="http://olesenm.github.com/xml-qstat/index.html"
        title="about"><img
        src="css/screen/icons/information.png"
        alt="[about]"
    /></a>

    <img alt=" | " src="css/screen/icon_divider.png" />
    <a href="" title="reload"><img
        src="css/screen/icons/arrow_refresh_small.png"
        alt="[reload]"
    /></a>
  </div>
</xsl:template>


<!-- bottom status bar with timestamp -->
<xsl:template name="bottomStatusBar">
  <xsl:param name="timestamp" />

  <xsl:if test="$timestamp">
    &newline;
    <xsl:comment> Bottom status bar </xsl:comment>
    &newline;

    <div class="dividerBarAbove">
      <!-- Rendered: with abbr showing the XSLT version and vendor name -->
      <xsl:element name="abbr">
        <xsl:attribute name="title">
          <xsl:text>XSLT </xsl:text>
          <xsl:value-of select="format-number(number(system-property('xsl:version')), '0.0')" />
          <xsl:text> (</xsl:text>
          <xsl:value-of select="system-property('xsl:vendor')"/>
          <xsl:text>)</xsl:text>
        </xsl:attribute>
        <xsl:text>Rendered</xsl:text>
      </xsl:element>
      <xsl:text>: </xsl:text>
      <xsl:value-of select="$timestamp"/>
    </div>
    &newline;
  </xsl:if>
</xsl:template>

</xsl:stylesheet>

<!-- =========================== End of File ============================== -->
