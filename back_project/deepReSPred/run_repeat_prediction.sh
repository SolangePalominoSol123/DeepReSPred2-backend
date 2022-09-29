#!/bin/bash

# DeepReSPred
# Prediction algorithm of tertiaty structure of repeat proteins from diferent input types. This algorithm uses DMPFold algorithm uses as a base and adapt it to the repeat-protein families. 
# DeepReSPred just need as an input any PFAM code of a repet protein family or any protein sequence in a fasta file to start the prediction.

# DMPFold original script by David T. Jones, June 2018
# Copyright (C) 2018 University College London
# License: GPLv3

# DeepReSPred (DMPFold adapted) original script by Solange Palomino, July 2021
# Copyright (C) 2021 Pontificia Universidad Católica del Perú


echo "---------------------------Start------------------------------"


# Set this to point to the DMPfold directory
dmpfolddir=/home/algPrograms/DMPfold
deeprespreddir=/home/back_project/deepReSPred



if [ "$#" -lt 1 ]; then
    echo "Usage: run_repeat_prediction.sh (PFAMCODE|filename.fasta) [outputDir]"
    exit 1
fi

pfamCode=$1
echo "Prediction preprocessing of" $pfamCode


dirAux="$( pwd )"
if [ "$#" -gt 1 ]; then
    dirAux=$2
fi

dirFlags=$dirAux/flagsEnding

echo "Results directory: " $dirAux
echo ""

#START TIMER
inicio_ns_General=`date +%s%N`
inicio_General=`date +%s`
echo "Started in (ns):" $inicio_ns_General

#Generate all files according to defined modifications
#All files will be generated in $dirAux/target directory p.j. python3 MappingFasta.py default target4/
python3 $deeprespreddir/MappingFasta.py $pfamCode $dirAux
#python3 MappingFasta.py default $dirAux 

echo ""
echo "---------------GENERATING INTERMEDIATE FILES---------------"
echo ""

counter=0

#Use all files ***.fasta to generate middle files .map y .21c

for file in $dirAux/target/*.fasta; do 
        mkdir -p $dirAux/results/test_seq$counter
        nameExtFileIs=$(basename $file)
        cp $file $dirAux/results/test_seq$counter
        cd $dirAux/results/test_seq$counter
        echo "--- generating intermediate files target File:"$nameExtFileIs
        csh $dmpfolddir/seq2maps.csh $file
        counter=$((counter+1))
done

if [ $counter -eq 0 ]; then
    echo "run_repeat_prediction.sh::: No fasta files founded."
    echo "-------------------"
    exit 1
fi

echo ""
echo ""

#:''
echo ""
echo "---------------EXECUTING DMPFOLD ALGORITHM---------------"
echo ""


nTests=0

for directory in $dirAux/results/test*; do
    echo "----Prediction n°" $nTests
	rm $directory/*.temp.fasta
    find . -type f -not \( -name '*map' -or -name '*fasta' -or -name '*.21c' -or -name 'final_*' \) -delete
    echo $directory/*.fasta
    sh $deeprespreddir/run_dmpfold.sh $directory/*.fasta $directory/*.21c $directory/*.map $directory/output $dirFlags

    nTests=$((nTests+1)) 
done


echo ""
echo ""
echo "-------------------End------------------"
echo "N° Tests:" $nTests

#END TIMER
fin_ns_General=`date +%s%N`
fin_General=`date +%s`
echo "End of general predictions in (ns):" $fin_ns_General


total_ns_General=$(($fin_ns_General-$inicio_ns_General))
total_General=$(($fin_General-$inicio_General))
echo "It has last: -$total_ns_General- nanoseconds, -$total_General- seconds"