#!/usr/bin/env python3
"""Spell- and grammar-check the user-facing strings in lib/l10n/*.arb.

Checks only what this branch changed by default, which is what makes it usable
as a pre-commit step; `--all` sweeps every string in every file.

What differs per application — its files and their languages, the rules its own
copy overrules, the product names and jargon no dictionary has — lives in
`tool/l10n_language.toml` in the application (`--config` points elsewhere).
Run as `dart run app_guards:l10n_language`.

The endpoint is `LANGUAGETOOL_URL`, defaulting to the public API. Point it at a
self-hosted instance to avoid the public rate limit (20 requests/minute) and to
keep the app's copy off a third party's server:

    LANGUAGETOOL_URL=https://languagetool.example.com/v2/check just l10n-check

What it will and will not find: spelling, agreement and punctuation. It will
not find a phrase that is grammatical and still wrong — "Wysyłek jednocześnie"
parses fine and means nothing, and a sentence stating an invented fact is not a
language error at all. Read the copy as well as running this.
"""
import argparse
import json
import os
import re
import subprocess
import sys
import tomllib
import urllib.parse
import urllib.request

ENDPOINT = os.environ.get(
    'LANGUAGETOOL_URL', 'https://api.languagetool.org/v2/check'
)

# Filled from the application's configuration by `load_config`.
FILES: tuple[tuple[str, str, str], ...] = ()
IGNORED_RULES: set[str] = set()
KNOWN_LOWER: set[str] = set()
PLACEHOLDER_VALUES: dict[str, str] = {}
DEFAULT_BASE = 'dev'


def load_config(path: str) -> None:
    """The application's half: see the `tool/l10n_language.toml` files."""
    global FILES, IGNORED_RULES, KNOWN_LOWER, PLACEHOLDER_VALUES, DEFAULT_BASE
    with open(path, 'rb') as f:
        config = tomllib.load(f)
    FILES = tuple(
        (entry['path'], entry['language'], entry.get('arm', 'other'))
        for entry in config['files']
    )
    IGNORED_RULES = set(config.get('ignored_rules', []))
    KNOWN_LOWER = {word.lower() for word in config.get('known_words', [])}
    PLACEHOLDER_VALUES = dict(config.get('placeholder_values', {}))
    DEFAULT_BASE = config.get('base', DEFAULT_BASE)


# Rules that judge a sentence against the ones before it. Unrelated labels are
# submitted as one text — a button caption does not follow the dialog title
# above it in the file — so "three sentences in a row start the same way" is an
# artefact of the batching, not of the copy.
IGNORED_RULE_PREFIXES = (
    'ENGLISH_WORD_REPEAT_BEGINNING',
    'EN_REPEATEDWORDS',
    'PL_WORD_REPEAT',
    'DE_WORD_REPEAT',
    'GERMAN_WORD_REPEAT_BEGINNING',
    'ES_WORD_REPEAT',
    'ES_REPEATEDWORDS',
    'SPANISH_WORD_REPEAT_BEGINNING',
    'FR_WORD_REPEAT',
    'FR_REPEATEDWORDS',
    'FRENCH_WORD_REPEAT_BEGINNING',
    'REP_',
)

# ICU placeholders, replaced so the checker sees a sentence rather than braces.
PLACEHOLDER = re.compile(r'\{(\w+)\}')

# What an unnamed placeholder becomes. A numeral rather than a letter: half of
# these count something, and Polish numeral agreement ("5 szpul") is a rule the
# checker should be able to judge instead of choking on an "X".
PLACEHOLDER_DEFAULT = '5'


def _balanced(text: str, opening: int) -> int:
    """Index of the brace closing the one at [opening]."""
    depth = 0
    for i in range(opening, len(text)):
        depth += {'{': 1, '}': -1}.get(text[i], 0)
        if depth == 0:
            return i
    return len(text) - 1


