""" main.py is the top level script.

Return "Hello World" at the root URL.
"""

import os
import sys
import re

import random
random.seed()

# sys.path includes 'server/lib' due to appengine_config.py
from flask import Flask, jsonify, request
from flask import render_template
app = Flask(__name__.split('.')[0])

DEFAULT_TEMPLATE = '<adj><noun><00>'
TPL_VAR_RE = re.compile(r'\<(?P<var>.*?)\>')

from words import DICTIONARY

def gen_number(m):
    low = 10 ** (len(m.group(0)) - 1)
    high = low * 10
    return int(low + random.random() * (high - low))

def eval_var(match):
    expr = match.groupdict()['var'].strip()
    gen_map = {
        r'noun': lambda _: random.choice(DICTIONARY['nouns']),
        r'adj': lambda _: random.choice(DICTIONARY['adjectives']),
        r'verb': lambda _: random.choice(DICTIONARY['verbs']),
        r'adv': lambda _: random.choice(DICTIONARY['adverbs']),
        r'(\d+)': gen_number
    }

    for k, v in gen_map.items():
        m = re.match(k, expr)
        if m is not None:
            return str(v(m))
    raise 'Unexpected expression "%s"' % expr

@app.route('/api/1/generate', methods=['GET'])
def generate():
    template = request.args.get('t', request.args.get('template', DEFAULT_TEMPLATE))

    try:
        result = re.sub(TPL_VAR_RE, eval_var, template)
        return jsonify({'password': result, 'template': template})
    except Exception as e:
        return jsonify({'error': repr(e), 'template': template})

@app.route('/')
@app.route('/<name>')
def hello(name=None):
  """ Return hello template at application root URL."""
  return render_template('hello.html', name=name)