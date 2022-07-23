# Goemon's Great Adventure Decompilation

This is a *work-in-progress* decompilation of Goemon's Great Adventure.

## Usage

### Requirements

*Python 3.8 or greater is required to use some tools used in this project.*

In order to install the requirements for these tools, please run the following command:

`python3 -m pip install -r tools/splat/requirements.txt --upgrade`

### Building

1. Place a Japanese version ROM file of Goemon's Great Adventure into the root of this repository and name it `baserom.z64`.

2. Initialize the repository using `make setup`.

3. Build the final ROM file using `make`.