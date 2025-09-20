

## Build from Source
### Step 1: Install VibeScript

VibeScript is required to run Contanizer Markitdown. Choose the installation method for your operating system:

#### For Linux Users (Recommended)

**Option A: Pre-compiled Binary**
```bash
curl -L https://github.com/OUIsolutions/VibeScript/releases/download/0.36.0/vibescript.out -o vibescript.out
chmod +x vibescript.out
sudo mv vibescript.out /usr/local/bin/vibescript
```

**Option B: Compile from Source**
```bash
curl -L https://github.com/OUIsolutions/VibeScript/releases/download/0.36.0/amalgamation.c -o vibescript.c
gcc vibescript.c -o vibescript.out
sudo mv vibescript.out /usr/local/bin/vibescript
```

#### For macOS Users

```bash
curl -L https://github.com/OUIsolutions/VibeScript/releases/download/0.36.0/amalgamation.c -o vibescript.c
gcc vibescript.c -o vibescript.out
sudo mv vibescript.out /usr/local/bin/vibescript
```

> **Note:** Make sure you have GCC installed. You can install it via Xcode Command Line Tools: `xcode-select --install`


### Step 2: Clone the Shipyard Repository
```bash
git clone https://github.com/OUIsolutions/shipyard.git
cd shipyard
```
### Step 3: Add Shipyard to Your Vibescript Path

```bash
vibescript add_script --file shipyard.lua shipyard
```

## Usage 
to make a release, first create a **release.json** file in the following format: 
```json 
{
   "replacers":{
       "BIG_VERSION":"0",
       "SMALL_VERSION":"1",
       "PATCH_VERSION":"0"
   },
   "release": "{BIG_VERSION}.{SMALL_VERSION}.{PATCH_VERSION}",
   "tag": "{BIG_VERSION}.{SMALL_VERSION}.{PATCH_VERSION}",
    "description": "description of the release",
    "assets": ["path/to/asset1", "path/to/asset2"]
}
```
then you can run the following command: 
```bash 
shipyard release.json
```
note that:
if  the tag not exist, it will be created, otherwise, it will be updated.
if the assets already exist, they will be replaced.



