class GangPoll {
  GangPoll(Map<String, dynamic> data)
    : options = List<String>.from(data['options']),
      buckets = List.generate(5, (i) => List<String>.from(data['v$i'])),
      closed = data['status'] == 'CLOSED',
      winner = data['winner'] as int;
  final List<String> options;
  final List<List<String>> buckets;
  final bool closed;
  final int winner;
  int get total => buckets.fold(0, (sum, voters) => sum + voters.length);
  int? choice(String uid) {
    for (var i = 0; i < options.length; i++) {
      if (buckets[i].contains(uid)) return i;
    }
    return null;
  }

  List<int> get leaders {
    final highest = buckets.fold(0, (n, v) => v.length > n ? v.length : n);
    return [
      for (var i = 0; i < options.length; i++)
        if (buckets[i].length == highest && highest > 0) i,
    ];
  }
}
