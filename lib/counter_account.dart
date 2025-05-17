import 'package:borsh_annotation/borsh_annotation.dart';

part 'counter_account.g.dart';

@BorshSerializable()
class CounterAccount {
  @BorshField()
  final int count;

  factory CounterAccount({required int count}) => CounterAccount._(count);

  CounterAccount._(this.count);

  factory CounterAccount.fromBorsh(List<int> data) =>
      CounterAccount(count: BInt32().read(data).value.toInt());
}
