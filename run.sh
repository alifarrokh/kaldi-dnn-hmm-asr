#!/bin/bash
# Copyright (c) 2024 Seyed Ali Farokh

stage=-1

# =============================================
# Configuration
# =============================================
# Kaldi params
kaldi_root="../../"
kaldi_cmd=utils/run.pl
n_jobs=10

# Dataset
train_list=dataset/train.txt # tab-separated train metadata
test_list=dataset/test.txt # tab-separated test metadata
lexicon_path=dataset/lexicon.txt
lm_arpa_path=dataset/fa-lm.arpa

# Script artifacts
raw_lang_dir=data/raw/lang # initial language files generated by this script
lang_dir=data/lang # language files generated by Kaldi
train_dir=data/train # train metadata will be stored here
test_dir=data/test # test metadata will be stored here
exps_dir=exp # models, logs, etc. will be stored here
feats_mfcc_dir=mfcc # extracted MFCC features will be stored here


# =============================================
# [STAGE 1] Prepare Language Files
# =============================================
if [ ${stage} -le 1 ] && [ ${stop_stage} -ge 1 ]; then
    echo "[STAGE 1] Preparing language files ..."
    mkdir -p $raw_lang_dir

    # Add special symbols to lexicon
    echo "<SIL> SIL" > $raw_lang_dir/lexicon.txt
    echo "<OOV> OOV" >> $raw_lang_dir/lexicon.txt
    cat $lexicon_path >> $raw_lang_dir/lexicon.txt

    # Create nonsilence_phones.txt, silence_phones.txt, and optional_silence.txt
    awk '{$1=""; sub(/^ /, ""); for (i=1; i<=NF; i++) print $i}' $lexicon_path \
        | sort -u \
        > $raw_lang_dir/nonsilence_phones.txt
    echo -e "SIL\nOOV" > $raw_lang_dir/silence_phones.txt
    echo "SIL" > $raw_lang_dir/optional_silence.txt

    # Generate Kaldi's language files
    utils/prepare_lang.sh $raw_lang_dir "<OOV>" $raw_lang_dir/tmp $lang_dir

    # Generate language model G.fst file
    $kaldi_root/src/lmbin/arpa2fst --disambig-symbol=#0 --max-arpa-warnings=0 \
        --read-symbol-table=$lang_dir/words.txt $lm_arpa_path $lang_dir/G.fst
fi


# =============================================
# [STAGE 2] Prepare Dataset
# =============================================
if [ ${stage} -le 2 ] && [ ${stop_stage} -ge 2 ]; then
    echo "[STAGE 1] Preparing dataset subsets ..."
    mkdir -p $train_dir $test_dir

    # Train subset
    cut -f 2,7 $train_list | tr "\t" " " > $train_dir/text # utt_id transcript
    cut -f 2,3 $train_list | tr "\t" " " > $train_dir/utt2spk # utt_id speaker_id
    cut -f 1,6 $train_list | tr "\t" " " > $train_dir/wav.scp # file_id wav_path
    cut -f 1,2,4,5 $train_list | awk '{temp=$1; $1=$2; $2=temp; print}' > $train_dir/segments # utt_id file_id start end
    utils/utt2spk_to_spk2utt.pl $train_dir/utt2spk > $train_dir/spk2utt
    utils/fix_data_dir.sh $train_dir

    # Train subset
    cut -f 2,7 $test_list | tr "\t" " " > $test_dir/text # utt_id transcript
    cut -f 2,3 $test_list | tr "\t" " " > $test_dir/utt2spk # utt_id speaker_id
    cut -f 1,6 $test_list | tr "\t" " " > $test_dir/wav.scp # file_id wav_path
    cut -f 1,2,4,5 $test_list | awk '{temp=$1; $1=$2; $2=temp; print}' > $test_dir/segments # utt_id file_id start end
    utils/utt2spk_to_spk2utt.pl $test_dir/utt2spk > $test_dir/spk2utt
    utils/fix_data_dir.sh $test_dir
fi


# =============================================
# [STAGE 3] Feature Extraction (MFCC)
# =============================================
if [ ${stage} -le 3 ] && [ ${stop_stage} -ge 3 ]; then
    echo "[STAGE 1] Extracting MFCC features ..."
    mkdir -p $feats_mfcc_dir/train $feats_mfcc_dir/test

    steps/make_mfcc.sh --cmd $kaldi_cmd --nj $n_jobs $train_dir $exps_dir/make_mfcc/data/train $feats_mfcc_dir
    steps/make_mfcc.sh --cmd $kaldi_cmd --nj $n_jobs $test_dir $exps_dir/make_mfcc/data/test $feats_mfcc_dir

    steps/compute_cmvn_stats.sh $train_dir $exps_dir/make_mfcc/data/train $feats_mfcc_dir
    steps/compute_cmvn_stats.sh $test_dir $exps_dir/make_mfcc/data/test $feats_mfcc_dir
fi
