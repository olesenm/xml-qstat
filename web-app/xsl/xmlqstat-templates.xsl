<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns="http://www.w3.org/1999/xhtml"
>
<!--
Copyright (c) 2006-2007 Chris Dagdigian (chris@bioteam.net)
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
    A collection of Named Templates with various useful functions
-->

<!-- ========================= Named Templates ============================ -->

<!--
   |
   | return the config name (site-specific or generic config) to be used
   | 1. config/config-{SITE}.xml
   | 2. config/config.xml
   |
   | The {SITE} will always be reduced to a short name (w/o domain)
   | for consistent behaviour regardless of the original URL
   -->
<xsl:template name="config-file">
  <xsl:param name="dir" select="'../config/'" />
  <xsl:param name="site" />

  <!-- config-{SITE}.xml with unqualified hostname -->
  <xsl:variable name="config-site-xml">
    <xsl:text>config-</xsl:text>
    <xsl:choose>
    <xsl:when test="contains($site, '.')">
      <xsl:value-of select="substring-before($site,'.')"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="$site"/>
    </xsl:otherwise>
    </xsl:choose>
    <xsl:text>.xml</xsl:text>
  </xsl:variable>

  <xsl:choose>
  <xsl:when test="count(document(concat($dir, $config-site-xml))/config) &gt; 0">
    <xsl:value-of select="concat($dir, $config-site-xml)"/>
  </xsl:when>
  <xsl:otherwise>
    <xsl:value-of select="concat($dir, 'config.xml')"/>
  </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!--
   |
   | extract @root @cell for clusterNode from the config-file
   |
   | format into "root=@root;cell=@cell;" for cgi queries
   -->
<xsl:template name="cgi-params">
  <xsl:param name="clusterName" />
  <xsl:param name="config-file" select="'../config/config.xml'" />

  <!-- choose site-specific or generic config -->
  <xsl:variable name="configNode" select="document($config-file)/config"/>

  <!-- treat a bad clusterName as 'default' -->
  <xsl:variable name="name">
    <xsl:choose>
    <xsl:when test="string-length($clusterName)">
      <xsl:value-of select="$clusterName" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:text>default</xsl:text>
    </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="defaultNode" select="$configNode/clusters/default" />
  <xsl:variable name="clusterNode" select="$configNode/clusters/cluster[@name=$name]" />


  <!-- the cell, a missing value is treated as 'default' -->
  <xsl:variable name="cell">
    <xsl:variable name="value">
      <xsl:choose>
      <xsl:when test="$name = 'default'">
        <xsl:value-of select="$defaultNode/@cell" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$clusterNode/@cell" />
      </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:choose>
    <xsl:when test="string-length($value)">
      <xsl:value-of select="$value" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:text>default</xsl:text>
    </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>


  <!-- the root, a missing value is treated as 'false' for some safety -->
  <xsl:variable name="root">
    <xsl:variable name="value">
      <xsl:choose>
      <xsl:when test="$name = 'default'">
        <xsl:value-of select="$defaultNode/@root" />
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$clusterNode/@root" />
      </xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:choose>
    <xsl:when test="string-length($value)">
      <xsl:value-of select="$value" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:text>false</xsl:text>
    </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:value-of select="concat('root=', $root, ';')"/>
  <xsl:value-of select="concat('cell=', $cell, ';')"/>
</xsl:template>


<!--
   |
   | count the number of tokens in a delimited list
   |
   -->
<xsl:template name="count-tokens">
  <xsl:param name="string" />
  <xsl:param name="delim" />

  <xsl:choose>
  <xsl:when test="contains($string, $delim)">
    <xsl:variable name="summation">
      <xsl:call-template name="count-tokens">
        <xsl:with-param name="string" select="substring-after($string, $delim)" />
        <xsl:with-param name="delim"  select="$delim" />
      </xsl:call-template>
    </xsl:variable>
    <xsl:value-of select="1 + $summation"/>
  </xsl:when>
  <xsl:otherwise>1</xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!--
   |
   | count the number of jobs
   | use string-length as a cheap hack to summarize the values
   |
   -->
