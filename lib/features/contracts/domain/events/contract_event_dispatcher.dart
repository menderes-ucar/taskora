import 'dart:async';

import 'contract_event.dart';

typedef ContractEventListener =
Future<void> Function(ContractEvent event);

class ContractEventDispatcher {
  final Set<ContractEventListener> _listeners =
  <ContractEventListener>{};

  bool _dispatching = false;

  void register(ContractEventListener listener) {
    _listeners.add(listener);
  }

  void unregister(ContractEventListener listener) {
    _listeners.remove(listener);
  }

  Future<void> dispatch(ContractEvent event) async {
    // Snapshot the listeners so a listener can register/unregister itself
    // without modifying the collection currently being iterated.
    final listeners = List<ContractEventListener>.of(_listeners);

    if (listeners.isEmpty) return;

    // Keep event ordering deterministic. Contract events can represent
    // financial/workflow state changes, so listeners are intentionally
    // awaited one by one instead of being fired in an uncontrolled race.
    _dispatching = true;

    try {
      for (final listener in listeners) {
        // A listener may have been unregistered after the snapshot was taken.
        // Do not invoke it if it is no longer active.
        if (!_listeners.contains(listener)) {
          continue;
        }

        await listener(event);
      }
    } finally {
      _dispatching = false;
    }
  }

  bool get hasListeners => _listeners.isNotEmpty;

  int get listenerCount => _listeners.length;

  bool get isDispatching => _dispatching;
}
