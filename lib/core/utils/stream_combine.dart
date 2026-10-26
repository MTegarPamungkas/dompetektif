import 'dart:async';

/// Combines the latest value of several streams.
///
/// Repositories in Dompetektif expose their initial value synchronously, so a
/// combined stream emits as soon as every source has produced at least once.
Stream<R> combineLatest<R>(
  List<Stream<dynamic>> streams,
  R Function(List<dynamic> values) combiner,
) {
  if (streams.isEmpty) {
    throw ArgumentError('combineLatest requires at least one stream');
  }

  return Stream.multi((controller) {
    final values = List<dynamic>.filled(streams.length, null);
    final hasValue = List<bool>.filled(streams.length, false);
    final subscriptions = <StreamSubscription<dynamic>>[];
    var cancelled = false;
    var completed = 0;

    void emitIfReady() {
      if (!cancelled && hasValue.every((value) => value)) {
        controller.add(combiner(List<dynamic>.from(values)));
      }
    }

    for (var index = 0; index < streams.length; index++) {
      final sourceIndex = index;
      subscriptions.add(
        streams[index].listen(
          (value) {
            values[sourceIndex] = value;
            hasValue[sourceIndex] = true;
            emitIfReady();
          },
          onError: controller.addError,
          onDone: () {
            completed++;
            if (completed == streams.length && !cancelled) {
              controller.close();
            }
          },
        ),
      );
    }

    controller.onCancel = () async {
      cancelled = true;
      for (final subscription in subscriptions) {
        await subscription.cancel();
      }
    };
  });
}

Stream<R> combineLatest2<A, B, R>(
  Stream<A> a,
  Stream<B> b,
  R Function(A a, B b) combiner,
) => combineLatest<R>([
  a,
  b,
], (values) => combiner(values[0] as A, values[1] as B));

Stream<R> combineLatest3<A, B, C, R>(
  Stream<A> a,
  Stream<B> b,
  Stream<C> c,
  R Function(A a, B b, C c) combiner,
) => combineLatest<R>([
  a,
  b,
  c,
], (values) => combiner(values[0] as A, values[1] as B, values[2] as C));

Stream<R> combineLatest4<A, B, C, D, R>(
  Stream<A> a,
  Stream<B> b,
  Stream<C> c,
  Stream<D> d,
  R Function(A a, B b, C c, D d) combiner,
) => combineLatest<R>(
  [a, b, c, d],
  (values) =>
      combiner(values[0] as A, values[1] as B, values[2] as C, values[3] as D),
);

Stream<R> combineLatest5<A, B, C, D, E, R>(
  Stream<A> a,
  Stream<B> b,
  Stream<C> c,
  Stream<D> d,
  Stream<E> e,
  R Function(A a, B b, C c, D d, E e) combiner,
) => combineLatest<R>(
  [a, b, c, d, e],
  (values) => combiner(
    values[0] as A,
    values[1] as B,
    values[2] as C,
    values[3] as D,
    values[4] as E,
  ),
);

Stream<R> combineLatest7<A, B, C, D, E, F, G, R>(
  Stream<A> a,
  Stream<B> b,
  Stream<C> c,
  Stream<D> d,
  Stream<E> e,
  Stream<F> f,
  Stream<G> g,
  R Function(A a, B b, C c, D d, E e, F f, G g) combiner,
) => combineLatest<R>(
  [a, b, c, d, e, f, g],
  (values) => combiner(
    values[0] as A,
    values[1] as B,
    values[2] as C,
    values[3] as D,
    values[4] as E,
    values[5] as F,
    values[6] as G,
  ),
);

Stream<R> combineLatest6<A, B, C, D, E, F, R>(
  Stream<A> a,
  Stream<B> b,
  Stream<C> c,
  Stream<D> d,
  Stream<E> e,
  Stream<F> f,
  R Function(A a, B b, C c, D d, E e, F f) combiner,
) => combineLatest<R>(
  [a, b, c, d, e, f],
  (values) => combiner(
    values[0] as A,
    values[1] as B,
    values[2] as C,
    values[3] as D,
    values[4] as E,
    values[5] as F,
  ),
);
