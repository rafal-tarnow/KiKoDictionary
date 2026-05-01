// ================= NOWY PLIK =================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/navigation_provider.dart';
import 'presentation/community_sentences_provider.dart';
import 'presentation/widgets/community_sentence_tile.dart';
import '../../core/constants/app_languages.dart';

class CommunitySentencesPage extends ConsumerWidget {
  const CommunitySentencesPage({super.key});

  // Ten sam piękny dialog co w prywatnych zadaniach
  void _showLoginPrompt(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.group_add_outlined,
                    size: 64,
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    "Dołącz do społeczności!",
                    style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Zaloguj się, aby zapisywać zdania od innych użytkowników w swoim prywatnym notatniku.",
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ref.read(navigationIndexProvider.notifier).state =
                            4; // Rejestracja
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text("ZAŁÓŻ KONTO"),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        ref.read(navigationIndexProvider.notifier).state =
                            5; // Logowanie
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text("ZALOGUJ SIĘ"),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text(
                      "Może później",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(communitySentencesProvider);
    final notifier = ref.read(communitySentencesProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      // --- PASEK PAGINACJI ---
      bottomNavigationBar: state.totalPages > 1
          ? SafeArea(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  border: Border(
                    top: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton.icon(
                      onPressed: state.currentPage > 1 && !state.isLoading
                          ? () => notifier.previousPage()
                          : null,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text("Poprzednia"),
                    ),
                    Text(
                      "Strona ${state.currentPage} z ${state.totalPages}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton.icon(
                      onPressed: !state.isLastPage && !state.isLoading
                          ? () => notifier.nextPage()
                          : null,
                      label: const Text("Następna"),
                      icon: const Icon(Icons.arrow_forward),
                    ),
                  ],
                ),
              ),
            )
          : null,

      body: Column(
        children: [
          // --- PASEK FILTROWANIA (Przyklejony do góry) ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.filter_list, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      hint: const Text("Język źródłowy"),
                      value: state.sourceLang,
                      items: AppLanguages.supported.keys.map((code) {
                        return DropdownMenuItem(
                          value: code,
                          child: Text(
                            '${AppLanguages.getFlag(code)} ${AppLanguages.getName(code)}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: (val) =>
                          notifier.updateFilters(sourceLang: val),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Pasek Błędu
          if (state.errorMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.red.shade100,
              width: double.infinity,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Błąd: ${state.errorMessage}',
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => notifier.refreshCurrentPage(),
                    icon: Icon(Icons.refresh, color: Colors.red.shade900),
                    label: Text(
                      "Ponów",
                      style: TextStyle(color: Colors.red.shade900),
                    ),
                  ),
                ],
              ),
            ),

          // --- LISTA ---
          Expanded(
            child: state.isLoading && state.sentences.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.sentences.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 72,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Brak zdań w tym języku",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Zmień filtry lub wróć później.",
                            style: TextStyle(color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  )
                : Stack(
                    children: [
                      ListView.separated(
                        itemCount: state.sentences.length,
                        padding: const EdgeInsets.all(8),
                        separatorBuilder: (context, index) => Divider(
                          height: 16,
                          thickness: 0.5,
                          color: Colors.grey.shade300,
                          indent: 8,
                          endIndent: 8,
                        ),
                        itemBuilder: (context, index) {
                          return CommunitySentenceTile(
                            sentence: state.sentences[index],
                            onLoginPrompt: () => _showLoginPrompt(
                              context,
                              ref,
                            ), // Przekazujemy funkcję dialogu!
                          );
                        },
                      ),
                      if (state.isLoading)
                        const Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          child: LinearProgressIndicator(minHeight: 3),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
