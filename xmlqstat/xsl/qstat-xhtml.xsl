<xsl:stylesheet version="1.0"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:dt="http://xsltsl.org/date-time"
    xmlns:str="http://xsltsl.org/string"
    exclude-result-prefixes="dt str"
>
<!--
   | process XML generated by
   |     "qstat -u * -xml -r -s prs"
   | to produce a list of active and pending jobs
-->

<!-- output declarations -->
<xsl:output method="xml" indent="yes" version="1.0" encoding="UTF-8"
    doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN"
    doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"
/>

<!-- Import the XSLTL library method -->
<xsl:include href="xsltl/stdlib.xsl"/>

<!-- Import our uniform masthead -->
<xsl:include href="xmlqstat-masthead.xsl"/>

<!-- Import our templates -->
<xsl:include href="xmlqstat-templates.xsl"/>

<!-- XSL Parameters -->
<xsl:param name="timestamp"/>
<xsl:param name="activeJobTable"/>
<xsl:param name="pendingJobTable"/>
<xsl:param name="filterByUser"/>

<!-- get specific configuration parameters -->
<xsl:param
    name="useJavaScript"
    select="document('../config/config.xml')/config/useJavaScript"
    />
<xsl:param
    name="viewlogProgram"
    select="//config/programs/viewlog"
    />

<xsl:param name="cgiParams">
  <xsl:if
    test="//config/cluster">&amp;SGE_ROOT=<xsl:value-of
    select="//config/cluster/@root"/><xsl:if
    test="//config/cluster/@cell != 'default'"
    >&amp;SGE_CELL=<xsl:value-of
    select="//config/cluster/@cell"/></xsl:if>
  </xsl:if>
</xsl:param>

<xsl:template match="/" >
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<meta http-equiv="Refresh" content="30" />
<link rel="icon" type="image/png" href="images/icons/silk/lorry_flatbed.png"/>
<title> jobs
  <xsl:if test="//config/cluster/@name">
  - <xsl:value-of select="//config/cluster/@name"/>
  </xsl:if>
</title>

<xsl:text>
</xsl:text>
<xsl:comment> useJavaScript = '<xsl:value-of select="$useJavaScript"/>' </xsl:comment>
<xsl:text>
</xsl:text>
<!-- NB: <script> .. </script> needs some (any) content -->
<xsl:if test="$useJavaScript = 'yes'" >
<script src="javascript/cookie.js" type="text/javascript">
  // Dortch cookies
</script>
<script src="javascript/xmlqstat.js" type="text/javascript">
  // display altering code
</script>
<xsl:text>
</xsl:text>
</xsl:if>

<xsl:comment> Load CSS from a file </xsl:comment>
<xsl:text>
</xsl:text>
<link href="css/xmlqstat.css" media="screen" rel="Stylesheet" type="text/css" />

<xsl:text>
</xsl:text>
<xsl:comment> Override CSS </xsl:comment>
<xsl:text>
</xsl:text>
<style type="text/css">
<!-- DIFFERENT CSS STYLE DEPENDING ON USER COOKIE PREFERENCE PARAM(s) -->
<!-- hide activeJobTable (depending on cookie value) -->
<xsl:if test="$useJavaScript = 'yes' and $activeJobTable = 'no'" >
  #activeJobTable { visibility: hidden; display: none; }
</xsl:if>
<!-- hide pendingJobTable (depending on cookie value) -->
<xsl:if test="$useJavaScript = 'yes' and $pendingJobTable = 'no'" >
  #pendingJobTable { visibility: hidden; display: none; }
</xsl:if>
<!-- END COOKIE DEPENDENT VARIABLE CSS STYLE OUTPUT -->
<xsl:text>
</xsl:text>
</style>
<xsl:text>
</xsl:text>
<xsl:comment> End Override CSS </xsl:comment>
<xsl:text>
</xsl:text>
</head>
<xsl:text>
</xsl:text>

<!-- CALCULATE TOTALS -->

<!-- done CALCULATE -->

<body>
<xsl:text>
</xsl:text>
<xsl:comment> Main body content </xsl:comment>
<xsl:text>
</xsl:text>

<div id="main">
<!-- Topomost Logo Div -->
<xsl:call-template name="topLogo"/>
<!-- Top Menu Bar -->
<xsl:call-template name="topMenu"/>

<xsl:text>
</xsl:text>
<xsl:comment> Top dotted line bar (holds the qmaster host and update time) </xsl:comment>
<div class="dividerBarBelow">
<xsl:choose>
<xsl:when test="//config/cluster">
  <!-- query host, cluster/cell name -->
  <xsl:value-of select="//config/cluster/@name"/>
  <xsl:if test="//config/cluster/@cell != 'default'">/<xsl:value-of
      select="//config/cluster/@cell"/>
  </xsl:if>
  <xsl:if test="//query/host">@<xsl:value-of select="//query/host"/>
  <xsl:text> </xsl:text>
  <!-- replace 'T' in dateTime for easier reading -->
  [<xsl:value-of select="translate(//query/time, 'T', '_')"/>]
  </xsl:if>
