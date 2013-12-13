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
from flask_sslify import SSLify
app = Flask(__name__.split('.')[0])

# don't use HTTPS locally -- it does not work
if not os.environ.get('SERVER_SOFTWARE', 'w/e').startswith('Development'):
    sslify = SSLify(app)

DEFAULT_TEMPLATE = '<adj><noun><00>'
MAX_PASSWORD_COUNT = 42
TPL_VAR_RE = re.compile(r'\<(?P<var>.*?)\>')

from words import DICTIONARY
ALL_WORDS = [w for _, d in DICTIONARY.items() for w in d]

def gen_number(m):
    low = 10 ** (len(m.group(0)) - 1)
    high = low * 10
    return int(low + random.random() * (high - low))

def gen_word(words):
    return random.choice(words).replace('_', '').replace('-', '')

def eval_var(match):
    expr = match.groupdict()['var'].strip()
    gen_map = {
        r'noun': lambda _: gen_word(DICTIONARY['nouns']),
        r'adj': lambda _: gen_word(DICTIONARY['adjectives']),
        r'verb': lambda _: gen_word(DICTIONARY['verbs']),
        r'adv': lambda _: gen_word(DICTIONARY['adverbs']),
        r'word': lambda _: gen_word(ALL_WORDS),
        r'(\d+)': gen_number
    }

    for k, v in gen_map.items():
        m = re.match(k, expr)
        if m is not None:
            return str(v(m))
    raise Exception('Unexpected expression "%s"' % expr)

@app.route('/api/1/generate', methods=['GET'])
def generate():
    # import time
    # time.sleep(1)
    try:
        template = request.args.get('t', request.args.get('template', DEFAULT_TEMPLATE))
        count = min(int(request.args.get('count', '5')), MAX_PASSWORD_COUNT)

        result = [re.sub(TPL_VAR_RE, eval_var, template) for _ in xrange(count)]
        return jsonify({'passwords': result, 'template': template})
    except Exception as e:
        return jsonify({'error': repr(e)})

@app.route('/')
@app.route('/<password_template>')
def index(password_template=DEFAULT_TEMPLATE):
    password_template = request.args.get('t', password_template)

    return render_template('index.html', **locals())