<xsl:template name="count-jobs">
  <xsl:param name="nodeList" />

  <xsl:variable name="count">
    <xsl:for-each select="$nodeList">
      <xsl:variable name="jobId" select="JB_job_number"/>
      <xsl:variable name="thisNode" select="generate-id(.)"/>
      <xsl:variable name="allNodes" select="key('job-summary', $jobId)"/>
      <xsl:variable name="firstNode" select="generate-id($allNodes[1])"/>
      <xsl:choose>
      <xsl:when test="$thisNode = $firstNode">1</xsl:when>
      </xsl:choose>
    </xsl:for-each>
  </xsl:variable>
  <xsl:value-of select="string-length($count)"/>
</xsl:template>

<!--
   |
   | count the number of slots multiplied by the task information
   |
   -->
<xsl:template name="count-slots">
  <xsl:param name="nodeList" />

  <xsl:choose>
  <xsl:when test="count($nodeList)">
    <xsl:variable name="first" select="$nodeList[1]"/>
    <xsl:variable name="summation">
      <xsl:call-template name="count-slots">
        <xsl:with-param name="nodeList" select="$nodeList[position()!=1]"/>
      </xsl:call-template>
    </xsl:variable>
    <xsl:variable name="slots" select="$first/slots"/>
    <xsl:variable name="tasks" select="$first/tasks"/>
    <xsl:variable name="nTasks">
      <xsl:choose>
      <xsl:when test="contains($tasks, ':')">
        <!-- handle n-m:s -->
        <xsl:variable name="min"  select="number(substring-before($tasks,'-'))"/>
        <xsl:variable name="max"  select="number(substring-before(substring-after($tasks,'-'), ':'))"/>
        <xsl:variable name="step" select="number(substring-after($tasks,':'))" />
        <xsl:choose>
        <xsl:when test="$step &gt; 1">
          <!-- eg 2-6:2 = 3 -->
          <xsl:value-of select="1 + ($max - $min) div $step"/>
        </xsl:when>
        <xsl:otherwise>
          <!-- safety: step-size 1 (or missing?), eg 2-7:1 = 6 -->
          <xsl:value-of select="1 + ($max - $min)"/>
        </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:when test="contains($tasks, ',')">
        <!-- comma-separated list: count the tokens -->
        <xsl:call-template name="count-tokens">
          <xsl:with-param name="string" select="$tasks" />
          <xsl:with-param name="delim" select="','" />
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>1</xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:value-of select="$slots * $nTasks + $summation"/>
  </xsl:when>
  <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- show/hide a particular 'div' element -->
<xsl:template name="toggleElementVisibility">
  <xsl:param name="name" />

  <div class="toggleVisibility">
    <xsl:attribute name="id"><xsl:value-of select="$name"/>Toggle</xsl:attribute>
    <xsl:element name="a">
      <xsl:attribute name="href">#</xsl:attribute>
      <xsl:attribute name="onclick">javascript:setDiv('<xsl:value-of select="$name"/>',false)</xsl:attribute>
      <img border="0" src="css/screen/icons/bullet_toggle_minus.png" alt="[hide]" title="hide" />
    </xsl:element>
    <xsl:element name="a">
      <xsl:attribute name="href">#</xsl:attribute>
      <xsl:attribute name="onclick">javascript:setDiv('<xsl:value-of select="$name"/>',true)</xsl:attribute>
      <img border="0" src="css/screen/icons/bullet_toggle_plus.png" alt="[show]" title="show" />
    </xsl:element>
  </div>

</xsl:template>


<!--
   | progressBar with size 'percent'
   | title (mouse help) and label
   -->
