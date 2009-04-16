<xsl:stylesheet version="1.0"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
>
<!--
   | process XML generated by
   |     "qstat -u * -xml -r -f -explain aAcE"
   | to produce
   |   1) a summary (default, renderMode = qstat)
   |   2) queue alerts (renderMode = qalert)
   |   3) job alerts (renderMode = jalert)
   |   3) active jobs (renderMode = ajobs)
   |   3) pending jobs (renderMode = pjobs)
   | for the Sony PSP
-->

<xsl:param name="timestamp"/>
<xsl:param name="renderMode">qstat</xsl:param>

<!-- define sorting keys -->
<xsl:key
    name="jstate"
    match="job_list"
    use="normalize-space(state)"
/>
<xsl:key
    name="job-summary"
    match="//Queue-List/job_list"
    use="JB_job_number"
/>

<xsl:template match="/">

<!--
  CALCULATE TOTAL PERCENTAGE OF JOB SLOTS IN USE CLUSTER-WIDE
-->
<!-- NB: slots_total reported actually includes slots_used -->
<xsl:variable
    name="slotsUsed"
    select="sum(//Queue-List/slots_used)"
    />
<xsl:variable
    name="slotsTotal"
    select=" sum(//Queue-List/slots_total) - sum(//Queue-List/slots_used)"
    />
<xsl:variable
    name="slotsPercent"
    select="($slotsUsed div $slotsTotal)*100"
    />
<!-- END CALCULATE SECTION -->

<!-- TOTAL NUMBER OF QUEUE INSTANCES -->
<xsl:variable name="queueInstances"  select="count(//Queue-List/name)"/>

<!-- COUNT UNUSUAL QUEUE LEVEL STATE INDICATORS -->
<xsl:variable name="QI_state_a"   select="count(//job_info/queue_info/Queue-List[state[.='a']  ])"/>
<xsl:variable name="QI_state_d"   select="count(//job_info/queue_info/Queue-List[state[.='d']  ])"/>
<xsl:variable name="QI_state_adu"   select="count(//job_info/queue_info/Queue-List[state[.='adu']  ])"/>
<xsl:variable name="QI_state_o"   select="count(//job_info/queue_info/Queue-List[state[.='o']  ])"/>
<xsl:variable name="QI_state_c"   select="count(//job_info/queue_info/Queue-List[state[.='c']  ])"/>
<xsl:variable name="QI_state_C"   select="count(//job_info/queue_info/Queue-List[state[.='C']  ])"/>
<xsl:variable name="QI_state_D"   select="count(//job_info/queue_info/Queue-List[state[.='D']  ])"/>
<xsl:variable name="QI_state_s"   select="count(//job_info/queue_info/Queue-List[state[.='s']  ])"/>
<xsl:variable name="QI_state_S"   select="count(//job_info/queue_info/Queue-List[state[.='S']  ])"/>
<xsl:variable name="QI_state_E"   select="count(//job_info/queue_info/Queue-List[state[.='E']  ])"/>
<xsl:variable name="QI_state_au"  select="count(//job_info/queue_info/Queue-List[state[.='au'] ])"/>

<!-- SUM THE OCCURANCES OF UNUSUAL QUEUE STATE INDICATORS
     (so we can decide to throw a warning in the main overview
      view...)
-->
<xsl:variable name="QI_unusual_statecount"
 select="$QI_state_a + $QI_state_d + $QI_state_adu"
 />

<!-- COUNT UNUSUAL JOB LEVEL STATE INDICATORS -->


<!--
   | Build a node set of all queues that are not usable for new or pending jobs
   | The intent here is that then we can sum(slots_total) to get the number of
   | job slots that are not usable.
   | This is then used to build the adjusted slot availability percentage
   -->
<xsl:variable name="nodeSet-unusableQueues"
    select="//job_info/queue_info/Queue-List[state[.='au']]
    | //job_info/queue_info/Queue-List[state[.='d']]
    | //job_info/queue_info/Queue-List[state[.='adu']]
    | //job_info/queue_info/Queue-List[state[.='E']]"
    />
<xsl:variable name="unusableSlotCount"
    select="sum($nodeSet-unusableQueues/slots_total)" />
