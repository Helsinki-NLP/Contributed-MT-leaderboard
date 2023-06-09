
# Contributed MT leaderboard

A repository of scores and leaderboard for MT models and benchmarks.

* [model scores for various benchmarks](models)
* [leaderboards per benchmark](scores)
* [recipes for automatic model evaluation](models)
* [merged benchmark translations for better comparison](compare)
* [web-based dashboard](https://github.com/Helsinki-NLP/OPUS-MT-dashboard)


## Leaderboards

The `scores` directory includes leaderboards for each evaluated benchmark in [OPUS-MT-testsets](https://github.com/Helsinki-NLP/OPUS-MT-testsets/). The benchmark-specific leaderboards are stored as plain text files with TAB-separated values using the following file structure:

```
scores/src-trg/benchmark/metric-scores.txt
```

`src` and `trg` correspond to the language pair, `benchmark` is the name of the benchmark and `metric` is the name of evaluation metric such as bleu, chrf or comet. The file names and structure corresponds to the benchmark files in [OPUS-MT-testsets](https://github.com/Helsinki-NLP/OPUS-MT-testsets). 

Furthermore, we also keep lists of the top-scoring models per benchmark for each language pair and a list of model score averages aggregated over selected benchmarks for each language pair. There are separate lists for each evaluation metric. For example, for [German - Ukrainian](scores/deu-ukr), there are score files like

```
scores/deu-ukr/avg-bleu-scores.txt
scores/deu-ukr/avg-chrf-scores.txt
scores/deu-ukr/avg-comet-scores.txt

scores/deu-ukr/top-bleu-scores.txt
scores/deu-ukr/top-chrf-scores.txt
scores/deu-ukr/top-comet-scores.txt
```

Scores for other models than OPUS-MT will be stored in the same way in the sub-directory `external-scores`.


### File Formats

All leaderboard files follow a very simple format with two TAB-separated values and rows sorted by score. The columns are:

* the actual score
* the model name

For example, the BLEU-score leaderboard for the Flores200 devtest benchmark in German-English is stored in [scores/deu-eng/flores200-devtest/bleu-scores.txt](scores/deu-eng/flores200-devtest/bleu-scores.txt) and includes lines like:

```
45.8	facebook/nllb-200-54.5B
```

The best performaning models for each benchmark for a given language pair are listed with the following format: TAB-separated plain text files with 3 columns:

* the name of the benchmark
* the top score among all models
* the name of the top-scoring model

To give an example, the top BLEU score for German-English benchmarks is stored in [scores/deu-eng/top-bleu-scores.txt](scores/deu-eng/top-bleu-scores.txt) with lines like:

```
flores200-devtest	45.8	facebook/nllb-200-54.5B
...
```


To make it easier to compare model performance, we also keep model lists sorted by scores averaged over a selected number of benchmarks. Those files start with a line that list the selected benchmarks used for computing the score and the following lines follow the standard leaderboard file format with TAB-separated values for the (averaged score and the download link of the model. For example, [scores/deu-ukr/avg-bleu-scores.txt](scores/deu-ukr/avg-bleu-scores.txt) starts like this:


```
flores news
22.95	facebook/nllb-200-54.5B
```



## Model Scores


The repository includes recipes for evaluating MT models and scores coming from systematically running MT benchmarks. 
Each sub directory in `models` corresponds to a specific model type and includes tables of automatic evaluation results.



The structure corresponds to the repository of OPUS-MT models with separate tables for different evaluation metrics (like BLEU, chrF and COMET):

```
models/provider/model-release-name.bleu-scores.txt
models/provider/model-release-name.spbleu-scores.txt
models/provider/model-release-name.chrf-scores.txt
models/provider/model-release-name.chrf++-scores.txt
models/provider/model-release-name.comet-scores.txt
```

The `provider` specifies the name of the provider (for example `facebook`). The `model-release-name` corresponds to the release name of the model (for example `nllb-200-54.5B`).

There is also another file that combines BLEU and chrF scores together with some other information about the test set and the model (see further down below).

```
models/provider/model-release-name.scores.txt
```

Additional metrics can be added using the same format replacing `metric` in `model-release-name.metric-scores.txt` with a descriptive unique name of the metric.

Note that chrF scores should for historical reasons be with decimals and not in percentages as they are given by current versions of sacrebleu. This is to match the implementation of the web interface of the OPUS-MT leaderboard.



### File Formats

Each model score file for each specific evaluation metric follows a very simple format: The file is a plain text file with TAB-separated values in three columns specifying

* the language pair of the benchmark (e.g. `eng-rus`)
* the name of the benchmark (e.g. `flores200-devtest`)
* the score

As an example, the English - Russian wmt19 model from facebook [models/facebook/nllb-200-54.5B.bleu-scores.txt](models/facebook/nllb-200-54.5B.bleu-scores.txt) includes the following lines:

```
ace_Arab-ace_Latn	flores200-devtest	6.8
ace_Arab-acm	flores200-devtest	2.5
ace_Arab-acq	flores200-devtest	2.4
ace_Arab-aeb	flores200-devtest	3.3
ace_Arab-afr	flores200-devtest	8.0
...
```


The only file that differs from this general format is the `src-trg/model-release-name.scores.txt` that combines BLEU and chrF scores. In addition to the scores, this file also includes

* the link to the actual model for downloading
* the size of the benchmark in terms of the number of sentences
* the size of the benchmark in terms of the number of tokens

Here is an example from [models/facebook/nllb-200-54.5B.scores.txt](models/facebook/nllb-200-54.5B.scores.txt):

```
ace_Arab-ace_Latn	flores200-devtest	0.36182	6.8	facebook/nllb-200-54.5B	1012	24121
ace_Arab-acm	flores200-devtest	0.2232	2.5	facebook/nllb-200-54.5B	1012	20497
ace_Arab-acq	flores200-devtest	0.21289	2.4	facebook/nllb-200-54.5B	1012	20945
ace_Arab-aeb	flores200-devtest	0.2582	3.3	facebook/nllb-200-54.5B	1012	20498
ace_Arab-afr	flores200-devtest	0.34476	8.0	facebook/nllb-200-54.5B	1012	25740
ace_Arab-ajp	flores200-devtest	0.27019	4.1	facebook/nllb-200-54.5B	1012	20450
ace_Arab-aka	flores200-devtest	0.24491	3.9	facebook/nllb-200-54.5B	1012	29549
ace_Arab-als	flores200-devtest	0.33013	8.8	facebook/nllb-200-54.5B	1012	27783
...
```


# Related work and links

* [MT-ComparEval](https://github.com/ondrejklejch/MT-ComparEval) with live instances for [WMT submissions](http://wmt.ufal.cz/) and [other experiments](http://mt-compareval.ufal.cz/)
* [compare-mt](https://github.com/neulab/compare-mt) - command-line tool for MT output comparison [pip package](https://pypi.org/project/compare-mt/)
* [intento report on the state of MT](https://inten.to/machine-translation-report-2022/)
