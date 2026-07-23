import 'package:flutter/material.dart';
import 'package:heal_setlog/core/extensions/build_context_x.dart';
import 'package:heal_setlog/core/theme/app_theme.dart';
import 'package:heal_setlog/core/theme/app_tokens.dart';
import 'package:heal_setlog/features/party/presentation/models/party_view_data.dart';

/// 로컬 상태로만 채팅 버블을 추가하는 목업 패널이다.
class PartyChatPanel extends StatefulWidget {
  /// 파티 채팅 패널을 생성한다.
  const PartyChatPanel({super.key});

  @override
  State<PartyChatPanel> createState() => _PartyChatPanelState();
}

class _PartyChatPanelState extends State<PartyChatPanel> {
  final TextEditingController _controller = TextEditingController();
  final List<PartyChatViewData> _messages = List<PartyChatViewData>.of(
    initialPartyChatViewData,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _send() {
    final message = _controller.text.trim();
    if (message.isEmpty) return;
    setState(() {
      _messages.add(
        PartyChatViewData(author: '나', message: message, isMine: true),
      );
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.xl),
            itemCount: _messages.length,
            itemBuilder: (BuildContext context, int index) {
              final chat = _messages[index];
              return Align(
                alignment: chat.isMine
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: chat.isMine
                        ? context.tokens.brandDim
                        : context.tokens.surface,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (!chat.isMine)
                        Text(
                          chat.author,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      Text(chat.message),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.sm,
              AppSpacing.xl,
              AppSpacing.md,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (_) => _send(),
                    decoration: InputDecoration(
                      hintText: context.l10n.partyChatHint,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: context.l10n.partySend,
                  onPressed: _send,
                  icon: const Icon(Icons.send_rounded),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
