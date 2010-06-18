<%@ page language="java" pageEncoding="utf-8" contentType="text/html;charset=utf-8"%>
<%@ page import="java.util.List" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Calendar" %>
<%@ page import="java.util.Date" %>
<%@ page import="java.util.Iterator" %>
<%@ page import="org.archive.wayback.ResultURIConverter" %>
<%@ page import="org.archive.wayback.WaybackConstants" %>
<%@ page import="org.archive.wayback.core.CaptureSearchResult" %>
<%@ page import="org.archive.wayback.core.CaptureSearchResults" %>
<%@ page import="org.archive.wayback.core.UIResults" %>
<%@ page import="org.archive.wayback.partition.BubbleCalendarData" %>
<%@ page import="org.archive.wayback.util.partition.Partition" %>
<%@ page import="org.archive.wayback.util.StringFormatter" %>
<jsp:include page="/WEB-INF/template/CookieJS.jsp" flush="true" />
<%
UIResults results = UIResults.extractCaptureQuery(request);

StringFormatter fmt = results.getWbRequest().getFormatter();
ResultURIConverter uriConverter = results.getURIConverter();

// deployment-specific URL prefixes
String staticPrefix = results.getStaticPrefix();
String queryPrefix = results.getQueryPrefix();
String replayPrefix = results.getReplayPrefix();

//deployment-specific address for the graph generator:
String graphJspPrefix = results.getContextConfig("graphJspPrefix");
if(graphJspPrefix == null) {
	graphJspPrefix = queryPrefix;
}

// graph size "constants": These are currently baked-in to the JS logic...
int imgWidth = 735;
int imgHeight = 75;
int yearWidth = 49;
int monthWidth = 4;

BubbleCalendarData data = new BubbleCalendarData(results);

String yearEncoded = data.getYearsGraphString(imgWidth,imgHeight);
String yearImgUrl = graphJspPrefix + "jsp/graph.jsp?graphdata=" + yearEncoded;

// a Calendar object for doing days-in-week, day-of-week,days-in-month math:
Calendar cal = BubbleCalendarData.getUTCCalendar();

%>
<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js" type="text/javascript"></script>
<script src="http://ajax.googleapis.com/ajax/libs/jqueryui/1.8.1/jquery-ui.min.js" type="text/javascript"></script>
<script type="text/javascript" src="<%= staticPrefix %>js/excanvas.compiled.js"></script>
<script type="text/javascript" src="<%= staticPrefix %>js/jquery.bt.min.js" charset="utf-8"></script>
<script type="text/javascript" src="<%= staticPrefix %>js/jquery.hoverintent.min.js" charset="utf-8"></script>
<script type="text/javascript" src="<%= staticPrefix %>js/graph-calc.js" ></script>
<!-- More ugly JS to manage the highlight over the graph -->
<script type="text/javascript">


var firstDate = <%= data.dataStartMSSE %>;
var lastDate = <%= data.dataEndMSSE %>;
var wbPrefix = "<%= replayPrefix %>";
var wbCurrentUrl = "<%= data.searchUrlForJS %>";

var curYear = <%= data.yearNum - 1996 %>;
var curMonth = -1;
var yearCount = 15;
var firstYear = 1996;
var startYear = <%= data.yearNum - 1996 %>;
var imgWidth = <%= imgWidth %>;
var yearImgWidth = <%= yearWidth %>;
var monthImgWidth = <%= monthWidth %>;
var trackerVal = "none";

