<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE stylesheet [
<!ENTITY  newline "<xsl:text>&#x0a;</xsl:text>">
<!ENTITY  space   "<xsl:text>&#x20;</xsl:text>">
]>
<xsl:stylesheet version="1.0"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
>
<!--
Copyright (c) 2009-2011 Mark Olesen

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
    process XML generated by the qlicserver
    to produce an overview of resource usage
    The menuMode only affects the top menu

    expected input:
     - qlicserver.xml
-->

<!-- ======================= Imports / Includes =========================== -->
<!-- Include our masthead and templates -->
<xsl:include href="xmlqstat-masthead.xsl"/>
<xsl:include href="xmlqstat-templates.xsl"/>
<!-- Include processor-instruction parsing -->
<xsl:include href="pi-param.xsl"/>


<!-- ======================== Passed Parameters =========================== -->
<xsl:param name="serverName">
  <xsl:call-template name="pi-param">
    <xsl:with-param  name="name"    select="'serverName'"/>
  </xsl:call-template>
</xsl:param>
<xsl:param name="timestamp">
  <xsl:call-template name="pi-param">
    <xsl:with-param  name="name"    select="'timestamp'"/>
  </xsl:call-template>
</xsl:param>
<xsl:param name="menuMode">
  <xsl:call-template name="pi-param">
    <xsl:with-param  name="name"    select="'menuMode'"/>
  </xsl:call-template>
</xsl:param>
<xsl:param name="urlExt">
  <xsl:call-template name="pi-param">
    <xsl:with-param  name="name"    select="'urlExt'"/>
  </xsl:call-template>
</xsl:param>

<!-- ======================= Internal Parameters ========================== -->
<!-- configuration parameters -->

<!-- site-specific or generic config -->
<xsl:variable name="config-file">
  <xsl:call-template name="config-file">
    <xsl:with-param  name="dir"   select="'../config/'" />
    <xsl:with-param  name="site"  select="$serverName" />
  </xsl:call-template>
</xsl:variable>

<!-- get clusterNode from the query results -->
<xsl:variable name="clusterNode" select="//query/cluster"/>
<xsl:variable name="clusterName" select="$clusterNode/@name"/>

<!-- possibly append ~{clusterName} to urls -->
<xsl:variable name="clusterSuffix">
  <xsl:if test="$clusterName">~<xsl:value-of select="$clusterName"/></xsl:if>
</xsl:variable>


<!-- ======================= Output Declaration =========================== -->
<xsl:output method="xml" indent="yes" version="1.0" encoding="UTF-8"
    doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN"
    doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"
/>


<!-- ============================ Matching ================================ -->
<xsl:template match="/" >
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<meta http-equiv="Refresh" content="30" />
<link rel="icon" type="image/png" href="css/screen/icons/database_key.png"/>
&newline;
<title> resources
<xsl:if test="$clusterName"> @<xsl:value-of select="$clusterName"/></xsl:if>
</title>
<!-- load css -->
<link href="css/xmlqstat.css" media="screen" rel="Stylesheet" type="text/css" />
</head>
&newline;

<!-- nothing to pre-calculate -->

<!-- begin body -->
<body>
&newline;
<xsl:comment> Main body content </xsl:comment>
&newline;

<div id="main">
<!-- Topomost Logo Div -->
<xsl:call-template name="topLogo">
  <xsl:with-param name="config-file" select="$config-file" />
</xsl:call-template>
<!-- Top Menu Bar -->
<xsl:choose>
<xsl:when test="$menuMode = 'qstatf'">
  <xsl:call-template name="qstatfMenu">
    <xsl:with-param name="clusterSuffix" select="$clusterSuffix"/>
    <xsl:with-param name="urlExt" select="$urlExt"/>
  </xsl:call-template>
</xsl:when>
<xsl:otherwise>
  <xsl:call-template name="topMenu">
    <xsl:with-param name="clusterName"   select="$clusterName"/>
    <xsl:with-param name="urlExt" select="$urlExt"/>
  </xsl:call-template>
</xsl:otherwise>
</xsl:choose>

