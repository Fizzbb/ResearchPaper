# Unsupervised Root-Cause Analysis for Integrated Systems

**Abstract**

The increasing complexity and high cost of integrated systems has placed immense pressure on root-cause analysis and diagnosis. In light of artificial intelligent and machine learning, a large amount of intelligent root-cause analysis methods have been proposed. However, most of them need historical test data with root-cause labels from repair history, which are often difficult and expensive to obtain. In this paper, we propose a two-stage unsupervised root-cause analysis method in which no repair history is needed. In the first stage, a decision-tree model is trained with system test information to roughly cluster the data. In the second stage, frequent-pattern mining is applied to extract frequent patterns in each decision-tree node to precisely cluster the data so that each cluster represents only a small number of root causes. In additional, L-method and cross validation are applied to automatically determine the hyper-parameters of our algorithm. Two industry case studies with system test data demonstrate that the proposed approach significantly outperforms the state-of-the-art unsupervised root-cause analysis method.

<img src="https://github.com/Fizzbb/ResearchPaper/blob/master/Two-Stage-Clustering/images/flow.png" width="600" height="400">
Fig 1. Decision Tree + Frequent Pattern Mining, Two-stage clustering automatically extracts patterns from different failures.


**Takeaways**

Label is not necessary for classification. Clustered syndromes can represent different classes. The goal is not to identify the name of the class, but to identify the class. 