function showTrackers(val) {
	if(val == trackerVal) {
		return;
	}

    document.getElementById("wbMouseTrackYearImg").style.display = val;
    trackerVal = val;
}
function getElementX2(obj) {
	var thing = jQuery(obj);
	if((thing == undefined) 
			|| (typeof thing == "undefined") 
			|| (typeof thing.offset == "undefined")) {
		return getElementX(obj);
	}
	return Math.round(thing.offset().left);
}
function setActiveYear(year) {
    if(curYear != year) {
        var yrOff = year * yearImgWidth;
        document.getElementById("wbMouseTrackYearImg").style.left = yrOff + "px";
        if(curYear != -1) {
        	document.getElementById("highlight-"+curYear).setAttribute("class","inactiveHighlight");
        }
        document.getElementById("highlight-"+year).setAttribute("class","activeHighlight");
        curYear = year;
    }
}
function trackMouseMove(event,element) {

    var eventX = getEventX(event);
    var elementX = getElementX2(element);
    var xOff = eventX - elementX;
	if(xOff < 0) {
		xOff = 0;
	} else if(xOff > imgWidth) {
		xOff = imgWidth;
	}
    var monthOff = xOff % yearImgWidth;

    var year = Math.floor(xOff / yearImgWidth);
	var yearStart = year * yearImgWidth;
    var monthOfYear = Math.floor(monthOff / monthImgWidth);
    if(monthOfYear > 11) {
        monthOfYear = 11;
    }
    var month = (year * 12) + monthOfYear;
    var day = 1;
	if(monthOff % 2 == 1) {
		day = 15;
	}
	var dateString = 
		zeroPad(year + firstYear) + 
		zeroPad(monthOfYear+1,2) +
		zeroPad(day,2) + "000000";

	var url = wbPrefix + dateString + '*/' +  wbCurrentUrl;
	document.getElementById('wm-graph-anchor').href = url;
	setActiveYear(year);
}
</script>

