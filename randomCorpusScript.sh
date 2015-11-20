#!/bin/bash
#The MIT License (MIT)
#
#Copyright (c) 2015 Hayda Almeida
#
#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in all
#copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
#SOFTWARE.
#
# script to perform random sampling and
# discriminate files to generate triage corpora
#
#
# Purpose: gather paths of corpus root and corpus src
# root --> parent folder, where train and test folders will be created
# src --> folder with all .XML files
#
paths(){
  echo ""
  read -p "Source files [path]: " CORPUS_SOURCE
  read -p "Positive instances [path]: " CORPUS_POSITIVE
  CORPUS_ROOT=${CORPUS_SOURCE%/*}
  echo ""
  echo "=============================================================="
  echo "============= Corpus root: " $CORPUS_ROOT
  echo "=========== Corpus source: " $CORPUS_SOURCE
  echo "====== Positive instances: " $CORPUS_POSITIVE
  echo "=============================================================="
  echo ""
  read -p "Are the directories correct? [Y/n] " PATHCONF
  echo ""
}

#
# Purpose: copies only .XML files from negative/positive 
# folders, avoiding duplicate files 
# 
copyXML(){
  for dir in $CORPUS_SOURCE/*/
    do
     thisDir=`basename ${dir}`
    if [ $thisDir = `basename ${CORPUS_POSITIVE}` ]
     then cp $dir/*.xml $POSITIVES
     echo "Positive files from $thisDir copied to $POSITIVES"
    else
     cp $dir/*.xml $NEGATIVES
     echo "Negative files from $thisDir copied to $NEGATIVES"
    fi
  done
}

#
# Purpose: prompt and define balance and size of test corpus
#
balanceTest(){
  echo ""
  read -p "Size of TEST corpus: " TEST_SIZE
  read -p "TEST - Positive instances [%]: " TEST_POS_RATIO
  TEST_POS_AMOUNT=$(( (( $TEST_SIZE * $TEST_POS_RATIO )) /100))
  TEST_NEG_AMOUNT=$(( $TEST_SIZE - $TEST_POS_AMOUNT ))
  echo ""
  echo "==============================================================="
  echo "========== Test corpus size: " $TEST_SIZE
  echo "=== Test positive instances: " $TEST_POS_AMOUNT
  echo "=== Test negative instances: " $TEST_NEG_AMOUNT
  echo "==============================================================="
  echo ""
  read -p "Are the size and balance correct? [Y/n] " BTESTCONF
 echo ""
}

#
# Purpose: perform random sampling, and moves selected 
# files from positive/negative to test_folder
#
moveTestFiles(){

  mkdir -p $CORPUS_ROOT/test
  TEST_FOLDER=$CORPUS_ROOT/test

  # number of negative instances in all families
  TEST_NEG_TOTAL=$(find /$NEGATIVES -name '*.xml' | wc -l)
   
       cd $NEGATIVES
       mv $(ls | shuf -n$TEST_NEG_AMOUNT) $TEST_FOLDER
       echo "Moved " $TEST_NEG_AMOUNT " from " `basename ${NEGATIVES}` " to " $TEST_FOLDER 
       cd

# random positives, move it to test folder
     cd $POSITIVES    
     mv $(ls | shuf -n$TEST_POS_AMOUNT) $TEST_FOLDER
     echo "Moved " $TEST_POS_AMOUNT " from " `basename ${POSITIVES}` " to " $TEST_FOLDER
     cd
}

#
# Purpose: prompt balance and size of train corpus
#
balanceTrain(){
  echo ""
  echo ""
  read -p "Initial size of TRAIN corpus: " TRAIN_IN_SIZE
  read -p "Initial Positive instances [%]: " TRAIN_POS_RATIO
  read -p "Sampling factor [%]: " SAMP_FACTOR
  read -p "Number of corpora [0 if no sampling]: " NUMBER_CORP

  # calculating positive ratios
  posPerc=( $( seq $(( $TRAIN_POS_RATIO - (( $SAMP_FACTOR * $NUMBER_CORP )) )) $SAMP_FACTOR $TRAIN_POS_RATIO ) )

  TRAIN_POS_AMOUNT=$(( (($TRAIN_IN_SIZE*$TRAIN_POS_RATIO)) / 100 ))

  # predicting corpora sizes
  declare -A corpSize
   for ((i = 0; i < ${#posPerc[@]}; i++ ))
    do
     corpSize[$i]=$(( (($TRAIN_POS_AMOUNT*100))/ ${posPerc[$i]} ))  
   done

  echo "==============================================================="
  echo "==== Train corpora to generate [#]: " ${#posPerc[@]}
  echo "====== Train positive instances[#]: " $TRAIN_POS_AMOUNT
  echo "===== Train positive instances [%]: " ${posPerc[@]}
  echo "===== Train corpora sizes [approx]: " ${corpSize[@]}
  echo "==============================================================="
  echo ""
  read -p "Continue with these parameters? [Y/n] " BTRAINCONF
  echo ""
}

#
# Purpose: random sampling, copy it from positive/negative to train_folder
#
copyTrainFiles(){
  for ((i = 0; i < ${#posPerc[@]}; i++ ))
    do
     negPerc=$((100 - ${posPerc[$i]}))
     mkdir -p $CORPUS_ROOT/train_${posPerc[$i]}_$negPerc
     TRAIN_FOLDER=$CORPUS_ROOT/train_${posPerc[$i]}_$negPerc
     TRAIN_SIZE=$(( (($TRAIN_POS_AMOUNT*100))/ ${posPerc[$i]} ))

     # negatives for this training set
     TRAIN_NEG_AMOUNT=$(( (( $negPerc * $TRAIN_POS_AMOUNT )) / ${posPerc[$i]} ))

    # random positives, copy it to train folder
         cd $POSITIVES
         cp $(ls | shuf -n$TRAIN_POS_AMOUNT) $TRAIN_FOLDER
         echo "Copied " $TRAIN_POS_AMOUNT " from " `basename ${POSITIVES}` " to " `basename ${TRAIN_FOLDER}` "."
         cd
    # random negatives, copy it to train folder
         cd $NEGATIVES
         cp $(ls | shuf -n$TRAIN_NEG_AMOUNT) $TRAIN_FOLDER
         echo "Copied " $TRAIN_NEG_AMOUNT " from " `basename ${NEGATIVES}` " to " `basename ${TRAIN_FOLDER}` "."
         cd
  done
}

#########################
### Main script order ###
#########################
# gather paths until user confirms the paths are correct
 paths
 while [ "$PATHCONF" != "Y" ]; do
 paths
 done

# creating folders for positive and negative files
 mkdir $CORPUS_ROOT/negatives
 NEGATIVES=$CORPUS_ROOT/negatives
 mkdir $CORPUS_ROOT/positives
 POSITIVES=$CORPUS_ROOT/positives

# copying only XML files - leaving duplicates behind
 copyXML

 balanceTest
 while [ "$BTESTCONF" != "Y" ]; do
 balanceTest
 done

 moveTestFiles

 balanceTrain
 while [ "$BTRAINCONF" != "Y" ]; do
 balanceTrain
 done

 copyTrainFiles

##########################



