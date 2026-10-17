import 'package:flutter/material.dart';

import '../models/study_result.dart';

class ResultScreen extends StatelessWidget {
  final StudyResult result;
  const ResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(result.topic, overflow: TextOverflow.ellipsis),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.lightbulb_outline), text: 'Explain'),
              Tab(icon: Icon(Icons.quiz_outlined), text: 'Quiz'),
              Tab(icon: Icon(Icons.style_outlined), text: 'Cards'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _ExplanationTab(steps: result.steps),
            _QuizTab(questions: result.quiz),
            _FlashcardsTab(cards: result.flashcards),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- Explanation

class _ExplanationTab extends StatelessWidget {
  final List<StudyStep> steps;
  const _ExplanationTab({required this.steps});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: steps.length,
      itemBuilder: (context, i) {
        final s = steps[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(radius: 14, child: Text('${i + 1}')),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(s.explanation),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ----------------------------------------------------------------------- Quiz

class _QuizTab extends StatefulWidget {
  final List<QuizQuestion> questions;
  const _QuizTab({required this.questions});

  @override
  State<_QuizTab> createState() => _QuizTabState();
}

class _QuizTabState extends State<_QuizTab> {
  final Map<int, int> _selected = {}; // question index -> chosen option index

  int get _score => _selected.entries
      .where((e) => widget.questions[e.key].answerIndex == e.value)
      .length;

  @override
  Widget build(BuildContext context) {
    final qs = widget.questions;
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: qs.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              'Score: $_score / ${_selected.length} answered (${qs.length} total)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          );
        }
        final qi = i - 1;
        final q = qs[qi];
        final chosen = _selected[qi];

        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${qi + 1}. ${q.question}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                for (var oi = 0; oi < q.options.length; oi++)
                  _optionTile(qi, q, oi, chosen),
                if (chosen != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    q.why,
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _optionTile(int qi, QuizQuestion q, int oi, int? chosen) {
    Color? color;
    IconData? icon;
    if (chosen != null) {
      if (oi == q.answerIndex) {
        color = Colors.green.shade100;
        icon = Icons.check_circle;
      } else if (oi == chosen) {
        color = Colors.red.shade100;
        icon = Icons.cancel;
      }
    }
    return Card(
      color: color,
      elevation: 0,
      child: ListTile(
        dense: true,
        title: Text(q.options[oi]),
        trailing: icon == null ? null : Icon(icon),
        onTap: chosen != null ? null : () => setState(() => _selected[qi] = oi),
      ),
    );
  }
}

// ----------------------------------------------------------------- Flashcards

class _FlashcardsTab extends StatefulWidget {
  final List<Flashcard> cards;
  const _FlashcardsTab({required this.cards});

  @override
  State<_FlashcardsTab> createState() => _FlashcardsTabState();
}

class _FlashcardsTabState extends State<_FlashcardsTab> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cards = widget.cards;
    if (cards.isEmpty) {
      return const Center(child: Text('No flashcards generated.'));
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text('Card ${_page + 1} of ${cards.length} (tap to flip)'),
        ),
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: cards.length,
            onPageChanged: (p) => setState(() => _page = p),
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.all(24),
              child: _FlipCard(card: cards[i]),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Text('Swipe left or right for the next card'),
        ),
      ],
    );
  }
}

class _FlipCard extends StatefulWidget {
  final Flashcard card;
  const _FlipCard({required this.card});

  @override
  State<_FlipCard> createState() => _FlipCardState();
}

class _FlipCardState extends State<_FlipCard> {
  bool _showBack = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = _showBack ? widget.card.back : widget.card.front;

    return GestureDetector(
      onTap: () => setState(() => _showBack = !_showBack),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: Card(
          key: ValueKey(_showBack),
          color: _showBack
              ? scheme.secondaryContainer
              : scheme.primaryContainer,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