<xsl:variable name="nodeSet-unavailableQueues"
    select="//job_info/queue_info/Queue-List[state[.='au']]
    | //job_info/queue_info/Queue-List[state[.='d']]
    | //job_info/queue_info/Queue-List[state[.='E']]
    | //job_info/queue_info/Queue-List[state[.='a']]
    | //job_info/queue_info/Queue-List[state[.='A']]
    | //job_info/queue_info/Queue-List[state[.='D']]"
    />
<xsl:variable name="nodeSet-loadAlarmQueues"
    select="//job_info/queue_info/Queue-List[state[.='a']]
    | //job_info/queue_info/Queue-List[state[.='A']]"
    />
<xsl:variable name="nodeSet-dEauQueues"
    select="//job_info/queue_info/Queue-List[state[.='d']]
    | //job_info/queue_info/Queue-List[state[.='au']]
    | //job_info/queue_info/Queue-List[state[.='E']]"
    />
<xsl:variable name="unavailableQueueInstanceCount"
    select="count($nodeSet-unavailableQueues)"
    />
<xsl:variable name="AdjSlotsPercent"
    select="($slotsUsed div ($slotsTotal - $unusableSlotCount) )*100"
    />
<xsl:variable name="unavailable-all-Percent"
    select="($unavailableQueueInstanceCount div $queueInstances)*100"
    />
<xsl:variable name="unavailable-load-Percent"
    select="(count($nodeSet-loadAlarmQueues) div $queueInstances)*100"
    />
<xsl:variable name="unavailable-dEau-Percent"
    select="(count($nodeSet-dEauQueues) div $queueInstances)*100"
    />

<!-- Active job stuff -->
<!--
   | count active jobs/slots for user or everyone
   | we can count the slots directly, since each task is listed separately
   | but we need to count the jobs ourselves
   -->
<xsl:variable name="AJ_total">
  <xsl:call-template name="count-jobs">
    <xsl:with-param
        name="nodeList"
        select="//job_info/queue_info/Queue-List/job_list"
    />
  </xsl:call-template>
</xsl:variable>
<xsl:variable name="AJ_slots">
  <xsl:value-of select="sum(//job_info/queue_info/Queue-List/job_list/slots)"/>
</xsl:variable>

<!-- Pending Job Stuff -->
<xsl:variable name="PJ_total"     select="count(//job_info/job_info/job_list)"/>

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<xsl:text>
</xsl:text>
<head>
<xsl:text>
</xsl:text>

<link rel="icon" type="image/png" href="../images/icons/silk/controller.png"/>
<xsl:choose>
<xsl:when test="$renderMode='qalert'">
  <title>queue alerts (psp)</title>
</xsl:when>
<xsl:when test="$renderMode='jalert'">
  <title>job alerts (psp)</title>
</xsl:when>
<xsl:when test="$renderMode='ajobs'">
  <title>active job (psp)</title>
</xsl:when>
<xsl:when test="$renderMode='pjobs'">
  <title>pending job (psp)</title>
</xsl:when>
<xsl:otherwise>
  <title>qstat (psp)</title>
</xsl:otherwise>
</xsl:choose>

<xsl:text>
</xsl:text>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<xsl:text>
</xsl:text>
<style type="text/css" media="screen">
  *
  {
      margin:0;
      padding:0;
      list-style-type:none;
  }

  html, body
  {
      margin:0;
      padding:0;
  }

  #sidebar
  {
      width:118px;
      width:25%;
      background:pink;
      border:1px solid #8CACBB;
      float:left;
  }

  #logo, #sidebarBottom
  {
      width:118px;
      width:25%;
      background:white;
      padding-left:1.5%;
      border:0px solid #8CACBB;
      font:normal normal normal .8em sans-serif;
  }

  #sidebar a, #sidebar a:visited
  {
      display:block;
      color:#900;
      background:#f6f6f6;
      padding:2px 5px;
      font:normal normal normal 1em sans-serif;
      text-align:left;
      text-decoration:none;
  }

  #sidebar a:hover, #sidebar a:focus, #content div:hover
  {
      background:#eed;
      color: #000;
  }

  #content
  {
      width:350px;
      width:72.5%;
      padding:5px;
      border:1px solid #ffffff;
      background:white;
      float:right;
      font:normal normal normal 1em sans-serif;
  }

  .sentence { padding-top:.8em; }