</xsl:when>
<xsl:otherwise>
  <!-- unnamed cluster: -->
  unnamed cluster
</xsl:otherwise>
</xsl:choose>
</div>
<xsl:text>
</xsl:text>

<xsl:comment> Active Jobs </xsl:comment>
<xsl:text>
</xsl:text>
<xsl:if test="count(//job_info)">

<!--
   | count active jobs/slots for user or everyone
   | here we can count the slots directly, since each job/task is listed separately
   -->
<xsl:variable name="AJ_total">
  <xsl:choose>
  <xsl:when test="$filterByUser">
    <xsl:value-of select="count(//job_info/queue_info/job_list[JB_owner=$filterByUser])"/>
  </xsl:when>
  <xsl:otherwise>
    <xsl:value-of select="count(//job_info/queue_info/job_list)"/>
  </xsl:otherwise>
  </xsl:choose>
</xsl:variable>
<xsl:variable name="AJ_slots">
  <xsl:choose>
  <xsl:when test="$filterByUser">
    <xsl:call-template name="count-slots">
      <xsl:with-param name="nodeList" select="//job_info/queue_info/job_list[JB_owner=$filterByUser]"/>
    </xsl:call-template>
  </xsl:when>
  <xsl:otherwise>
    <xsl:call-template name="count-slots">
      <xsl:with-param name="nodeList" select="//job_info/queue_info/job_list"/>
    </xsl:call-template>
  </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<blockquote>
<xsl:choose>
<xsl:when test="$AJ_total &gt; 0">
  <!-- active jobs: -->
  <table class="listing">
    <tr valign="middle">
    <td>
      <div class="tableCaption">
        <xsl:value-of select="$AJ_total"/> active jobs
        <xsl:if test="$filterByUser">
          for <em><xsl:value-of select="$filterByUser"/></em>
        </xsl:if>
        (<xsl:value-of select="$AJ_slots"/> slots)
      </div>
      <!-- show/hide activeJobTable via javascript -->
      <xsl:if test="$useJavaScript = 'yes'" >
        <xsl:call-template name="toggleElementVisibility">
          <xsl:with-param name="name"  select="'activeJobTable'"/>
        </xsl:call-template>
      </xsl:if>
    </td>
    </tr>
  </table>
  <xsl:apply-templates select="//job_info/queue_info" />
</xsl:when>
<xsl:otherwise>
  <!-- no active jobs -->
  <div class="skipTableFormat">
    <img alt="*" src="images/icons/silk/bullet_blue.png" />
    no active jobs
    <xsl:if test="$filterByUser">
      for <em><xsl:value-of select="$filterByUser"/></em>
    </xsl:if>
  </div>
</xsl:otherwise>
</xsl:choose>
</blockquote>

<xsl:text>
</xsl:text>
<xsl:comment> Pending Jobs </xsl:comment>
<xsl:text>
</xsl:text>

<!--
   | count pending jobs/slots for user or everyone
   | we must count the slots ourselves, since pending job tasks are grouped together
   -->
<xsl:variable name="PJ_total">
  <xsl:choose>
  <xsl:when test="$filterByUser">
    <xsl:value-of select="count(//job_info/job_info/job_list[JB_owner=$filterByUser])"/>
  </xsl:when>
  <xsl:otherwise>
    <xsl:value-of select="count(//job_info/job_info/job_list)"/>
  </xsl:otherwise>
  </xsl:choose>
</xsl:variable>
<xsl:variable name="PJ_slots">
  <xsl:choose>
  <xsl:when test="$filterByUser">
    <xsl:call-template name="count-slots">
      <xsl:with-param name="nodeList" select="//job_info/job_info/job_list[JB_owner=$filterByUser]"/>
    </xsl:call-template>
  </xsl:when>
  <xsl:otherwise>
    <xsl:call-template name="count-slots">
      <xsl:with-param name="nodeList" select="//job_info/job_info/job_list"/>
    </xsl:call-template>
  </xsl:otherwise>
  </xsl:choose>
</xsl:variable>

<blockquote>
<xsl:choose>
<xsl:when test="$PJ_total &gt; 0">
  <!-- pending jobs: -->
  <table class="listing">
    <tr valign="middle">
    <td>
      <div class="tableCaption">
        <xsl:value-of select="$PJ_total"/> pending jobs
        <xsl:if test="$filterByUser" >
          for <em><xsl:value-of select="$filterByUser"/></em>
        </xsl:if>
        (<xsl:value-of select="$PJ_slots"/> slots)
      </div>
      <!-- show/hide pendingJobTable via javascript -->
      <xsl:if test="$useJavaScript = 'yes'" >
        <xsl:call-template name="toggleElementVisibility">
          <xsl:with-param name="name" select="'pendingJobTable'"/>
        </xsl:call-template>
      </xsl:if>
    </td>
    </tr>
  </table>
  <xsl:apply-templates select="//job_info/job_info" />
