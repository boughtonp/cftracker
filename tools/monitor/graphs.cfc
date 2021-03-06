<cfcomponent output="false">
	<cffunction name="init" output="false">
		<cfset variables.baseDir = GetDirectoryFromPath(GetCurrentTemplatePath()) />
		<cfif Not ListFind('/,\', Right(variables.baseDir, 1))>
			<cfset variables.baseDir &= '/' />
		</cfif>
		<cfset variables.imagePath = variables.baseDir & 'images' />
		<cfset variables.rrdPath = variables.baseDir & 'rrd' />
		<cfset variables.cfcRrdGraph = CreateObject('component', 'rrdGraph') />
		<cfset variables.height = 200 />
		<cfset variables.width = 340 />
		<cfreturn this />
	</cffunction>
	
	<cffunction name="regenerate" output="false">
		<cfset var lc = {} />
		<cflock name="#application.applicationName#-graphGen" type="exclusive" timeout="10">
			<cfif Not StructKeyExists(variables, 'lastUpdated') Or DateDiff('s', variables.lastUpdated, Now()) Gte application.cftracker.graphs.interval>
				<cfif Not StructKeyExists(variables, 'lastUpdated')>
					<cfset lc.previous = DateAdd('s', -application.cftracker.graphs.interval, Now()) />
				<cfelse>
					<cfset lc.previous = variables.lastUpdated />
				</cfif>
				<cfset variables.lastUpdated = Now() />
				<cfset variables.ts = DateDiff('s', CreateDate(1970, 1, 1), variables.lastUpdated) />
				<cfset variables.end = DateAdd('s', -ts % 300, variables.lastUpdated) />
				<cfset variables.start = {} />
				<cfset variables.start['day']   = DateAdd('d',    -1, variables.lastUpdated) />
				<cfset variables.start['week']  = DateAdd('ww',   -1, variables.lastUpdated) />
				<cfset variables.start['month'] = DateAdd('m',    -1, variables.lastUpdated) />
				<cfset variables.start['year']  = DateAdd('yyyy', -1, variables.lastUpdated) />
				<cfset lc.returned = variables.garbage() />
				<cfset lc.returned = (variables.memory() Or lc.returned) />
				<cfset lc.returned = (variables.os() Or lc.returned) />
				<cfset lc.returned = (variables.misc() Or lc.returned) />
				<cfif Not lc.returned>
					<!--- All of the RRD files were missing, keep running this until they appear --->
					<cfset variables.lastUpdated = lc.previous />
				</cfif>
			</cfif>
		</cflock>
	</cffunction>
	
	<cffunction name="garbage" output="false">
		<cfscript>
			var lc = {};
			if (FileExists(variables.rrdPath & '/garbage.rrd')) {
				variables.cfcRrdGraph.init('-');
				variables.cfcRrdGraph.addDatasource('type1', variables.rrdPath & '/garbage.rrd', 'type1', 'average');

				variables.cfcRrdGraph.comment('               Maximum     Average     Minimum  ', true);
				
				variables.cfcRrdGraph.line(itemName = 'type1', colour = '89AC66', legend = 'Normal    ', width = 1);
				variables.cfcRrdGraph.gprint('type1', 'max', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('type1', 'average', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('type1', 'min', '%8.2lf %s', true);

				variables.cfcRrdGraph.setMinValue(0);
				variables.cfcRrdGraph.setTitle('Garbage Collection activity');
				variables.cfcRrdGraph.setHeight(variables.height);
				variables.cfcRrdGraph.setWidth(variables.width);
				variables.cfcRrdGraph.setBase(1000);

				for (lc.view in variables.start) {
					variables.cfcRrdGraph.setFilename(variables.imagePath & '/garbage1-' & lc.view & '.png');
					variables.cfcRrdGraph.setTimeSpan(variables.start[lc.view], variables.end);
					variables.cfcRrdGraph.render();
				}

				variables.cfcRrdGraph.init('-');
				variables.cfcRrdGraph.comment('               Maximum     Average     Minimum  ', true);
				variables.cfcRrdGraph.addDatasource('type2', variables.rrdPath & '/garbage.rrd', 'type2', 'average');
				variables.cfcRrdGraph.line(itemName = 'type2', colour = 'DB4C3C', legend = 'Full      ', width = 1);
				variables.cfcRrdGraph.gprint('type2', 'max', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('type2', 'average', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('type2', 'min', '%8.2lf %s', true);

				variables.cfcRrdGraph.setMinValue(0);
				variables.cfcRrdGraph.setTitle('Garbage Collection activity');
				variables.cfcRrdGraph.setHeight(variables.height);
				variables.cfcRrdGraph.setWidth(variables.width);
				variables.cfcRrdGraph.setBase(1000);

				for (lc.view in variables.start) {
					variables.cfcRrdGraph.setFilename(variables.imagePath & '/garbage2-' & lc.view & '.png');
					variables.cfcRrdGraph.setTimeSpan(variables.start[lc.view], variables.end);
					variables.cfcRrdGraph.render();
				}
				return true;
			}
			return false;
		</cfscript>
	</cffunction>
	
	<cffunction name="memory" output="false">
		<cfscript>
			var lc = {};
			lc.rrdPath = variables.rrdPath & '/memory.rrd';
			if (FileExists(lc.rrdPath)) {
				variables.cfcRrdGraph.init('-');
				variables.cfcRrdGraph.addDatasource('heapused', lc.rrdPath, 'heapused', 'average');
				variables.cfcRrdGraph.addDatasource('heapfree', lc.rrdPath, 'heapfree', 'average');
				variables.cfcRrdGraph.addDatasource('heapallo', lc.rrdPath, 'heapallo', 'average');
				variables.cfcRrdGraph.addDatasource('heapmax', lc.rrdPath, 'heapmax', 'average');

				variables.cfcRrdGraph.comment('               Maximum     Average     Minimum  ', true);
				variables.cfcRrdGraph.line(itemName = 'heapused', colour = 'DB4C3C', legend = 'Used      ', width = 1);
				variables.cfcRrdGraph.gprint('heapused', 'max', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('heapused', 'average', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('heapused', 'min', '%8.2lf %s', true);
				variables.cfcRrdGraph.line(itemName = 'heapfree', colour = 'CA9C0F', legend = 'Free      ', width = 1);
				variables.cfcRrdGraph.gprint('heapfree', 'max', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('heapfree', 'average', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('heapfree', 'min', '%8.2lf %s', true);
				variables.cfcRrdGraph.line(itemName = 'heapallo', colour = '7F8DA9', legend = 'Allocated ', width = 1);
				variables.cfcRrdGraph.gprint('heapallo', 'max', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('heapallo', 'average', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('heapallo', 'min', '%8.2lf %s', true);
				variables.cfcRrdGraph.line(itemName = 'heapmax', colour = '89AC66', legend = 'Max       ', width = 1);
				variables.cfcRrdGraph.gprint('heapmax', 'max', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('heapmax', 'average', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('heapmax', 'min', '%8.2lf %s', true);

				variables.cfcRrdGraph.setMinValue(0);
				variables.cfcRrdGraph.setTitle('Heap memory usage');
				variables.cfcRrdGraph.setHeight(variables.height);
				variables.cfcRrdGraph.setWidth(variables.width);
				variables.cfcRrdGraph.setBase(1024);

				for (lc.view in variables.start) {
					variables.cfcRrdGraph.setFilename(variables.imagePath & '/memory-heap-' & lc.view & '.png');
					variables.cfcRrdGraph.setTimeSpan(variables.start[lc.view], variables.end);
					variables.cfcRrdGraph.render();
				}

				variables.cfcRrdGraph.init('-');
				variables.cfcRrdGraph.addDatasource('nonheapused', lc.rrdPath, 'nonheapused', 'average');
				variables.cfcRrdGraph.addDatasource('nonheapfree', lc.rrdPath, 'nonheapfree', 'average');
				variables.cfcRrdGraph.addDatasource('nonheapallo', lc.rrdPath, 'nonheapallo', 'average');
				variables.cfcRrdGraph.addDatasource('nonheapmax', lc.rrdPath, 'nonheapmax', 'average');

				variables.cfcRrdGraph.comment('               Maximum     Average     Minimum  ', true);
				
				variables.cfcRrdGraph.line(itemName = 'nonheapused', colour = 'DB4C3C', legend = 'Used      ', width = 1);
				variables.cfcRrdGraph.gprint('nonheapused', 'max', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('nonheapused', 'average', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('nonheapused', 'min', '%8.2lf %s', true);
				variables.cfcRrdGraph.line(itemName = 'nonheapfree', colour = 'CA9C0F', legend = 'Free      ', width = 1);
				variables.cfcRrdGraph.gprint('nonheapfree', 'max', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('nonheapfree', 'average', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('nonheapfree', 'min', '%8.2lf %s', true);
				variables.cfcRrdGraph.line(itemName = 'nonheapallo', colour = '7F8DA9', legend = 'Allocated ', width = 1);
				variables.cfcRrdGraph.gprint('nonheapallo', 'max', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('nonheapallo', 'average', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('nonheapallo', 'min', '%8.2lf %s', true);
				variables.cfcRrdGraph.line(itemName = 'nonheapmax', colour = '89AC66', legend = 'Max       ', width = 1);
				variables.cfcRrdGraph.gprint('nonheapmax', 'max', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('nonheapmax', 'average', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('nonheapmax', 'min', '%8.2lf %s', true);

				variables.cfcRrdGraph.setMinValue(0);
				variables.cfcRrdGraph.setTitle('Non-Heap memory usage');
				variables.cfcRrdGraph.setHeight(variables.height);
				variables.cfcRrdGraph.setWidth(variables.width);
				variables.cfcRrdGraph.setBase(1024);

				for (lc.view in variables.start) {
					variables.cfcRrdGraph.setFilename(variables.imagePath & '/memory-nonheap-' & lc.view & '.png');
					variables.cfcRrdGraph.setTimeSpan(variables.start[lc.view], variables.end);
					variables.cfcRrdGraph.render();
				}
				return true;
			}
			return false;
		</cfscript>
	</cffunction>
	
	<cffunction name="os" output="false">
		<cfscript>
			var lc = {};
			lc.rrdPath = variables.rrdPath & '/os.rrd';
			if (FileExists(lc.rrdPath)) {
				variables.cfcRrdGraph.init('-');
				// vmcommit, phyfree, phyused, phytotal, swapfree, swapused, swaptotal
				variables.cfcRrdGraph.addDatasource('phyused', lc.rrdPath, 'phyused', 'average');
				variables.cfcRrdGraph.addDatasource('phyfree', lc.rrdPath, 'phyfree', 'average');
				variables.cfcRrdGraph.addDatasource('phytotal', lc.rrdPath, 'phytotal', 'average');

				variables.cfcRrdGraph.comment('               Maximum     Average     Minimum  ', true);
				
				variables.cfcRrdGraph.line(itemName = 'phyused', colour = 'DB4C3C', legend = 'Used      ', width = 1);
				variables.cfcRrdGraph.gprint('phyused', 'max', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('phyused', 'average', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('phyused', 'min', '%8.2lf %s', true);
				variables.cfcRrdGraph.line(itemName = 'phyfree', colour = 'CA9C0F', legend = 'Free      ', width = 1);
				variables.cfcRrdGraph.gprint('phyfree', 'max', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('phyfree', 'average', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('phyfree', 'min', '%8.2lf %s', true);
				variables.cfcRrdGraph.line(itemName = 'phytotal', colour = '89AC66', legend = 'Total     ', width = 1);
				variables.cfcRrdGraph.gprint('phytotal', 'max', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('phytotal', 'average', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('phytotal', 'min', '%8.2lf %s', true);

				variables.cfcRrdGraph.setMinValue(0);
				variables.cfcRrdGraph.setTitle('Phyiscal memory usage (System not JVM)');
				variables.cfcRrdGraph.setHeight(variables.height);
				variables.cfcRrdGraph.setWidth(variables.width);
				variables.cfcRrdGraph.setBase(1024);

				for (lc.view in variables.start) {
					variables.cfcRrdGraph.setFilename(variables.imagePath & '/os-phy-' & lc.view & '.png');
					variables.cfcRrdGraph.setTimeSpan(variables.start[lc.view], variables.end);
					variables.cfcRrdGraph.render();
				}

				variables.cfcRrdGraph.init('-');
				variables.cfcRrdGraph.addDatasource('swapused', lc.rrdPath, 'swapused', 'average');
				variables.cfcRrdGraph.addDatasource('swapfree', lc.rrdPath, 'swapfree', 'average');
				variables.cfcRrdGraph.addDatasource('swaptotal', lc.rrdPath, 'swaptotal', 'average');

				variables.cfcRrdGraph.comment('               Maximum     Average     Minimum  ', true);
				
				variables.cfcRrdGraph.line(itemName = 'swapused', colour = 'DB4C3C', legend = 'Used      ', width = 1);
				variables.cfcRrdGraph.gprint('swapused', 'max', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('swapused', 'average', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('swapused', 'min', '%8.2lf %s', true);
				variables.cfcRrdGraph.line(itemName = 'swapfree', colour = 'CA9C0F', legend = 'Free      ', width = 1);
				variables.cfcRrdGraph.gprint('swapfree', 'max', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('swapfree', 'average', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('swapfree', 'min', '%8.2lf %s', true);
				variables.cfcRrdGraph.line(itemName = 'swaptotal', colour = '89AC66', legend = 'Total     ', width = 1);
				variables.cfcRrdGraph.gprint('swaptotal', 'max', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('swaptotal', 'average', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('swaptotal', 'min', '%8.2lf %s', true);

				variables.cfcRrdGraph.setMinValue(0);
				variables.cfcRrdGraph.setTitle('Swap memory usage (System not JVM)');
				variables.cfcRrdGraph.setHeight(variables.height);
				variables.cfcRrdGraph.setWidth(variables.width);
				variables.cfcRrdGraph.setBase(1024);

				for (lc.view in variables.start) {
					variables.cfcRrdGraph.setFilename(variables.imagePath & '/os-swap-' & lc.view & '.png');
					variables.cfcRrdGraph.setTimeSpan(variables.start[lc.view], variables.end);
					variables.cfcRrdGraph.render();
				}
				return true;
			}
			return false;
		</cfscript>
	</cffunction>

	<cffunction name="misc" output="false">
		<cfscript>
			var lc = {};
			lc.rrdPath = variables.rrdPath & '/misc.rrd';
			if (FileExists(lc.rrdPath)) {
				// Compilation Time
				variables.cfcRrdGraph.init('-');
				variables.cfcRrdGraph.addDatasource('comptime', lc.rrdPath, 'comptime', 'average');
				variables.cfcRrdGraph.comment('                 Maximum     Average     Minimum  ', true);
				
				variables.cfcRrdGraph.line(itemName = 'comptime', colour = '7F8DA9', legend = 'Compilation ', width = 1);
				variables.cfcRrdGraph.gprint('comptime', 'max', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('comptime', 'average', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('comptime', 'min', '%8.2lf %s', true);

				variables.cfcRrdGraph.setMinValue(0);
				variables.cfcRrdGraph.setTitle('Compilation activity');
				variables.cfcRrdGraph.setHeight(variables.height);
				variables.cfcRrdGraph.setWidth(variables.width);
				variables.cfcRrdGraph.setBase(1000);

				for (lc.view in variables.start) {
					variables.cfcRrdGraph.setFilename(variables.imagePath & '/compilation-' & lc.view & '.png');
					variables.cfcRrdGraph.setTimeSpan(variables.start[lc.view], variables.end);
					variables.cfcRrdGraph.render();
				}

				// CPU Usage
				variables.cfcRrdGraph.init('-');
				variables.cfcRrdGraph.addDatasource('cpuUsage', lc.rrdPath, 'cpuUsage', 'average');
				variables.cfcRrdGraph.addCDef('cputime', 'cpuUsage,1000000000,/');
				variables.cfcRrdGraph.comment('               Maximum     Average     Minimum  ', true);
				
				variables.cfcRrdGraph.line(itemName = 'cputime', colour = '89AC66', legend = 'CPU Usage ', width = 1);
				variables.cfcRrdGraph.gprint('cputime', 'max', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('cputime', 'average', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('cputime', 'min', '%8.2lf %s', true);

				variables.cfcRrdGraph.setMinValue(0);
				variables.cfcRrdGraph.setTitle('CPU usage');
				variables.cfcRrdGraph.setHeight(variables.height);
				variables.cfcRrdGraph.setWidth(variables.width);
				variables.cfcRrdGraph.setBase(1000);
				

				for (lc.view in variables.start) {
					variables.cfcRrdGraph.setFilename(variables.imagePath & '/cpu-' & lc.view & '.png');
					variables.cfcRrdGraph.setTimeSpan(variables.start[lc.view], variables.end);
					variables.cfcRrdGraph.render();
				}

				// Classes loaded
				variables.cfcRrdGraph.init('-');

				variables.cfcRrdGraph.addDatasource('classload', lc.rrdPath, 'classload', 'average');
				variables.cfcRrdGraph.comment('               Maximum     Average     Minimum  ', true);
				
				variables.cfcRrdGraph.line(itemName = 'classload', colour = 'CA9C0F', legend = 'Classes   ', width = 1);
				variables.cfcRrdGraph.gprint('classload', 'max', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('classload', 'average', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('classload', 'min', '%8.2lf %s', true);

				//variables.cfcRrdGraph.setMinValue(0);
				variables.cfcRrdGraph.setTitle('Total Classes Loaded');
				variables.cfcRrdGraph.setHeight(variables.height);
				variables.cfcRrdGraph.setWidth(variables.width);
				variables.cfcRrdGraph.setBase(1000);
				
				for (lc.view in variables.start) {
					variables.cfcRrdGraph.setFilename(variables.imagePath & '/class-total-' & lc.view & '.png');
					variables.cfcRrdGraph.setTimeSpan(variables.start[lc.view], variables.end);
					variables.cfcRrdGraph.render();
				}
				
				// Classes loading activity
				variables.cfcRrdGraph.init('-');

				variables.cfcRrdGraph.addDatasource('classtotal', lc.rrdPath, 'classtotal', 'average');
				variables.cfcRrdGraph.addDatasource('classunload', lc.rrdPath, 'classunload', 'average');
				variables.cfcRrdGraph.addCDef('classun', 'classunload,-1,*');
				variables.cfcRrdGraph.comment('               Maximum     Average     Minimum  ', true);

				variables.cfcRrdGraph.line(itemName = 'classtotal', colour = 'DB4C3C', legend = 'Loading   ', width = 1);
				variables.cfcRrdGraph.gprint('classtotal', 'max', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('classtotal', 'average', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('classtotal', 'min', '%8.2lf %s', true);
				variables.cfcRrdGraph.line(itemName = 'classun', colour = '89AC66', legend = 'Unloading ', width = 1);
				variables.cfcRrdGraph.gprint('classun', 'max', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('classun', 'average', '%8.2lf %s');
				variables.cfcRrdGraph.gprint('classun', 'min', '%8.2lf %s', true);
				
				variables.cfcRrdGraph.setMinValue(0);
				variables.cfcRrdGraph.setTitle('Class Loading rates');
				variables.cfcRrdGraph.setHeight(variables.height);
				variables.cfcRrdGraph.setWidth(variables.width);
				variables.cfcRrdGraph.setBase(1000);
				
				for (lc.view in variables.start) {
					variables.cfcRrdGraph.setFilename(variables.imagePath & '/class-activity-' & lc.view & '.png');
					variables.cfcRrdGraph.setTimeSpan(variables.start[lc.view], variables.end);
					variables.cfcRrdGraph.render();
				}
				return true;
			}
			return false;
		</cfscript>
	</cffunction>
</cfcomponent>