</style>
<xsl:text>
</xsl:text>
</head>
<xsl:text>
</xsl:text>
<body>
<xsl:text>
</xsl:text>
<div id="sidebar">
  <ul id="menu">
    <li><a href="qstat.html"><img border="0" alt="*"  src="../images/icons/silk/bullet_blue.png" /> Home</a></li>
    <li><a href="qalert.html"><img border="0" alt="*" src="../images/icons/silk/bullet_blue.png" /> Queue Alerts</a></li>
    <li><a href="jalert.html"><img border="0" alt="*" src="../images/icons/silk/bullet_blue.png" /> Job Alerts</a></li>
    <li><a href="ajobs.html"><img border="0" alt="*"  src="../images/icons/silk/bullet_blue.png" /> Active Jobs</a></li>
    <li><a href="pjobs.html"><img border="0" alt="*"  src="../images/icons/silk/bullet_blue.png" /> Pending Jobs</a></li>
  </ul>
</div>

<!--
   | WHICH VIEW DO WE RENDER?
   |
   | There are so many variables computed in this template block
   | that it does not make sense to call out to other templates and
   | pass all those values around.
   |
   | Instead we'll do everything here. Each main #content.DIV block will
   | be fully rendered within a XSL:CHOOSE block ...
-->
<xsl:choose>
<xsl:when test="not($renderMode) or $renderMode='qstat'">
  <!-- default view -->
  <div id="content">
    <h1>Grid Engine Cluster Summary</h1>
    <div id="queueInstances">
      <img src="../images/icons/silk/accept.png" alt="OK" />
      Queue Instances: <xsl:value-of select="format-number($queueInstances,'###,###,###')"/>
    </div>
    <div id="activeJobs">
      <img src="../images/icons/silk/accept.png" alt="OK" />
      Jobs Active/Pending: <xsl:value-of select="$AJ_total"/> / <xsl:value-of select="$PJ_total"/>
    </div>
    <div id="slotsTotal">
      <img src="../images/icons/silk/accept.png" alt="OK" />
      Slots Total/Active: <xsl:value-of
      select="format-number($slotsTotal,'###,###,###')"/> / <xsl:value-of select="$AJ_slots"/>
    </div>
    <div id="slotsAvail">
    <xsl:choose>
    <xsl:when test="$unavailable-all-Percent >= 50" >
      <img src="../images/icons/silk/exclamation.png" alt="*" />
    </xsl:when>
    <xsl:when test="$unavailable-all-Percent >= 10" >
      <img src="../images/icons/silk/error.png" alt="*" />
    </xsl:when>
    </xsl:choose>
    Slots Available/Unavailable:
    <xsl:value-of select="$slotsTotal - $unusableSlotCount"/> / <xsl:value-of select="$unusableSlotCount"/>
  </div>

  <div id="unusualQueueStates">
    <xsl:choose>
    <xsl:when test="$QI_unusual_statecount &gt; 0">
      <img src="../images/icons/silk/error.png" alt="*" /> Some unusual Queue Instance states detected
    </xsl:when>
    <xsl:otherwise>
     <!-- no unusual states detected -->
     <img src="../images/icons/silk/accept.png" alt="*" /> No unusual Queue Instance states detected
    </xsl:otherwise>
    </xsl:choose>
    </div>

    <div class="sentence">
      With <xsl:value-of select="$unusableSlotCount"/> slots belonging to queue instances that
      are administratively disabled or in an unusable state, the adjusted slot utilization
      percentage is <xsl:value-of select="format-number($AdjSlotsPercent,'##0.#') "/>%.
    </div>

    <div class="sentence">
      <xsl:value-of select="format-number($unavailable-all-Percent,'##0.#') "/>% of configured
      grid queue instances are closed to new jobs due to load threshold alarms, errors or
      administrative action.
    </div>
  </div>
