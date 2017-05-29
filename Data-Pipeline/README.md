# Map of the Internet Data-Pipeline

## Environment Setup Suggestions

### Python

Our datapipeline relies on running a series of python scripts to generate our data sets. Since various projects require different python versions, I recommend using a tool that will allow you to create sandboxed python environments.

*Using virtiualenv*

1. Install virtiualenv (https://virtualenv.pypa.io/en/stable/userguide/)
2. Create `venv` folder where you want this environment to live. I made it sibling to our data pipleline folder.
3. Run `> virtualenv venv` - this will generate a default python environment inside that folder
4. Navigate into `venv` to make sure the default folders (bin, libs etc...) have been created
5. Activate that python environment by running `source bin/activate`. When activated your terminal should be prefaced with `(venv)`, to indicate you are running in that python environment. Woo!

Once setup, you should only need to reactivate the environment each time you want to work with the project. I used *pypa* to find and install missing python libs (https://www.pypa.io/en/latest/)


## Data Pipeline Details

### Details

* Autonomous System (AS) link data comes from `http://www.caida.org/data/` (under `datasets/topology/`)
* AS geo data comes from `http://dev.maxmind.com/geoip/legacy/geolite/`

### Adding New Data

#### Update Geo data
1. Download new geo data (from http://dev.maxmind.com/geoip/legacy/geolite/)
2. Run `geopipeline.py` to generate `loc.py`
3. TODO one more step to get loc.py into json; look into smoothing out this step

### Update AS Link data
1. Go to http://data.caida.org/datasets/topology/ark/ipv4/as-links/; you may have to request this data set by entering in an email and reason for data usage.
2. Currently we only use one file as a representative each year. Unless a particular point in the year is desired, navigate to the `team-1` folder, select the desired year and then download the first data set available for that year. (Named like `cycle-aslinks.l7.t1.cXXXXXX.YYYYMMDD.txt.gz`)
3. Unzip and copy those files into the `aspipeline/data` folder
4. Run `aspipeline.py`; this will generate the data files under `aspipeline/out`.
5. Copy the files from `aspipeline/out` into the project's `Common/Data` folder.

### Update asinfo.json

After looking through the original scripts, it appears that asinfo is created soley with the geo data (`loc.py`)
1. Run `converttojson.py`, this will build asinfo.json

### Update as2attr.txt

This file appears to come from http://griley.ece.gatech.edu/MANIACS/as_taxonomy/, and has not been updated since 2006. 
TODO detemine if we can get updated data for this.

### Update C++ Files
TODO Ideally this would not have to be done, look into ways to smooth out pipeline.

.

.

.

.

.

.

.

.

.

.

.

.

.


## Notes I made while first going through the data pipeline...

### Data.caida.org

datasets/topology/

--------------------
ksitter-as-links
--------------------
tools/asadj2graph.pl
  	Desc: filter AS adjacency files into AS graph adjacency matrices
	Input: AS adjacency files: http://www.caida.org/tools/measurement/skitter/as_adjacencies.xml
	Output: AS graph adjacency matrices in the following format: "line AS_X AS_Y" - represents a link between AS_X and AS_Y

* skitter is a tool for actively probing the Internet in order to analyze topology and performance; only used until 2008.
* Archipelago (Ark) is the replacement tool for collecting similar data, and produces the IPv4 Routed /24 Topology Dataset

--------------------
ipv4.allpref24-aslinks
--------------------
* Data files for "recent" data in the project are in the format "cycle-aslinks.l7.t1.cXXXXXX.YYYYMMDD.txt.gz" 
	ie. "cycle-aslinks.l7.t1.c000359.20090103.txt.gz"


### aspipeline

aspipeline.py
 	* Takes files in data folder, runs all the maths on them, and creates a file in the out folder named with the date
 	* Uses eigenvector.py

historicalstats.py
	* Cannot find where this file is being used
	* Uses asgraph.py

asyearsfiltered
	* Cannot find where this is being used

--------------------
data
--------------------
* Pulled a single representative file out of the skitter and ipv4 folders (Data.caida.org)
* Did not always pick Jan 1, not sure why, perhaps picked dates that corresponded with timeline events?

--------------------
out
--------------------
* Results of aspipeline.py




### geopipeline
geopipeline.py
	* Uses data/GeoIPASNum2.csv
	* Uses data/GeoLiteCity_20130101/GeoLiteCity-Blocks.csv
	* Uses data/GeoLiteCity_20130101/GeoLiteCity-Location.csv
	* Writes out to "../loc.py"

--------------------
data
--------------------
* Taken from http://dev.maxmind.com/geoip/legacy/geolite/
* May need data attribution:
	This product includes GeoLite data created by MaxMind, available from 
	<a href="http://www.maxmind.com">http://www.maxmind.com</a>.

--------------------
out
--------------------
* Contains loc.py, but since geopipeline does not appear to write to this folder, this file may not be the most recent result




### companynames

* Includes GeoIPAsNum2.csv (Also from http://dev.maxmind.com/geoip/legacy/geolite/)

companynames.py
	* Uses asinfo.json as input data (asinfo)
	* Uses data.txt as input data (vals)
	* Creates top100.csv

asinfo.js
	* ??? No idea where this file comes from	

data.txt
	* ??? No idea where this file comes from
	* Appears to be used to generate top100.csv

top100.csv
	* Generated by companynames.py?
	* List of ASNum,ASName for "top" ASCompanies? 


### asgraph

* Looks like it contains ALL the data from the Ark (ipv4.allpref24-aslinks) data collection method
* Could be the superset of the data used in aspipeline/data (from 2008 onwards)
* Also, asgraph/cycle-aslinks.l7.t1.c002162.20120916.txt used in getasinfo.py to grab all ASNs 
	* Why this file? Because it was the most "up to date" at the time?


### ashhtml

* Looks like scraped HTML data for each AS
* Each file contains ASBlock numbers, names and addresses (and lots of other infoz)
* All files generated by getasinfo2.py
* Could be used for archiving purposes - I do not see these HTML pages being used anywhere



### Top Level Scripts / files

getasinfo.py
	* Pulls data from asgraph/cycle-aslinks.l7.t1.c002162.20120916.txt to get the full list of ASNs to query
	* Calls http://ipduh.com/ip/whois/as/?<ASNNUm> to get the HTML code that contains a bunch of info for each ASN.
	* Scrapes the HTML for specific fields, and creates an "asinfo" json object that is written directly into results.py

getasinfo2.py
	* Same as getasinfo.py except...
	* Instead of picking out fields and writing to results.py, it generates the HTML pages found in the ashtml folder
	* Does not pick out specific fields or write to results.py

results.py
	* Generated by getasinfo.py

loc.py
	* Generated by geopipeline/geopipeline.py

converttojson.py
	* Does not appear to be used

as2attr.txt
	* Does not appear to be used 

as_rel.txt
	* Does not appear to be used 

asinfo.json / asinfo2.json
	* Does not appear to be used
	* Perhaps a relic from before asinfo was being written into results.py?


### App Data


--------------------
data
--------------------
* Single txt files for each year
* Files pulled directly from aspipeline/out



Android app is using:
/data/
* history.json


MapController.cpp
* Hardcodes in lastTimelinePoint
* Uses unified.txt to load in data



Files to update when adding a new year:

data folder

history.json: 


### Attempting to run all existing scripts to recreate final outout data using exsiting inputs

Suggestion:
* Install virtiualenv (https://virtualenv.pypa.io/en/stable/userguide/) to create contained python environments
* Use pypa to install libs - Search for python libs here https://www.pypa.io/en/latest/

--------------------
aspipeline
--------------------
aspipeline.py
	* ERROR: ImportError: No module named networkx
	* SOLUTION: Install networkx (suggestion, setup custom python env)

	* ERROR: ImportError: No module named p9base
	* ISSUE: Not a standard or known 3rd party python lib
	* SOLUTION: Jeff wrote this; add this helper script to the folder

	* ERROR: generator' object has no attribute '__getitem__' ("aspipeline.py", line 479)
	* PROBLEM: networkx lib has changed, such that the connected_components returns a generator, not a list 
	* SOLUTION: Create sorted_components = sorted(nx.connected_components(self.graph), key=len, reverse=True) to simulate that old list


historicalstats.py
	* Same issue as aspipline (uses same logic) 
	* TODO refactor so that aspipeline and historicalstats use same ASGraph class
	* For now, since we don't have to regen the old data, will not fix

projected stats in data folder
	* No idea where these files come from

getasinfo.py
	* Needs most recent file in asgraph folder

	* ERROR: socket.error: [Errno 54] Connection reset by peer
	* NOTE: Occurs after a period of time, numerous calls made successfully; more than likely hit a new rate limit imposed by the ipduh.com services
	* OPTIONS: use getasinfo2.py (run in batches) to save the HTML and scrape that later.




Pipeline improvements

* File naming, even though we are using not jan 1st data, need to rename files so we are not having to map them in MapCongroller::setTimelinePoint
* Move simulated years out to json that can be generated


Places with hardcoded dates
* MapController::setTimelinePoint
* hostory.json
* INternetMap.java ==> is simualted (showNodePopup) hard codes years.


