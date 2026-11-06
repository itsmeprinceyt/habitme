import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:habit_me/core/logic/providers.dart';
import 'package:habit_me/data/models/label.dart';
import 'package:habit_me/data/repositories/label_repository.dart';

class LabelController extends AsyncNotifier<List<HabitLabel>> {
  LabelRepository get _repo => ref.read(labelRepositoryProvider);

  @override
  Future<List<HabitLabel>> build() async {
    return _repo.getAll();
  }

  Future<void> reload() async {
    state = AsyncData(await _repo.getAll());
  }

  Future<HabitLabel> addLabel(String name, {int? color}) async {
    final label = HabitLabel.create(name: name, color: color);
    await _repo.insert(label);
    state = AsyncData(await _repo.getAll());
    return label;
  }

  Future<void> updateLabel(HabitLabel label) async {
    await _repo.update(label);
    state = AsyncData(await _repo.getAll());
    ref.read(habitControllerProvider.notifier).reconcile();
  }

  Future<void> deleteLabel(String id) async {
    await _repo.delete(id);
    state = AsyncData(await _repo.getAll());
    ref.read(habitControllerProvider.notifier).reconcile();
  }
}