<xsl:template name="progressBarAbs">
  <xsl:param name="value" select="0" />
  <xsl:param name="total" select="0" />
  <xsl:param name="title" />
  <xsl:param name="label" select="concat($value, '/', $total)" />
  <xsl:param name="class" />

  <xsl:variable name="percent">
    <xsl:choose>
    <xsl:when test="not($total) or $total &lt;= 0">0</xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="($value div $total)*100"/>
    </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <div class="progbarOuter" style="width:100px;">
    <xsl:element name="div">
      <xsl:if test="$percent &gt; 0">
        <xsl:attribute name="class">progbarInner <xsl:if test="$class"><xsl:value-of select="$class"/></xsl:if></xsl:attribute>
        <xsl:attribute name="style">width:<xsl:value-of select="format-number($percent,'##0.#')"/>%;</xsl:attribute>
      </xsl:if>
      <xsl:choose>
      <xsl:when test="$title">
        <xsl:element name="abbr">
          <xsl:attribute name="title"><xsl:value-of select="$title"/></xsl:attribute>
          <xsl:value-of select="$label" />
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$label" />
      </xsl:otherwise>
      </xsl:choose>
    </xsl:element>
  </div>
</xsl:template>


<!--
   | progressBar with size 'percent'
   | title (mouse help) and label
   -->
<xsl:template name="progressBar">
  <xsl:param name="title" />
  <xsl:param name="label" />
  <xsl:param name="percent" />
  <xsl:param name="class" />

  <div class="progbarOuter" style="width:100px;">
    <xsl:element name="div">
      <xsl:if test="$percent &gt; 0">
        <xsl:attribute name="class">progbarInner <xsl:if test="$class"><xsl:value-of select="$class"/></xsl:if></xsl:attribute>
        <xsl:attribute name="style">width:<xsl:value-of select="format-number($percent,'##0.#')"/>%;</xsl:attribute>
      </xsl:if>
      <xsl:choose>
      <xsl:when test="$title">
        <xsl:element name="abbr">
          <xsl:attribute name="title"><xsl:value-of select="$title"/></xsl:attribute>
          <xsl:value-of select="$label" />
        </xsl:element>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$label" />
      </xsl:otherwise>
      </xsl:choose>
    </xsl:element>
  </div>
</xsl:template>


<!-- extract value before the memory suffix (G, M, K) -->
<xsl:template name="memoryValue">
  <xsl:param name="value" />
  <xsl:param name="suffix" />

  <xsl:choose>
  <xsl:when test="$suffix">
    <xsl:value-of select="substring($value, 0, string-length($value))"/>
  </xsl:when>
  <xsl:otherwise>
    <xsl:value-of select="$value"/>
  </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- extract the memory suffix (G, M, K) -->
<xsl:template name="memorySuffix">
  <xsl:param name="value" />

  <xsl:choose>
  <xsl:when test="contains($value, 'G')">
    <xsl:value-of select="'G'"/>
  </xsl:when>
  <xsl:when test="contains($value, 'M')">
    <xsl:value-of select="'M'"/>
  </xsl:when>
  <xsl:when test="contains($value, 'K')">
    <xsl:value-of select="'K'"/>
  </xsl:when>
  <xsl:otherwise>0</xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!--
   | simple means of handling memory with a 'G', 'M' and 'K' suffix
   | and displaying a progressBar (slider)
   -->