def resolve_placeholders(text: str, arm: str = 'other') -> str:
    """A plural collapses to one arm; LT cannot parse the ICU syntax.

    [arm] is the one whose wording agrees with [PLACEHOLDER_DEFAULT]. Polish
    puts 5 in `many` while `other` is for fractions, so collapsing every
    language to `other` produced a numeral disagreeing with its own noun.

    The braces are counted rather than split on. Both ends matter: the opening
    one is found by walking back from `, plural,` because a plain placeholder
    may sit ahead of the plural, and the closing one by matching, because an
    arm is followed by the arms after it.
    """
    while ', plural,' in text:
        opening = text.rindex('{', 0, text.index(', plural,'))
        closing = _balanced(text, opening)
        block = text[opening:closing + 1]
        marker = f'{arm}{{' if f'{arm}{{' in block else 'other{'
        chosen = block.index(marker) + len(marker) - 1
        text = (
            text[:opening]
            + block[chosen + 1:_balanced(block, chosen)]
            + text[closing + 1:]
        )
    return PLACEHOLDER.sub(
        lambda m: PLACEHOLDER_VALUES.get(m.group(1), PLACEHOLDER_DEFAULT), text
    )


def strings(path: str, arm: str) -> dict[str, str]:
    with open(path, encoding='utf-8') as f:
        data = json.load(f)
    return {
        key: resolve_placeholders(value, arm)
        for key, value in data.items()
        if not key.startswith('@') and isinstance(value, str)
    }


def strings_at(ref: str, path: str, arm: str) -> dict[str, str]:
    """The same file as of [ref], or empty when it is not there."""
    shown = subprocess.run(
        ['git', 'show', f'{ref}:{path}'], capture_output=True, text=True
    )
    if shown.returncode != 0:
        return {}
    return {
        key: resolve_placeholders(value, arm)
        for key, value in json.loads(shown.stdout).items()
        if not key.startswith('@') and isinstance(value, str)
    }


def check(text: str, language: str) -> dict:
    body = urllib.parse.urlencode(
        {'text': text, 'language': language, 'level': 'picky'}
    ).encode()
    request = urllib.request.Request(
        ENDPOINT,
        data=body,
        # Some instances sit behind a filter that refuses urllib's own agent.
        headers={'User-Agent': 'curl/8', 'Accept': 'application/json'},
    )
    with urllib.request.urlopen(request, timeout=90) as response:
        return json.load(response)


SEPARATOR = '\n\n'


def batched(
    entries: list[tuple[str, str]], limit: int = 12000
) -> list[tuple[str, list[tuple[int, str]]]]:
    """Batches under the API's per-request text limit, each with an index of
    where every string starts, so a finding can name the key it is in."""
    batches: list[tuple[str, list[tuple[int, str]]]] = []
    current: list[str] = []
    index: list[tuple[int, str]] = []
    size = 0
    for key, text in entries:
        if size + len(text) > limit and current:
            batches.append((SEPARATOR.join(current), index))
            current, index, size = [], [], 0
        index.append((size, key))
        current.append(text)
        size += len(text) + len(SEPARATOR)
    if current:
        batches.append((SEPARATOR.join(current), index))
    return batches


def key_at(index: list[tuple[int, str]], offset: int) -> str:
    """The .arb key the finding at [offset] belongs to."""
    found = index[0][1]
    for start, key in index:
        if start > offset:
            break
        found = key
    return found