</xsl:when>
<xsl:otherwise>
  <!-- no pending jobs -->
  <div class="skipTableFormat">
    <img alt="*" src="images/icons/silk/bullet_blue.png" />
    no pending jobs
    <xsl:if test="$filterByUser" >
      for user <em><xsl:value-of select="$filterByUser"/></em>
    </xsl:if>
  </div>
</xsl:otherwise>
</xsl:choose>
</blockquote>
</xsl:if>

<!-- bottom status bar with rendered time -->
<xsl:call-template name="bottomStatusBar">
  <xsl:with-param name="timestamp" select="$timestamp" />
</xsl:call-template>

<xsl:text>
</xsl:text>
</div>
</body></html>
</xsl:template>


<!--
  active jobs: header
 -->
<xsl:template match="job_info/queue_info">
  <div id="activeJobTable">
    <table class="listing">
    <tr>
      <th>jobId</th>
      <th>owner</th>
      <th>name</th>
      <th>slots</th>
      <th>tasks</th>
      <th>queue</th>
      <th>startTime</th>
      <th>state</th>
    </tr>
    <xsl:for-each select="job_list[@state='running']">
      <!-- sorted by job number and task -->
      <xsl:sort select="JB_job_number"/>
      <xsl:sort select="tasks"/>
      <xsl:apply-templates select="."/>
    </xsl:for-each>
    </table>
  </div>
</xsl:template>

<!--
  active jobs: contents
 -->
<xsl:template match="job_list[@state='running']">
<!-- per user sort -->
<xsl:if test="not($filterByUser) or JB_owner=$filterByUser">

  <tr>
  <!-- jobId with resource requests -->
  <!-- link jobId to details: "jobinfo?{jobId}" -->
  <td>
    <xsl:element name="a">
      <xsl:attribute name="title">
        <xsl:for-each select="hard_request">
          <xsl:value-of select="@name"/>=<xsl:value-of select="."/>
          <xsl:text> </xsl:text>
        </xsl:for-each>
      </xsl:attribute>
      <xsl:attribute name="href">jobinfo?<xsl:value-of select="JB_job_number"/></xsl:attribute>
      <xsl:value-of select="JB_job_number" />
    </xsl:element>
  </td>
  <!-- owner -->
  <td>
    <!-- link owner names to "jobs?user={owner}" -->
    <xsl:element name="a">
      <xsl:attribute name="title">view jobs owned by <xsl:value-of select="JB_owner"/></xsl:attribute>
      <xsl:attribute name="href">jobs?user=<xsl:value-of select="JB_owner"/></xsl:attribute>
      <xsl:value-of select="JB_owner" />
    </xsl:element>
  </td>
  <!-- name and full name -->
  <td>
    <xsl:call-template name="shortName">
      <xsl:with-param name="name" select="full_job_name"/>
    </xsl:call-template>
  </td>
  <!-- slots -->
  <td>
    <xsl:value-of select="slots" />
  </td>
  <!-- task -->
  <td>
    <xsl:value-of select="tasks" />
  </td>
  <!-- queue -->
  <td>
    <xsl:call-template name="unqualifiedQueue">
      <xsl:with-param name="queue" select="queue_name"/>
    </xsl:call-template>
  </td>
  <!-- startTime -->
  <td>
     <xsl:value-of select="JAT_start_time"/>
  </td>
  <!-- state : with link to residuals -->
  <td>
    <xsl:value-of select="state" />
    <xsl:if test="$viewlogProgram">
      <xsl:apply-templates select="." mode="viewlog"/>
    </xsl:if>
  </td>
  </tr>
<xsl:text>
</xsl:text>
</xsl:if>
</xsl:template>


<!--
  pending jobs: header
 -->
<xsl:template match="//job_info/job_info">
  <div id="pendingJobTable">
    <table class="listing">
    <tr>
      <th>jobId</th>
      <th>owner</th>
      <th>name</th>
      <th>slots</th>
      <th>tasks</th>
      <th>queue</th>
      <th>priority</th>
      <th>state</th>
    </tr>
    <xsl:for-each select="job_list[@state='pending']">
      <!-- sorted by priority and job number -->
      <xsl:sort select="JAT_prio" order="descending"/>
      <xsl:sort select="JB_job_number"/>
      <xsl:apply-templates select="."/>
    </xsl:for-each>
    </table>
  </div>
</xsl:template>

