
# Kaldi DNN-HMM Speech Recognition
This repository contains a simple recipe for training a hybrid DNN-HMM (Deep Neural Network - Hidden Markov Model) speech recognition model using [Kaldi](https://github.com/kaldi-asr/kaldi).


## Prerequisites
### 1. Installing Kaldi
Follow the [Kaldi installation guide](https://github.com/kaldi-asr/kaldi/blob/master/INSTALL) to set up Kaldi. After installing Kaldi, replace `run.sh` with the one available in `egs/librispeech` recipe. 

### 2. Dataset Metadata
Before using this recipe, you need to prepare two metadata files: `dataset/train.txt` and `dataset/test.txt`. Each line in these files should contain a tab-separated list of metadata for a specific training example:
```txt
file_id    utt_id    spk_id    start    end    path/to/file.wav    transcription
```
It is assumed that each training file may contain multiple utterances. Therefore, `start` and `end` refer to the start and end times of each utterance, in seconds, respectively.

### 3. Lexicon
A lexicon is a dictionary that maps each word in the dataset to its corresponding phonetic transcription, detailing how each word is pronounced using smaller linguistic units called phonemes. Each line of dataset/`lexicon.txt` maps a word from your dataset to a space-separated list of its phonetic representation. The file `lexicon.txt.example` contains an example subset of a Persian lexicon.
```txt
word1 p1 p2 p3
word2 p5 p1 p2 p4
...
```

### 3. Language Model
A language model in `.arpa` format is required, which can be created using the [KenLM](https://github.com/kpu/kenlm) toolkit.


## Pipeline Overview
The following steps are included in the training pipeline:
1. Dataset preparation (stage 1-2)
2. MFCC feature extraction (stage 3)
3. Training a context-independent (monophone) HMM (stage 4)
4. Aligning monophone states to training samples (stage 5)
5. Training a context-dependent (triphone) HMM (stage 5)
6. Extracting mel features (stage 6)
7. Aligning triphone states to training samples (stage 7)
8. Training a hybrid DNN-HMM model (stage 7)


## Usage
Run certain stages of the recipe:
```sh
./run.sh 1 3 # stage=1 stop_stage=3
```

## Results
The models were trained on a Persian dataset containing approximately 40 hours of speech data, and the trained language model was a bigram.
<div align="center">

| Model                        | WER (%) |
|------------------------------|---------|
| Context-independent HMM      | 56.44   |
| Context-dependent HMM        | 33.30   |
| Hybrid DNN-HMM               | 26.56   |

</div>