<xsl:template name="memoryUsed">
  <xsl:param name="free" />
  <xsl:param name="used" />
  <xsl:param name="total" />

  <xsl:variable name="memoryFree">
    <xsl:choose>
    <xsl:when test="string-length($free) and not(contains($free, '-')) ">
       <xsl:value-of select="$free" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:text>0</xsl:text>
    </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="memoryUsed">
    <xsl:choose>
    <xsl:when test="string-length($used) and not(contains($used, '-')) ">
       <xsl:value-of select="$used" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:text>0</xsl:text>
    </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <xsl:variable name="memoryTotal">
    <xsl:choose>
    <xsl:when test="string-length($total) and not(contains($total, '-')) ">
       <xsl:value-of select="$total" />
    </xsl:when>
    <xsl:otherwise>
      <xsl:text>0</xsl:text>
    </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

  <!-- prefix (value) and suffix (G, M, K) -->
  <xsl:variable name="suffixUsed">
    <xsl:call-template name="memorySuffix">
      <xsl:with-param name="value"  select="$memoryUsed" />
    </xsl:call-template>
  </xsl:variable>
  <xsl:variable name="valueUsed">
    <xsl:call-template name="memoryValue">
      <xsl:with-param name="value"  select="$memoryUsed" />
      <xsl:with-param name="suffix" select="$suffixUsed" />
    </xsl:call-template>
  </xsl:variable>

  <!-- prefix (value) and suffix (G, M, K) -->
  <xsl:variable name="suffixTotal">
    <xsl:call-template name="memorySuffix">
      <xsl:with-param name="value"  select="$memoryTotal" />
    </xsl:call-template>
  </xsl:variable>
  <xsl:variable name="valueTotal">
    <xsl:call-template name="memoryValue">
      <xsl:with-param name="value"  select="$memoryTotal" />
      <xsl:with-param name="suffix" select="$suffixTotal" />
    </xsl:call-template>
  </xsl:variable>

  <!-- output progress bar -->
  <xsl:choose>
  <xsl:when test="$memoryTotal = 0">
    <xsl:choose>
    <xsl:when test="$memoryFree != 0">
      <xsl:value-of select="$memoryFree"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:call-template name="progressBar">
        <xsl:with-param name="title" select="'not available'" />
        <xsl:with-param name="label" select="'NA'" />
        <xsl:with-param name="percent" select="0"/>
      </xsl:call-template>
    </xsl:otherwise>
    </xsl:choose>
  </xsl:when>
  <xsl:when test="$suffixUsed = $suffixTotal">
    <xsl:call-template name="progressBar">
      <xsl:with-param name="title" select="concat($memoryUsed, ' used')" />
      <xsl:with-param name="label" select="$memoryTotal" />
      <xsl:with-param name="percent"
        select="($valueUsed div $valueTotal)*100"
      />
    </xsl:call-template>
  </xsl:when>
  <xsl:when test="
      ($suffixUsed = 'M' and $suffixTotal = 'G') or
      ($suffixUsed = 'K' and $suffixTotal = 'M')">
    <!-- factor 1000 between used and total -->
    <xsl:call-template name="progressBar">
      <xsl:with-param name="title" select="concat($memoryUsed,' used')" />
      <xsl:with-param name="label" select="$memoryTotal" />
      <xsl:with-param name="percent"
        select="($valueUsed div ($valueTotal * 1024)) * 100"
      />
    </xsl:call-template>
  </xsl:when>
  <xsl:otherwise>
    <xsl:call-template name="progressBar">
      <xsl:with-param name="title" select="concat($memoryUsed,' used')" />
      <xsl:with-param name="label" select="$memoryTotal" />
      <xsl:with-param name="percent" select="0" />
    </xsl:call-template>
  </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!--
    change the style (background color, font) based on the queue status
-->
<xsl:template name="queue-state-style">
  <xsl:param name="state" />

  <xsl:choose>
  <xsl:when test="contains($state, 'u')">
    <xsl:attribute name="class">alarmState</xsl:attribute>
  </xsl:when>
  <xsl:when test="contains($state, 'E')">
    <xsl:attribute name="class">errorState</xsl:attribute>
  </xsl:when>
  <xsl:when test="contains($state, 'a')">
    <xsl:attribute name="class">warnState</xsl:attribute>
  </xsl:when>
  <xsl:when test="contains($state, 'd')">
    <xsl:attribute name="class">disableState</xsl:attribute>
  </xsl:when>
  <xsl:when test="contains($state, 'S')">
    <xsl:attribute name="class">suspendState</xsl:attribute>
  </xsl:when>
  </xsl:choose>
</xsl:template>