&newline;
<xsl:comment> Top dotted line bar (holds the qmaster host and update time) </xsl:comment>
&newline;
<div class="dividerBarBelow">
<xsl:choose>
<xsl:when test="//query/cluster and //query/host">
  <!-- query host, cluster/cell name -->
  <xsl:value-of select="//query/cluster/@name"/>
  <xsl:if test="
      string-length(//query/cluster/@cell)
      and //query/cluster/@cell != 'default'
      ">
    <xsl:text>/</xsl:text>
    <xsl:value-of select="//query/cluster/@cell"/>
  </xsl:if>
  <xsl:text>@</xsl:text>
  <xsl:value-of select="//query/host"/>

  &space;
  <!-- replace 'T' in dateTime for easier reading -->
  [<xsl:value-of select="translate(//query/time, 'T', '_')"/>]
</xsl:when>
<xsl:otherwise>
  <!-- unnamed cluster: -->
  default
</xsl:otherwise>
</xsl:choose>
</div>

&newline;
<xsl:comment> Resources </xsl:comment>
&newline;

<!-- resources: -->
<blockquote>
<table class="listing">
  <tr valign="middle">
    <td>
      <div class="tableCaption">Resources</div>
    </td>
  </tr>
</table>
<xsl:apply-templates select="//qlicserver/resources" />
</blockquote>

<!-- bottom status bar with rendered time -->
<xsl:call-template name="bottomStatusBar">
  <xsl:with-param name="timestamp" select="$timestamp" />
</xsl:call-template>

&newline;
</div>
</body></html>
<!-- end body/html -->
</xsl:template>


<!--
  resources: header
-->
<xsl:template match="qlicserver/resources">
<div id="resourcesTable">
  <table class="listing">
  <tr>
    <th/>
    <th>used</th>
    <th>total</th>
    <th>limit</th>
    <th>extern</th>
    <th>intern</th>
    <th>wait</th>
    <th>free</th>
  </tr>
  <xsl:apply-templates select="resource"/>
  </table>
</div>
</xsl:template>


<!--
  resources: content
-->
<xsl:template match="resources/resource">
  <tr align="right">
  <!-- annotate with 'served', 'from' and 'note' attributes -->
  <xsl:variable name="annotation">
    <xsl:if test="@served">served = <xsl:value-of select="@served"/>
      <xsl:if test="@from"> [<xsl:value-of select="@from"/>]</xsl:if>
      <xsl:if test="@note">&space;</xsl:if>
    </xsl:if>
    <xsl:if test="@note">(<xsl:value-of select="@note"/>)</xsl:if>
  </xsl:variable>

  <td align="left">
    <xsl:choose>
    <xsl:when test="@served or @note">
      <xsl:element name="abbr">
        <xsl:attribute name="title"><xsl:value-of select="$annotation"/></xsl:attribute>
        <xsl:value-of select="@name" />
      </xsl:element>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="@name" />
    </xsl:otherwise>
    </xsl:choose>
  </td>

  <xsl:variable name="valueUsed">
    <xsl:choose>
    <xsl:when test="@extern and @intern">
      <xsl:value-of select="@extern + @intern"/>
    </xsl:when>
    <xsl:when test="@extern">
      <xsl:value-of select="@extern"/>
    </xsl:when>
    <xsl:when test="@intern">
      <xsl:value-of select="@intern"/>
    </xsl:when>
    <xsl:otherwise>
      0
    </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>
  <xsl:variable name="valueTotal" select="@total"/>

  <!-- used -->
  <td width="100px" align="left">
    <xsl:choose>
    <xsl:when test="$valueUsed &gt; 0 and ($valueUsed &gt;= $valueTotal)">
      <xsl:call-template name="progressBar">
        <xsl:with-param name="class"   select="'warnBar'"/>
        <xsl:with-param name="label"   select="concat($valueUsed, '/', $valueTotal)" />
        <xsl:with-param name="percent" select="100"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="$valueUsed &gt; 0">
      <xsl:call-template name="progressBar">
        <xsl:with-param name="label"   select="concat($valueUsed, '/', $valueTotal)" />
        <xsl:with-param name="percent" select="($valueUsed div $valueTotal)*100"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
    </xsl:otherwise>
    </xsl:choose>
  </td>

  <!-- total: display as alarm if none found -->
  <xsl:choose>
  <xsl:when test="@total &gt; 0">
    <td><xsl:value-of select="@total"/></td>
  </xsl:when>
  <xsl:otherwise>
    <!-- alarm color -->
    <td class="alarmState">0</td>
  </xsl:otherwise>
  </xsl:choose>

  <!-- limit -->
  <td>
    <xsl:value-of select="@limit" />
  </td>

  <!-- extern: display users -->
  <xsl:choose>
  <xsl:when test="@extern">
    <td>
      <xsl:element name="abbr">
        <xsl:attribute name="title">
          <xsl:for-each select="user[@type = 'extern']">
            <xsl:value-of select="@name"/>@<xsl:value-of select="@host"/>=<xsl:value-of select="."/>
            &space;
          </xsl:for-each>
        </xsl:attribute>
        <xsl:value-of select="@extern" />
      </xsl:element>
    </td>
  </xsl:when>
  <xsl:when test="@type = 'intern'">
    <!-- empty color -->
    <td bgcolor="#dee7ec"/>
  </xsl:when>
  <xsl:otherwise>
    <td/>
  </xsl:otherwise>
  </xsl:choose>
  <!-- intern: display users -->
  <xsl:choose>
  <xsl:when test="@intern">
    <td>
      <xsl:element name="abbr">
        <xsl:attribute name="title">
          <xsl:for-each select="user[@type = 'intern']">
            <xsl:value-of select="@name"/>@<xsl:value-of select="@host"/>=<xsl:value-of select="."/>
            &space;
          </xsl:for-each>
        </xsl:attribute>
        <xsl:value-of select="@intern" />
      </xsl:element>
    </td>
  </xsl:when>
  <xsl:when test="@type = 'track'">
    <!-- empty color -->
    <td bgcolor="#dee7ec"/>
  </xsl:when>
  <xsl:otherwise>
    <td/>
  </xsl:otherwise>
  </xsl:choose>
  <!-- waiting: display users -->
  <td>
    <xsl:element name="abbr">
      <xsl:attribute name="title">
        <xsl:for-each select="user[@type = 'waiting']">
          <xsl:value-of select="@name"/>=<xsl:value-of select="."/>
          &space;
        </xsl:for-each>
      </xsl:attribute>
      <xsl:value-of select="@waiting" />
    </xsl:element>
  </td>
  <xsl:choose>
  <!-- free: display warn/alarm when exhausted -->
  <xsl:when test="@free">
    <td>
    <xsl:value-of select="@free"/>
    </td>
  </xsl:when>
  <xsl:when test="@type = 'track'">
    <!-- pale warn color -->
    <td class="warnState">0</td>
  </xsl:when>
  <xsl:when test="@waiting">
    <!-- alarm color -->
    <td class="alarmState">0</td>
  </xsl:when>
  <xsl:otherwise>
    <!-- warn color -->
    <td class="warnState">0</td>
  </xsl:otherwise>
  </xsl:choose>

  </tr>
&newline;
</xsl:template>


</xsl:stylesheet>

<!-- =========================== End of File ============================== -->
