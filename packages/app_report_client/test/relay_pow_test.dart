import 'dart:convert';

import 'package:app_report_client/app_report_client.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

/// The proof of work, verified the way the relay verifies it.
///
/// A solver that returns a nonce nobody checked is a solver that passes every
/// test and fails every send, so these re-derive the digest rather than trusting
/// the return value.
int leadingZeroBits(List<int> digest) {
  var bits = 0;
  for (final byte in digest) {
    if (byte == 0) {
      bits += 8;
      continue;
    }
    for (var mask = 0x80; mask > 0; mask >>= 1) {
      if (byte & mask != 0) return bits;
      bits++;
    }
    return bits;
  }
  return bits;
}

bool solves(String seed, int bits, String nonce) =>
    leadingZeroBits(sha256.convert(utf8.encode('$seed:$nonce')).bytes) >= bits;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the nonce it returns actually satisfies the challenge', () async {
    // Ten bits is about a thousand attempts — enough that a solver returning a
    // constant cannot pass, cheap enough to run on every CI job.
    const challenge = PowChallenge(seed: 'a3f9c1', bits: 10);

    final nonce = await solvePow(challenge);

    expect(int.tryParse(nonce), isNotNull, reason: 'the relay parses it');
    expect(solves(challenge.seed, challenge.bits, nonce), isTrue);
  });

  test('a different seed needs a different answer', () async {
    // The seed is what stops one solved challenge from paying for every later
    // report; a solver ignoring it would hand back the same nonce.
    const first = PowChallenge(seed: 'seed-one', bits: 10);
    const second = PowChallenge(seed: 'seed-two', bits: 10);

    final a = await solvePow(first);
    final b = await solvePow(second);

    expect(solves(first.seed, 10, a), isTrue);
    expect(solves(second.seed, 10, b), isTrue);
    // Not required to differ — but a nonce solving the wrong seed is the bug
    // this is here for.
    expect(solves(second.seed, 10, a) && solves(first.seed, 10, b), isFalse);
  });

  test('zero bits is satisfied immediately, not by hashing to nothing', () async {
    // What the suites use to avoid paying for hashing. It has to be a real
    // answer, because the relay still checks it.
    const challenge = PowChallenge(seed: 'anything', bits: 0);

    final nonce = await solvePow(challenge);

    expect(solves('anything', 0, nonce), isTrue);
  });

  test('the same challenge solved twice gives an answer that still works',
      () async {
    // A report queued before the app was killed re-solves on the way out; the
    // second answer has to be as good as the first.
    const challenge = PowChallenge(seed: 'restart', bits: 8);

    final first = await solvePow(challenge);
    final second = await solvePow(challenge);

    expect(first, second, reason: 'deterministic search from zero');
    expect(solves('restart', 8, second), isTrue);
  });
}