</xsl:when>
<xsl:when test="$renderMode='qalert'">
  <!-- queue alerts -->
  <div id="content">
    <h1>Grid Engine Queue Instance Alerts</h1>
    <xsl:if test="$QI_state_au &gt; 0">
      <div>
        <img alt="(!)" src="../images/icons/silk/error.png" />
        <xsl:text> </xsl:text>
        <xsl:value-of select="$QI_state_au"/> alarm/unreachable state 'au'
      </div>
    </xsl:if>
    <xsl:if test="$QI_state_adu &gt; 0">
      <div>
        <img alt="(!)" src="../images/icons/silk/error.png" />
        <xsl:text> </xsl:text>
        <xsl:value-of select="$QI_state_adu"/> alarm/unreachable/disabled alarm state 'adu'
      </div>
    </xsl:if>
    <xsl:if test="$QI_state_a &gt; 0">
      <div>
        <img alt="(!)" src="../images/icons/silk/information.png" />
        <xsl:text> </xsl:text>
        <xsl:value-of select="$QI_state_a"/> load threshold alarm state 'a'
      </div>
    </xsl:if>
    <xsl:if test="$QI_state_d &gt; 0">
      <div>
        <img alt="(!)" src="../images/icons/silk/cancel.png" />
        <xsl:text> </xsl:text>
        <xsl:value-of select="$QI_state_d"/> admin disabled state 'd'
      </div>
    </xsl:if>
    <xsl:if test="$QI_state_S &gt; 0">
      <div>
        <img alt="(!)" src="../images/icons/silk/control_pause.png" />
        <xsl:text> </xsl:text>
        <xsl:value-of select="$QI_state_S"/> subordinate state 'S'
      </div>
    </xsl:if>
  </div>
</xsl:when>
<xsl:when test="$renderMode='jalert'">
  <!-- job alerts -->
  <div id="content">
    <h1>Grid Engine Job Alerts</h1>
    <xsl:if test="$QI_state_S &gt; 0">
      <div class="sentence">
        <img alt="(!)" src="../images/icons/silk/bullet_blue.png" />
        <xsl:value-of select="$QI_state_S"/> queue instance(s) in subordinate state 'S'
      </div>
    </xsl:if>
  </div>
</xsl:when>
<xsl:when test="$renderMode='ajobs'">
  <!-- active jobs -->
  <div id="content">
    <h1>Grid Engine Active Jobs</h1>
    <div class="sentence">
      <img alt="(!)" src="../images/icons/silk/bullet_blue.png" />
      <xsl:value-of select="$AJ_total"/> active jobs
      (<xsl:value-of select="$AJ_slots"/> slots)
    </div>

    <!-- only do this stuff if there are active jobs -->
    <xsl:if test="$AJ_total &gt; 0">
      <div class="sentence">
        <img alt="*" src="../images/icons/silk/bullet_blue.png" />
          <xsl:call-template name="count-jobs">
            <xsl:with-param
                name="nodeList"
                select="//job_info/queue_info/Queue-List/job_list[state = 'r']"
            />
          </xsl:call-template>
          jobs report normal 'running' status
      </div>

      <!-- GENERATE A UNIQUE LIST OF ACTIVE JOB STATES THAT MAY BE OF INTEREST -->
      <xsl:for-each select="/job_info/queue_info/Queue-List/job_list [generate-id() = generate-id( key('jstate',normalize-space(state))[1] )]">
        <!-- Skip state=running (because its boring and OK, we want other states) -->
        <xsl:if test="./state != 'r'">
          <div class="sentence">
            <img alt="*" src="../images/icons/silk/bullet_blue.png" />At least 1 job
            is reporting state=<xsl:value-of select="./state"/>
          </div>
        </xsl:if>
      </xsl:for-each>
    </xsl:if> <!-- if AJ_jobs is greater than zero -->

  </div>
</xsl:when>

<xsl:when test="$renderMode='pjobs'">
  <!-- pending jobs -->
  <div id="content">
    <h1>Grid Engine Pending Jobs</h1>
    <div class="sentence"><img alt="(!)" src="../images/icons/silk/bullet_blue.png" />
      <xsl:value-of select="$PJ_total"/> pending jobs
    </div>
  </div>
</xsl:when>

</xsl:choose>
<!-- end of choose between renderMode -->

<xsl:text>
</xsl:text>
<div id="logo">
  <img style="align: center;valign=middle" alt="logo" width="90%"
    src="../images/xml-qstat-logo.png"
  />
</div>

<div id="sidebarBottom">
  <em>Last Updated:</em><br/>
  <span id="timestamp"><xsl:value-of select="$timestamp" /></span>
</div>

<xsl:text>
</xsl:text>
</body>
</html>
</xsl:template>

<!--
   | count the number of jobs
   | use string-length as a cheap hack to summarize the values
   -->
<xsl:template name="count-jobs">
  <xsl:param name="nodeList"/>
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

</xsl:stylesheet>