<!--
   | choose an appropriate icon based on the status of queues
   -->
<xsl:template name="queue-state-icon">
  <xsl:param name="state" />

  <xsl:element name="img">
    <xsl:attribute name="title"><xsl:value-of select="$state"/></xsl:attribute>
    <xsl:attribute name="alt">(<xsl:value-of select="$state"/>) </xsl:attribute>
    <xsl:attribute name="src">
    <xsl:choose>
      <xsl:when test="contains($state, 'd')">css/screen/icons/delete.png</xsl:when>
      <xsl:when test="contains($state, 'E')">css/screen/icons/exclamation.png</xsl:when>
      <xsl:when test="contains($state, 'u')">css/screen/icons/cross.png</xsl:when>
      <xsl:when test="contains($state, 'a')">css/screen/icons/error.png</xsl:when>
      <xsl:when test="contains($state, 'S')">css/screen/icons/control_pause.png</xsl:when>
      <xsl:otherwise>css/screen/icons/tick.png</xsl:otherwise>
      </xsl:choose>
    </xsl:attribute>
  </xsl:element>
</xsl:template>


<!--
   | display the queue status with brief explanation
   -->
<xsl:template name="queue-state-explain">
  <xsl:param name="state" />

  <xsl:choose>
  <xsl:when test="contains($state, 'u')" >
    <!-- 'u' unavailable state : alarm color -->
    <abbr title="This queue instance is in ALARM/UNREACHABLE state. Is SGE running on this node?">
      <xsl:value-of select="$state"/>
    </abbr>
  </xsl:when>
  <xsl:when test="contains($state, 'E')" >
    <!-- 'E' error : alarm color -->
    <abbr title="This queue instance is in ERROR state. Check node!">
      <xsl:value-of select="$state"/>
    </abbr>
  </xsl:when>
  <xsl:when test="contains($state, 'a')" >
    <!-- 'a' alarm state : warn color -->
    <abbr title="This queue instance is in ALARM state.">
      <xsl:value-of select="$state"/>
    </abbr>
  </xsl:when>
  <xsl:when test="contains($state, 'd')" >
    <!-- 'd' disabled state : empty color -->
    <abbr title="This queue has been disabled by a grid administrator">
      <xsl:value-of select="$state"/>
    </abbr>
  </xsl:when>
  <xsl:when test="contains($state, 'S')" >
    <!-- 'S' suspended -->
    <abbr title="Queue is (S)uspended">
      <xsl:value-of select="$state"/>
    </abbr>
  </xsl:when>
  <xsl:otherwise>
    <!-- default -->
    <xsl:value-of select="$state"/>
  </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!--
   | transform 'host.domain.name' to 'hostname'
   -->
<xsl:template name="unqualifiedHost">
  <xsl:param name="host" />

  <xsl:choose>
  <xsl:when test="contains($host, '.')">
    <xsl:value-of select="substring-before($host,'.')"/>
  </xsl:when>
  <xsl:otherwise>
    <xsl:value-of select="$host"/>
  </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!--
   | transform 'queue@host.domain.name' to 'queue@hostname'
   -->
<xsl:template name="unqualifiedQueue">
  <xsl:param name="queue" />

  <xsl:choose>
  <xsl:when test="contains($queue, '@@')">
    <!-- leave queue@@hostgroup untouched -->
    <xsl:value-of select="$queue"/>
  </xsl:when>
  <xsl:when test="contains($queue, '@')">
    <!-- change queue@host.domain.name to queue@host -->
    <xsl:value-of select="substring-before($queue, '@')"/>
    <xsl:text>@</xsl:text>
    <xsl:call-template name="unqualifiedHost">
      <xsl:with-param name="host" select="substring-after($queue, '@')" />
    </xsl:call-template>
  </xsl:when>
  <xsl:otherwise>
    <xsl:value-of select="$queue"/>
  </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!--
   | display a shorter name with the longer name via mouseover
   -->