<!--
  pending jobs: content
 -->
<xsl:template match="job_list[@state='pending']">
<!-- per user sort -->
<xsl:if test="not($filterByUser) or JB_owner=$filterByUser">

  <tr>
  <!-- jobId with resource requests -->
  <!-- link jobId to details: "jobinfo?{jobId}" -->
  <td>
    <xsl:element name="a">
      <xsl:attribute name="title">
        <xsl:for-each select="hard_request">
          <xsl:value-of select="@name"/>=<xsl:value-of select="."/>
          <xsl:text> </xsl:text>
        </xsl:for-each>
      </xsl:attribute>
      <xsl:attribute name="href">jobinfo?<xsl:value-of select="JB_job_number"/></xsl:attribute>
      <xsl:value-of select="JB_job_number" />
    </xsl:element>
  </td>
  <!-- owner -->
  <td>
    <!-- link owner names to "jobs?user={owner}" -->
    <xsl:element name="a">
      <xsl:attribute name="title">view jobs owned by <xsl:value-of select="JB_owner"/></xsl:attribute>
      <xsl:attribute name="href">jobs?user=<xsl:value-of select="JB_owner"/></xsl:attribute>
      <xsl:value-of select="JB_owner" />
    </xsl:element>
  </td>
  <!-- name and full name -->
  <td>
    <xsl:call-template name="shortName">
      <xsl:with-param name="name" select="full_job_name"/>
    </xsl:call-template>
  </td>
  <!-- slots -->
  <td>
    <xsl:value-of select="slots" />
  </td>
  <!-- task -->
  <td>
    <xsl:value-of select="tasks" />
  </td>
  <!-- queue -->
  <td>
    <xsl:for-each select="hard_req_queue">
      <xsl:call-template name="unqualifiedQueue">
        <xsl:with-param name="queue" select="."/>
      </xsl:call-template>
      <xsl:text> </xsl:text>
    </xsl:for-each>
  </td>
  <!-- priority with submissionTime-->
  <td>
    <xsl:element name="acronym">
      <xsl:attribute name="title">
        <xsl:value-of select="JB_submission_time"/>
      </xsl:attribute>
    <xsl:value-of select="JAT_prio" />
    </xsl:element>
  </td>
  <!-- state -->
  <td>
    <xsl:value-of select="state" />
  </td>
  </tr>
<xsl:text>
</xsl:text>
</xsl:if>
</xsl:template>


<!--
  create links for viewlog with plots
-->
<xsl:template match="job_list" mode="viewlog">
<xsl:text>
</xsl:text>

<xsl:if test="count(hard_request)">
  <xsl:variable name="resources">
    <xsl:for-each
        select="hard_request"><xsl:value-of
        select="@name"/>,</xsl:for-each>
  </xsl:variable>
  <xsl:variable name="request">jobid=<xsl:value-of
        select="JB_job_number"/><xsl:if
        test="tasks">.<xsl:value-of
        select="tasks"/></xsl:if><xsl:text>&amp;</xsl:text>resources=<xsl:value-of
        select="$resources"/>
  </xsl:variable>

  <!-- url viewlog?jobid=...&resources={resources} -->
  <xsl:element name="a">
    <xsl:attribute name="title">viewlog</xsl:attribute>
    <xsl:attribute name="href"><xsl:value-of
        select="$viewlogProgram"/>?<xsl:value-of
        select="$request"/><xsl:value-of select="$cgiParams"/></xsl:attribute>
    <img src="images/icons/silk/page_find.png" alt="[v]" border="0" />
  </xsl:element>

  <!-- url viewlog?action=plot&jobid=...&resources={resources} -->
  <xsl:element name="a">
    <xsl:attribute name="title">plotlog</xsl:attribute>
    <xsl:attribute name="href"><xsl:value-of
        select="$viewlogProgram"/>?action=plot<xsl:text>&amp;</xsl:text><xsl:value-of
        select="$request"/><xsl:value-of select="$cgiParams"/></xsl:attribute>
    <img src="images/icons/silk/chart_curve.png" alt="[p]" border="0" />
  </xsl:element>

  <!-- url viewlog?action=plot&owner=...&resources={resources} -->
  <xsl:element name="a">
    <xsl:attribute name="title">plotlogs</xsl:attribute>
    <xsl:attribute name="href"><xsl:value-of
        select="$viewlogProgram"/>?action=plot<xsl:text>&amp;</xsl:text>owner=<xsl:value-of
        select="JB_owner"/><xsl:text>&amp;</xsl:text>resources=<xsl:value-of
        select="$resources"/><xsl:value-of select="$cgiParams"/></xsl:attribute>
    <img src="images/icons/silk/chart_curve_add.png" alt="[P]" border="0" />
  </xsl:element>
</xsl:if>
</xsl:template>


</xsl:stylesheet>
