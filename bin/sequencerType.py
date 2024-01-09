#!/usr/bin/env python

import argparse
from pathlib import Path 

def main(args):
    path = Path(args.path)
    seqType = None

    if (len(list(path.glob('**/final_summary_*.txt')))):
        seqType = "nanopore"

    elif (len(list(path.glob('**/CompletedJobInfo.xml')))):
        seqType = "illumina"

    print(seqType)
    
if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument('path')
    args = parser.parse_args()
    main(args)