<xsl:template name="shortName">
  <xsl:param name="name" />
  <xsl:param name="length" select="32" />

  <xsl:choose>
  <xsl:when test="string-length($name) &gt; $length">
    <xsl:element name="abbr">
      <xsl:attribute name="title">
        <xsl:value-of select="$name" />
      </xsl:attribute>
      <xsl:value-of select="substring($name,0,$length)" /> ...
    </xsl:element>
  </xsl:when>
  <xsl:otherwise>
    <xsl:value-of select="$name" />
  </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!-- The following use-* templates could probably also be refactored -->

<!--
   | enable/disable qstat.xml depending on local settings
   | default (for a missing entry) is disabled
   -->
<xsl:template name="use-qlicserver">
  <xsl:param name="config-file" />
  <xsl:param name="clusterName"     select="'default'" />
  <xsl:param name="feature-name"    select="'qlicserver'" />
  <xsl:param name="feature-default" select="'false'" />

  <xsl:variable
      name="configNode"
      select="document($config-file)/config"/>
  <xsl:variable
      name="clusterNode"
      select="$configNode/clusters/cluster[@name=$clusterName]" />

  <xsl:choose>
  <xsl:when test="not(string-length($config-file))">
    <!-- no config-file specified -->
    <xsl:value-of select="$feature-default" />
  </xsl:when>
  <xsl:when test="$clusterNode/qlicserver">
    <!-- local setting exists -->
    <xsl:choose>
    <xsl:when test="
        not(string-length($clusterNode/qlicserver/@enabled))
        or $clusterNode/qlicserver/@enabled = 'true'">
      <xsl:text>true</xsl:text>
    </xsl:when>
    <xsl:otherwise>
      <xsl:text>false</xsl:text>
    </xsl:otherwise>
    </xsl:choose>
  </xsl:when>
  <xsl:when test="$configNode/qlicserver">
    <!-- global setting exists -->
    <xsl:choose>
    <xsl:when test="
        not(string-length($configNode/qlicserver/@enabled))
        or $configNode/qlicserver/@enabled = 'true'">
      <xsl:text>true</xsl:text>
    </xsl:when>
    <xsl:otherwise>
      <xsl:text>false</xsl:text>
    </xsl:otherwise>
    </xsl:choose>
  </xsl:when>
  <xsl:otherwise>
    <xsl:value-of select="$feature-default" />
  </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!--
   | enable/disable qhost.xml depending on local settings
   | default (for a missing entry) is enabled
   -->
<xsl:template name="use-qhost">
  <xsl:param name="config-file" />
  <xsl:param name="clusterName" />
  <xsl:param name="feature-name"    select="'qhost'" />
  <xsl:param name="feature-default" select="'true'" />

  <xsl:variable
      name="configNode"
      select="document($config-file)/config"/>
  <xsl:variable
      name="clusterNode"
      select="$configNode/clusters/cluster[@name=$clusterName]" />

  <xsl:choose>
  <xsl:when test="not(string-length($config-file))">
    <xsl:text>true</xsl:text>
    <!-- no config-file specified -->
    <!-- <xsl:value-of select="$feature-default" /> -->
  </xsl:when>
  <xsl:when test="$clusterNode/qhost">
    <!-- local setting exists -->
    <xsl:choose>
    <xsl:when test="
        not(string-length($clusterNode/qhost/@enabled))
        or $clusterNode/qhost/@enabled = 'true'">
      <xsl:text>true</xsl:text>
    </xsl:when>
    <xsl:otherwise>
      <xsl:text>false</xsl:text>
    </xsl:otherwise>
    </xsl:choose>
  </xsl:when>
  <xsl:when test="$configNode/qhost">
    <!-- global setting exists -->
    <xsl:choose>
    <xsl:when test="
        not(string-length($configNode/qhost/@enabled))
        or $configNode/qhost/@enabled = 'true'">
      <xsl:text>true</xsl:text>
    </xsl:when>
    <xsl:otherwise>
      <xsl:text>false</xsl:text>
    </xsl:otherwise>
    </xsl:choose>
  </xsl:when>
  <xsl:otherwise>
    <xsl:value-of select="$feature-default" />
  </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!--
   | enable/disable qstat.xml depending on local settings
   | default (for a missing entry) is enabled
   -->