def interesting(match: dict) -> bool:
    context = match['context']
    word = context['text'][context['offset']:context['offset'] + context['length']]
    rule = match['rule']['id']
    if rule in IGNORED_RULES or rule.startswith(IGNORED_RULE_PREFIXES):
        return False
    # Case-insensitively: a term is the same term at the start of a sentence or
    # on a button as it is mid-phrase, and listing both spellings of every one
    # of them is how the list goes stale.
    if word.lower() in KNOWN_LOWER:
        return False
    if (
        rule.startswith(('MORFOLOGIK', 'GERMAN_SPELLER', 'FRENCH_SPELLER', 'SPANISH_SPELLER', 'FR_SPELLING_RULE'))
        or rule.endswith('_SPELLER_RULE')
        or 'SPELLER' in rule
    ):
        # The dictionary rule also fires on identifiers, units and product
        # names, which is what the configuration's `known_words` are for:
        # a word that is not in either and is a plain lowercase run of letters
        # is a typo, in both languages.
        #
        # This used to add `and not word.isascii()`, meaning to keep the
        # Polish file quiet about the English terms it quotes. Every English
        # word is ASCII, so on `app_en.arb` it switched spelling off outright
        # — `sorce`, `fille` and `cannnot` all came back clean — and on the
        # Polish side it lost every typo written without its diacritics.
        #
        # Title case counts as a word: it is how every sentence and every
        # button label starts, so leaving it out hid a typo in the most
        # prominent copy in the app. All caps still does not — that is the
        # acronyms (`AMS`, `HMS`, `FTP`), where a dictionary has no opinion.
        #
        # Per token, because the rule reports a compound suggestion across the
        # words it spans: a misspelt first word comes back as "Thiss print",
        # and asking whether *that* is alphabetic drops it on the space.
        tokens = word.split()
        return bool(tokens) and all(
            token.isalpha() and (token.islower() or token.istitle())
            for token in tokens
        )
    return True


def report(match: dict, key: str) -> str:
    context = match['context']
    word = context['text'][context['offset']:context['offset'] + context['length']]
    suggestions = [r['value'] for r in match['replacements'][:3]]
    return (
        f"  {key}  [{match['rule']['id']}]\n"
        f"      {word!r} -> {suggestions}\n"
        f"      {match['message']}\n"
        f"      ...{context['text'].strip()}..."
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        '--config',
        default='tool/l10n_language.toml',
        help='the application\'s configuration (default: tool/l10n_language.toml)',
    )
    parser.add_argument(
        '--base',
        help='git ref to diff against (default: the configuration\'s `base`)',
    )
    parser.add_argument(
        '--all',
        action='store_true',
        help='check every string, not only the ones this branch changed',
    )
    parser.add_argument(
        '--lang',
        help='comma-separated list of languages to check (e.g. de, fr, es, pl, en)',
    )
    args = parser.parse_args()
    load_config(args.config)
    base = args.base or DEFAULT_BASE

    files_to_check: list[tuple[str, str, str]] = []
    for path, language, arm in FILES:
        lang_code = os.path.basename(path).replace('app_', '').replace('.arb', '')
        if args.lang:
            targets = [t.strip().lower() for t in args.lang.split(',')]
            if lang_code not in targets and language.lower() not in targets:
                continue
            if not os.path.exists(path):
                print(f"Warning: {path} not found on disk, skipping.", file=sys.stderr)
                continue
        else:
            if not os.path.exists(path):
                continue
        files_to_check.append((path, language, arm))

    if not files_to_check:
        print('No translation files found to check.')
        return 0

    findings = 0
    for path, language, arm in files_to_check:
        current = strings(path, arm)
        if args.all:
            entries = list(current.items())
            scope = f'{len(entries)} strings'
        else:
            previous = strings_at(base, path, arm)
            entries = [(k, v) for k, v in current.items() if previous.get(k) != v]
            scope = f'{len(entries)} changed since {base}'

        print(f'\n=== {path} ({scope}) ===')
        if not entries:
            print('  nothing to check')
            continue

        skipped = 0
        for text, index in batched(entries):
            for match in check(text, language)['matches']:
                if interesting(match):
                    print(report(match, key_at(index, match['offset'])))
                    findings += 1
                else:
                    skipped += 1
        print(f'  known false positives skipped: {skipped}')

    print(f'\n{findings} finding(s) to read.')
    return 1 if findings else 0


if __name__ == '__main__':
    sys.exit(main())