<script type="text/javascript">
$().ready(function(){
    $(".date").each(function(i){
        var size = $(this).find(".hidden").text();
        var offset = size / 2;
        if (size >= 1 && size <= 20) {size = 20, offset = 10;}
        $(this).find("img").attr("src","<%= staticPrefix %>images/blueblob-dk.png");
        $(this).find(".measure").css({'width':+size+'px','height':+size+'px','top':'-'+offset+'px','left':'-'+offset+'px'});
    });
    $(".day a").each(function(i){
        var dateClass = $(this).attr("class");
        var dateId = "#"+dateClass;
        $(this).hover(function(){
            $(dateId).removeClass("opacity20");
        },function(){
            $(dateId).addClass("opacity20");    
        });
    });
    $(".tooltip").bt({
        positions: ['top','right','left','bottom'],
        contentSelector: "$(this).find('.pop').html()",
        padding: '0', 
        width: '145px',
        spikeGirth: 12, 
        spikeLength: 12,
        overlap: '2px',
        cornerRadius: 5,
        fill: '#efefef',
        strokeWidth: 1,
        strokeStyle: '#efefef',
        shadow: true, 
        shadowColor: '#333',
        shadowBlur: 6,
        shadowOffsetX: 0,
        shadowOffsetY: 0, 
        noShadowOpts: {strokeStyle:'#ccc'},
        hoverIntentOpts: {interval:0,timeout:4000}, 
        clickAnywhereToClose: true,
        closeWhenOthersOpen: true,
        windowMargin: 30,
        cssStyles: {
            fontSize: '12px',
            fontFamily: '"Arial","Helvetica Neue","Helvetica",sans-serif',
            lineHeight: 'normal',
            padding: '10px',
            color: '#333'
        }
    });
});
</script>
<style type="text/css">
body,div,p,td,th,ul,ol,li {margin:0;padding:0;}
body {background-color:#fff;font-family:"Arial","Helvetica Neue","Helvetica",sans-serif;font-size:100%;}
img {border:none;}
a {color:#069;}
.clearfix{width:100%;clear:both;}
.clearfix:after {content:".";display:block;height:0;clear:both;visibility:hidden;}
#position {padding:0;margin:0 auto;width:990px;background-color:#fff;}
#wbCalendar {position:relative;width:990px;margin-top:25px;}
.calPosition {padding:15px 0 25px 25px;}
#calUnder {overflow:hidden;}
#calOver {position:absolute;top:0;left:0;}
.hidden{display:none;}
.opacity20 {
    opacity:.2;
	-ms-filter:"progid:DXImageTransform.Microsoft.Alpha(Opacity=20)";
	filter: alpha(opacity=20);
}
.month {
    width: 240px;
    height: 210px;
    float: left;
}
.month table {
    border-collapse: collapse;
    font-family: "Arial", sans-serif;
    border-spacing: 1px;
}
.month table th {
    font-size: 0.75em;
    font-weight: 700;
    text-transform: uppercase;
    padding: 6px;
}
.month table span.label {
    display: block;
    min-height: 20px;
}
.month table td {
    padding: 0;
    vertical-align: middle;
    color: #666;
}
.month table td .day {
    width: 30px;
    height: 30px;
    text-align: center;
}
.month table td .day a,
.month table td .day span {
    display: block;
    font-size: 0.6875em;
    width: 30px;
    height: 22px;
    padding-top: 8px;
}
.month table td .day a {
    color: #000;
    font-weight: 700;
    text-decoration: none;
}
.month table td .day span {
    padding-top: 9px;
    height: 19px;
}
.month table td .day a:hover {
    font-size: 0.9375em;
    padding-top: 6px;
    height: 22px;
}
.month table td .date {
    width: 30px;
    height: 30px;
}
.month table td .position {
    position: relative;
    top: 15px;
    left: 15px;
    width: 1px;
    height: 1px;
}
.month table td .measure {
    position: absolute;
}
.activeHighlight {
    background-color: #000!important;
    padding-top: 4px;
    font-size: 1.375em!important;
    color: #fff300!important;
    font-weight: normal!important;
    cursor: pointer;
}
.inactiveHighlight {
    background-color: #fff!important;
    padding-top: 4px;
    font-size: .75em!important;
    color: #000!important;
    font-weight: normal!important;
    cursor: pointer;
}

.bt-content {
  text-align: left;
}
.pop {display:none;}
.bt-content h3 {font-size: 1em;font-weight: 700;text-transform: uppercase;margin:0 0 5px;}
.bt-content p {font-size: 0.875em;margin: 5px 0;color:#666;}
.bt-content ul {line-height:1.5em;margin:0 0 0 1em;}
.bt-content em {color:#999;}
.bt-content a:hover {color:#036;}

#wbSearch {float:left;padding:30px 30px 0;}
#wbSearch #logo {float:left; width:223px;}
#wbSearch #form {float:left;width:707px;}
#wbSearch form {margin:0;padding:0;}
#wbSearch input {font-family:"Arial","Helvetica Neue","Helvetica",sans-serif;font-size:1.125em;}
#wbSearch input[type=text] {width:450px;font-weight:700;}
#wbSearch input[type=submit] {vertical-align: middle;}
#wbMeta {padding:15px 0;}
#wbMeta p {margin:0 0 2px;padding:0;}
#wbMeta p.wbThis {font-size:0.75em;}
#wbMeta p.wbNote {color:#666;font-size: 0.6875em;}
#wbMeta p.wbNote a {color:#666;}
#wbChart {text-align:center;padding:0 30px;}
#wbChartThis {position:relative;margin:0 auto;}
.wbChartThisContainer,.wbChartHover {width:<%= yearWidth %>px;height:30px;float:left;overflow:visible;}
.wbChartThisTop {
    width: <%= yearWidth %>px;
    height: 80px;
    border: 1px solid #ccc;
}
.wbGradient {
    background: #f3f3f3 -moz-linear-gradient(top,#ffffff,#f3f3f3);
    background: #f3f3f3 -webkit-gradient(linear, left top, left bottom, from(#fff), to(#f3f3f3), color-stop(1.0, #f3f3f3));
    background-color: #f3f3f3;
    filter: progid:DXImageTransform.Microsoft.Gradient(enabled='true',startColorstr=#FFFFFFFF, endColorstr=#FFF3F3F3);
}
.wbSelected, #wbSelected {
    background: #fff300!important;
    border-bottom: 1px solid #000!important;
    filter: progid:DXImageTransform.Microsoft.Gradient(enabled='false')!important;
    cursor: pointer;
}
#wbSelected {
    cursor: default!important;
}
.wbChartThisBtm {
    text-align:center;
}
.wbChartSm {
    padding-top: 4px;
    font-size: 0.625em;
    color: #999;
    font-weight: 700;
}
.wbChartBig, #wbChartBig {
    background-color: #000!important;
    padding-top: 4px;
    font-size: 1.375em!important;
    color: #fff300!important;
    font-weight: normal!important;
    cursor: pointer;
}
#wbChartBig {
    cursor: default!important;
}
#wbChartGraph,#wbChartOver {
    position: absolute;
    top: 1px;
    left: 1px;
    cursor: pointer;
}

</style>

<script type="text/javascript">
$().ready(function(){
    var yrCount = $(".wbChartThisContainer").size();
    var yrTotal = <%= yearWidth %> * yrCount;
    var yrPad = (930 - yrTotal) / 2;
    $("#wbChartThis").css("padding-left",yrPad+"px");
});
</script>

<div id="wbChart">
    
  <div id="wbChartThis">
        <a style="position:relative; white-space:nowrap; width:<%= imgWidth %>px;height:<%= imgHeight %>px;" href="" id="wm-graph-anchor">
        <div id="wm-ipp-sparkline" style="position:relative; white-space:nowrap; width:<%= imgWidth %>px;height:<%= imgHeight %>px;background: #f3f3f3 -moz-linear-gradient(top,#ffffff,#f3f3f3);background: #f3f3f3 -webkit-gradient(linear, left top, left bottom, from(#fff), to(#f3f3f3), color-stop(1.0, #f3f3f3));background-color: #f3f3f3;filter: progid:DXImageTransform.Microsoft.Gradient(enabled='true',startColorstr=#FFFFFFFF, endColorstr=#FFF3F3F3);cursor:pointer;border: 1px solid #ccc;border-left:none;" title="<%= fmt.format("ToolBar.sparklineTitle") %>">
			<img id="sparklineImgId" style="position:absolute;z-index:9012;top:0;left:0;"
				onmouseover="showTrackers('inline');" 
				onmouseout="showTrackers('none');"
				onmousemove="trackMouseMove(event,this)"
				alt="sparklines"
				width="<%= imgWidth %>"
				height="<%= imgHeight %>"
				border="0"
				src="<%= yearImgUrl %>"></img>
			<img id="wbMouseTrackYearImg" 
				style="display:none; position:absolute; z-index:9010;"
				width="<%= yearWidth %>" 
				height="<%= imgHeight %>"
				border="0"
				src="<%= staticPrefix %>images/toolbar/transp-yellow-pixel.png"></img>
			<img id="wbMouseTrackMonthImg"
				style="display:none; position:absolute; z-index:9011; " 
				width="<%= monthWidth %>"
				height="<%= imgHeight %>" 
				border="0"
				src="<%= staticPrefix %>images/toolbar/transp-red-pixel.png"></img>
        </div>
        </a>
        	<%
        	for(int i = 1996; i < 2011; i++) {
        		String curClass = "inactiveHighlight";
        		if(data.yearNum == i) {
            		curClass = "activeHighlight";
        		}
        	%>
	            <div class="wbChartThisContainer">
	                <a style="text-decoration: none;" href="<%= queryPrefix + i + "0101000000*/" + data.searchUrlForJS %>">
	                
	                	<div id="highlight-<%= i - 1996 %>"
						onmouseover="showTrackers('inline'); setActiveYear(<%= i - 1996 %>)" 
						onmouseout="showTrackers('none');"
	                	class="<%= curClass %>"><%= i %></div>
	                </a>
	            </div>
            <%
        	}
            %>
  </div>
</div>
<div class="clearfix"></div>

<div id="wbCalendar">
    
  <div id="calUnder" class="calPosition">

    


<%
// draw 12 months, 0-11 (0=Jan, 11=Dec)
for(int moy = 0; moy < 12; moy++) {
	Partition<Partition<CaptureSearchResult>> curMonth = data.monthsByDay.get(moy);
	List<Partition<CaptureSearchResult>> monthDays = curMonth.list();
%>
    <div class="month" id="<%= data.yearNum %>-<%= moy %>">
	    <table>
	
	       <thead>
	           <tr>
	               <th colspan="7"><span class="label"></span></th>
	           </tr>
	       </thead>
	       <tbody>
	           <tr>
<%
		cal.setTime(curMonth.getStart());
		int skipDays = cal.get(Calendar.DAY_OF_WEEK) - 1;
		int daysInMonth = cal.getActualMaximum(Calendar.DAY_OF_MONTH);
		// skip until the 1st:
		for(int i = 0; i < skipDays; i++) {
			%><td><div class="date"></div></td><%
		}
		int dow = skipDays;
		int dom;
		for(dom = 0; dom < daysInMonth; dom++) {


			int count = monthDays.get(dom).count();
			if(count > 0) {
				// one or more captures in this day:
				CaptureSearchResult firstCaptureInDay = 
					monthDays.get(dom).list().get(0);
				String replayUrl = uriConverter.makeReplayURI(
							firstCaptureInDay.getCaptureTimestamp(),
							firstCaptureInDay.getOriginalUrl());
				String safeUrl = fmt.escapeHtml(replayUrl);		
				%><td>
                    <div class="date">
                        <div class="position">
                           <div class="hidden"><%= count %></div>
                           <div class="measure opacity20" id=""><img width="100%" height="100%"/></div>
                        </div>
                    </div>
				</td><%

			} else {
				// zero captures in this day:
				%><td>
	                <div class="date"></div>
				</td><%
				
			}


			if(((dom+skipDays+1) % 7) == 0) {
				// end of the week, start a new tr:
				%></tr><tr><%
			}
		}
		// fill in blank days until the end of the current week:
		while(((dom+skipDays) % 7) != 0) {
			%><td></td><%
			dom++;
		}
%>
			   </tr>
			</tbody>
		</table>    
      </div>
    
<%
}
%>
  </div>
  <div id="calOver" class="calPosition">
<%

for(int moy = 0; moy < 12; moy++) {
	Partition<Partition<CaptureSearchResult>> curMonth = data.monthsByDay.get(moy);
	List<Partition<CaptureSearchResult>> monthDays = curMonth.list();
%>
    <div class="month" id="<%= data.yearNum %>-<%= moy %>">
	    <table>
	
	       <thead>
	           <tr>
	               <th colspan="7"><span class="label"><%= fmt.format("{0,date,MMM}",curMonth.getStart()) %></span></th>
	           </tr>
	       </thead>
	       <tbody>
	           <tr>
<%
		cal.setTime(curMonth.getStart());
		int skipDays = cal.get(Calendar.DAY_OF_WEEK) - 1;
		int daysInMonth = cal.getActualMaximum(Calendar.DAY_OF_MONTH);
		// skip until the 1st:
		for(int i = 0; i < skipDays; i++) {
			%><td><div class="date"></div></td><%
		}
		int dow = skipDays;
		int dom;
		for(dom = 0; dom < daysInMonth; dom++) {


			int count = monthDays.get(dom).count();
			
			if(count > 0) {
				// one or more captures in this day:
				CaptureSearchResult firstCaptureInDay =
					monthDays.get(dom).list().get(0);
				String replayUrl = uriConverter.makeReplayURI(
						firstCaptureInDay.getCaptureTimestamp(),
						firstCaptureInDay.getOriginalUrl());
				Date firstCaptureInDayDate = firstCaptureInDay.getCaptureDate();
				String safeUrl = fmt.escapeHtml(replayUrl);
				int dupes = 999;

				%><td>
                    <div class="date tooltip">
                        <div class="pop">
                            <h3><%= fmt.format("{0,date,MMMMM d, yyyy}",firstCaptureInDayDate) %></h3>
                            <p><%= count %> snapshots, <em><%= dupes %> duplicates</em></p>
                            <ul>
							<%
							Iterator<CaptureSearchResult> dayItr = 
								monthDays.get(dom).iterator();
							while(dayItr.hasNext()) {
								CaptureSearchResult c = dayItr.next();
								String replayUrl2 = uriConverter.makeReplayURI(
										c.getCaptureTimestamp(),c.getOriginalUrl());
								String safeUrl2 = fmt.escapeHtml(replayUrl2);
								%>
								<li><a href="<%= safeUrl2 %>"><%= fmt.format("{0,date,HH:mm:ss}",c.getCaptureDate()) %></a></li>
								<%
							}
							%>
                            </ul>
                        </div>
                        <div class="day">

                            <a href="<%= safeUrl %>" title="<%= count %> snapshots (<%= dupes %> duplicates)" class="<%= fmt.format("{0,date,MMM-d-yyyy}",firstCaptureInDayDate) %>"><%= dom + 1 %></a>
                        </div>
                    </div>
			      </td><%

			} else {
				// zero captures in this day:
				%><td>
	                <div class="date">
	    	            <div class="day"><span><%= dom + 1 %></span></div>
		            </div>
				</td><%
				
			}


			if(((dom+skipDays+1) % 7) == 0) {
				// end of the week, start a new tr:
				%></tr><tr><%
			}
		}
		// fill in blank days until the end of the current week:
		while(((dom+skipDays) % 7) != 0) {
			%><td></td><%
			dom++;
		}
%>
			   </tr>
			</tbody>
		</table>    
      </div>
<%
}
%>
    </div>
  </div>