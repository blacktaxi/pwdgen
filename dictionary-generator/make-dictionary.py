#!python
"""Reads the WordNet database and spits it out as a dictionary of synsets without properties (just lemma names)."""
import nltk
from nltk.corpus import wordnet
print 'DICTIONARY =', repr(
    { pos: [lemma.name
        for synset in wordnet.all_synsets(pos=getattr(wordnet, pos))
        for lemma in synset.lemmas]
        for pos in ['NOUN', 'VERB', 'ADJ', 'ADV'] })