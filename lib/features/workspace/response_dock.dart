import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/models/api_request.dart';
import '../../core/models/api_response.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/palette.dart';
import '../../core/theme/tokens.dart';
import '../../core/theme/typography.dart';
import '../../core/util/format.dart';
import '../../core/widgets/app_button.dart';
import '../../core/widgets/chips.dart';
import 'workspace_controller.dart';

/// The dock above the nav: the state of the last send and the Send button.
///
/// Board 2.1 to 2.3 and 13. Send lives here rather than in the URL bar so it is
/// within thumb reach, and the response grows out of it.
class ResponseDock extends StatelessWidget {
  const ResponseDock({
    required this.tab,
    required this.canSend,
    required this.onSend,
    required this.onCancel,
    required this.onExpand,
    super.key,
  });

  final WorkspaceTab tab;
  final bool canSend;
  final VoidCallback onSend;
  final VoidCallback onCancel;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final ApiResponse? response = tab.response;

    // A send that produced nothing takes the danger well and offers a retry,
    // rather than pretending to be a response.
    if (response != null && !response.arrived &&
        response.failure != FailureKind.cancelled) {
      return _FailureDock(response: response, host: tab.draft.host, onRetry: onSend);
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.only(left: Space.screen, right: Space.sm),
      decoration: BoxDecoration(
        color: c.surfaceContainer,
        borderRadius: Radii.dockR,
        border: Border.all(color: c.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: <Widget>[
          if (tab.sending) const Positioned(left: 0, right: 0, top: 0, child: _SendHairline()),
          Row(
            spacing: Space.md,
            children: <Widget>[
              Expanded(
                child: tab.sending
                    ? _SendingLine(startedAt: tab.startedAt, host: tab.draft.host)
                    : response == null
                        ? _IdleLine(canSend: canSend, sentAt: tab.sentAt)
                        : _ResultLine(response: response, onExpand: onExpand),
              ),
              if (tab.sending)
                AppButton(
                  label: 'Cancel',
                  icon: Icons.close_rounded,
                  type: AppButtonType.secondary,
                  onPressed: onCancel,
                )
              else
                AppButton(
                  label: 'Send',
                  icon: Icons.send_rounded,
                  filledIcon: true,
                  onPressed: canSend ? onSend : null,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The 3dp hairline across the top of the dock. It appears only once a request
/// has run past 120 ms, so a fast local call never flashes it.
class _SendHairline extends StatefulWidget {
  const _SendHairline();

  @override
  State<_SendHairline> createState() => _SendHairlineState();
}

class _SendHairlineState extends State<_SendHairline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slide = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  Timer? _grace;
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    _grace = Timer(Motion.sendHairline, () {
      if (!mounted) return;
      setState(() => _shown = true);
      _slide.repeat();
    });
  }

  @override
  void dispose() {
    _grace?.cancel();
    _slide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    if (!_shown) return const SizedBox(height: 3);
    if (Motion.reduced(context)) {
      return Container(height: 3, color: c.primary);
    }
    return SizedBox(
      height: 3,
      child: ColoredBox(
        color: c.primaryContainer,
        child: AnimatedBuilder(
          animation: _slide,
          builder: (BuildContext context, Widget? child) =>
              FractionallySizedBox(
                alignment: Alignment(_slide.value * 2 - 1, 0),
                widthFactor: 0.38,
                child: child,
              ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.primary,
              borderRadius: Radii.fullR,
            ),
          ),
        ),
      ),
    );
  }
}

class _IdleLine extends StatelessWidget {
  const _IdleLine({required this.canSend, required this.sentAt});

  final bool canSend;
  final DateTime? sentAt;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: <Widget>[
        Text(
          'No response yet',
          style: AppType.titleMedium.copyWith(color: c.onSurface),
        ),
        Text(
          canSend
              ? 'last sent · ${sentAt == null ? 'never' : Fmt.relative(sentAt!)}'
              : 'add a URL to send',
          style: AppType.monoLabel.copyWith(color: c.onSurfaceVariant),
        ),
      ],
    );
  }
}

/// `Sending…` with the elapsed time counting up, at ten frames a second: any
/// faster is unreadable, any slower reads as stalled.
class _SendingLine extends StatefulWidget {
  const _SendingLine({required this.startedAt, required this.host});

  final DateTime? startedAt;
  final String host;

  @override
  State<_SendingLine> createState() => _SendingLineState();
}

class _SendingLineState extends State<_SendingLine> {
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(
      const Duration(milliseconds: 100),
      (Timer _) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final int ms = widget.startedAt == null
        ? 0
        : DateTime.now().difference(widget.startedAt!).inMilliseconds;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 2,
      children: <Widget>[
        Text(
          'Sending…',
          style: AppType.titleMedium.copyWith(color: c.onSurface),
        ),
        Text(
          <String>[
            Fmt.elapsed(ms),
            if (widget.host.isNotEmpty) widget.host,
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppType.monoLabel.copyWith(color: c.onSurfaceVariant),
        ),
      ],
    );
  }
}

class _ResultLine extends StatelessWidget {
  const _ResultLine({required this.response, required this.onExpand});

  final ApiResponse response;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final (Color dot, _, Color text) = StatusChip.rolesFor(
      c,
      response.statusCode,
      arrived: response.arrived,
    );
    return InkWell(
      onTap: onExpand,
      child: Row(
        spacing: Space.sm,
        children: <Widget>[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          Flexible(
            child: Text(
              response.statusLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppType.monoTabular.copyWith(
                color: text,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Flexible(
            child: Text(
              '${Fmt.duration(response.durationMs)} · '
              '${Fmt.bytes(response.sizeBytes)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppType.monoLabel.copyWith(color: c.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

/// No response at all: DNS, TLS, a timeout. The whole dock takes the danger
/// well, names what happened, and offers the retry.
class _FailureDock extends StatelessWidget {
  const _FailureDock({
    required this.response,
    required this.host,
    required this.onRetry,
  });

  final ApiResponse response;
  final String host;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppColors c = context.colors;
    final bool timeout = response.failure == FailureKind.timeout;
    final String title = timeout
        ? 'Timed out'
        : host.isEmpty
            ? 'Request failed'
            : "Couldn't reach $host";
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.fromLTRB(Space.lg, Space.sm, Space.sm, Space.sm),
      decoration: BoxDecoration(
        color: c.dangerContainer,
        borderRadius: Radii.dockR,
      ),
      child: Row(
        spacing: Space.md,
        children: <Widget>[
          Icon(
            timeout ? Icons.timer_off_rounded : Icons.wifi_off_rounded,
            size: IconSpec.size,
            color: c.onDangerContainer,
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppType.titleMedium.copyWith(
                    color: c.onDangerContainer,
                  ),
                ),
                Text(
                  '${response.failureDetail} · '
                  '${Fmt.elapsed(response.durationMs)}',
                  maxLines: 2,
                  style: AppType.monoLabel.copyWith(
                    color: c.onDangerContainer,
                  ),
                ),
              ],
            ),
          ),
          Semantics(
            button: true,
            label: 'Retry',
            child: Material(
              color: c.danger,
              shape: const StadiumBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: onRetry,
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Text(
                    'Retry',
                    style: AppType.titleMedium.copyWith(
                      color: const Color(0xFFFFFFFF),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
