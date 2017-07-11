# Data-Pipeline

In 2013, the teams at Cogeco Peer 1 and Steamclock Software designed and developed this map for iOS and Android. It uses data from CAIDa, the Center for Applied Internet Data Analysis, which maps the key ISPs, exchange points, universities, and other organizations that run the Autonomous Systems (AS) that route traffic online.

Using this data, along side geolocation data from the GeoLite databases available from MaxMind, we generate the datasets our applications need to display AS nodes geographically.

Cleaning up the data pipeline is a work in progress, and as such, the state of this folder may change drastically. 

Note: You do NOT have to generate new data sets to build the applications; all the data required for the applications to function is already contained in the Common/Data folder.

## Environment Setup Suggestions

### Python

Our datapipeline relies on running a series of python scripts to generate our data sets. Since various projects require different python versions, we recommend using a tool that will allow you to create sandboxed python environments.

*Using virtiualenv*

1. Install virtiualenv (https://virtualenv.pypa.io/en/stable/userguide/)
2. Create `venv` folder where you want this environment to live. During development, we made this folder sibling to our data pipleline folder.
3. Run `> virtualenv venv` - this will generate a default python environment inside that folder
4. Navigate into `venv` to make sure the default folders (bin, libs etc...) have been created
5. Activate that python environment by running `source bin/activate`. When activated your terminal should be prefaced with `(venv)`, to indicate you are running in that python environment. Woo!

Once setup, you should only need to reactivate the environment each time you want to work with the project. We used *pypa* to find and install missing python libs (https://www.pypa.io/en/latest/)


## Data Pipeline Details

### Pieces of the Puzzle (Common/Data)

The result of our data pipeline spits out these major files:

1. YYYY.txt files - contains network layout information for each AS node, as well as connection information (one file per year)
2. asinfo.json - contains names and geographical information for each AS node
3. as2attr.txt - contains taxonomy info for AS nodes

### Steps to add new year

#### 1. Update Geo data
1. Download new geo data (from http://dev.maxmind.com/geoip/legacy/geolite/)
2. Run `geopipeline.py` to generate `loc.py`
3. Run `converttojson.py` to create asinfo.json 

Note: Need to look into steamlining this since there is really no need for the intermediate loc.py file.

### 2. Update AS data
1. Go to http://data.caida.org/datasets/topology/ark/ipv4/as-links/; you may have to request this data set by entering in an email and reason for data usage.
2. Currently we only use one file as a representative each year. Unless a particular point in the year is desired, navigate to the `team-1` folder, select the desired year and then download the first data set available for that year. (Named like `cycle-aslinks.l7.t1.cXXXXXX.YYYYMMDD.txt.gz`)
3. Unzip and copy those files into the `aspipeline/data` folder
4. Run `aspipeline.py`; this will generate the data files under `aspipeline/out`.
5. Copy the files from `aspipeline/out` into the project's `Common/Data` folder.

### 3. Update Taxonomy data 

It appears as if the data set used to generate as2attr.txt came from http://griley.ece.gatech.edu/MANIACS/as_taxonomy/, and has not been updated since 2006. Right now this data cannot be updated as-is.

Note: Need to detemine if we can get updated data for this.

### 4. Copy over all files into Common/Data folder

Once complete, copy the YYYY.txt files, asinfo.json and as2attr.txt into the Common/Data folder.

### 5. Update history and globalSettings

Update these data files to include reference to the new XXXX.txt data file generated above. 

### 6. Update unified.txt

In order to speed up initial app load, we need to create the unified.txt file which contains quick lookup data for the new "default" year. Currently this is done by enabling the block of code in MapController.cpp that creates the unified file and then running tha app on an emulator in iOS.

Note: Now that we have complete control over the data pipeline we should look into creating this file in python.

## Troubleshooting

Below are some issues encountered when initally running through the python scripts in the pipeline:

#### ERROR (aspipeline): ImportError: No module named networkx

SOLUTION: Install networkx (suggestion, setup custom python env)

#### ERROR (aspipeline): ImportError: No module named p9base

ISSUE: Not a standard or known 3rd party python lib

SOLUTION: Jeff wrote this; add this helper script to the folder

#### ERROR (aspipeline): generator' object has no attribute '__getitem__' ("aspipeline.py", line 479)

PROBLEM: networkx lib has changed, such that the connected_components returns a generator, not a list 

SOLUTION: Create sorted_components = sorted(nx.connected_components(self.graph), key=len, reverse=True) to simulate that old list

#### ERROR (getasinfo): socket.error: [Errno 54] Connection reset by peer

NOTE: Occurs after a period of time, numerous calls made successfully; more than likely hit a new rate limit imposed by the ipduh.com services

OPTIONS: use getasinfo2.py (run in batches) to save the HTML and scrape that later.