<xsl:template name="use-qstat">
  <xsl:param name="config-file" />
  <xsl:param name="clusterName"     select="'default'" />
  <xsl:param name="feature-name"    select="'qstat'" />
  <xsl:param name="feature-default" select="'true'" />

  <xsl:variable
      name="configNode"
      select="document($config-file)/config"/>
  <xsl:variable
      name="clusterNode"
      select="$configNode/clusters/cluster[@name=$clusterName]" />

  <xsl:choose>
  <xsl:when test="not(string-length($config-file))">
    <!-- no config-file specified -->
    <xsl:value-of select="$feature-default" />
  </xsl:when>
  <xsl:when test="$clusterNode/qstat">
    <!-- local setting exists -->
    <xsl:choose>
    <xsl:when test="
        not(string-length($clusterNode/qstat/@enabled))
        or $clusterNode/qstat/@enabled = 'true'">
      <xsl:text>true</xsl:text>
    </xsl:when>
    <xsl:otherwise>
      <xsl:text>false</xsl:text>
    </xsl:otherwise>
    </xsl:choose>
  </xsl:when>
  <xsl:when test="$configNode/qstat">
    <!-- global setting exists -->
    <xsl:choose>
    <xsl:when test="
        not(string-length($configNode/qstat/@enabled))
        or $configNode/qstat/@enabled = 'true'">
      <xsl:text>true</xsl:text>
    </xsl:when>
    <xsl:otherwise>
      <xsl:text>false</xsl:text>
    </xsl:otherwise>
    </xsl:choose>
  </xsl:when>
  <xsl:otherwise>
    <xsl:value-of select="$feature-default" />
  </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<!--
   | enable/disable qstatf.xml depending on local settings
   | default (for a missing entry) is enabled
   -->
<xsl:template name="use-qstatf">
  <xsl:param name="config-file" />
  <xsl:param name="clusterName"     select="'default'" />
  <xsl:param name="feature-name"    select="'qstatf'" />
  <xsl:param name="feature-default" select="'true'" />

  <xsl:variable
      name="configNode"
      select="document($config-file)/config"/>
  <xsl:variable
      name="clusterNode"
      select="$configNode/clusters/cluster[@name=$clusterName]" />

  <xsl:choose>
  <xsl:when test="not(string-length($config-file))">
    <!-- no config-file specified -->
    <xsl:value-of select="$feature-default" />
  </xsl:when>
  <xsl:when test="$clusterNode/qstatf">
    <!-- local setting exists -->
    <xsl:choose>
    <xsl:when test="
        not(string-length($clusterNode/qstatf/@enabled))
        or $clusterNode/qstatf/@enabled = 'true'">
      <xsl:text>true</xsl:text>
    </xsl:when>
    <xsl:otherwise>
      <xsl:text>false</xsl:text>
    </xsl:otherwise>
    </xsl:choose>
  </xsl:when>
  <xsl:when test="$configNode/qstatf">
    <!-- global setting exists -->
    <xsl:choose>
    <xsl:when test="
        not(string-length($configNode/qstatf/@enabled))
        or $configNode/qstatf/@enabled = 'true'">
      <xsl:text>true</xsl:text>
    </xsl:when>
    <xsl:otherwise>
      <xsl:text>false</xsl:text>
    </xsl:otherwise>
    </xsl:choose>
  </xsl:when>
  <xsl:otherwise>
    <xsl:value-of select="$feature-default" />
  </xsl:otherwise>
  </xsl:choose>
</xsl:template>


</xsl:stylesheet>

<!-- =========================== End of File ============================== -->
