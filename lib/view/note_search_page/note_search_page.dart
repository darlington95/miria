import 'package:auto_route/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_misskey_app/model/account.dart';
import 'package:flutter_misskey_app/providers.dart';
import 'package:flutter_misskey_app/view/common/account_scope.dart';
import 'package:flutter_misskey_app/view/common/misskey_notes/misskey_note.dart';
import 'package:flutter_misskey_app/view/common/pushable_listview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:misskey_dart/misskey_dart.dart';

final noteSearchProvider = StateProvider.autoDispose((ref) => "");

@RoutePage()
class NoteSearchPage extends ConsumerStatefulWidget {
  final String? initialSearchText;
  final Account account;

  const NoteSearchPage({
    super.key,
    this.initialSearchText,
    required this.account,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => NoteSearchPageState();
}

class NoteSearchPageState extends ConsumerState<NoteSearchPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final initial = widget.initialSearchText;
    if (initial != null) {
      Future(() {
        ref.read(noteSearchProvider.notifier).state = initial;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AccountScope(
        account: widget.account,
        child: Scaffold(
            appBar: AppBar(
              title: Text("ノート検索"),
            ),
            body: Column(
              children: [
                TextField(
                    controller: TextEditingController(
                        text: widget.initialSearchText ?? ""),
                    decoration: const InputDecoration(icon: Icon(Icons.search)),
                    textInputAction: TextInputAction.done,
                    onSubmitted: (value) {
                      ref.read(noteSearchProvider.notifier).state = value;
                    }),
                const Expanded(
                    child: Padding(
                        padding: EdgeInsets.only(left: 10, right: 10),
                        child: NoteSearchList()))
              ],
            )));
  }
}

class NoteSearchList extends ConsumerWidget {
  const NoteSearchList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchValue = ref.watch(noteSearchProvider);
    final account = AccountScope.of(context);

    if (searchValue.isEmpty) {
      return Container();
    }

    return PushableListView(
        listKey: searchValue,
        initializeFuture: () async {
          final notes = await ref
              .read(misskeyProvider(account))
              .notes
              .search(NotesSearchRequest(query: searchValue));
          ref.read(notesProvider(account)).registerAll(notes);
          return notes.toList();
        },
        nextFuture: (lastItem) async {
          final notes = await ref.read(misskeyProvider(account)).notes.search(
              NotesSearchRequest(query: searchValue, untilId: lastItem.id));
          ref.read(notesProvider(account)).registerAll(notes);
          return notes.toList();
        },
        itemBuilder: (context, item) {
          return MisskeyNote(note: item);
        });
  }
}