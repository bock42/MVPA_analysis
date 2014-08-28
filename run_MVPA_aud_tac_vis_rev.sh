#!/bin/bash
SUBJ=$SUBJECT
DATADIR=/data/jet/aguirre/abock/Semantic_Decoding/
TOOLBOXDIR=/data/jet/aguirre/abock/Shared/
CONDITIONS=4
NRUNS=4

matlab -nojvm -nodisplay -nosplash -r "dataPath = genpath('$DATADIR'); addpath(dataPath); run_MVPA('$SUBJ','$DATADIR','$TOOLBOXDIR',$CONDITIONS,$NRUNS);"

