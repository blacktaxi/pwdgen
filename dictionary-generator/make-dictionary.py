#!python
"""Reads the WordNet database and spits it out as a dictionary of synsets without properties (just lemma names)."""

import nltk
from nltk.corpus import wordnet
wn = wordnet

import random
random.seed()

nouns = list(wn.all_synsets(pos=wn.NOUN))
verbs = list(wn.all_synsets(pos=wn.VERB))
adjectives = list(wn.all_synsets(pos=wn.ADJ))
adverbs = list(wn.all_synsets(pos=wn.ADV))

print repr(
    {
        t: [l.name for s in globals()[t] for l in s.lemmas] for t in ['nouns', 'verbs', 'adjectives', 'adverbs']
    }
)

#print to_string(gen_from_pattern(adverbs, adjectives, adjectives, nouns))
